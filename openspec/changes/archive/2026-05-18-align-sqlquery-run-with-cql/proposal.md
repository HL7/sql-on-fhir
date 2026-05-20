## Why

The `$sqlquery-run` operation currently defines a custom `parameter` (0..*) input with
`name` + `value` parts to pass query parameters. This is similar to how SDC `$populate`
handles its `context` parameter (repeating with `name`+`content` parts), but for our use
case — passing arbitrary typed parameters to a library by name — there is a more precise
precedent.

The [CQL IG `$evaluate` operation](https://build.fhir.org/ig/HL7/cql-ig/en/OperationDefinition-cql-library-evaluate.html)
([source](https://github.com/HL7/cql-ig/blob/main/input/resources/operationdefinition-cql-library-evaluate.json))
uses `parameters: Parameters (0..1)` — a nested `Parameters` resource where values are
bound by name to library parameters. This is the closest analogy to our case: both CQL
`$evaluate` and `$sqlquery-run` execute a Library with user-supplied typed parameters.

The FHIR `Parameters` resource already provides `name` + `value[x]` pairs with full
type support, lists (via repeated names), and complex types (via parts). Our custom
`parameter` with `part[name, value]` reinvents this structure.

As noted in [chat.fhir.org CQL discussions](https://chat.fhir.org/#narrow/stream/cql/topic/Measure%20Evaluate%20Input%20Parameters),
commonly used primitive parameters are surfaced as top-level operation parameters for
GET compatibility, while the nested `Parameters` resource is used for arbitrary/dynamic
inputs — exactly our scenario.

See issue [#318](https://github.com/FHIR/sql-on-fhir-v2/issues/318).

## What Changes

- **BREAKING**: Replace `parameter` (0..*) with parts `{name, value}` → `parameters` (Parameters, 0..1)
  - Current (lines 388-406 in `input/fsh/operations.fsh`):
    ```
    parameter: 0..*
      part[0]: name (string, 1..1)
      part[1]: value (DataType, 1..1)
    ```
  - Proposed (aligned with CQL `$evaluate`):
    ```
    parameters: Parameters (0..1)
    ```
  - Parameter binding: by name, matching `Library.parameter.name` declarations
- Update operation documentation in `OperationDefinition-SQLQueryRun-intro.md` and
  `OperationDefinition-SQLQueryRun-notes.md` to reflect new parameter passing style
- Update FSH examples in `input/fsh/examples/sql-query-examples.fsh`
- Add clear examples of operation calls with parameters showing before/after:
  - **Before** (current — custom parts):
    ```json
    { "name": "parameter", "part": [
      { "name": "name", "valueString": "patient_id" },
      { "name": "value", "valueString": "Patient/123" }
    ]}
    ```
  - **After** (proposed — nested Parameters resource):
    ```json
    { "name": "parameters", "resource": {
      "resourceType": "Parameters",
      "parameter": [
        { "name": "patient_id", "valueString": "Patient/123" },
        { "name": "from_date", "valueDate": "2024-01-01" }
      ]
    }}
    ```
  The new style is more concise — no wrapping `part` with separate `name`/`value`,
  just direct `name` + `value[x]` in the Parameters resource. Multiple parameters go
  into one resource instead of repeating the outer parameter.

## Capabilities

### New Capabilities

_(none — this is a modification of existing capability)_

### Modified Capabilities

- `sqlquery-run`: Replace custom parameter passing with nested `Parameters` resource input, aligned with CQL `$evaluate` pattern

## Impact

- **FSH**: `input/fsh/operations.fsh` — rewrite `parameter[4]` definition
- **Documentation**: `OperationDefinition-SQLQueryRun-intro.md`, `OperationDefinition-SQLQueryRun-notes.md` — update parameter usage guidance and examples
- **Examples**: `input/fsh/examples/sql-query-examples.fsh` — update example instances
- **Breaking**: Clients currently sending repeated `parameter` parts will need to send a single `Parameters` resource instead
- **No impact** on: ViewDefinition processing, SQL execution, output formats, or other operations
