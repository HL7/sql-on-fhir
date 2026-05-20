## 1. Prepare

- [x] 1.1 Confirm parallel changes `add-sqlquery-run-limit` and
      `align-format-parameter-defaults` are applied (both archived; FSH
      reflects the updated `_format.documentation`).
- [x] 1.2 Re-read the spec FSH instance `ViewDefinitionExport` in
      `input/fsh/operations.fsh`.
- [x] 1.3 Diff the current reference JSON against the FSH instance.
- [x] 1.4 Skim sibling files in `sof-js/metadata/OperationDefinition/` for
      style conventions; aligned indentation/key ordering with
      `$viewdefinition-run.json`.

## 2. Rewrite the reference JSON

- [x] 2.1 Set identification fields. Note: existing repository convention
      (commit dae3b11) keeps `id` matching the filename
      (`$viewdefinition-export`) with `name` reflecting the FSH
      (`ViewDefinitionExport`). The change spec text predates that commit;
      followed the established convention to stay consistent with
      `$viewdefinition-run.json`. `resource = ["ViewDefinition"]` per
      Decision 2.
- [x] 2.2 Rewrote the `description` using the FSH text.
- [x] 2.3 Introduced the repeating `view` wrapper with `name`,
      `viewReference`, and `viewResource` parts.
- [x] 2.4 Attached `operationdefinition-allowed-type` extension to
      `viewResource`.
- [x] 2.5 Renamed `format` -> `_format`; cardinality `0..1`;
      scope `["system","type"]`; extensible binding to `OutputFormatCodes`.
- [x] 2.6 Added `clientTrackingId`, `header`, `patient`, `group`, `_since`,
      `source` input parameters with FSH-matching cardinalities and scopes.
- [x] 2.7 Set `exportId` output cardinality to `1..1`.
- [x] 2.8 Added `clientTrackingId`, `cancelUrl`, `_format`,
      `exportStartTime`, `exportEndTime`, `exportDuration`,
      `estimatedTimeRemaining` outputs.
- [x] 2.9 Set `output.location.max` to `"*"`.
- [x] 2.10 Removed the per-output `format` part.
- [x] 2.11 Carried `documentation` strings across from the FSH.

## 3. Verification

- [x] 3.1 JSON parses (`node -e "JSON.parse(...)"` -> OK).
- [ ] 3.2 IG build skipped - FSH is unchanged in this change, so the IG
      output is identical to the prior build; the alignment target is the
      already-published FSH instance.
- [x] 3.3 `bun test` in `sof-js`: 149 pass / 9 fail, identical to the
      pre-change baseline (verified by `git stash` round-trip). No
      regressions introduced.
- [ ] 3.4 Reference server `GET /OperationDefinition/$viewdefinition-export`
      not exercised; the loader reads the JSON file generically (other JSON
      files in this directory load the same way), and `bun test` exercises
      that loader path.
- [ ] 3.5 `npm run validate` does not exist as a script (no such target in
      `package.json`); the JSON test-suite AJV check does not cover
      `sof-js/metadata/`. Will be noted in the PR description.
- [x] 3.6 `openspec validate align-viewdefinition-export-reference --strict`
      reports valid.

## 4. Pull request

- [ ] 4.1 Stage only the change directory and the rewritten JSON file.
- [ ] 4.2 Reference upstream issue
      [#344](https://github.com/FHIR/sql-on-fhir-v2/issues/344).
- [ ] 4.3 Note that this is metadata-only.
- [ ] 4.4 Request review and merge once approved.
