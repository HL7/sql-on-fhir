## Why

The three operations defined in `input/fsh/operations.fsh` declare the `_format` input parameter inconsistently: `$viewdefinition-export` uses cardinality `0..1` with no documented default, while `$viewdefinition-run` and `$sqlquery-run` use `1..1`. This forces clients to specify `_format` explicitly for two of the three operations or receive `400 Bad Request`, prevents servers from honouring an `Accept` header without violating the OperationDefinition, and leaves `$viewdefinition-export` free to behave differently across implementations when `_format` is omitted.

Surfaced during a Pathling implementation review of `$sqlquery-run` (aehrc/pathling#2579) and tracked in upstream issue [#345](https://github.com/FHIR/sql-on-fhir-v2/issues/345).

## What Changes

- Change `parameter[_format].min` from `1` to `0` on `$viewdefinition-run` and `$sqlquery-run`. The cardinality on `$viewdefinition-export` (already `0..1`) is unchanged.
- Update the `documentation` text on the `_format` parameter for all three operations to state that `ndjson` is returned when the parameter is omitted.
- Add narrative in each operation's `*-notes.md` page clarifying that:
    - When `_format` is omitted, the server returns `ndjson`.
    - The `Accept` header MAY be used to negotiate the output format when `_format` is not supplied, but a value supplied via `_format` SHALL take precedence.
- Update the parameter tables in the `*-notes.md` pages so the `Required` column shows `No` for `_format` on `$viewdefinition-run` and `$sqlquery-run`.
- Not a breaking change for clients that already supply `_format`. Clients that previously received `400` from `$viewdefinition-run` or `$sqlquery-run` for omitting `_format` will now receive `ndjson`.

## Capabilities

### New Capabilities

_(none - this modifies behaviour of existing operations)_

### Modified Capabilities

- `viewdefinition-export`: Add a named default (`ndjson`) for `_format` and clarify `Accept` header interaction. Cardinality remains `0..1`.
- `viewdefinition-run`: Relax `_format` cardinality from `1..1` to `0..1` and define `ndjson` as the default. Clarify `Accept` header interaction.
- `sqlquery-run`: Relax `_format` cardinality from `1..1` to `0..1` and define `ndjson` as the default. Clarify `Accept` header interaction.

## Impact

- **FSH**: `input/fsh/operations.fsh` - change `parameter._format.min` on the `ViewDefinitionRun` and `SQLQueryRun` `OperationDefinition` instances, and update the `documentation` strings on all three operations.
- **Narrative**: `input/pagecontent/OperationDefinition-ViewDefinitionExport-notes.md`, `OperationDefinition-ViewDefinitionRun-notes.md`, and `OperationDefinition-SQLQueryRun-notes.md` - update parameter tables and "Format Parameter Clarification" sections; add a sentence on `Accept` header precedence.
- **Reference implementation** (`sof-js/`): out of scope; `sof-js` does not currently host the operation endpoints.
- **No impact** on: output format value sets (`OutputFormatCodes`, `SQLQueryRunOutputFormatCodes`), the `SQLQuery` profile, ViewDefinition processing, or any other parameter.
