### Examples

#### Instance-Level (Library on Server)

When the SQLQuery Library is stored on the server, invoke directly on the instance:

```http
POST /Library/patient-bp-query/$sqlquery-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "_format", "valueCode": "csv" },
    { "name": "parameters", "resource": {
      "resourceType": "Parameters",
      "parameter": [
        { "name": "patient_id", "valueString": "Patient/123" },
        { "name": "from_date", "valueDate": "2024-01-01" }
      ]
    }}
  ]
}
```

#### Type-Level with Reference

Reference a stored Library by URL or relative reference:

```http
POST /Library/$sqlquery-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "_format", "valueCode": "json" },
    { "name": "queryReference", "valueReference": {
      "reference": "Library/patient-bp-query"
    }},
    { "name": "parameters", "resource": {
      "resourceType": "Parameters",
      "parameter": [
        { "name": "patient_id", "valueString": "Patient/123" }
      ]
    }}
  ]
}
```

#### Type-Level with Inline Resource

Pass the SQLQuery Library inline for ad-hoc queries:

```http
POST /Library/$sqlquery-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "_format", "valueCode": "ndjson" },
    { "name": "queryResource", "resource": {
      "resourceType": "Library",
      "meta": { "profile": ["https://sql-on-fhir.org/ig/StructureDefinition/SQLQuery"] },
      "type": { "coding": [{ "system": "https://sql-on-fhir.org/ig/CodeSystem/LibraryTypesCodes", "code": "sql-query" }] },
      "status": "active",
      "relatedArtifact": [
        { "type": "depends-on", "resource": "https://example.org/ViewDefinition/patient_view", "label": "p" }
      ],
      "content": [{
        "contentType": "application/sql",
        "data": "U0VMRUNUIHAuaWQsIHAubmFtZSBGUk9NIHAgV0hFUkUgcC5hY3RpdmUgPSB0cnVl",
        "extension": [{
          "url": "https://sql-on-fhir.org/ig/StructureDefinition/sql-text",
          "valueString": "SELECT p.id, p.name FROM p WHERE p.active = true"
        }]
      }]
    }}
  ]
}
```

#### System-Level

Invoke at the server base without a resource type. This is useful when the server
supports SQLQuery Libraries but does not expose them as FHIR Library resources:

```http
POST /$sqlquery-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "_format", "valueCode": "csv" },
    { "name": "queryReference", "valueReference": {
      "reference": "Library/patient-bp-query"
    }},
    { "name": "parameter", "part": [
      { "name": "name", "valueString": "patient_id" },
      { "name": "value", "valueString": "Patient/123" }
    ]}
  ]
}
```

#### Response

For flat formats (`csv`, `json`, `ndjson`, `parquet`), the response is a Binary:

```http
HTTP/1.1 200 OK
Content-Type: text/csv

patient_id,systolic,effective_date
Patient/123,120,2024-01-15
Patient/123,118,2024-02-20
```

#### FHIR Format Response

When `_format=fhir`, the response is a FHIR Parameters resource with each row as a
repeating `row` parameter.

```http
POST /Library/patient-bp-query/$sqlquery-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "_format", "valueCode": "fhir" },
    { "name": "parameters", "resource": {
      "resourceType": "Parameters",
      "parameter": [
        { "name": "patient_id", "valueString": "Patient/123" }
      ]
    }}
  ]
}
```

Response:

```json
{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "row", "part": [
      { "name": "patient_id", "valueString": "Patient/123" },
      { "name": "systolic", "valueInteger": 120 },
      { "name": "effective_date", "valueDate": "2024-01-15" }
    ]},
    { "name": "row", "part": [
      { "name": "patient_id", "valueString": "Patient/123" },
      { "name": "systolic", "valueInteger": 118 },
      { "name": "effective_date", "valueDate": "2024-02-20" }
    ]}
  ]
}
```

When a query returns zero rows, the response is a Parameters resource with no
`parameter` elements:

```json
{
  "resourceType": "Parameters"
}
```

### SQL to FHIR type mapping

When `_format=fhir`, each result column must be encoded using a FHIR `value[x]`
type. The following table defines the mapping from
[ISO/IEC 9075](https://www.iso.org/standard/76583.html) SQL types to FHIR
parameter value types.

| ISO/IEC 9075 SQL type                                | FHIR value type     |
|------------------------------------------------------|---------------------|
| BOOLEAN                                              | `valueBoolean`      |
| TINYINT, SMALLINT, INT, INTEGER                      | `valueInteger`      |
| BIGINT                                               | `valueInteger64`    |
| DECIMAL, NUMERIC                                     | `valueDecimal`      |
| REAL                                                 | `valueDecimal`      |
| FLOAT, DOUBLE PRECISION                              | `valueDecimal`      |
| CHARACTER, CHARACTER VARYING, CHARACTER LARGE OBJECT | `valueString`       |
| BINARY, BINARY VARYING, BINARY LARGE OBJECT          | `valueBase64Binary` |
| DATE                                                 | `valueDate`         |
| TIME, TIME WITH TIME ZONE                            | `valueTime`         |
| TIMESTAMP                                            | `valueDateTime`     |
| TIMESTAMP WITH TIME ZONE                             | `valueInstant`      |
{:.table-data}

SQL NULL values are represented by omitting the corresponding part from the row
parameter.

Conversion of REAL, FLOAT, and DOUBLE PRECISION values to `valueDecimal` may
introduce representation artefacts due to the difference between binary and
decimal floating point.

TIMESTAMP WITH TIME ZONE values may carry sub-millisecond precision (e.g.
microseconds), but FHIR `instant` supports at most millisecond precision.
Implementations SHOULD round to the nearest millisecond when converting to
`valueInstant`.

TIMESTAMP (without time zone) values are converted to `valueDateTime` without a
timezone offset. FHIR `dateTime` permits values with or without a timezone, so
the absence of timezone information is preserved rather than trying to infer a
time zone.

ISO/IEC 9075 types not listed in this table (such as INTERVAL, ARRAY, XML, ROW,
and MULTISET) are not supported. If a query produces a result column with an
unsupported type, the server MUST return a `422 Unprocessable Entity` error.
Query authors can work around this by casting unsupported types to a supported
type within the SQL query.

### Parameter Passing

Query parameters are passed as a nested `Parameters` resource, following the same
pattern as the [CQL `$evaluate` operation](https://build.fhir.org/ig/HL7/cql-ig/en/OperationDefinition-cql-library-evaluate.html).
Each parameter in the `Parameters` resource is bound by name to a parameter declared
in the SQLQuery Library (`Library.parameter`).

Use the appropriate `value[x]` type matching the Library's declared parameter type:

| Library.parameter.type | Parameters.parameter value |
|------------------------|----------------------------|
| `string` | `valueString` |
| `integer` | `valueInteger` |
| `date` | `valueDate` |
| `dateTime` | `valueDateTime` |
| `boolean` | `valueBoolean` |
| `decimal` | `valueDecimal` |

### Error Handling

| Status | Condition |
|--------|-----------|
| `400 Bad Request` | Missing required parameter, unknown parameter name, or value type mismatch |
| `404 Not Found` | Library or ViewDefinition not found |
| `422 Unprocessable Entity` | SQL execution error, or unsupported SQL column type when using `_format=fhir` (see [type mapping](#sql-to-fhir-type-mapping)) |
