## Why

The `OperationDefinition` for `$viewdefinition-export` shipped by the reference
server in `sof-js/metadata/OperationDefinition/$viewdefinition-export.json` has
drifted significantly from the `ViewDefinitionExport` definition in
`input/fsh/operations.fsh`. Implementers reading the reference server's
metadata see a different set of parameters - and different cardinalities - than
the spec narrative describes, undermining the reference server's role as a
working example of the spec. Tracked as
[issue #344](https://github.com/FHIR/sql-on-fhir-v2/issues/344).

The published FSH (the spec) is the source of truth. This change rewrites the
reference server JSON to match it, with no spec-level behaviour change.

**Prerequisites**: this change assumes the following parallel OpenSpec changes
have already been applied to the FSH and narrative:

- `add-sqlquery-run-limit` - touches `$sqlquery-run` only; no impact here, but
  listed for completeness.
- `align-format-parameter-defaults` - relaxes `_format` cardinality and
  updates the `_format` `documentation` text on all three operations to name
  `ndjson` as the default when the parameter is omitted, and clarifies
  `Accept`-header precedence. The reference JSON's `_format` `documentation`
  string must mirror this updated text.

## What Changes

- Replace `sof-js/metadata/OperationDefinition/$viewdefinition-export.json`
  with content equivalent to the spec `ViewDefinitionExport` instance:
    - **Identification**: set `id` and `name` to `ViewDefinitionExport`; flip
      `system` to `true`; correct the description typos ("viewdefintion adn"
      → "view definition and").
    - **Resource**: keep `ViewDefinition` (the published FSH uses
      `CanonicalResource` only as a hack workaround; the reference server's
      direct `ViewDefinition` is the intended target). See design.md for the
      rationale.
    - **View input**: introduce the top-level repeating `view` wrapper
      (`min = 1`, `max = "*"`) with parts `name` (optional), `viewReference`
      (`max = 1`), and `viewResource` (`max = 1`, type `Resource` plus the
      `operationdefinition-allowed-type` extension pointing at the
      `ViewDefinition` profile). Remove the existing flat `viewReference` and
      `viewResource` top-level parameters.
    - **Format parameter**: rename `format` → `_format`; add `system` to the
      `scope`. The `documentation` text follows the updated FSH (per
      `align-format-parameter-defaults`), which names `ndjson` as the default
      when omitted and states that `_format` takes precedence over `Accept`.
    - **Bulk export inputs**: add `clientTrackingId` (string, 0..1), `header`
      (boolean, 0..1), `patient` (Reference, 0.._), `group` (Reference, 0.._),
      `_since` (instant, 0..1), `source` (string, 0..1).
    - **Output parameters**: raise `exportId.min` to `1`; add
      `clientTrackingId` (out, 0..1), `cancelUrl` (uri, 0..1), `_format` (out,
      0..1), `exportStartTime`, `exportEndTime`, `exportDuration`,
      `estimatedTimeRemaining`; raise `output.location.max` from `1` to `*`;
      remove the per-output `format` part (the spec carries `_format` once at
      the top level).
- Make no FSH or narrative changes; the spec instance in
  `input/fsh/operations.fsh` is unchanged.
- Make no changes to the reference server's runtime route handlers - this
  change is metadata-only. The `$viewdefinition-export` operation is not yet
  implemented in `sof-js`; updating its `OperationDefinition` does not require
  new handler code.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `viewdefinition-export-reference`: Align the reference server's
  `OperationDefinition` metadata for `$viewdefinition-export` with the
  published FSH definition, so the reference server publishes the same
  parameter contract as the spec.

## Impact

- **Reference server metadata**: rewrite
  `sof-js/metadata/OperationDefinition/$viewdefinition-export.json`.
- **No impact** on:
    - `input/fsh/operations.fsh` (the spec source of truth, already correct).
    - The reference server route handlers, since `$viewdefinition-export` is
      not yet implemented at runtime in `sof-js`.
    - Other operations (`$viewdefinition-run`, `$sqlquery-run`, `$evaluate`,
      `$materialize`, `$refresh`, `$validate`) - their metadata files are not
      touched.
    - The `OutputFormatCodes` / `ExportStatusCodes` value sets and the
      `ViewDefinition` profile.
- **Breaking change**: yes, for any consumer that has come to depend on the
  reference server's drifted parameter shape (flat `viewReference` /
  `viewResource`, `format` rather than `_format`, single-file `output.location`,
  per-output `format` part). These consumers will need to align with the spec
  parameter shape. The mitigation is that the spec has always defined the
  correct shape; the reference metadata has been wrong.
