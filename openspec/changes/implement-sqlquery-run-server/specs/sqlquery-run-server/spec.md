# SQLQuery Run server capability

## ADDED Requirements

### Requirement: System-level invocation route

The reference server SHALL expose `POST /$sqlquery-run` for system-level
invocation of the operation. The request body SHALL be a FHIR `Parameters`
resource. The Library to execute SHALL be sourced from a `queryReference`
input parameter (resolved against the server's stored Libraries) or a
`queryResource` input parameter (used inline).

#### Scenario: System route resolves a stored Library by reference

- **WHEN** a client posts a `Parameters` body to `/$sqlquery-run` containing
  `_format` of `csv` and `queryReference` pointing at `Library/patient-count`
- **THEN** the server SHALL resolve the Library from local storage, execute
  it, and return a 200 response with `Content-Type: text/csv`

#### Scenario: System route accepts an inline Library

- **WHEN** a client posts a `Parameters` body to `/$sqlquery-run` containing
  `_format` of `json` and a `queryResource` whose value is an inline SQLQuery
  Library
- **THEN** the server SHALL execute that Library and return a 200 response

#### Scenario: System route rejects request with no Library source

- **WHEN** a client posts a `Parameters` body to `/$sqlquery-run` that lacks
  both `queryReference` and `queryResource`
- **THEN** the server SHALL return a 400 response with an `OperationOutcome`
  describing the missing input

### Requirement: Type-level invocation route

The reference server SHALL expose `POST /Library/$sqlquery-run` with the same
request body contract as the system route. The handler SHALL share the
underlying execution logic with the system route - the only difference is the
URL.

#### Scenario: Type route returns NDJSON output

- **WHEN** a client posts a `Parameters` body to `/Library/$sqlquery-run`
  containing `_format` of `ndjson` and a `queryReference` to a known Library
- **THEN** the server SHALL return a 200 response with
  `Content-Type: application/ndjson` and one JSON object per line

### Requirement: Instance-level invocation route

The reference server SHALL expose `POST /Library/:id/$sqlquery-run`. The
Library to execute SHALL be the server-stored Library whose id matches the
URL segment. `queryReference` and `queryResource` SHALL be ignored on this
route.

#### Scenario: Instance route returns 404 for unknown Library

- **WHEN** a client posts a `Parameters` body to
  `/Library/does-not-exist/$sqlquery-run`
- **THEN** the server SHALL return a 404 response with an `OperationOutcome`
  whose code is `not-found`

#### Scenario: Instance route executes the Library identified in the URL

- **WHEN** a client posts a `Parameters` body to
  `/Library/patient-count/$sqlquery-run` containing `_format` of `json`
- **THEN** the server SHALL execute the `patient-count` Library and return a
  200 response with the result rows as a JSON array

### Requirement: ViewDefinition dependency materialisation

For each `relatedArtifact` entry on the resolved Library where `type` equals
`depends-on`, the server SHALL resolve the referenced ViewDefinition,
materialise it into a temporary SQLite table named after the artifact's
`label`, and populate the table with rows produced by `evaluate()` over the
in-process FHIR data. ViewDefinition column types SHALL be carried over to
the temp table to enable correct typing of `_format=fhir` output. Temporary
tables SHALL be dropped at the end of the request.

#### Scenario: A single ViewDefinition dependency is materialised

- **GIVEN** a Library whose `relatedArtifact` declares one dependency with
  `label = "patient_demographics"` referencing the `patient_demographics`
  ViewDefinition
- **WHEN** the operation executes
- **THEN** the server SHALL create a temporary SQLite table named
  `patient_demographics`, populate it with the rows produced by evaluating
  the ViewDefinition, run the Library's SQL against it, and drop the table
  before returning

#### Scenario: A referenced ViewDefinition cannot be resolved

- **WHEN** the resolved Library declares a `relatedArtifact` dependency on a
  ViewDefinition that does not exist on the server
- **THEN** the server SHALL return a 404 response with an `OperationOutcome`
  identifying the missing ViewDefinition

### Requirement: SQL extraction from Library content

The server SHALL extract the SQL string from the Library's first `content`
entry. Extraction SHALL prefer the `sql-text` extension on `content[0]` when
present, and otherwise base64-decode `content[0].data`.

#### Scenario: SQL is read from the sql-text extension

- **GIVEN** a Library whose `content[0].extension[sql-text].valueString` is
  `SELECT 1 AS one`
- **WHEN** the operation executes
- **THEN** the server SHALL execute `SELECT 1 AS one`

#### Scenario: SQL is read from base64 data when no extension is present

- **GIVEN** a Library whose `content[0].data` is a base64 encoding of
  `SELECT 1 AS one` and no `sql-text` extension
- **WHEN** the operation executes
- **THEN** the server SHALL decode the base64 payload and execute the
  resulting SQL

### Requirement: Parameter binding from nested Parameters resource

The server SHALL accept a nested FHIR `Parameters` resource on the input
parameter named `parameters`. Each nested parameter SHALL be bound by name to
a parameter declared in the Library's `Library.parameter` collection. The
nested parameter's `value[x]` type SHALL match the declared
`Library.parameter.type`. Bindings SHALL be passed to SQLite as named
parameters - the implementation SHALL NOT interpolate parameter values into
the SQL string.

#### Scenario: A string parameter is bound by name

- **GIVEN** a Library declaring `Library.parameter.name = "patient_id"` of
  type `string` and SQL referencing `:patient_id`
- **WHEN** the request supplies a nested `parameters` resource with a
  parameter `patient_id` whose `valueString` is `Patient/123`
- **THEN** the server SHALL bind `patient_id` to the value `Patient/123` when
  executing the SQL

#### Scenario: Type mismatch between input and declaration

- **WHEN** the request supplies a nested parameter whose `value[x]` type
  differs from the Library's declared `parameter.type`
- **THEN** the server SHALL return a 400 response with an `OperationOutcome`
  describing the mismatch

#### Scenario: Unknown parameter name

- **WHEN** the request supplies a nested parameter whose name does not match
  any declared `Library.parameter.name`
- **THEN** the server SHALL return a 400 response with an `OperationOutcome`
  identifying the unknown parameter

### Requirement: Output format support

The server SHALL accept a required `_format` input parameter and return
results in one of `json`, `ndjson`, `csv`, or `fhir`. JSON, NDJSON, and CSV
responses SHALL be returned as a `Binary` with the appropriate
`Content-Type`. The `fhir` format SHALL return a FHIR `Parameters` resource
with one `row` parameter per result row.

#### Scenario: JSON output

- **WHEN** a request supplies `_format = json`
- **THEN** the response `Content-Type` SHALL be `application/fhir+json` and
  the body SHALL be a JSON array of row objects

#### Scenario: NDJSON output

- **WHEN** a request supplies `_format = ndjson`
- **THEN** the response `Content-Type` SHALL be `application/ndjson` and the
  body SHALL contain one JSON object per line

#### Scenario: CSV output with default header row

- **WHEN** a request supplies `_format = csv` and no `header` input
- **THEN** the response `Content-Type` SHALL be `text/csv` and the first line
  SHALL be the comma-separated column names

#### Scenario: CSV output with header suppressed

- **WHEN** a request supplies `_format = csv` and `header = false`
- **THEN** the response body SHALL contain only data rows, no header line

#### Scenario: FHIR output produces a Parameters resource

- **WHEN** a request supplies `_format = fhir` and the query returns two rows
- **THEN** the response body SHALL be a `Parameters` resource with two
  `parameter` entries named `row`, each carrying one `part` per result column

#### Scenario: FHIR output for an empty result set

- **WHEN** a request supplies `_format = fhir` and the query returns zero
  rows
- **THEN** the response body SHALL be `{ "resourceType": "Parameters" }`
  with no `parameter` array

### Requirement: SQL-to-FHIR type mapping for `_format=fhir`

When `_format = fhir`, the server SHALL encode each result column using the
SQL-to-FHIR type mapping defined in `OperationDefinition-SQLQueryRun-notes.md`.
The source ViewDefinition column type, when known, takes precedence over the
SQLite storage class. SQL `NULL` values SHALL be omitted from the row
parameter.

#### Scenario: Boolean column is encoded as valueBoolean

- **GIVEN** a result column whose source ViewDefinition declared type is
  `boolean`
- **WHEN** the response is built under `_format = fhir`
- **THEN** the corresponding `part` SHALL use `valueBoolean`

#### Scenario: Integer column is encoded as valueInteger

- **GIVEN** a result column whose source ViewDefinition declared type is
  `integer`
- **WHEN** the response is built under `_format = fhir`
- **THEN** the corresponding `part` SHALL use `valueInteger`

#### Scenario: NULL value is omitted from the row

- **GIVEN** a row whose `effective_date` column value is SQL NULL
- **WHEN** the response is built under `_format = fhir`
- **THEN** the row's `part` array SHALL contain no entry named
  `effective_date`

#### Scenario: Unsupported column type returns 422

- **WHEN** a query produces a result column whose SQL type is not listed in
  the SQL-to-FHIR type mapping (e.g. an `INTERVAL`)
- **AND** the request supplies `_format = fhir`
- **THEN** the server SHALL return a 422 response with an `OperationOutcome`
  identifying the unsupported column

### Requirement: Library canonical resource loading

The server SHALL load `Library` resources stored under
`sof-js/metadata/Library/` into a `library` SQLite table during startup, in
the same way it loads other canonical resources (`ViewDefinition`,
`OperationDefinition`, `CodeSystem`, `ValueSet`).

#### Scenario: Sample Library is available after startup

- **WHEN** the server starts with at least one JSON file under
  `sof-js/metadata/Library/`
- **THEN** the file's contents SHALL be loaded into the `library` table and
  resolvable via `read(config, "Library", id)`

### Requirement: Error responses

The server SHALL return `OperationOutcome` resources with appropriate HTTP
status codes for failure conditions: 400 for missing required inputs or
invalid parameter values, 404 for unresolved Libraries or ViewDefinitions,
and 422 for SQL execution failures and unsupported column types under
`_format = fhir`.

#### Scenario: Missing \_format returns 400

- **WHEN** a request omits the required `_format` input parameter
- **THEN** the server SHALL return a 400 response with an `OperationOutcome`
  whose code is `required`

#### Scenario: SQL execution failure returns 422

- **GIVEN** a Library whose SQL refers to a column that does not exist on the
  materialised temp table
- **WHEN** the operation executes
- **THEN** the server SHALL return a 422 response with an `OperationOutcome`
  whose code is `processing` and whose diagnostics include the SQLite error
  message

### Requirement: Interactive HTML form for instance route

The server SHALL expose `GET /Library/:id/$sqlquery-run/form` returning an
HTML page that lets a developer fill in input parameters via a form, mirroring
the existing `ViewDefinition/:id/$run/form` endpoint. The form SHALL render
the operation definition's input parameters and submit a `Parameters` body to
the operation's POST endpoint.

#### Scenario: Form renders for a stored Library

- **WHEN** a browser issues `GET /Library/patient-count/$sqlquery-run/form`
- **THEN** the response SHALL be HTML containing input controls for
  `_format`, `parameters`, and the other documented input parameters
