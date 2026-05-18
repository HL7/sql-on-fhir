## Why

The `OperationDefinition` for `$viewdefinition-run` shipped by the reference
server in `sof-js/metadata/OperationDefinition/$run.json` has drifted from the
`ViewDefinitionRun` definition in `input/fsh/operations.fsh`. The differences
affect the operation URL/code, parameter names, cardinalities, scopes, types,
and paging model - they are not purely cosmetic. Implementers reading the
reference server's metadata see a different operation contract than the spec
narrative describes, undermining the reference server's role as a working
example of the spec. Tracked as
[issue #343](https://github.com/FHIR/sql-on-fhir-v2/issues/343).

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

- Rename `sof-js/metadata/OperationDefinition/$run.json` to
  `sof-js/metadata/OperationDefinition/$viewdefinition-run.json` (using
  `git mv` so history is preserved) and rewrite its contents to be equivalent
  to the spec `ViewDefinitionRun` instance:
    - **Identification**: set `id` and `name` to `ViewDefinitionRun`; set
      `url` to `http://sql-on-fhir.org/OperationDefinition/$viewdefinition-run`;
      set `code` to `viewdefinition-run`; flip `system` to `true`.
    - **Resource**: keep `ViewDefinition` (the published FSH uses
      `CanonicalResource` only as a hack workaround; the reference server's
      direct `ViewDefinition` is the intended target). See `design.md` for
      the rationale, which mirrors Decision 2 in
      `align-viewdefinition-export-reference`.
    - **Format parameter**: rename `format` -> `_format`; relax cardinality
      to `0..1` (per `align-format-parameter-defaults`); add `system` to the
      `scope`. The `documentation` text follows the updated FSH (per
      `align-format-parameter-defaults`), which names `ndjson` as the default
      when omitted and states that `_format` takes precedence over `Accept`.
    - **viewReference**: cap `max` at `"1"` (spec value); add `system` to
      the `scope`.
    - **viewResource**: change `type` from `ViewDefinition` to
      `CanonicalResource` with `targetProfile` of `Canonical(ViewDefinition)`
      and the `operationdefinition-allowed-type` extension pointing at the
      `ViewDefinition` profile; cap `max` at `"1"`; scope `["system","type"]`.
    - **patient**: cap `max` at `"1"`; add `system` to the `scope`.
    - **group**: keep `max = "*"`; add `system` to the `scope`.
    - **header**: add `system` to the `scope`; align `documentation` with the
      FSH ("Include CSV headers (default true). Applies only when csv output
      is requested.").
    - **source / resource**: replace the two-`source`-parameters trick with
      a single `source` (string, `0..1`, scope `["system","type","instance"]`)
      for an external data source and a separate `resource` (Resource,
      `0..*`, scope `["system","type","instance"]`) for inline FHIR
      resources.
    - **\_limit**: add `_limit` (integer, `0..1`, scope
      `["system","type","instance"]`) per the spec.
    - **\_since**: add `system` to the `scope`.
    - **Paging**: remove `_count` and `_page`. The spec does not include a
      paging model for `$viewdefinition-run`; the single `_limit` parameter
      is the only result-set cap.
    - **Output `return`**: keep `Binary` and set cardinality to `1..1` (the
      spec mandates a return value).
- Make no FSH or narrative changes; the spec instance in
  `input/fsh/operations.fsh` is unchanged.
- Make no changes to the reference server's runtime route handlers - this
  change is metadata-only. The reference server's existing `$run` route in
  `sof-js/src/server/run.js` reads `req.query.format` and `req.query.header`
  at runtime, not `_format`. Aligning the runtime to honour the renamed
  parameters and the new operation path (`$viewdefinition-run`) is out of
  scope here and is tracked as separate work; see `design.md`.

## Capabilities

### New Capabilities

- `viewdefinition-run-reference`: Captures the requirements for the
  reference server's `$viewdefinition-run` `OperationDefinition` metadata
  file, including the contract that it mirrors the spec FSH and the one
  deliberate divergence on the `resource` element.

### Modified Capabilities

_(none - this change introduces a new capability that scopes the reference
metadata; no existing requirements are amended.)_

## Impact

- **Reference server metadata**: rename and rewrite
  `sof-js/metadata/OperationDefinition/$run.json` ->
  `sof-js/metadata/OperationDefinition/$viewdefinition-run.json`.
- **No impact** on:
    - `input/fsh/operations.fsh` (the spec source of truth, already correct).
    - The reference server route handlers in `sof-js/src/server/run.js`,
      which continue to read the legacy `format` / `header` query parameters
      and remain mounted at `/ViewDefinition/:id/$run`. Aligning the runtime
      with the renamed metadata and operation path is a separate, larger
      piece of work.
    - Other operations (`$viewdefinition-export`, `$sqlquery-run`,
      `$evaluate`, `$materialize`, `$refresh`, `$validate`) - their metadata
      files are not touched.
    - The `OutputFormatCodes` value set and the `ViewDefinition` profile.
- **Breaking change**: yes, for any consumer that has come to depend on the
  reference server's drifted parameter shape (the `format` parameter name,
  the `$run` filename/operation code, the `_count`/`_page` paging
  parameters, the two-`source`-parameters trick, or the `viewResource`
  declared with `type = ViewDefinition`). These consumers will need to
  align with the spec parameter shape. The mitigation is that the spec has
  always defined the correct shape; the reference metadata has been wrong.
