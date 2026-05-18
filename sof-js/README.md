# Reference implementation of the SQL on FHIR spec in JavaScript

SQL on FHIR reference implementation is meant to be a guide to anyone trying
write their own SQL on FHIR implementation. It includes a thorough test suit
aiming to cover every aspect of SQL on FHIR specification.

_Disclaimer: implementation is, currently, in active development, not all
aspects of the spec are covered._

## Setup

This implementation requires [bun](https://bun.sh/). Run `bun install` to fetch
the dependencies.

## Running the implementation

The only way to interact with this implementation is by running tests using the
following command:

```bash
bun test
```

It is possible to specify which tests to run, see `bun test --help`.

## `$sqlquery-run` operation

The reference server implements the `$sqlquery-run` operation defined in the
SQL on FHIR Implementation Guide. It executes a SQLQuery Library against the
materialised output of one or more ViewDefinitions, with named-parameter
binding and pluggable output formats.

Routes:

- `POST /$sqlquery-run` - system level. Provide either `queryReference` or
  `queryResource` in the request body.
- `POST /Library/$sqlquery-run` - type level. Same body shape as the system
  route.
- `POST /Library/:id/$sqlquery-run` - instance level. The Library id comes
  from the URL.
- `GET /Library/:id/$sqlquery-run/form` - HTML form for interactive testing.

Sample Libraries are loaded from `metadata/Library/`:

- `patient-count` - `SELECT COUNT(*) AS total FROM patient_demographics`.
- `patient-by-id` - parameterised lookup that takes a `patient_id` string.

Supported `_format` values: `json`, `ndjson`, `csv`, `fhir`. The `fhir` format
returns a FHIR `Parameters` resource per the SQL-to-FHIR type mapping in
`OperationDefinition-SQLQueryRun-notes.md`. Out of scope for this
implementation: the `source` parameter and `parquet` output.

Example invocation:

```bash
curl -X POST http://localhost:3000/Library/patient-count/\$sqlquery-run \
  -H 'Content-Type: application/fhir+json' \
  -d '{"resourceType":"Parameters","parameter":[{"name":"_format","valueCode":"json"}]}'
```

## TODO

- [ ] migrate all tests
- [ ] generate tests jsons from ref impl tests
- [ ] fix sandbox
- [ ] fix test report page
- [ ] add compiler
