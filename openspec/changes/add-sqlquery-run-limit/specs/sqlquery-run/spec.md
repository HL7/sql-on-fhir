## ADDED Requirements

### Requirement: Row-limit input parameter

The `$sqlquery-run` operation SHALL accept an optional `_limit` input parameter of FHIR type `integer` with cardinality `0..1` and scope `system`, `type`, and `instance`. The parameter SHALL be declared in the `SQLQueryRun` `OperationDefinition` with the documentation text "Maximum number of rows to return.", matching the existing `_limit` parameter on `$viewdefinition-run`.

When supplied, `_limit` is the maximum number of rows the server returns to the client. The limit applies to the final result set, after the SQL query (including any in-query `LIMIT`) has been evaluated. Servers MAY enforce a maximum value, silently capping client-supplied limits at a smaller server-defined maximum. Returning fewer rows than the client requested - whether because the query yielded fewer rows or because the server applied its own cap - SHALL NOT be treated as an error.

#### Scenario: Client supplies `_limit` within server-allowed range

- **WHEN** a client invokes `$sqlquery-run` with `_limit=5` against a query that would otherwise return 100 rows
- **AND** the server's internal maximum (if any) is greater than or equal to 5
- **THEN** the server SHALL return exactly 5 rows in the requested output format
- **AND** the response status SHALL be `200 OK`

#### Scenario: Query naturally returns fewer rows than `_limit`

- **WHEN** a client invokes `$sqlquery-run` with `_limit=100` against a query that yields 3 rows
- **THEN** the server SHALL return all 3 rows
- **AND** the response status SHALL be `200 OK`
- **AND** the server SHALL NOT raise an error or warning because the result was smaller than `_limit`

#### Scenario: Server caps client-supplied `_limit`

- **WHEN** a client invokes `$sqlquery-run` with `_limit=10000` against a server whose configured maximum is 1000
- **AND** the underlying query would yield more than 1000 rows
- **THEN** the server SHALL return at most 1000 rows
- **AND** the response status SHALL be `200 OK`
- **AND** the server SHALL NOT raise an error because the client-supplied value exceeded the server cap

#### Scenario: `_limit` omitted

- **WHEN** a client invokes `$sqlquery-run` without an `_limit` parameter
- **THEN** the server SHALL execute the query and return rows subject only to the server's own internal limits (if any), with behaviour identical to the operation prior to the introduction of `_limit`

#### Scenario: `_limit` applied after in-query `LIMIT`

- **WHEN** the SQLQuery Library contains a query that includes an in-query `LIMIT 20`
- **AND** the client invokes `$sqlquery-run` with `_limit=5`
- **THEN** the server SHALL return at most 5 rows
- **AND** when the client invokes with `_limit=50` (greater than the in-query `LIMIT`), the server SHALL return at most 20 rows
