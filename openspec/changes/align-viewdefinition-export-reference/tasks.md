## 1. Prepare

- [ ] 1.1 Confirm that the parallel changes `add-sqlquery-run-limit` and
      `align-format-parameter-defaults` are applied to the FSH and narrative
      (this change depends on the updated `_format` documentation from the
      latter; `add-sqlquery-run-limit` is unrelated but listed for
      ordering). If either is not applied, rebase this work after they are.
- [ ] 1.2 Re-read the spec FSH instance `ViewDefinitionExport` in
      `input/fsh/operations.fsh` to confirm the parameter shape,
      cardinalities, types, scopes, bindings, and documentation that the
      reference JSON must mirror. Pay particular attention to the
      `_format.documentation` string, which now (per
      `align-format-parameter-defaults`) names `ndjson` as the default and
      states that `_format` takes precedence over `Accept`.
- [ ] 1.3 Open the current
      `sof-js/metadata/OperationDefinition/$viewdefinition-export.json` and
      diff it against the FSH instance to confirm the set of differences
      matches the inventory in `proposal.md` / `design.md`.
- [ ] 1.4 Skim the other JSON files in `sof-js/metadata/OperationDefinition/`
      (`$run.json`, `$sqlquery-run.json`, etc.) to confirm field ordering /
      style conventions to follow (indentation, key order).

## 2. Rewrite the reference JSON

- [ ] 2.1 In `sof-js/metadata/OperationDefinition/$viewdefinition-export.json`,
      set identification fields: `id = "ViewDefinitionExport"`,
      `name = "ViewDefinitionExport"`, `system = true`, `type = true`,
      `instance = true`, `code = "viewdefinition-export"`,
      `resource = ["ViewDefinition"]` (per Decision 2 in `design.md`).
- [ ] 2.2 Rewrite the `description` to drop the typos ("viewdefintion adn");
      use prose equivalent to the FSH `Description` field.
- [ ] 2.3 Replace the flat `viewReference` and `viewResource` input
      parameters with a single repeating `view` wrapper parameter
      (`min = 1`, `max = "*"`, scope `["system","type"]`) whose `part` array
      is `name` (string, 0..1), `viewReference` (Reference, 0..1), and
      `viewResource` (Resource, 0..1).
- [ ] 2.4 On the `viewResource` part, attach an
      `operationdefinition-allowed-type` extension
      (`url = "http://hl7.org/fhir/StructureDefinition/operationdefinition-allowed-type"`)
      with `valueUri =
"https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition"`.
- [ ] 2.5 Rename the existing `format` input parameter to `_format`, set
      cardinality `0..1`, type `code`, scope `["system","type"]`, and keep
      the extensible binding to `OutputFormatCodes`.
- [ ] 2.6 Add bulk-export input parameters as siblings of `view` and
      `_format`: `clientTrackingId` (string, `0..1`), `header` (boolean,
      `0..1`), `patient` (Reference, `0..*`), `group` (Reference, `0..*`),
      `_since` (instant, `0..1`), `source` (string, `0..1`). Each SHALL have
      scope `["system","type"]` and `use = "in"` matching the FSH.
- [ ] 2.7 Update `exportId` output parameter cardinality from `0..1` to
      `1..1`.
- [ ] 2.8 Add the missing output parameters: `clientTrackingId` (string,
      0..1), `cancelUrl` (uri, 0..1), `_format` (code, 0..1, extensible
      binding to `OutputFormatCodes`), `exportStartTime` (instant, 0..1),
      `exportEndTime` (instant, 0..1), `exportDuration` (integer, 0..1),
      `estimatedTimeRemaining` (integer, 0..1).
- [ ] 2.9 In the `output` output parameter, change the `location` part's
      `max` from `"1"` to `"*"`.
- [ ] 2.10 Remove the per-output `format` part from the `output` parameter.
- [ ] 2.11 Carry across the `documentation` strings from the FSH onto each
      parameter (input and output) so the reference metadata reads the
      same as the spec narrative for each field.

## 3. Verification

- [ ] 3.1 Run `bun -e "JSON.parse(require('fs').readFileSync(
 'sof-js/metadata/OperationDefinition/$viewdefinition-export.json',
 'utf-8'))"` (or equivalent) to confirm the file parses as JSON.
- [ ] 3.2 From the repo root, build the IG (`npm run build:ig` or
      `./_genonce.sh`) and confirm the generated
      `output/OperationDefinition-ViewDefinitionExport.json` lists the same
      set of `parameter[].name` values as the reference JSON (Decision 2's
      `resource` divergence is expected and accepted).
- [ ] 3.3 In `sof-js`, run `bun install` then `bun test`; confirm no test
      regressions caused by the metadata change.
- [ ] 3.4 Start the reference server locally (`cd sof-js && bun run start`
      or the equivalent) and request
      `GET /OperationDefinition/$viewdefinition-export`. Confirm the
      response contains the new parameter set (e.g. `_format`, the `view`
      wrapper with three parts, `cancelUrl`, `_since`).
- [ ] 3.5 Verify the file passes `npm run validate` (the AJV check used for
      the JSON test suite); if `validate` does not cover
      `sof-js/metadata/`, document that explicitly in the PR description.
- [ ] 3.6 Run `openspec validate align-viewdefinition-export-reference
--strict` and resolve any reported issues.

## 4. Pull request

- [ ] 4.1 Stage only the change directory and the rewritten JSON file.
      Confirm `git status` shows no other modifications.
- [ ] 4.2 Reference upstream issue
      [#344](https://github.com/FHIR/sql-on-fhir-v2/issues/344) in the PR
      description; quote the proposal's "What Changes" list as the summary.
- [ ] 4.3 Note in the PR description that this is metadata-only (no
      runtime handler is added; the operation is not yet implemented in
      `sof-js`).
- [ ] 4.4 Request review and merge once approved.
