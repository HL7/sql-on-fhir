## Why

The SQL on FHIR specification defines the `$sqlquery-run` operation
(`OperationDefinition-SQLQueryRun`), but the JavaScript reference
implementation in `sof-js/` does not yet implement it. Implementers reading the
spec have no end-to-end example to validate their understanding of how
ViewDefinitions, SQLQuery Library resources, and the new `_format=fhir`
Parameters response fit together. Closing this gap is tracked as
[issue #332](https://github.com/FHIR/sql-on-fhir-v2/issues/332).

The reference server already provides the building blocks (`evaluate()` for
materialising ViewDefinitions, a SQLite backing store, JSON/NDJSON/CSV output
helpers). The remaining work is wiring them together behind the operation's
three endpoints.

## What Changes

- Add a new `$sqlquery-run` route handler module in
  `sof-js/src/server/sqlQueryRun.js` that resolves a SQLQuery Library, materialises
  each `relatedArtifact` ViewDefinition into a temporary SQLite table named after
  the artifact's `label`, executes the Library's SQL with named parameter bindings,
  and returns results in the requested format.
- Mount the operation at three routes (system, type, instance level):
    - `POST /$sqlquery-run`
    - `POST /Library/$sqlquery-run`
    - `POST /Library/:id/$sqlquery-run`
- Support the four output formats listed as in scope in the issue: `json`,
  `ndjson`, `csv`, and `fhir` (Parameters resource using the SQL-to-FHIR type
  mapping defined in `OperationDefinition-SQLQueryRun-notes.md`).
- Extend `sof-js/src/server/db.js` to load `Library` as a canonical resource
  type so server-stored Libraries can be resolved by reference.
- Ship sample artefacts: at least one `Library` resource (a SQLQuery against
  the existing Patient demographics ViewDefinition) under `sof-js/metadata/Library/`
  and the `$sqlquery-run` OperationDefinition under
  `sof-js/metadata/OperationDefinition/`.
- Add an HTML form UI for interactive testing, mirroring the existing
  `ViewDefinition/$run/form` pattern.
- Add tests under `sof-js/tests/server/sqlQueryRun.test.js` covering each
  endpoint, each output format, parameter binding, and the documented error
  responses (400, 404, 422).

Out of scope (explicit per the issue): the `source` parameter for external
data sources, and `parquet` output.

## Capabilities

### New Capabilities

- `sqlquery-run-server`: Reference server implementation of the
  `$sqlquery-run` operation - request routing, Library resolution,
  ViewDefinition materialisation into SQLite temp tables, parameter binding,
  query execution, and output formatting (including the FHIR Parameters
  response).

### Modified Capabilities

_(none - the spec-level operation contract is defined elsewhere; this change
introduces a new server-side capability)_

## Impact

- New files under `sof-js/`:
    - `src/server/sqlQueryRun.js` (route handlers and execution logic)
    - `metadata/Library/` directory with at least one sample SQLQuery
    - `metadata/OperationDefinition/$sqlquery-run.json`
    - `tests/server/sqlQueryRun.test.js`
- Changes to existing files:
    - `src/server.js` - mount the new routes, add Library to the index page
    - `src/server/db.js` - add `Library` to the canonical resource list
    - `src/server/utils.js` - extend `resourceTypes` only if Library data
      resources are needed (canonical loading is sufficient for the first cut)
- No changes to the published spec or FSH artefacts; this is purely a
  reference-implementation change.
