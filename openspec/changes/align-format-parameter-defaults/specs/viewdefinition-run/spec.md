## ADDED Requirements

### Requirement: Optional `_format` parameter with `ndjson` default

The `$viewdefinition-run` operation SHALL declare the `_format` input parameter with cardinality `0..1` in the `ViewDefinitionRun` `OperationDefinition`. When a client omits `_format`, and no `Accept` header is supplied that the server elects to honour, the server SHALL return the result in `ndjson` format. The `documentation` text on the `_format` parameter SHALL name `ndjson` as the default. The parameter table in `OperationDefinition-ViewDefinitionRun-notes.md` SHALL show the `Required` column as `No` for `_format`.

#### Scenario: Client omits `_format` and `Accept` does not negotiate an alternative

- **WHEN** a client invokes `$viewdefinition-run` (at type or instance level) without an `_format` parameter
- **AND** the request either omits `Accept` or supplies an `Accept` value the server does not use to negotiate an alternative format
- **THEN** the server SHALL execute the view and return a `Binary` whose content is encoded as `ndjson`
- **AND** the response `Content-Type` SHALL be `application/x-ndjson`
- **AND** the response status SHALL be `200 OK`
- **AND** the server SHALL NOT return `400 Bad Request` solely because `_format` was missing

#### Scenario: Client supplies `_format` explicitly

- **WHEN** a client invokes `$viewdefinition-run` with `_format=csv`
- **AND** the server supports `csv` for this operation
- **THEN** the server SHALL return the result encoded as `csv`
- **AND** the server SHALL NOT substitute `ndjson` for the supplied value

#### Scenario: Backwards compatibility for clients that always supply `_format`

- **WHEN** a client invokes `$viewdefinition-run` with `_format=ndjson` (the same value it supplied before this change)
- **THEN** the server SHALL behave identically to the operation prior to the relaxation of `_format`'s cardinality

---

### Requirement: `_format` takes precedence over the `Accept` header

When both `_format` and the HTTP `Accept` header are supplied and indicate different output formats for `$viewdefinition-run`, the server SHALL use the format named by `_format`. The `Accept` header MAY be used to select a format other than the default `ndjson` only when `_format` is omitted, and any such use SHALL be limited to formats the server supports for this operation.

#### Scenario: `_format` and `Accept` disagree

- **WHEN** a client invokes `$viewdefinition-run` with `_format=csv` and `Accept: application/x-ndjson`
- **THEN** the server SHALL return the result in `csv` format
- **AND** the response `Content-Type` SHALL reflect the chosen `csv` format (`text/csv`)

#### Scenario: `Accept` used to choose format when `_format` omitted

- **WHEN** a client invokes `$viewdefinition-run` without `_format` and supplies `Accept: application/json`
- **AND** the server supports `json` for this operation and elects to honour `Accept`
- **THEN** the server MAY return the result in `json` format
- **AND** if the server does not honour `Accept`, it SHALL fall back to the default (`ndjson`)
