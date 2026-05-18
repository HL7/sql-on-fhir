## 1. FSH OperationDefinition

- [ ] 1.1 Add `parameter[6]` block to `SQLQueryRun` in `input/fsh/operations.fsh` (after the current `parameter[5]` source block, before the existing `return` parameter): `_limit` (integer, 0..1, scope system/type/instance, documentation "Maximum number of rows to return.")
- [ ] 1.2 Renumber the existing `return` parameter from `parameter[6]` to `parameter[7]` (preserving all of its current configuration: name, use, min/max, type, allowedType extensions, documentation)

## 2. Documentation

- [ ] 2.1 Update `input/pagecontent/OperationDefinition-SQLQueryRun-notes.md` to describe `_limit`: add an input parameter table (or extend existing sections) covering `_format`, `header`, `queryReference`, `queryResource`, `parameters`, `source`, and `_limit` with name/type/scope/cardinality/description, modelled on the `$viewdefinition-run` notes tables
- [ ] 2.2 Add a "Row Limit" subsection to the notes that documents: (a) servers MAY cap, (b) the cap is applied to the final result set after SQL evaluation (including any in-query `LIMIT`), (c) returning fewer rows than requested is not an error
- [ ] 2.3 Add at least one HTTP example demonstrating `_limit` (extend an existing example or add a new one), showing the parameter alongside `_format`
- [ ] 2.4 Ensure all in-text references to `_limit` are consistent with the `$viewdefinition-run` notes (same wording for shared concepts)

## 3. Validation

- [ ] 3.1 Run SUSHI (`npm run build:ig` or `sushi build`) and verify the FSH compiles without new errors
- [ ] 3.2 Build the IG (`npm run build:ig`) and confirm `output/OperationDefinition-SQLQueryRun.html` lists `_limit` as an input parameter
- [ ] 3.3 Inspect the rendered notes page (`output/OperationDefinition-SQLQueryRun.html`) and confirm the parameter table and "Row Limit" narrative render correctly
- [ ] 3.4 Compare against `output/OperationDefinition-ViewDefinitionRun.html` to confirm `_limit` is presented consistently between the two operations
- [ ] 3.5 Check `output/qa.html` for any new validation errors related to the change (pre-existing errors may be ignored, but record them)

## 4. Issue closure

- [ ] 4.1 Note in the PR description that this change closes [issue #346](https://github.com/FHIR/sql-on-fhir-v2/issues/346)
- [ ] 4.2 Cross-reference Pathling PR `aehrc/pathling#2579` in the PR description so the downstream implementation can drop its non-spec annotation
