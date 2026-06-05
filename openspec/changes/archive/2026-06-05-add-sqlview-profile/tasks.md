## 1. Terminology

- [x] 1.1 Add the `sql-view` concept ("SQL View Definition") to the
      `LibraryTypesCodes` code system in `input/fsh/terminology.fsh`.

## 2. Profiles

- [x] 2.1 Add the `SQLView` profile to
      `input/fsh/profiles/library-profiles.fsh`: parent `Library`,
      `obeys sql-must-be-sql-expressions`, `type = LibraryTypesCodes#sql-view`.
- [x] 2.2 Constrain `parameter 0..0` on `SQLView` with an explanatory `^short`.
- [x] 2.3 Add `content` rules to `SQLView` mirroring `SQLQuery` (cardinality,
      `contentType` binding, `sql-text` extension, `data`).
- [x] 2.4 Add `relatedArtifact` rules to `SQLView` (`type = depends-on`,
      `resource 1..1`, `label 1..1 obeys sql-name`), constrain
      `relatedArtifact.resource only Canonical(ViewDefinition or SQLView)`, and
      set a `^short` stating the resource may be a ViewDefinition or SQLView.
- [x] 2.5 Update the `SQLQuery` profile: constrain
      `relatedArtifact.resource only Canonical(ViewDefinition or SQLView)` and
      update the `relatedArtifact.resource` `^short` (and `relatedArtifact.type`
      short) to state references may be a ViewDefinition or an SQLView.

## 3. Examples

- [x] 3.1 Add an `SQLView` example instance (no parameters, referencing a
      ViewDefinition) in `input/fsh/examples/`.
- [x] 3.2 Add an `SQLQuery` example whose `relatedArtifact` references the new
      `SQLView`, demonstrating composition.

## 4. Documentation

- [x] 4.1 Add `StructureDefinition-SQLView-intro.md` and
      `StructureDefinition-SQLView-notes.md` in `input/pagecontent/`
      (scope/usage, dependency rules, no-parameters constraint).
- [x] 4.2 Update `StructureDefinition-SQLQuery-intro.md` /
      `-notes.md` to describe query composition (SQL-view analogy, a dependency
      graph authors should keep acyclic, materialisation as an implementation
      choice) and that `relatedArtifact` may reference ViewDefinitions or
      SQLViews.
- [x] 4.3 Add a `SQL View` menu entry in `sushi-config.yaml`.

## 5. Build and verify

- [x] 5.1 Run `npm run build:ig` and confirm `output/qa.json` reports zero
      errors and zero unsuppressed warnings; suppress only non-actionable
      warnings via `input/ignoreWarnings.txt` if needed.
- [x] 5.2 Confirm the generated `StructureDefinition-SQLView` fixes `type` to
      `sql-view` and constrains `parameter` to `0..0`.
- [x] 5.3 Confirm both generated profiles declare
      `relatedArtifact.resource.type.targetProfile` listing the `ViewDefinition`
      and `SQLView` canonicals, that SUSHI compiles
      `Canonical(ViewDefinition or SQLView)` without error, and that the
      logical-model target (`ViewDefinition`) produces no non-actionable IG
      Publisher errors (fall back to documentation-only if it does).
- [x] 5.4 Confirm the `SQLView` and composing `SQLQuery` examples validate and
      render on the IG site (`output/`).
