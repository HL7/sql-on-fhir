# Tasks

## 1. Specification updates

- [x] 1.1 Add `%rowIndex` documentation to
      `input/pagecontent/StructureDefinition-ViewDefinition-notes.md` in a new
      section under "Using Constants" or as part of a new "Environment Variables"
      section.
- [x] 1.2 Update the processing algorithm section to describe how `%rowIndex` is
      set during iteration (step 2 of the recursive `Process(S, N)` algorithm).
- [x] 1.3 Add `%rowIndex` to the FHIRPath subset documentation if a formal list
      of supported environment variables exists.

## 2. Test suite

- [x] 2.1 Create `tests/row_index.json` with comprehensive test cases:
  - Basic `forEach` with `%rowIndex` column.
  - Basic `forEachOrNull` with `%rowIndex` column.
  - Nested `forEach` demonstrating independent `%rowIndex` per level.
  - `%rowIndex` at top level (should be 0).
  - `%rowIndex` with `repeat` directive.
  - `%rowIndex` combined with `unionAll`.
- [x] 2.2 Validate new tests with `npm run validate`.

## 3. Reference implementation (sof-js)

- [x] 3.1 Update `sof-js/src/index.js` to track iteration index in `forEach`,
      `forEachOrNull`, and `repeat` functions.
- [x] 3.2 Update `sof-js/src/path.js` `fhirpath_evaluate` to accept and pass
      `%rowIndex` as an environment variable to the fhirpath library.
- [x] 3.3 Run `bun test` in `sof-js/` to verify all tests pass.

## 4. Documentation

- [x] 4.1 Add an example ViewDefinition to
      `input/fsh/examples/view-definition-examples.fsh` demonstrating `%rowIndex`
      usage.
- [x] 4.2 Update the functional model documentation
      (`input/pagecontent/functional-model.md`) if needed to explain `%rowIndex`
      semantics.
