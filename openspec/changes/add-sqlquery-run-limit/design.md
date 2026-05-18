## Context

The `SQLQueryRun` OperationDefinition (`input/fsh/operations.fsh:340-429`) has 6 input parameters and 1 output parameter, indexed `parameter[0]` through `parameter[6]`. It does not currently accept a row-limit parameter.

The sibling `ViewDefinitionRun` OperationDefinition (`input/fsh/operations.fsh:312-320`) defines `_limit` (integer, 0..1, scope system/type/instance, documentation "Maximum number of rows to return."). The narrative documentation in `input/pagecontent/OperationDefinition-ViewDefinitionRun-notes.md` describes `_limit` in three places (GET-method available parameters list, the Filtering narrative, and the Filtering parameter table).

`$sqlquery-run` documentation (`input/pagecontent/OperationDefinition-SQLQueryRun-notes.md`) does not yet present input parameters in a tabular form; it documents parameter passing in narrative + HTTP examples and lists an error-handling table. There is no GET-method section because the operation is POST-only (the existing examples and intro all use POST).

Files involved:

- `input/fsh/operations.fsh` - SQLQueryRun OperationDefinition, lines 340-429
- `input/pagecontent/OperationDefinition-SQLQueryRun-notes.md` - examples, parameter passing narrative, error handling table
- `input/pagecontent/OperationDefinition-SQLQueryRun-intro.md` - execution flow (no parameter list)

## Goals / Non-Goals

**Goals:**

- Add `_limit` to `$sqlquery-run` with the exact same OperationDefinition signature as `$viewdefinition-run`.
- Document the server-side semantics for `_limit` in `$sqlquery-run` notes: server MAY cap, applied to the final result set after SQL evaluation, exceeding the cap is not an error.
- Add at least one HTTP example demonstrating `_limit` usage with `$sqlquery-run`.

**Non-Goals:**

- Changing `$viewdefinition-run` in any way.
- Adding `_limit` to `$sqlquery-export` (the export operation has its own asynchronous semantics; out of scope here).
- Introducing a server-advertised maximum value (e.g. via a CapabilityStatement extension). The spec only states that servers MAY cap.
- Adding GET-method support to `$sqlquery-run`.
- Implementing `_limit` in the `sof-js/` reference implementation.

## Decisions

### 1. Signature: mirror `$viewdefinition-run` exactly

**Choice**: Use `_limit` (integer, 0..1, scope system/type/instance), with documentation `"Maximum number of rows to return."` - identical to `$viewdefinition-run`.

**Alternatives considered**:

- Use a different name (e.g. `limit`, `maxRows`) - rejected; the operations should be consistent and `_limit` is already established.
- Different cardinality or scopes - rejected; there is no reason for the two operations to diverge here.

**Rationale**: Issue #346 explicitly asks for consistency between the two operations, and consistency reduces cognitive load for implementers and clients.

### 2. Parameter index

**Choice**: Append as a new `parameter[6]` and shift the existing `return` from index 6 to index 7.

**Alternatives considered**:

- Insert between existing input parameters (e.g. as `parameter[5]`) and shift everything below - rejected; renumbering more elements than necessary introduces a larger diff and risks accidental edits.
- Append after `return` - rejected; FSH convention in this file places inputs before output, and grouping all inputs together is clearer.

**Rationale**: Appending to the end of the input parameter block, with `return` moving to the next index, is the minimal disruption to the file. Index numbers are not part of the operation contract (parameters are bound by `name`), so renumbering is safe.

### 3. Server-side cap is permitted but not advertised

**Choice**: Document that servers MAY enforce a maximum value, silently capping client-supplied limits. Do not require servers to advertise this maximum, and do not return an error or warning if a client requests more rows than the server allows.

**Alternatives considered**:

- Require an error when the client request exceeds the server cap - rejected; this would force clients to know server limits in advance.
- Require advertisement via CapabilityStatement - rejected as scope creep. Implementations can add this later if needed.
- Require an OperationOutcome warning in the response - rejected; flat output formats (csv, ndjson, parquet, json array) have no place to surface a warning, and adding one for some formats only would be inconsistent.

**Rationale**: The issue proposal explicitly suggests "the simplest rule is that exceeding is not an error; the server returns up to `_limit` rows". This matches typical pagination semantics and is the path of least surprise for clients.

### 4. Application order: after SQL evaluation

**Choice**: `_limit` applies to the final result set returned to the client, after the SQL query (including any in-query `LIMIT`) has been evaluated.

**Alternatives considered**:

- Inject `LIMIT` into the SQL query before execution - rejected; some dialects do not support `LIMIT` as a postfix, and modifying user SQL is fragile. Implementations are free to push the limit down as an optimisation, but the observable behaviour is post-evaluation.
- Apply before any in-query `LIMIT` - rejected; this is undefined for queries that already specify a smaller `LIMIT`.

**Rationale**: Treating `_limit` as a post-processing cap gives a well-defined semantics regardless of the underlying SQL or dialect, and lets implementations optimise transparently.

### 5. Documentation placement

**Choice**: Add tabular input parameter documentation to `OperationDefinition-SQLQueryRun-notes.md` similar to the `$viewdefinition-run` notes (which already has parameter tables). Add a short narrative paragraph clarifying server cap + post-SQL semantics + non-error behaviour, and one HTTP example using `_limit`.

**Alternatives considered**:

- Documentation as narrative only, no table - rejected; the corresponding `$viewdefinition-run` document uses tables and they are useful for implementers.
- Full reformatting of the notes to match `$viewdefinition-run` structure exactly - out of scope here; we add just enough to cover `_limit` cleanly without restructuring unrelated content.

**Rationale**: Implementers reading the spec should find consistent parameter documentation in both operations.

## Risks / Trade-offs

- **Risk**: Implementations that already silently truncate large result sets may surface different effective row counts depending on whether the client passes `_limit` or relies on a server default.
  **Mitigation**: The narrative explicitly permits server-side caps and clarifies that exceeding is not an error, so this divergence is spec-conformant.

- **Risk**: Clients that expect `_limit` to inject a SQL `LIMIT` clause might be surprised by the post-evaluation semantics (e.g. for aggregating queries where `LIMIT` matters mid-pipeline).
  **Mitigation**: The narrative explicitly states the cap is applied after SQL evaluation. Authors that need in-query `LIMIT` semantics can write the SQL accordingly.

- **Trade-off**: Not requiring servers to advertise a maximum keeps the spec simple but means clients must discover server caps empirically. This is acceptable for a v0/pre-release IG; a future change can add discoverability if needed.

## Migration Plan

- Not a breaking change. Clients that omit `_limit` continue to behave exactly as today.
- Servers that did not previously cap may add an internal cap at their discretion without breaking existing clients (the cap is silent).
- No deprecation cycle required.
