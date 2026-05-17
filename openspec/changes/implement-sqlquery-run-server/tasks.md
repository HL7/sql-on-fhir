## 1. Sample data and metadata

- [x] 1.1 Add `sof-js/metadata/OperationDefinition/$sqlquery-run.json` (the SQLQueryRun OperationDefinition copied from the IG output, or hand-derived from `input/fsh/operations.fsh`).
- [x] 1.2 Create `sof-js/metadata/Library/` directory with at least one sample SQLQuery Library that depends on the existing `patient_demographics` ViewDefinition (e.g. `patient-count.json` running `SELECT COUNT(*) AS total FROM patient_demographics`).
- [x] 1.3 Add a second sample Library that exercises a parameterised query (e.g. `patient-by-id.json` taking a `patient_id` string parameter and returning that patient's demographics) so tests can cover parameter binding.

## 2. Canonical resource loading

- [x] 2.1 Add `Library` to the `canonicals` array in `sof-js/src/server/db.js` so files under `metadata/Library/` are loaded into a `library` SQLite table at startup.
- [x] 2.2 Verify with `bun test` that `read(config, 'Library', 'patient-count')` returns the seeded resource.

## 3. Core execution module

- [x] 3.1 Create `sof-js/src/server/sqlQueryRun.js` exporting `mountRoutes(app)` and helper functions per the design.
- [x] 3.2 Implement `resolveLibrary({ id, queryReference, queryResource, config })` covering instance, type, and system shapes. Return 404 source signal when not found.
- [x] 3.3 Implement `extractSql(library)` that prefers `content[0].extension[sql-text].valueString`, falling back to base64-decoded `content[0].data`.
- [x] 3.4 Implement `materialiseDependencies(library, req)` that, for each `relatedArtifact` of `type === 'depends-on'`, resolves the ViewDefinition (server-relative or canonical URL with id-segment fallback), runs `evaluate()` against in-process FHIR data, and creates a temporary SQLite table named after `label` with column types derived from the ViewDefinition's `column.type`. Return a per-label map of column-type metadata.
- [x] 3.5 Implement `bindParameters(library, parametersResource)` that maps each nested `parameters.parameter[i]` to a SQLite named binding using the type-mapping table from `OperationDefinition-SQLQueryRun-notes.md`. Return 400-shaped errors for unknown names and type mismatches.
- [x] 3.6 Implement `executeQuery(sql, bindings, db)` that runs the prepared statement and returns the row array, mapping SQLite errors to a 422-shaped error.
- [x] 3.7 Implement `dropTempTables(labels, db)` and call it from a `try/finally` block in the request handler.

## 4. Output formatting

- [x] 4.1 Implement `formatJson(rows)`, `formatNdjson(rows)`, and `formatCsv(rows, includeHeader)` mirroring the helpers in `sof-js/src/server/run.js`.
- [x] 4.2 Implement `formatFhir(rows, columnTypes)` that builds a FHIR `Parameters` resource with one `row` parameter per row, mapping each column to the correct `value[x]` per the SQL-to-FHIR table. Omit `part` entries for SQL `NULL`. Empty input returns `{ resourceType: 'Parameters' }`.
- [x] 4.3 Surface unsupported column types from `formatFhir` as a 422 error with code `not-supported`.

## 5. Routing

- [x] 5.1 Implement `postSqlQueryRunSystem` (`POST /$sqlquery-run`).
- [x] 5.2 Implement `postSqlQueryRunType` (`POST /Library/$sqlquery-run`).
- [x] 5.3 Implement `postSqlQueryRunInstance` (`POST /Library/:id/$sqlquery-run`).
- [x] 5.4 Implement `getSqlQueryRunForm` (`GET /Library/:id/$sqlquery-run/form`) reusing `renderOperationDefinition()`.
- [x] 5.5 Wire `mountRoutes(app)` and call it from `sof-js/src/server.js`. Add the new operation to the index page links.

## 6. Tests

- [x] 6.1 Create `sof-js/tests/server/sqlQueryRun.test.js` using the same Bun test setup as `run.test.js` and `export.test.js`.
- [x] 6.2 Test the system route returning JSON for a stored Library.
- [x] 6.3 Test the type route with `queryReference` returning NDJSON.
- [x] 6.4 Test the type route with an inline `queryResource` returning CSV with and without the header row.
- [x] 6.5 Test the instance route returning a `Parameters` resource under `_format=fhir`, including the SQL-to-FHIR type mapping for at least an integer and a string column.
- [x] 6.6 Test parameter binding: post `parameters` with one `valueString` and verify the resulting row matches.
- [x] 6.7 Test the empty-result case under `_format=fhir` returns `{ resourceType: 'Parameters' }` with no `parameter` array.
- [x] 6.8 Test error paths: 400 (missing `_format`), 400 (unknown nested parameter name), 404 (unknown Library id on the instance route), 422 (SQL referencing a non-existent column).

## 7. Documentation and verification

- [x] 7.1 Add a section to `sof-js/README.md` describing the `$sqlquery-run` endpoints, sample Libraries, and the HTML form route.
- [x] 7.2 Run `cd sof-js && bun test` and confirm all new tests pass alongside the existing suite.
- [x] 7.3 Boot the server (`bun run src/server.js`) and manually verify each endpoint shape returns the expected output for the seeded Libraries; capture the curl commands or browser screenshots used for the demonstration.
