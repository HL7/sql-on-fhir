## Context

The `$sqlquery-run` operation executes a SQLQuery Library against the
materialised output of one or more ViewDefinitions. The reference server in
`sof-js/` already exposes the prerequisite pieces:

- `evaluate()` materialises a ViewDefinition + FHIR resources into an array of
  flat row objects (see `sof-js/src/index.js`).
- `getDb()`/`migrate()` open a SQLite database (`db.sqlite` by default) and
  load canonical metadata (ViewDefinition, OperationDefinition, CodeSystem,
  ValueSet) from `sof-js/metadata/<ResourceType>/`.
- The existing `$run` and `$viewdefinition-export` route modules show the
  conventions for routing, HTML form rendering, error responses, and CSV/JSON
  output.

The operation is invoked at three URL shapes (system, type, instance) and
takes its inputs as a FHIR `Parameters` resource. Library parameters are
themselves passed via a nested `Parameters` resource (the alignment with CQL
`$evaluate` is already complete in the spec - see the archived
`align-sqlquery-run-with-cql` change).

## Goals / Non-Goals

**Goals:**

- End-to-end invocation works for system, type, and instance routes.
- Output formats `json`, `ndjson`, `csv`, and `fhir` are supported.
- Library parameters are bound to the SQL by name, using SQLite's named
  parameter API (no string interpolation).
- ViewDefinition dependencies declared via `relatedArtifact[type=depends-on]`
  are materialised into temporary SQLite tables named after their `label`.
- Error responses match the spec table (400, 404, 422) and return an
  `OperationOutcome`.
- An HTML form lets a developer try the operation interactively, mirroring
  `ViewDefinition/$run/form`.
- A test file in `sof-js/tests/server/sqlQueryRun.test.js` exercises each
  endpoint shape and each format, parameter binding, and error paths.

**Non-Goals:**

- The `source` parameter (external data sources). The first cut materialises
  rows from the in-process FHIR data already loaded by the reference server.
- The `parquet` output format.
- Async/long-running execution. `$sqlquery-run` is synchronous in this
  implementation.
- Concurrency hardening across multiple simultaneous requests sharing the same
  SQLite file. The first cut accepts the existing single-process model.

## Decisions

### 1. Module layout

A new file `sof-js/src/server/sqlQueryRun.js` exports `mountRoutes(app)` and
the per-request handlers. Mount in `sof-js/src/server.js` alongside the other
`mountRoutes(...)` calls. Rationale: keeps the operation isolated, mirroring
`run.js`/`export.js`/`evaluate.js`.

File name uses lower camel case per the user's TypeScript guideline; existing
files in this directory mostly use single words but the camel-case convention
applies for multi-word names.

### 2. Library resolution

Three input forms are supported:

- Instance route (`/Library/:id/$sqlquery-run`): resolve from the canonical
  `library` table by id.
- `queryReference` (input parameter): parse `Library/<id>` or canonical URL and
  resolve from the `library` table.
- `queryResource` (input parameter): use the inline resource directly.

The `library` table is added to the canonical list in
`sof-js/src/server/db.js` (alongside `ViewDefinition`, `OperationDefinition`,
`CodeSystem`, `ValueSet`). Sample Libraries live in
`sof-js/metadata/Library/`.

### 3. ViewDefinition materialisation

For every `relatedArtifact` with `type === 'depends-on'`:

1. Resolve the ViewDefinition. Two cases:
    - The `resource` is a server-relative reference (e.g. `ViewDefinition/x`) -
      read from the local DB.
    - The `resource` is a canonical URL - look up by `url` in the `viewdefinition`
      table, falling back to a search by trailing id segment to support the
      example fixtures whose canonical URLs do not match local ids.
2. Run `evaluate(viewDef, fhirData)` against data fetched the same way as the
   existing `runOperation()` does (whole-table scan, with `patient` filter
   when supplied).
3. `CREATE TEMP TABLE "<label>" (col1, col2, ...)` using the column names
   declared by the ViewDefinition's `select[].column[]` definitions. Column
   types map from the ViewDefinition's `column.type` to the closest SQLite
   storage class:

    | ViewDefinition `column.type`             | SQLite affinity |
    | ---------------------------------------- | --------------- |
    | `boolean`                                | INTEGER         |
    | `integer`, `integer64`                   | INTEGER         |
    | `decimal`                                | REAL            |
    | `date`, `dateTime`, `time`, `instant`    | TEXT            |
    | everything else (`string`, `code`, etc.) | TEXT            |

4. Insert each row using a prepared statement.
5. Cache the resolved column types per label for use during the `_format=fhir`
   response (see decision 5).

The temp tables live for the duration of the request (they are dropped at the
end via `try/finally`). SQLite's `TEMP` tables are private to the connection;
since `sqlite3` (Node) connections are pooled inside the library, we
explicitly drop them to be safe.

### 4. SQL extraction

Pull the SQL string from the Library's first `content` entry, in this order
(matching the spec):

1. `content[0].extension[sql-text].valueString` if present.
2. Otherwise `Buffer.from(content[0].data, 'base64').toString('utf8')`.

Only `content[0]` is executed by the reference implementation. Multiple
content entries (different dialects) are not selected between - the first
entry is treated as the canonical SQL.

### 5. Parameter binding and FHIR type mapping

Two distinct mappings are needed:

**Input** (`Parameters` → SQLite named parameter values): map each
`parameters.parameter[i]` by name to the matching `Library.parameter[]` entry,
read the value via `value[x]` matching the declared FHIR type, and bind as a
SQLite named parameter (`:name`). Type mismatch or unknown name returns 400.

**Output** (SQLite rows → FHIR Parameters resource for `_format=fhir`): use
the SQL-to-FHIR type mapping from `OperationDefinition-SQLQueryRun-notes.md`
(BOOLEAN → `valueBoolean`, INTEGER → `valueInteger`, REAL/FLOAT → `valueDecimal`,
TEXT/CHARACTER → `valueString`, BINARY → `valueBase64Binary`, DATE → `valueDate`,
TIME → `valueTime`, TIMESTAMP → `valueDateTime`, TIMESTAMP WITH TIME ZONE →
`valueInstant`).

For each result column, prefer the type from the source ViewDefinition column
(captured during materialisation). Fall back to SQLite's `typeof()` storage
class when no source column type is available (e.g. computed columns).
Unsupported source types return 422 per the spec.

`NULL` values are encoded by omitting the corresponding `part` from the row.

### 6. Routing

```
POST /$sqlquery-run                    # system level
POST /Library/$sqlquery-run            # type level
POST /Library/:id/$sqlquery-run        # instance level
GET  /Library/:id/$sqlquery-run/form   # interactive HTML form
```

All POST handlers share a common core function `executeSqlQueryRun(req, library, parametersResource)`.
The route handlers differ only in how they resolve the Library.

### 7. Output formatting

Reuse the existing patterns from `run.js`:

- `json` → `application/fhir+json`, pretty-printed array of row objects.
- `ndjson` → `application/ndjson`, one JSON object per line.
- `csv` → `text/csv`, optional header row controlled by the `header` input
  (defaults to true).
- `fhir` → `application/fhir+json`, a `Parameters` resource where each row is
  a `parameter` named `row` with one `part` per column (NULLs omitted). Empty
  result → `{ "resourceType": "Parameters" }`.

### 8. Error mapping

| Trigger                                         | Status | OperationOutcome code |
| ----------------------------------------------- | ------ | --------------------- |
| Missing or invalid request body                 | 400    | `invalid`             |
| Missing required input (`_format`, no Library)  | 400    | `required`            |
| Unknown parameter name or wrong `value[x]`      | 400    | `invalid`             |
| Library not found by id/reference               | 404    | `not-found`           |
| Referenced ViewDefinition not found             | 404    | `not-found`           |
| SQLite execution error                          | 422    | `processing`          |
| Unsupported SQL column type when `_format=fhir` | 422    | `not-supported`       |

### 9. Sample data

Add at least one sample Library that depends on existing ViewDefinitions in
`sof-js/metadata/ViewDefinition/`. The simplest viable seed: a `patient_count`
Library whose SQL is `SELECT COUNT(*) AS total FROM patient_demographics`,
depending on the existing `patient_demographics` ViewDefinition. This keeps
the smoke test independent of any new ViewDefinition.

### 10. Tests

Unit tests live in `sof-js/tests/server/sqlQueryRun.test.js` using `bun test`
(matches the existing tests in the same directory). Cover:

- Each route shape (system, type, instance) returns 200 with expected output.
- Each `_format` value (`json`, `ndjson`, `csv`, `fhir`).
- Parameter binding: one `valueString`, one `valueDate`.
- Empty result set under `_format=fhir` returns
  `{ "resourceType": "Parameters" }`.
- Error paths: 400 (missing `_format`), 404 (unknown Library), 400 (unknown
  parameter name).

Integration tests are kept to a small number per the user's testing
guidelines; the Vitest-style structure already used in `run.test.js`/
`export.test.js` is followed.

## Risks / Trade-offs

- **SQLite as the execution engine.** The spec is database-agnostic but our
  reference implementation pins SQLite, which means dialect choices (e.g.
  named parameter syntax `:name`, lack of `DISTINCT ON`, limited data types)
  shape what the reference accepts. → Document this in the new module's
  docstring; defer multi-dialect work.
- **Single shared connection for temp tables.** If the underlying
  `node-sqlite3` library multiplexes statements across connections the temp
  tables may not be visible. → Use a single `db.serialize` block per request
  or fall back to a per-request `Database` instance if temp-table visibility
  becomes a problem in tests.
- **ViewDefinition resolution by canonical URL is loose.** The current
  fixtures store local ids that do not match canonical URLs. → Match by `url`
  first, then fall back to id-from-trailing-segment; document this matching
  rule alongside the sample fixture.
- **Type inference for computed columns.** SQLite's typeless storage means a
  result column derived purely in SQL (e.g. `COUNT(*) AS total`) has no
  declared type. → Use `typeof()` per row, infer the most specific FHIR type
  per the mapping table, and if mixed types appear in a single column return
  422 with a clear message.

## Migration Plan

No production migration is involved (this is the reference implementation).
Deployment-side: the existing `bun test` command will pick up the new test
file; the existing Docker image build needs no changes.

## Open Questions

- Should the HTML form accept inline Library JSON, a Library reference picker,
  or both? Defaulting to "both with reference picker as the primary control"
  mirrors the existing `$run` form, which already lists the canonical
  resources.
