## 1. FSH OperationDefinition

- [x] 1.1 Replace `parameter[4]` (lines 388-406 in `input/fsh/operations.fsh`): remove `parameter` with parts, add `parameters` of type `Parameters` (0..1) with scopes type+instance
- [x] 1.2 Renumber `parameter[5]` (source) → `parameter[4]`, `parameter[6]` (return) → `parameter[5]` — N/A, indices unchanged since [4] replaced in-place

## 2. Documentation

- [x] 2.1 Update `input/pagecontent/OperationDefinition-SQLQueryRun-intro.md` — replace references to `parameter` parts with `parameters` resource description
- [x] 2.2 Update `input/pagecontent/OperationDefinition-SQLQueryRun-notes.md` — rewrite all three HTTP examples (instance-level, type-level with reference, type-level with inline) to use nested `Parameters` resource instead of repeated `parameter` parts
- [x] 2.3 Update the Parameter Types table in notes to reference `Parameters.parameter.value[x]` instead of custom parts

## 3. FSH Examples

- [x] 3.1 Update example instances in `input/fsh/examples/sql-query-examples.fsh` — N/A, these define Library instances (Library.parameter declarations), not operation invocations

## 4. Validation

- [x] 4.1 Run SUSHI to verify FSH compiles without errors (0 errors, 2 warnings)
- [x] 4.2 Build IG and check `output/qa.html` for validation issues — 19 errors, all pre-existing (broken links, extension types, publication version), none related to our change
