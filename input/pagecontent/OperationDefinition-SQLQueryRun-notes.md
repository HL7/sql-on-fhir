### Input Parameters

The operation is invoked with POST. The following input parameters are passed
inside a `Parameters` resource in the request body.

| Name           | Type       | Scope                  | Required     | Max | Description                                                                                           |
| -------------- | ---------- | ---------------------- | ------------ | --- | ----------------------------------------------------------------------------------------------------- |
| \_format       | code       | system, type, instance | No           | 1   | Output format: `json`, `ndjson`, `csv`, `parquet`, `fhir`. [Details](#format-parameter-clarification) |
| header         | boolean    | system, type, instance | No           | 1   | Include CSV headers (default: true). Only applies to `csv` format                                     |
| queryReference | Reference  | system, type           | Conditional¹ | 1   | Reference to a SQLQuery Library stored on the server                                                  |
| queryResource  | Resource   | system, type           | Conditional¹ | 1   | Inline SQLQuery Library resource to execute                                                           |
| parameters     | Parameters | system, type, instance | No           | 1   | Input parameters bound by name to parameters declared in the SQLQuery Library                         |
| source         | string     | system, type, instance | No           | 1   | External data source containing the ViewDefinition tables (e.g. URI, bucket name)                     |
| \_limit        | integer    | system, type, instance | No           | 1   | Maximum number of rows to return                                                                      |

{:.table-data}

¹ Either `queryReference` or `queryResource` is required at the system and type
levels; neither is allowed at the instance level (the Library is identified by
the path).

#### Output Parameter

| Name   | Type     | Description                                                                                          |
| ------ | -------- | ---------------------------------------------------------------------------------------------------- |
| return | Resource | Query results. Returns Binary for flat formats (csv, json, ndjson, parquet) or Parameters for `fhir`. The Binary is a raw stream in the format's native media type, not a serialized Binary envelope. See [Return Representation](operations-common.html#return-representation) |

{:.table-data}

#### Row Limit

When supplied, `_limit` is the maximum number of rows the server returns to the
client.

Servers MAY enforce a maximum value, silently capping client-supplied limits at
a smaller server-defined maximum. The cap is applied to the final result set
after the SQL query (including any in-query `LIMIT`) has been evaluated;
implementations are free to push the limit down into the query as an
optimisation, but the observable behaviour is post-evaluation.

Returning fewer rows than the client requested - whether because the query
yielded fewer rows or because the server applied its own cap - is not treated
as an error.

#### Format Parameter Clarification

The supported formats (`json`, `ndjson`, `csv`, `parquet`, `fhir`), the default,
the `Accept`-vs-`_format` precedence rule, the raw-vs-envelope representation
axis, and transfer framing are defined in
[Common Operation Behavior](operations-common.html) and apply identically to
this operation:

- It is RECOMMENDED to support `json`, `ndjson` and `csv` by default; servers MAY
  support `parquet` and `fhir`, and SHALL document supported formats in the
  CapabilityStatement.
- If `_format` is omitted (and no format is derivable from `Accept`), the server
  SHALL return the result in `ndjson` format.
- When `_format` is supplied, its value SHALL take precedence over `Accept`.
- The response of any format MAY use `Transfer-Encoding: chunked`; chunked
  transfer is independent of the format. See
  [Streaming and Transfer Encoding](operations-common.html#streaming).

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

#### Default Format (`_format` omitted)

When `_format` is omitted, the server returns the result in `ndjson` format:

```http
POST /Library/patient-bp-query/$sqlquery-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "parameters", "resource": {
      "resourceType": "Parameters",
      "parameter": [
        { "name": "patient_id", "valueString": "Patient/123" }
      ]
    }}
  ]
}
```

```http
HTTP/1.1 200 OK
Content-Type: application/x-ndjson

{"patient_id":"Patient/123","systolic":120,"effective_date":"2024-01-15"}
{"patient_id":"Patient/123","systolic":118,"effective_date":"2024-02-20"}
```

#### Capping Result Rows with `_limit`

Use `_limit` to ask the server to return at most a given number of rows. The
server may return fewer rows if the query yields fewer or if its configured
maximum is smaller; see [Row Limit](#row-limit) for the full semantics.

```http
POST /Library/patient-bp-query/$sqlquery-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "_format", "valueCode": "csv" },
    { "name": "_limit", "valueInteger": 100 }
  ]
}
```

#### Response

For flat formats (`csv`, `json`, `ndjson`, `parquet`), the response body is the
raw payload in the format's native media type (the `Binary` stream), not a
serialized `Binary` resource envelope; `Content-Type` is set to that media type.
The response MAY be sent with `Transfer-Encoding: chunked` regardless of format.
See [Return Representation](operations-common.html#return-representation) and
[Streaming](operations-common.html#streaming).

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
        {
            "name": "row",
            "part": [
                { "name": "patient_id", "valueString": "Patient/123" },
                { "name": "systolic", "valueInteger": 120 },
                { "name": "effective_date", "valueDate": "2024-01-15" }
            ]
        },
        {
            "name": "row",
            "part": [
                { "name": "patient_id", "valueString": "Patient/123" },
                { "name": "systolic", "valueInteger": 118 },
                { "name": "effective_date", "valueDate": "2024-02-20" }
            ]
        }
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
| ---------------------------------------------------- | ------------------- |
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

Query parameters are passed as a nested `Parameters` resource, following the
same pattern as the
[CQL `$evaluate` operation](https://build.fhir.org/ig/HL7/cql-ig/en/OperationDefinition-cql-library-evaluate.html).
See [Parameter Types](StructureDefinition-SQLQuery.html#parameter-types) on the
SQLQuery profile for the binding rules and the mapping from
`Library.parameter.type` to the `value[x]` element to use.

### Error Handling

| Status                     | Condition                                                                                                                     |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `400 Bad Request`          | Missing required parameter, unknown parameter name, or value type mismatch                                                    |
| `404 Not Found`            | Library or ViewDefinition not found                                                                                           |
| `422 Unprocessable Entity` | SQL execution error, or unsupported SQL column type when using `_format=fhir` (see [type mapping](#sql-to-fhir-type-mapping)) |
