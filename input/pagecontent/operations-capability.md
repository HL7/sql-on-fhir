# CapabilityStatement for SQL-on-FHIR API

The server SHALL support the CapabilityStatement resource to allow clients to discover supported operations.

Both data operations are invoked at the system level, so they are declared in
`CapabilityStatement.rest.operation` rather than under a resource type. The
`CapabilityStatement.rest.operation` array SHALL contain:

- An operation element with:
  - name = "$sql-run"
  - definition = "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/SQLRun"
- An operation element with:
  - name = "$sql-export"
  - definition = "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/SQLExport"

A client therefore learns which data operations a server offers without reading
any `rest.resource` entry.

The `rest.resource` entries remain relevant for the artefacts themselves, which
a server may still expose as FHIR resources. If the server supports CRUD and
search interactions for the ViewDefinition resource type, the
`CapabilityStatement.rest.resource` array SHALL contain an entry for it whose
interaction array includes the appropriate codes:

- read
- search-type
- write
- patch
- delete
- create

The same applies to the Library resource type, of which
[SQLQuery](StructureDefinition-SQLQuery.html) and
[SQLView](StructureDefinition-SQLView.html) are profiles. Neither entry carries
an `operation` element, because the data operations no longer hang off a resource
type.

## Declaring partial operation support {#partial-operation-support}

A server need not support every parameter of an operation. Which subset it does
support SHALL be discoverable from its CapabilityStatement, using the mechanism
base FHIR already defines for
[`CapabilityStatement.rest.operation.definition`](https://hl7.org/fhir/R5/capabilitystatement-definitions.html#CapabilityStatement.rest.operation.definition):

- Citing an OperationDefinition published by this guide asserts support for the
  **full** capabilities of that operation, including every parameter it declares.
- A server supporting only a subset SHALL publish its own OperationDefinition
  whose `base` is the canonical URL of the one this guide publishes, declaring
  only the parameters it supports, and SHALL point
  `CapabilityStatement.rest.operation.definition` at its own definition rather
  than at this guide's.

This applies to the three ways of naming an operation's subject as it does to any
other parameter: a server that resolves canonical URLs and inline resources but
not literal references declares that by omitting `subjectReference` from its own
definition. A request carrying a parameter the server does not support is
rejected with `400 Bad Request` and an `OperationOutcome`.

`operation.documentation` remains available for free-text notes, but it is not
machine-readable, so it is not a substitute for the mechanism above.

For example, a server that supports `subjectCanonical` and `subjectResource` on
`$sql-run` but not `subjectReference` cites its own definition:

```json
{
  "resourceType": "CapabilityStatement",
  "rest": [
    {
      "mode": "server",
      "operation": [
        {
          "name": "$sql-run",
          "definition": "http://example.org/OperationDefinition/sql-run-supported"
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
  "url": "http://example.org/OperationDefinition/sql-run-supported",
  "name": "SQLRunSupported",
  "base": "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/SQLRun",
  "status": "active",
  "kind": "operation",
  "code": "sql-run",
  "system": true,
  "type": false,
  "instance": false,
  "parameter": [
    {
      "name": "subjectCanonical",
      "use": "in",
      "min": 0,
      "max": "1",
      "type": "canonical"
    },
    {
      "name": "subjectResource",
      "use": "in",
      "min": 0,
      "max": "1",
      "type": "CanonicalResource"
    },
    { "name": "return", "use": "out", "min": 1, "max": "1", "type": "Binary" }
  ]
}
```

A client reading that definition knows not to send `subjectReference`.

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
    "operation": [
      {
        "name": "$sql-run",
        "definition": "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/SQLRun"
      },
      {
        "name": "$sql-export",
        "definition": "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/SQLExport"
      }
    ],
    "resource": [{
      "type": "ViewDefinition",
      "interaction": [
        { "code": "read" },
        { "code": "search-type" },
        { "code": "write" },
        { "code": "patch" },
        { "code": "delete" },
        { "code": "create" }
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
      ]
    }]
  }]
}
```

The two `rest.resource` entries carry their CRUD and search interactions and no
`operation` element; the data operations are declared once, at the system level,
in `rest.operation`.
