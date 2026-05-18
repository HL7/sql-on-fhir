# Reference server `$viewdefinition-run` metadata

## ADDED Requirements

### Requirement: Reference metadata mirrors the spec FSH

The reference server's `OperationDefinition` for `$viewdefinition-run` (at `sof-js/metadata/OperationDefinition/$viewdefinition-run.json`) SHALL be equivalent to the `ViewDefinitionRun` instance declared in `input/fsh/operations.fsh`, with two deliberate divergences: the `resource` element SHALL be `[ "ViewDefinition" ]` rather than the `[ "CanonicalResource" ]` hack value the FSH uses, and the `id` SHALL be `$viewdefinition-run` (matching the reference-server filename-as-id convention) rather than the FSH `ViewDefinitionRun`. All other identification, parameter, and metadata fields SHALL match the spec FSH.

#### Scenario: Identification fields match the spec

- **GIVEN** the reference metadata file
- **WHEN** an implementer reads identifying fields
- **THEN** `id` SHALL be `$viewdefinition-run` (matching the
  reference-server filename-as-id convention used by every other file
  under `sof-js/metadata/OperationDefinition/`)
- **AND** `name` SHALL be `ViewDefinitionRun`
- **AND** `url` SHALL be
  `http://sql-on-fhir.org/OperationDefinition/$viewdefinition-run`
- **AND** `version` SHALL be `0.0.1`
- **AND** `status` SHALL be `active`
- **AND** `kind` SHALL be `operation`
- **AND** `code` SHALL be `viewdefinition-run`
- **AND** `system`, `type`, and `instance` SHALL all be `true`
- **AND** `resource` SHALL contain exactly `[ "ViewDefinition" ]`

#### Scenario: The file is named after the spec operation code

- **GIVEN** the reference server metadata directory
- **WHEN** a maintainer enumerates files under
  `sof-js/metadata/OperationDefinition/`
- **THEN** the file `\$viewdefinition-run.json` SHALL be present
- **AND** the file `\$run.json` SHALL be absent (the previous file SHALL
  have been renamed via `git mv`, preserving history)

---

### Requirement: Format parameter is `_format` with system-wide scope

The reference metadata SHALL declare the input format parameter with name `_format` (not `format`), cardinality `0..1`, type `code`, scope `["system","type","instance"]`, an extensible binding to `OutputFormatCodes`, and documentation that names `ndjson` as the default when the parameter is omitted and states that `_format` takes precedence over the HTTP `Accept` header (matching the FSH `documentation` string as updated by `align-format-parameter-defaults`).

#### Scenario: `_format` replaces `format`

- **GIVEN** the reference metadata file
- **WHEN** a consumer reads the input parameter set
- **THEN** there SHALL be a parameter named `_format`
- **AND** there SHALL be no parameter named `format`

#### Scenario: `_format` is optional with cardinality 0..1

- **WHEN** a consumer inspects the `_format` parameter cardinality
- **THEN** `min` SHALL be `0`
- **AND** `max` SHALL be `"1"`

#### Scenario: Scope includes `system`, `type`, and `instance`

- **WHEN** a consumer inspects the `_format` parameter scope
- **THEN** the scope SHALL contain each of `system`, `type`, and `instance`

#### Scenario: Documentation names the default and precedence rule

- **WHEN** a consumer reads the `_format` parameter's `documentation`
  string
- **THEN** the text SHALL match the FSH instance's `documentation` value
  for this parameter (post-`align-format-parameter-defaults`), which names
  `ndjson` as the default when omitted and states that `_format` takes
  precedence over the `Accept` header

---

### Requirement: View input parameters mirror the spec

The reference metadata SHALL declare two view-input parameters as siblings, matching the spec FSH: `viewReference` (Reference, `0..1`, scope `["system","type"]`) and `viewResource` (CanonicalResource, `0..1`, scope `["system","type"]`) with `targetProfile` of `Canonical(ViewDefinition)` and an `operationdefinition-allowed-type` extension whose `valueUri` is `https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition`. The reference metadata SHALL NOT declare a top-level `view` wrapper parameter (that is the `$viewdefinition-export` shape; for `$viewdefinition-run` the spec uses flat single-valued view inputs).

#### Scenario: `viewReference` is single-valued

- **GIVEN** the reference metadata file
- **WHEN** a consumer inspects the `viewReference` parameter
- **THEN** `max` SHALL be `"1"`
- **AND** `type` SHALL be `Reference`
- **AND** the scope SHALL contain both `system` and `type`

#### Scenario: `viewResource` uses CanonicalResource and the allowed-type extension

- **WHEN** a consumer inspects the `viewResource` parameter
- **THEN** `type` SHALL be `CanonicalResource`
- **AND** `targetProfile` SHALL include the canonical of `ViewDefinition`
- **AND** the parameter SHALL carry an `operationdefinition-allowed-type`
  extension whose `valueUri` is
  `https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition`
- **AND** `max` SHALL be `"1"`

---

### Requirement: Subject filter parameters mirror the spec

The reference metadata SHALL declare the subject-filter input parameters as follows, each with `use = "in"` and matching the spec FSH: `patient` (Reference, `0..1`, scope `["system","type","instance"]`) and `group` (Reference, `0..*`, scope `["system","type","instance"]`).

#### Scenario: `patient` is single-valued

- **GIVEN** the reference metadata file
- **WHEN** a consumer inspects the `patient` parameter
- **THEN** `max` SHALL be `"1"`
- **AND** `type` SHALL be `Reference`
- **AND** the scope SHALL contain each of `system`, `type`, and `instance`

#### Scenario: `group` is repeating

- **WHEN** a consumer inspects the `group` parameter
- **THEN** `max` SHALL be `"*"`
- **AND** `type` SHALL be `Reference`
- **AND** the scope SHALL contain each of `system`, `type`, and `instance`

---

### Requirement: External `source` and inline `resource` are distinct parameters

The reference metadata SHALL declare two distinct input parameters: `source` (string, `0..1`, scope `["system","type","instance"]`) for the external data source identifier (URI, bucket name, etc.) and `resource` (Resource, `0..*`, scope `["system","type","instance"]`) for inline FHIR resources to transform. The reference metadata SHALL NOT declare two parameters with the same name `source` (the previous JSON declared one `string` and one `Resource`, both named `source`; this is replaced by the spec's name split).

#### Scenario: `source` is a single string

- **GIVEN** the reference metadata file
- **WHEN** a consumer reads the parameter named `source`
- **THEN** there SHALL be exactly one parameter with that name
- **AND** its `type` SHALL be `string`
- **AND** its `max` SHALL be `"1"`

#### Scenario: Inline resources are carried under `resource`

- **WHEN** a consumer reads the parameter named `resource`
- **THEN** its `type` SHALL be `Resource`
- **AND** its `max` SHALL be `"*"`
- **AND** the scope SHALL contain each of `system`, `type`, and `instance`

---

### Requirement: Result-set cap uses a single `_limit` parameter

The reference metadata SHALL declare a single `_limit` input parameter (integer, `0..1`, scope `["system","type","instance"]`) capping the returned row count, matching the spec FSH. The reference metadata SHALL NOT declare `_count` or `_page` paging parameters; the spec defines no paging model for `$viewdefinition-run`.

#### Scenario: `_limit` is present and single-valued

- **GIVEN** the reference metadata file
- **WHEN** a consumer enumerates input parameter names
- **THEN** `_limit` SHALL be present
- **AND** its `type` SHALL be `integer`
- **AND** its `max` SHALL be `"1"`

#### Scenario: `_count` and `_page` are absent

- **WHEN** a consumer scans the input parameter names
- **THEN** there SHALL be no parameter named `_count`
- **AND** there SHALL be no parameter named `_page`

---

### Requirement: Header and `_since` input parameters mirror the spec

The reference metadata SHALL declare a `header` parameter (boolean, `0..1`, scope `["system","type","instance"]`) with documentation aligned to the FSH ("Include CSV headers (default true). Applies only when csv output is requested.") and a `_since` parameter (instant, `0..1`, scope `["system","type","instance"]`).

#### Scenario: `header` carries the spec documentation

- **GIVEN** the reference metadata file
- **WHEN** a consumer reads the `header` parameter
- **THEN** its `type` SHALL be `boolean`
- **AND** its documentation SHALL describe the CSV-headers semantics from
  the FSH
- **AND** the scope SHALL contain each of `system`, `type`, and `instance`

#### Scenario: `_since` is present with system-wide scope

- **WHEN** a consumer reads the `_since` parameter
- **THEN** its `type` SHALL be `instant`
- **AND** its `max` SHALL be `"1"`
- **AND** the scope SHALL contain each of `system`, `type`, and `instance`

---

### Requirement: Output `return` parameter mirrors the spec

The reference metadata SHALL declare a single output parameter named `return` with type `Binary`, cardinality `1..1`, and documentation that describes the returned representation as the transformed data encoded in the requested output format (matching the FSH).

#### Scenario: `return` is mandatory and Binary-typed

- **GIVEN** the reference metadata file
- **WHEN** a consumer reads the `return` output parameter
- **THEN** `use` SHALL be `out`
- **AND** `min` SHALL be `1`
- **AND** `max` SHALL be `"1"`
- **AND** `type` SHALL be `Binary`
