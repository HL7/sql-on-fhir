# CapabilityStatement for SQL-on-FHIR API

The server SHALL support the CapabilityStatement resource to allow clients to discover supported operations.

The CapabilityStatement.rest.resource array SHALL contain an entry for the ViewDefinition resource type with:

- An operation element with:
  - name = "$viewdefinition-export"
  - definition = "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/ViewDefinitionExport"
- An operation element with:
  - name = "$viewdefinition-run"
  - definition = "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/ViewDefinitionRun"

If the server supports CRUD and search interactions for the ViewDefinition resource type, the interaction array SHALL include the appropriate codes:

- read
- search-type
- write
- patch
- delete
- create

The CapabilityStatement.rest.resource array SHALL also contain an entry for the Library resource type (a SQLQuery is a profile of Library) with:

- An operation element with:
  - name = "$sqlquery-run"
  - definition = "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/SQLQueryRun"
- An operation element with:
  - name = "$sqlquery-export"
  - definition = "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/SQLQueryExport"

If the server supports CRUD and search interactions for the Library resource type, the interaction array SHALL include the appropriate codes:

- read
- search-type
- write
- patch
- delete
- create

## Example

```http
GET /metadata HTTP/1.1
Accept: application/fhir+json
```

```http
HTTP/1.1 200 OK
Content-Type: application/fhir+json

{
  "resourceType": "CapabilityStatement",
  "status": "active",
  "date": "2023-07-13T10:00:00Z",
  "publisher": "SQL on FHIR",
  "kind": "instance",
  "fhirVersion": "4.0.1",
  "format": ["application/fhir+json"],
  "rest": [{
    "mode": "server",
    "resource": [{
      "type": "ViewDefinition",
      "interaction": [
        { "code": "read" },
        { "code": "search-type" },
        { "code": "write" },
        { "code": "patch" },
        { "code": "delete" },
        { "code": "create" }
      ],
      "operation": [
        {
          "name": "$viewdefinition-export",
          "definition": "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/ViewDefinitionExport"
        },
        {
          "name": "$viewdefinition-run",
          "definition": "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/ViewDefinitionRun"
        }
      ]
    },
    {
      "type": "Library",
      "interaction": [
        { "code": "read" },
        { "code": "search-type" },
        { "code": "write" },
        { "code": "patch" },
        { "code": "delete" },
        { "code": "create" }
      ],
      "operation": [
        {
          "name": "$sqlquery-run",
          "definition": "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/SQLQueryRun"
        },
        {
          "name": "$sqlquery-export",
          "definition": "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/SQLQueryExport"
        }
      ]
    }]
  }]
}
```
