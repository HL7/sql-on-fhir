## Why

The `$viewdefinition-run` operation defines a `_limit` input parameter (a server-side row cap) but `$sqlquery-run` does not. The two operations sit side-by-side, serve very similar use cases, and there is no design reason for the asymmetry. If anything, `$sqlquery-run` has a stronger case for a row cap because user-supplied SQL can produce arbitrarily large result sets via aggregation, joins, and CTEs.

See issue [#346](https://github.com/FHIR/sql-on-fhir-v2/issues/346). Surfaced during a Pathling implementation review of `$sqlquery-run` (aehrc/pathling#2579), where `_limit` was added to the implementation by mirroring the `$viewdefinition-run` pattern, then flagged as a non-spec parameter.

## What Changes

- Add `_limit` input parameter to `$sqlquery-run` with the same signature as `$viewdefinition-run`:
    - `name`: `_limit`
    - `use`: `in`
    - cardinality: `0..1`
    - `scope`: `system`, `type`, `instance`
    - `type`: `integer`
    - `documentation`: "Maximum number of rows to return."
- Update `OperationDefinition-SQLQueryRun-notes.md` to document `_limit` in the parameter tables and add narrative clarifying:
    - Servers MAY enforce a maximum value (capping client-supplied limits).
    - The limit applies to the final result set returned to the client, after the SQL query (including any in-query `LIMIT`) has been evaluated.
    - Exceeding the cap is not an error; the server returns up to `_limit` rows.
- Not a breaking change: existing clients that omit `_limit` continue to work unchanged.

## Capabilities

### New Capabilities

_(none - this modifies an existing capability)_

### Modified Capabilities

- `sqlquery-run`: Add `_limit` input parameter and the server-side semantics described above.

## Impact

- **FSH**: `input/fsh/operations.fsh` - add a new `parameter[N]` block for `_limit` to the `SQLQueryRun` OperationDefinition.
- **Documentation**: `input/pagecontent/OperationDefinition-SQLQueryRun-notes.md` - extend the parameter tables and narrative to describe `_limit`.
- **No impact** on: `$viewdefinition-run`, `$sqlquery-export`, the `SQLQuery` profile, ViewDefinition processing, output formats, or other parameters of `$sqlquery-run`.
- **Reference implementation** (`sof-js/`): out of scope here; it does not currently implement `$sqlquery-run` end-to-end.
