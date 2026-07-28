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

## Declaring partial operation support {#partial-operation-support}

A server need not support every parameter of an operation. Which subset it does
support SHALL be discoverable from its CapabilityStatement, using the mechanism
base FHIR already defines for
[`CapabilityStatement.rest.resource.operation.definition`](https://hl7.org/fhir/R5/capabilitystatement-definitions.html#CapabilityStatement.rest.resource.operation.definition):

- Citing an OperationDefinition published by this guide asserts support for the
  **full** capabilities of that operation, including every parameter it declares.
- A server supporting only a subset SHALL publish its own OperationDefinition
  whose `base` is the canonical URL of the one this guide publishes, declaring
  only the parameters it supports, and SHALL point
  `CapabilityStatement.rest.resource.operation.definition` at its own definition
  rather than at this guide's.

This applies to the three ways of naming an operation's subject as it does to any
other parameter: a server that resolves canonical URLs and inline resources but
not literal references declares that by omitting the `*Reference` parameter from
its own definition. A request carrying a parameter the server does not support is
rejected with `400 Bad Request` and an `OperationOutcome`.

`operation.documentation` remains available for free-text notes, but it is not
machine-readable, so it is not a substitute for the mechanism above.

For example, a server that supports `queryCanonical` and `queryResource` on
`$sqlquery-run` but not `queryReference` cites its own definition:

```json
{
  "resourceType": "CapabilityStatement",
  "rest": [
    {
      "mode": "server",
      "resource": [
        {
          "type": "Library",
          "operation": [
            {
              "name": "$sqlquery-run",
              "definition": "http://example.org/OperationDefinition/sqlquery-run-supported"
            }
          ]
        }
      ]
    }
  ]
}
```

That definition names this guide's as its base, and omits the parameter it does
not support:

```json
{
  "resourceType": "OperationDefinition",
  "url": "http://example.org/OperationDefinition/sqlquery-run-supported",
  "base": "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/SQLQueryRun",
  "status": "active",
  "kind": "operation",
  "code": "sqlquery-run",
  "system": true,
  "type": true,
  "instance": true,
  "parameter": [
    {
      "name": "queryCanonical",
      "use": "in",
      "min": 0,
      "max": "1",
      "type": "canonical"
    },
    {
      "name": "queryResource",
      "use": "in",
      "min": 0,
      "max": "1",
      "type": "Library"
    },
    { "name": "return", "use": "out", "min": 1, "max": "1", "type": "Binary" }
  ]
}
```

A client reading that definition knows not to send `queryReference`.

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
