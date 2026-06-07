### Quick Start

A minimal SQLQuery Library:

```json
{
  "resourceType": "Library",
  "meta": {
    "profile": ["https://sql-on-fhir.org/ig/StructureDefinition/SQLQuery"]
  },
  "type": {
    "coding": [
      {
        "system": "https://sql-on-fhir.org/ig/CodeSystem/LibraryTypesCodes",
        "code": "sql-query"
      }
    ]
  },
  "name": "PatientBloodPressure",
  "status": "active",
  "relatedArtifact": [
    {
      "type": "depends-on",
      "resource": "https://example.org/ViewDefinition/patient_view",
      "label": "patient"
    },
    {
      "type": "depends-on",
      "resource": "https://example.org/ViewDefinition/bp_view",
      "label": "bp"
    }
  ],
  "parameter": [
    { "name": "patient_id", "type": "string", "use": "in" },
    { "name": "from_date", "type": "date", "use": "in" }
  ],
  "content": [
    {
      "contentType": "application/sql",
      "extension": [
        {
          "url": "https://sql-on-fhir.org/ig/StructureDefinition/sql-text",
          "valueString": "SELECT patient.id, bp.systolic FROM ..."
        }
      ],
      "data": "U0VMRUNUIHBhdGllbnQu..."
    }
  ]
}
```

Decoded SQL (matches both the `sql-text` extension and the base64 `data`):

```sql
SELECT patient.id, bp.systolic
FROM patient
JOIN bp ON patient.id = bp.patient_id
WHERE patient.id = :patient_id
  AND bp.effective_date >= :from_date
```

### Query Composition

An SQLQuery may reference a reusable
[SQLView](StructureDefinition-SQLView.html) as well as ViewDefinitions, letting
queries build on one another much like SQL views. A ViewDefinition projects FHIR
resources into tables; an SQLView wraps a query over those tables and exposes it
under a canonical URL; an SQLQuery composes both as its table sources.

These references form a directed graph of ViewDefinitions, SQLViews, and
SQLQueries, in which each referenced result acts as a virtual table for the
referencing query. Authors SHOULD keep this graph acyclic. Whether circular
dependencies are detected, any limit on dependency depth, and whether
intermediate results are materialised or inlined (for example as CTEs or
database views) are implementation decisions and are not mandated by this
specification.

The [Active Patient Addresses](Library-ActivePatientAddressesQuery.html) example
shows an SQLQuery that references the
[Active Patients](Library-ActivePatientsView.html) SQLView.

### Parameter Types

Each `Library.parameter` declares a `type` that callers must honour when
supplying values. When parameters are passed at invocation time via a
`Parameters` resource (for example to [`$sqlquery-run`](OperationDefinition-SQLQueryRun.html)
or [`$sqlquery-export`](OperationDefinition-SQLQueryExport.html)), each entry
is bound by name to the matching `Library.parameter`, and the appropriate
`value[x]` element must be used for the declared type:

| Library.parameter.type | Parameters.parameter value |
| ---------------------- | -------------------------- |
| `string`               | `valueString`              |
| `integer`              | `valueInteger`             |
| `date`                 | `valueDate`                |
| `dateTime`             | `valueDateTime`            |
| `boolean`              | `valueBoolean`             |
| `decimal`              | `valueDecimal`             |

{:.table-data}

### SQL Annotations

SQL files MAY include annotations to generate SQLQuery Libraries automatically.
Library elements are authoritative. Based on
[Brian Kaney's sql-fhir-library-builder](https://github.com/reason-healthcare/sql-fhir-library-builder).

Syntax: `@key: value` in SQL comments.

```sql
/*
@name: PatientBloodPressure
@title: Patient Blood Pressure Report
@version: 1.0.0
@status: active
*/

-- @param: patient_id string Patient identifier
-- @param: from_date date Start date
-- @relatedDependency: https://example.org/ViewDefinition/patient_view as patient
-- @relatedDependency: https://example.org/ViewDefinition/bp_view as bp

SELECT patient.id, bp.systolic
FROM patient JOIN bp ON patient.id = bp.patient_id
WHERE patient.id = :patient_id AND bp.effective_date >= :from_date
```

Annotation reference:

| Annotation           | FHIR Mapping          | Format                                            |
| -------------------- | --------------------- | ------------------------------------------------- |
| `@name`              | `Library.name`        | `@name: identifier`                               |
| `@title`             | `Library.title`       | `@title: Human Title`                             |
| `@description`       | `Library.description` | `@description: text`                              |
| `@version`           | `Library.version`     | `@version: semver`                                |
| `@status`            | `Library.status`      | `@status: draft\|active\|retired`                 |
| `@author`            | `Library.author.name` | `@author: Name` (repeatable)                      |
| `@publisher`         | `Library.publisher`   | `@publisher: Org`                                 |
| `@param`             | `Library.parameter`   | `@param: name type [description]` (repeatable)    |
| `@relatedDependency` | `relatedArtifact`     | `@relatedDependency: URL [as label]` (repeatable) |

### Tooling

Builders SHALL:

1. Parse annotations from block (`/* */`) and line (`--`) comments
2. Populate the `sql-text` extension with the SQL text (plain text)
3. Generate `content.data` with base64-encoded SQL
4. Set `content.contentType` to `application/sql`
5. Set `type` to `LibraryTypesCodes#sql-query`
6. Set `parameter.use` to `in` for all parameters
7. Set `relatedArtifact.type` to `depends-on` for all dependencies

Builders SHOULD:

1. Infer `name` from filename if `@name` not provided
2. Default `status` to `draft` if not specified
3. Validate parameter types against allowed FHIR types
4. Validate labels as SQL identifiers (`^[a-zA-Z_][a-zA-Z0-9_]*$`)
5. Warn on unrecognized annotations
