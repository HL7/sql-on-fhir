## 1. FSH OperationDefinition changes

- [x] 1.1 In `input/fsh/operations.fsh`, change `parameter[_format].min` from `1` to `0` on the `ViewDefinitionRun` instance (currently at lines ~229-239).
- [x] 1.2 In `input/fsh/operations.fsh`, change `parameter[_format].min` from `1` to `0` on the `SQLQueryRun` instance (currently at lines ~360-370).
- [x] 1.3 Update the `documentation` string on `parameter[_format]` for `ViewDefinitionExport` to mention that `ndjson` is returned when the parameter is omitted.
- [x] 1.4 Update the `documentation` string on `parameter[_format]` for `ViewDefinitionRun` to mention that `ndjson` is returned when the parameter is omitted.
- [x] 1.5 Update the `documentation` string on `parameter[_format]` for `SQLQueryRun` to mention that `ndjson` is returned when the parameter is omitted.
- [x] 1.6 Run SUSHI (`npx sushi .` or `npm run build:ig`) and confirm the generated `OperationDefinition-ViewDefinitionRun.json` and `OperationDefinition-SQLQueryRun.json` files now have `parameter[?(@.name=='_format')].min == 0`, and that `OperationDefinition-ViewDefinitionExport.json` still has `min == 0`.

## 2. Narrative updates - `$viewdefinition-export`

- [x] 2.1 In `input/pagecontent/OperationDefinition-ViewDefinitionExport-notes.md`, locate the "Format Parameter Clarification" section (around line 285).
- [x] 2.2 Add a sentence stating: "If `_format` is omitted, the server SHALL return the export output in `ndjson` format."
- [x] 2.3 Add a sentence clarifying precedence: "Servers MAY honour the HTTP `Accept` header to negotiate an alternative format when `_format` is not supplied. When `_format` is supplied, its value SHALL take precedence over `Accept`."
- [x] 2.4 Confirm the parameter table near line 245 already shows `0`/`1` cardinality for `_format` (no change needed; verify only).

## 3. Narrative updates - `$viewdefinition-run`

- [x] 3.1 In `input/pagecontent/OperationDefinition-ViewDefinitionRun-notes.md`, update the "Output Control" parameter table (around line 88) so the `Required` column for `_format` reads `No` instead of `Yes`.
- [x] 3.2 In the same file, update the "Format Parameter Clarification" section (around line 139) to add the same two sentences as in `$viewdefinition-export` (default `ndjson`; `_format` precedence over `Accept`).
- [x] 3.3 Review the request/response examples in the file. Keep at least one example that omits `_format` so the default behaviour is illustrated, but do not remove existing examples that use explicit `_format` values.

## 4. Narrative updates - `$sqlquery-run`

- [x] 4.1 In `input/pagecontent/OperationDefinition-SQLQueryRun-notes.md`, locate the parameter tables (sections around the "Output Control" / parameter listing).
- [x] 4.2 Update the `Required` column for `_format` from `Yes` to `No` in any parameter table that lists it.
- [x] 4.3 Add a "Format Parameter Clarification" subsection (modelled on the equivalent section in `OperationDefinition-ViewDefinitionRun-notes.md`) that states the default `ndjson` and the `_format` vs `Accept` precedence.
- [x] 4.4 Add at least one request example (sibling to the existing `_format=csv`/`_format=fhir` examples) that omits `_format` and shows the server returning `ndjson`.

## 5. Build verification

- [x] 5.1 Run `npm run build:ig` and verify the build completes without errors.
- [x] 5.2 Open `output/qa.html` and confirm no new errors or warnings are introduced.
- [x] 5.3 Open the rendered operation pages for `$viewdefinition-export`, `$viewdefinition-run`, and `$sqlquery-run` and visually confirm the parameter tables and "Format Parameter Clarification" sections render the new wording.
- [x] 5.4 Validate the change with `openspec validate align-format-parameter-defaults --strict` and resolve any reported issues.

## 6. Cross-reference and follow-up

- [x] 6.1 Confirm no other narrative pages (e.g. capability statement pages, intro pages) repeat the "\_format is required" wording. If they do, update them for consistency.
- [ ] 6.2 Reference upstream issue [#345](https://github.com/FHIR/sql-on-fhir-v2/issues/345) and Pathling implementation review (aehrc/pathling#2579) in the eventual PR description.
- [ ] 6.3 Mark this change ready for review and request feedback from the SQL on FHIR community before merging.
