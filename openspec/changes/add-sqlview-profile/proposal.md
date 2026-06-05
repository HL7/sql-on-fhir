## Why

Real-world analytics often require multi-step transformations where the output
of one query feeds into another. Today an SQLQuery Library can only reference
ViewDefinitions as table sources, so authors must write complex single-pass
queries, duplicate logic, or rely on implementation-specific composition
mechanisms. Resolving [issue #329](https://github.com/HL7/sql-on-fhir/issues/329)
lets queries build on one another, much like SQL views.

## What Changes

- Add a new `SQLView` Library profile representing a reusable, named query that
  other queries can reference as a virtual table source.
  - Library `type` of `LibraryTypesCodes#sql-view`.
  - `parameter` constrained to `0..0` (dependent views cannot be parameterised
    for now, keeping the first iteration simple).
  - `relatedArtifact` entries reference either a ViewDefinition or another
    SQLView.
- Add the `sql-view` code to the `LibraryTypesCodes` code system.
- Update the existing `SQLQuery` profile so its `relatedArtifact` entries may
  reference either a ViewDefinition or an SQLView (previously ViewDefinition
  only).
- Add documentation describing query composition (the SQL-view analogy, the
  dependency DAG, and that materialisation of intermediate results is an
  implementation choice).
- Add an example demonstrating an SQLQuery that references an SQLView.

No breaking changes: existing SQLQuery instances that reference only
ViewDefinitions remain valid.

## Capabilities

### New Capabilities

- `sql-view`: A reusable named-query Library profile (`SQLView`) plus the rules
  governing how SQLQuery and SQLView compose by referencing ViewDefinitions and
  other SQLViews through `relatedArtifact`.

### Modified Capabilities

<!-- The existing SQLQuery profile is not yet captured as an OpenSpec capability,
     so its updated dependency rule is documented within the new sql-view
     capability rather than as a delta to an existing spec. -->

## Acceptance Criteria

- The IG build (`npm run build:ig`) completes with zero errors and zero
  unsuppressed warnings in `output/qa.json`.
- A `StructureDefinition-SQLView` profile is generated whose `type` is fixed to
  `LibraryTypesCodes#sql-view`.
- The generated `SQLView` profile constrains `Library.parameter` to `0..0`
  (max cardinality 0).
- The `LibraryTypesCodes` code system contains a `sql-view` concept.
- A `Library` resource conforming to `SQLView` (type `sql-view`, no parameters,
  `relatedArtifact` referencing a ViewDefinition and/or another SQLView)
  validates successfully against the profile.
- An example SQLQuery whose `relatedArtifact` references an SQLView validates
  successfully and renders on the IG site.

## Impact

- `input/fsh/profiles/library-profiles.fsh`: new `SQLView` profile; updated
  `relatedArtifact` documentation on `SQLQuery`.
- `input/fsh/terminology.fsh`: new `sql-view` code in `LibraryTypesCodes`.
- `input/fsh/examples/`: new example instance(s) for `SQLView` and a composing
  `SQLQuery`.
- `input/pagecontent/`: new intro/notes pages for `SQLView`; updates to the
  `SQLQuery` pages describing composition.
- `sushi-config.yaml`: menu entry for the new `SQLView` page.
- No changes to the `$sqlquery-run` / `$sqlquery-export` operation contracts.
