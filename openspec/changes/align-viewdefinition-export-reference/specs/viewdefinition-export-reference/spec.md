# Reference server `$viewdefinition-export` metadata

## ADDED Requirements

### Requirement: Reference metadata mirrors the spec FSH

The reference server's `OperationDefinition` for `$viewdefinition-export` (at `sof-js/metadata/OperationDefinition/$viewdefinition-export.json`) SHALL be equivalent to the `ViewDefinitionExport` instance declared in `input/fsh/operations.fsh`, with one deliberate divergence: the `resource` element SHALL be `[ "ViewDefinition" ]` rather than the `[ "CanonicalResource" ]` hack value the FSH uses. All other identification, parameter, and metadata fields SHALL match the spec FSH.

#### Scenario: Identification fields match the spec

- **GIVEN** the reference metadata file
- **WHEN** an implementer reads identifying fields
- **THEN** `id` SHALL be `ViewDefinitionExport`
- **AND** `name` SHALL be `ViewDefinitionExport`
- **AND** `url` SHALL be
  `http://sql-on-fhir.org/OperationDefinition/$viewdefinition-export`
- **AND** `version` SHALL be `0.0.1`
- **AND** `status` SHALL be `active`
- **AND** `kind` SHALL be `operation`
- **AND** `code` SHALL be `viewdefinition-export`
- **AND** `system`, `type`, and `instance` SHALL all be `true`
- **AND** `resource` SHALL contain exactly `[ "ViewDefinition" ]`
- **AND** `description` SHALL be free of the typos "viewdefintion" and "adn"
  present in the previous file

---

### Requirement: View input is declared as a repeating `view` wrapper

The reference metadata SHALL declare the view input as a single top-level
input parameter named `view`, with `min = 1`, `max = "*"`, scope of
`["system","type"]`, and the following parts:

- `name` (string, 0..1) - optional friendly name for the exported view.
- `viewReference` (Reference, 0..1) - reference to a ViewDefinition stored
  on the server.
- `viewResource` (Resource, 0..1) - inline ViewDefinition; declared with the
  `operationdefinition-allowed-type` extension whose `valueUri` is
  `https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition`.

The reference metadata SHALL NOT declare flat top-level `viewReference` or
`viewResource` parameters outside this wrapper.

#### Scenario: A single `view` repetition pairs reference and friendly name

- **GIVEN** the reference metadata file
- **WHEN** a consumer parses the input parameters
- **THEN** there SHALL be exactly one top-level `view` parameter with
  `min = 1` and `max = "*"`
- **AND** the `view` parameter SHALL have three parts: `name`,
  `viewReference`, and `viewResource`, each with `max = "1"`

#### Scenario: `viewResource` uses the allowed-type extension

- **WHEN** a consumer inspects the `viewResource` part
- **THEN** its `type` SHALL be `Resource`
- **AND** it SHALL carry an `operationdefinition-allowed-type` extension
  whose `valueUri` is
  `https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition`

#### Scenario: Flat `viewReference` and `viewResource` are absent

- **WHEN** a consumer scans the top-level input parameters
- **THEN** there SHALL be no top-level parameter named `viewReference`
- **AND** there SHALL be no top-level parameter named `viewResource`

---

### Requirement: Format parameter is `_format` with system + type scope

The reference metadata SHALL declare the input format parameter with name
`_format` (not `format`), cardinality `0..1`, type `code`, scope
`["system","type"]`, an extensible binding to `OutputFormatCodes`, and
documentation that names `ndjson` as the default when the parameter is
omitted and states that `_format` takes precedence over the HTTP `Accept`
header (matching the FSH `documentation` string as updated by
`align-format-parameter-defaults`).

#### Scenario: `_format` replaces `format`

- **GIVEN** the reference metadata file
- **WHEN** a consumer reads the input parameter set
- **THEN** there SHALL be a parameter named `_format`
- **AND** there SHALL be no parameter named `format`

#### Scenario: Scope includes both `system` and `type`

- **WHEN** a consumer inspects the `_format` parameter scope
- **THEN** the scope SHALL contain both `system` and `type`

#### Scenario: Documentation names the default and precedence rule

- **WHEN** a consumer reads the `_format` parameter's `documentation` string
- **THEN** the text SHALL match the FSH instance's `documentation` value for
  this parameter (post-`align-format-parameter-defaults`), which names
  `ndjson` as the default when omitted and states that `_format` takes
  precedence over the `Accept` header

---

### Requirement: Bulk export inputs are present

The reference metadata SHALL declare the following additional input
parameters, each with scope `["system","type"]`:

- `clientTrackingId` (string, 0..1) - client-provided tracking identifier.
- `header` (boolean, 0..1) - toggle CSV headers.
- `patient` (Reference, 0..\*) - filter by patient.
- `group` (Reference, 0..\*) - filter by group.
- `_since` (instant, 0..1) - filter by last-updated time.
- `source` (string, 0..1) - external data source.

#### Scenario: All bulk-export inputs are declared

- **GIVEN** the reference metadata file
- **WHEN** a consumer enumerates the input parameter names
- **THEN** the set SHALL include each of `clientTrackingId`, `header`,
  `patient`, `group`, `_since`, and `source`

#### Scenario: Patient and group are repeating

- **WHEN** a consumer inspects the `patient` and `group` parameters
- **THEN** each SHALL have `max = "*"`
- **AND** each SHALL have `type = "Reference"`

---

### Requirement: Output parameters mirror the spec

The reference metadata SHALL declare the following output parameters:

- `exportId` (string, **1..1**) - server-generated export identifier.
- `clientTrackingId` (string, 0..1) - echoed when supplied on input.
- `status` (code, 1..1) - bound to `ExportStatusCodes` (required strength).
- `location` (uri, 1..1) - poll URL.
- `cancelUrl` (uri, 0..1) - optional cancellation URL.
- `_format` (code, 0..1) - echoed output format, extensible binding to
  `OutputFormatCodes`.
- `exportStartTime` (instant, 0..1).
- `exportEndTime` (instant, 0..1).
- `exportDuration` (integer, 0..1).
- `estimatedTimeRemaining` (integer, 0..1).
- `output` (0..\*) with parts:
    - `name` (string, 1..1).
    - `location` (uri, **1..\***) - multi-file downloads.

The reference metadata SHALL NOT carry a per-output `format` part; the output
format is communicated once at the top level via the `_format` output
parameter.

#### Scenario: `exportId` is mandatory

- **GIVEN** the reference metadata file
- **WHEN** a consumer reads the `exportId` output parameter
- **THEN** `min` SHALL be `1` and `max` SHALL be `"1"`

#### Scenario: `output.location` permits multiple files

- **WHEN** a consumer inspects the `location` part of the `output` parameter
- **THEN** `max` SHALL be `"*"`

#### Scenario: Per-output `format` part is absent

- **WHEN** a consumer enumerates the parts of the `output` parameter
- **THEN** there SHALL be no part named `format`

#### Scenario: Timing outputs and cancellation URL are present

- **WHEN** a consumer enumerates the output parameter names
- **THEN** the set SHALL include each of `cancelUrl`, `_format`,
  `exportStartTime`, `exportEndTime`, `exportDuration`, and
  `estimatedTimeRemaining`
