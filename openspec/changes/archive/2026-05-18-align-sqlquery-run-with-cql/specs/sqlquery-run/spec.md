## MODIFIED Requirements

### Requirement: Query parameter passing
The `$sqlquery-run` operation SHALL accept query parameters via a `parameters` input
parameter of type `Parameters` (FHIR resource) with cardinality 0..1. Parameter values
within the `Parameters` resource SHALL be bound by name to parameters declared in the
SQLQuery Library (`Library.parameter.name`). The `value[x]` type of each parameter
SHALL match the declared type in `Library.parameter.type`.

#### Scenario: Single parameter
- **WHEN** a client invokes `$sqlquery-run` with a `parameters` resource containing one parameter `patient_id` with `valueString` "Patient/123"
- **THEN** the server SHALL bind `patient_id` to the value "Patient/123" in the SQL query execution

#### Scenario: Multiple parameters
- **WHEN** a client invokes `$sqlquery-run` with a `parameters` resource containing `patient_id` (valueString) and `from_date` (valueDate)
- **THEN** the server SHALL bind both parameters by name to the SQL query execution

#### Scenario: No parameters
- **WHEN** a client invokes `$sqlquery-run` without a `parameters` input
- **THEN** the server SHALL execute the query without parameter bindings (query must not require parameters)

#### Scenario: Parameter type mismatch
- **WHEN** a client provides a parameter with a `value[x]` type that does not match the declared `Library.parameter.type`
- **THEN** the server SHALL return a 400 Bad Request with an OperationOutcome describing the type mismatch

#### Scenario: Unknown parameter name
- **WHEN** a client provides a parameter whose name does not match any declared `Library.parameter.name`
- **THEN** the server SHALL return a 400 Bad Request with an OperationOutcome describing the unknown parameter

## REMOVED Requirements

### Requirement: Custom parameter parts
The previous `parameter` input (0..*) with nested `part[0]: name` (string) and
`part[1]: value` (DataType) is removed.

**Reason**: Replaced by `parameters: Parameters (0..1)` — a nested Parameters resource
that provides the same `name` + `value[x]` structure using the standard FHIR resource,
aligned with CQL `$evaluate` operation pattern.

**Migration**: Replace repeated `parameter` entries with a single `parameters` resource:
```json
// Before
{ "name": "parameter", "part": [
  { "name": "name", "valueString": "patient_id" },
  { "name": "value", "valueString": "Patient/123" }
]}

// After
{ "name": "parameters", "resource": {
  "resourceType": "Parameters",
  "parameter": [
    { "name": "patient_id", "valueString": "Patient/123" }
  ]
}}
```
