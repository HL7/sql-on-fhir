## Context

The `$sqlquery-run` operation (defined in `input/fsh/operations.fsh`, lines 331-424) has
6 input parameters and 1 output. Parameter #4 (`parameter`, 0..*) uses a custom `part`
structure with `name` (string) and `value` (DataType) to pass query parameters by name.

The CQL IG `$evaluate` operation uses a single `parameters: Parameters (0..1)` input —
a nested `Parameters` resource — for the same purpose. `Parameters` is a FHIR **resource**
(not a datatype), so it is passed via `resource` element, not `value[x]`.

Files involved:
- `input/fsh/operations.fsh` — OperationDefinition FSH (lines 388-406 for parameter[4])
- `input/pagecontent/OperationDefinition-SQLQueryRun-intro.md` — intro docs
- `input/pagecontent/OperationDefinition-SQLQueryRun-notes.md` — examples and parameter type table
- `input/fsh/examples/sql-query-examples.fsh` — FSH example instances

## Goals / Non-Goals

**Goals:**
- Replace `parameter` (0..*) with `parameters: Parameters (0..1)` in the OperationDefinition
- Update all documentation and examples to show the new calling convention
- Align with CQL `$evaluate` pattern for passing arbitrary typed parameters to a Library

**Non-Goals:**
- Changing other operation parameters (`_format`, `header`, `queryReference`, `queryResource`, `source`)
- Adding new parameters (e.g., `url` canonical, `subject`)
- Modifying the `$sqlquery-export` or `$viewdefinition-run` operations
- Changes to the reference implementation in `sof-js/`

## Decisions

### 1. Use `Parameters` resource (not parts)

**Choice**: `parameters: Parameters (0..1)` — one nested Parameters resource.

**Alternatives considered**:
- Keep current `parameter` (0..*) with `part[name, value]` — works, but reinvents what
  Parameters already provides and diverges from CQL precedent
- Flat top-level parameters — not feasible because query parameters are dynamic/arbitrary,
  not known at OperationDefinition time

**Rationale**: Parameters resource provides `name` + `value[x]` with full FHIR type coverage,
list support (repeated names), and complex types (parts) out of the box. CQL `$evaluate`
validates this as the FHIR-standard approach for library parameter passing.

### 2. Parameter name: `parameters` (plural)

**Choice**: Name the parameter `parameters` (matching CQL `$evaluate`).

**Rationale**: Consistent with the only other FHIR IG that does the same thing. The name
clearly indicates it carries a `Parameters` resource.

### 3. Scope: type + instance

**Choice**: Keep the same scopes as the current `parameter` — available at both type-level
and instance-level invocations.

**Rationale**: Query parameters are needed regardless of how the Library is specified.

### 4. Documentation: parameter type mapping table stays

**Choice**: Keep the parameter type mapping table in notes (string→valueString, date→valueDate, etc.)
but reframe it in context of `Parameters.parameter.value[x]`.

**Rationale**: Implementers still need guidance on which `value[x]` type to use for each
`Library.parameter.type`. The table is still useful, just needs updated framing.

## Risks / Trade-offs

- **Breaking change** → Only affects clients passing query parameters; mitigated by clear
  before/after examples in documentation. The spec is pre-release, so breaking changes are expected.
- **Slightly more verbose for single parameter** → A single parameter now requires a nested
  `Parameters` resource wrapper. But for multiple parameters it's actually more concise,
  and consistency with CQL outweighs the minor verbosity.
- **No GET compatibility** → `Parameters` resource cannot be passed via URL query string.
  This is acceptable — same limitation as CQL `$evaluate`, and our parameters are complex types.
