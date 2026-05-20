## ADDED Requirements

### Requirement: Default output format when `_format` is omitted

The `$viewdefinition-export` operation SHALL treat the `_format` input parameter as optional (cardinality `0..1`). When a client omits `_format`, and no `Accept` header is supplied that the server elects to honour, the server SHALL return the exported content in `ndjson` (newline-delimited JSON) format. The `documentation` text for the `_format` parameter in the `ViewDefinitionExport` `OperationDefinition` SHALL state this default explicitly.

#### Scenario: Client omits `_format` and `Accept` does not negotiate an alternative

- **WHEN** a client invokes `$viewdefinition-export` without an `_format` parameter
- **AND** the request either omits `Accept` or supplies an `Accept` value the server does not use to negotiate an alternative format
- **THEN** the server SHALL produce export output in `ndjson` format
- **AND** the response artefacts referenced by the operation outcome SHALL be encoded as newline-delimited JSON
- **AND** the response SHALL NOT be rejected with a `400 Bad Request` solely because `_format` was missing

#### Scenario: Client supplies `_format` explicitly

- **WHEN** a client invokes `$viewdefinition-export` with `_format=csv`
- **THEN** the server SHALL produce export output in `csv` format if it supports `csv`
- **AND** the server SHALL NOT substitute `ndjson` for the supplied value

---

### Requirement: `_format` takes precedence over the `Accept` header

When both `_format` and the HTTP `Accept` header are supplied and indicate different output formats, the server SHALL use the format named by `_format`. The `Accept` header MAY be used to select a format other than the default `ndjson` only when `_format` is omitted, and any such use SHALL be limited to formats the server supports for this operation.

#### Scenario: `_format` and `Accept` disagree

- **WHEN** a client invokes `$viewdefinition-export` with `_format=csv` and `Accept: application/x-ndjson`
- **THEN** the server SHALL produce export output in `csv` format
- **AND** the server SHALL NOT use the `Accept` header to override the supplied `_format`

#### Scenario: `Accept` used to choose format when `_format` omitted

- **WHEN** a client invokes `$viewdefinition-export` without `_format` and supplies `Accept: text/csv`
- **AND** the server supports `csv` for this operation and elects to honour `Accept`
- **THEN** the server MAY produce export output in `csv` format
- **AND** if the server does not honour `Accept`, it SHALL fall back to the default (`ndjson`)
