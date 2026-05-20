## 1. Prepare

- [x] 1.1 Confirm that the parallel changes `add-sqlquery-run-limit` and
      `align-format-parameter-defaults` are applied to the FSH and
      narrative (this change depends on the updated `_format` documentation
      and `0..1` cardinality from the latter; `add-sqlquery-run-limit` is
      unrelated but listed for ordering). If either is not applied, rebase
      this work after they are.
- [x] 1.2 Re-read the spec FSH instance `ViewDefinitionRun` in
      `input/fsh/operations.fsh` to confirm the parameter shape,
      cardinalities, types, scopes, bindings, and documentation that the
      reference JSON must mirror. Pay particular attention to the
      `_format.documentation` string, which now (per
      `align-format-parameter-defaults`) names `ndjson` as the default and
      states that `_format` takes precedence over `Accept`.
- [x] 1.3 Open the current
      `sof-js/metadata/OperationDefinition/$run.json` and diff it against
      the FSH instance to confirm the set of differences matches the
      inventory in `proposal.md` / `design.md`.
- [x] 1.4 Skim the sibling JSON files in
      `sof-js/metadata/OperationDefinition/`
      (`$viewdefinition-export.json`, `$sqlquery-run.json`, etc.) to
      confirm field ordering / style conventions to follow (indentation,
      key order, how the `operationdefinition-allowed-type` extension is
      encoded).

## 2. Rename and rewrite the reference JSON

- [x] 2.1 Run `git mv sof-js/metadata/OperationDefinition/\$run.json sof-js/metadata/OperationDefinition/\$viewdefinition-run.json`
      so the filename matches the spec operation code and history is
      preserved.
- [x] 2.2 In the renamed file, set identification fields:
      `id = "ViewDefinitionRun"`, `name = "ViewDefinitionRun"`,
      `url = "http://sql-on-fhir.org/OperationDefinition/$viewdefinition-run"`,
      `code = "viewdefinition-run"`, `system = true`, `type = true`,
      `instance = true`, `resource = ["ViewDefinition"]` (per Decision 2 in
      `design.md`).
- [x] 2.3 Carry across or rewrite the `description` to mirror the FSH
      `Description` field ("Execute a view definition against supplied or
      server data.").
- [x] 2.4 Rename the existing `format` input parameter to `_format`, set
      cardinality `0..1`, type `code`, scope `["system","type","instance"]`,
      and keep the extensible binding to `OutputFormatCodes`. Carry the FSH
      `documentation` string verbatim (which post-
      `align-format-parameter-defaults` names `ndjson` as the default and
      `_format` takes precedence over `Accept`).
- [x] 2.5 Update the `header` input parameter: scope
      `["system","type","instance"]`, documentation aligned with the FSH
      ("Include CSV headers (default true). Applies only when csv output is
      requested.").
- [x] 2.6 Update `viewReference`: cap `max` at `"1"`, scope
      `["system","type"]`, type `Reference`. Carry the FSH documentation
      ("Reference to a ViewDefinition stored on the server.").
- [x] 2.7 Replace the existing `viewResource` parameter declaration with
      the spec form: `type = "CanonicalResource"`, `targetProfile`
      containing the canonical of `ViewDefinition`, `max = "1"`, scope
      `["system","type"]`, and attach an
      `operationdefinition-allowed-type` extension
      (`url = "http://hl7.org/fhir/StructureDefinition/operationdefinition-allowed-type"`)
      with `valueUri = "https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition"`.
- [x] 2.8 Update `patient`: cap `max` at `"1"`, scope
      `["system","type","instance"]`, type `Reference`, carry the FSH
      documentation.
- [x] 2.9 Update `group`: keep `max = "*"`, scope
      `["system","type","instance"]`, type `Reference`, carry the FSH
      documentation.
- [x] 2.10 Replace the two same-named `source` parameters with two
      distinct parameters per the spec: `source` (type `string`, `0..1`,
      scope `["system","type","instance"]`) for the external data source,
      and `resource` (type `Resource`, `0..*`, scope
      `["system","type","instance"]`) for inline resources. Use the FSH
      documentation strings for both.
- [x] 2.11 Add `_limit` (type `integer`, `0..1`, scope
      `["system","type","instance"]`) with the FSH documentation
      ("Maximum number of rows to return.").
- [x] 2.12 Update `_since`: scope `["system","type","instance"]`, type
      `instant`, `0..1`, carry the FSH documentation.
- [x] 2.13 Remove the `_count` and `_page` input parameters; the spec does
      not include a paging model for `$viewdefinition-run`.
- [x] 2.14 Update the output `return` parameter: type `Binary`, `1..1`,
      with documentation matching the FSH ("Transformed data encoded in
      the requested output format.").

## 3. Keep the reference server booting

- [x] 3.1 In `sof-js/src/server/run.js`, update the `read(req.config,
'OperationDefinition', '$run')` call (around line 37) so the form-render
      lookup resolves to the renamed metadata's id (`ViewDefinitionRun`).
      This is the minimum change to keep the existing `$run` route
      functional; renaming the route itself or teaching the handler to read
      `_format` is explicitly out of scope (see `design.md`).
- [x] 3.2 Grep the rest of `sof-js/` for any other reference to the
      `OperationDefinition` id `$run` (e.g., links, tests, fixtures); fix
      any that would break the boot or the form page.

## 4. Verification

- [x] 4.1 Run `bun -e "JSON.parse(require('fs').readFileSync('sof-js/metadata/OperationDefinition/\$viewdefinition-run.json','utf-8'))"`
      (or equivalent) to confirm the file parses as JSON.
- [x] 4.2 From the repo root, build the IG (`npm run build:ig` or
      `./_genonce.sh`) and confirm the generated
      `output/OperationDefinition-ViewDefinitionRun.json` lists the same
      set of `parameter[].name` values as the reference JSON (Decision 2's
      `resource` divergence is expected and accepted).
- [x] 4.3 In `sof-js`, run `bun install` then `bun test`; confirm no test
      regressions caused by the metadata change.
- [x] 4.4 Start the reference server locally (`cd sof-js && bun run start`
      or the equivalent) and:
    - request `GET /OperationDefinition/ViewDefinitionRun` and confirm
      the response contains the new parameter set (`_format`, the
      `viewReference`/`viewResource` pair, distinct `source` and
      `resource` parameters, `_limit`, no `_count` / `_page`).
    - visit `/ViewDefinition/<id>/$run/form` for any existing
      ViewDefinition and confirm the form still renders (the lookup fix
      from 3.1 is needed for this to succeed).
- [x] 4.5 Verify the file passes `npm run validate` (the AJV check used
      for the JSON test suite); if `validate` does not cover
      `sof-js/metadata/`, document that explicitly in the PR description.
- [x] 4.6 Run `openspec validate align-viewdefinition-run-reference --strict`
      and resolve any reported issues.

## 5. Pull request

- [x] 5.1 Stage only the change directory, the renamed JSON file, and the
      minimal `sof-js/src/server/run.js` lookup fix. Confirm `git status`
      shows no other modifications.
- [ ] 5.2 Reference upstream issue
      [#343](https://github.com/FHIR/sql-on-fhir-v2/issues/343) in the PR
      description; quote the proposal's "What Changes" list as the
      summary.
- [ ] 5.3 Note in the PR description that this is a metadata-first
      alignment: the published `OperationDefinition` now matches the spec,
      but the runtime route (`/ViewDefinition/:id/$run`) and its
      `format`/`header` query parameters are unchanged in this PR. Link to
      the follow-up that will close the runtime gap.
- [ ] 5.4 Request review and merge once approved.
