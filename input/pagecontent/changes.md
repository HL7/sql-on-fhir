<!-- The Kramdown table-of-contents marker must stay unindented for Kramdown to
     recognise it as an inline attribute list, which is not how Prettier would
     format a list continuation. -->
<!-- prettier-ignore -->
- Contents
{:toc}

This page records the changes made in each version of this specification.

The record begins at version 3.0.0-ballot, because published version 2.0.0 was
released without a changelog and retro-documenting it is out of scope. For the
earlier specifications, see
[published version 2.0.0](https://sql-on-fhir.org/ig/2.0.0), released
2024-10-09, and the
[original SQL on FHIR draft](https://github.com/FHIR/sql-on-fhir-archived/blob/master/sql-on-fhir.md),
which this specification replaced. Everything below is stated relative to
published 2.0.0.

### STU3 Ballot (version 3.0.0-ballot)

#### Non-Compatible Changes

- [#377](https://github.com/HL7/sql-on-fhir/issues/377): **The canonical base
  and the package identifier have changed.** The canonical base moved from
  `https://sql-on-fhir.org/ig` to `http://hl7.org/fhir/uv/sql-on-fhir`, and the
  package identifier from `org.sql-on-fhir.ig` to `hl7.fhir.uv.sql-on-fhir`.
  Four things move with it:
  - the canonical URL of every artefact, so the ViewDefinition logical model is
    now `http://hl7.org/fhir/uv/sql-on-fhir/StructureDefinition/ViewDefinition`
    rather than `https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition`;
  - `meta.profile` values in any resource that claims conformance to a SQL on
    FHIR profile, including the `SQLQuery` and `SQLView` Library profiles;
  - the `select` and `unionAll` content references inside the ViewDefinition
    logical model, which are expressed as
    `{canonical}/StructureDefinition/ViewDefinition#ViewDefinition.select`;
  - `dependencies` entries in downstream implementation guides, which name the
    package identifier rather than the canonical.

  **Migration**: replace `https://sql-on-fhir.org/ig` with
  `http://hl7.org/fhir/uv/sql-on-fhir` wherever it appears, and depend on
  `hl7.fhir.uv.sql-on-fhir` in place of `org.sql-on-fhir.ig`. Version 2.0.0
  remains published at its original canonical, so a resource that must keep
  claiming conformance to 2.0.0 should keep the old URL.

- [#268](https://github.com/HL7/sql-on-fhir/pull/268):
  **`ViewDefinition.identifier` is now repeating.** ViewDefinition derives from
  `CanonicalResource`, which declares `identifier` as `0..*`. In 2.0.0 the
  element was declared locally as `0..1`. In JSON this changes the
  representation from an object to an array.

  **Migration**: wrap the existing `identifier` object in an array. Readers
  should accept either form until every producer has been updated.

- [#301](https://github.com/HL7/sql-on-fhir/pull/301): **The `sql-expressions`
  invariant now rejects a `select` that sets more than one of `forEach`,
  `forEachOrNull` and `repeat`.** In 2.0.0 the expression was
  `(forEach | forEachOrNull).count() <= 1`. Because `|` is the FHIRPath union
  operator, which discards duplicates, a `select` that set both `forEach` and
  `forEachOrNull` to the same expression collapsed to a single item and passed.
  The invariant now counts the elements that are present, so any two of the
  three keywords together are an error however their values compare.

  **Migration**: in any ViewDefinition that sets two of these keywords, keep the
  one that was intended and remove the other. A view that only ever set one is
  unaffected.

Readers who tracked the continuous build rather than published 2.0.0 should also
note that the OperationDefinition canonical URLs changed form, to the
conventional `{canonical}/OperationDefinition/<Id>` without the `$` prefix
([#372](https://github.com/HL7/sql-on-fhir/issues/372)).
`OperationDefinition.code` did not change, so the invocation path of every
operation, such as `$viewdefinition-run`, is unaffected. Relative to 2.0.0 this
is not a breaking change at all, because none of the operations existed then.

#### Compatible, Substantive Changes

- [#291](https://github.com/HL7/sql-on-fhir/issues/291): Added the `SQLQuery`
  profile on `Library`, which represents a single logical SQL query as a
  shareable FHIR resource, with dialect-specific variants, bound parameters, and
  `relatedArtifact` entries naming the ViewDefinitions it reads
  ([#293](https://github.com/HL7/sql-on-fhir/pull/293)). The SQL is carried in a
  readable form by the new `sql-text` extension alongside the base64
  `content.data` ([#309](https://github.com/HL7/sql-on-fhir/pull/309)).
- [#329](https://github.com/HL7/sql-on-fhir/issues/329): Added the `SQLView`
  profile, so one query can depend on the result of another and queries can be
  composed rather than duplicated.
- [#293](https://github.com/HL7/sql-on-fhir/pull/293): Added the
  `LibraryTypesCodes` code system, which marks a Library as a SQL query or a
  reusable SQL view, and the `ExportStatusCodes` code system, which names the
  states an asynchronous export passes through.
- [#309](https://github.com/HL7/sql-on-fhir/pull/309): Added the
  `SQLContentTypeCodes` code system and the `AllSQLContentTypeCodes` value set,
  which name the SQL dialect a query is written in. The `contentType` binding was
  later relaxed to extensible
  ([#351](https://github.com/HL7/sql-on-fhir/issues/351)).
- [#331](https://github.com/HL7/sql-on-fhir/issues/331): Bound each operation's
  output format parameter to a value set of the formats it actually supports,
  rather than leaving it open. The synchronous run operations bind
  `OutputFormatCodes`; the export operations were later narrowed to
  `ExportOutputFormatCodes`, which omits the `fhir` format that only the run
  operations produce ([#365](https://github.com/HL7/sql-on-fhir/pull/365)).
- [760f8f6](https://github.com/HL7/sql-on-fhir/commit/760f8f6): Added the
  `$viewdefinition-run` operation, for synchronous evaluation of a ViewDefinition
  with streamed results. It was first specified in prose and later expressed as an
  OperationDefinition
  ([340dce5](https://github.com/HL7/sql-on-fhir/commit/340dce5)). Its name was
  settled as `$viewdefinition-run` rather than `$run`
  ([#371](https://github.com/HL7/sql-on-fhir/issues/371)), and system-level
  invocation was added alongside the instance level
  ([#330](https://github.com/HL7/sql-on-fhir/issues/330)).
- [760f8f6](https://github.com/HL7/sql-on-fhir/commit/760f8f6): Added the
  `$viewdefinition-export` operation, for asynchronous bulk export of
  ViewDefinition results to CSV, NDJSON or Parquet, likewise specified in prose
  before becoming an OperationDefinition
  ([340dce5](https://github.com/HL7/sql-on-fhir/commit/340dce5)). It was renamed
  from `$export` so it does not collide with Bulk Data Export
  ([#304](https://github.com/HL7/sql-on-fhir/issues/304)), and gained a parameter
  controlling the CSV header row
  ([#305](https://github.com/HL7/sql-on-fhir/issues/305)).
- [#309](https://github.com/HL7/sql-on-fhir/pull/309): Added the `$sqlquery-run`
  operation, for synchronous execution of a `SQLQuery` Library against
  materialised ViewDefinition tables. Its parameters were then aligned to the CQL
  `Library/$evaluate` pattern
  ([#318](https://github.com/HL7/sql-on-fhir/issues/318),
  [#322](https://github.com/HL7/sql-on-fhir/issues/322)).
- [#319](https://github.com/HL7/sql-on-fhir/issues/319): Added the
  `$sqlquery-export` operation, the asynchronous counterpart to
  `$sqlquery-run`.
- [#369](https://github.com/HL7/sql-on-fhir/pull/369): Aligned both export
  operations to the simplified asynchronous interaction pattern, so their
  polling, completion and error behaviour is described once and shared. The
  pattern is still cited from a branch build of the API incubator guide, which
  remains to be replaced with a published link
  ([#368](https://github.com/HL7/sql-on-fhir/issues/368)).
- [#296](https://github.com/HL7/sql-on-fhir/pull/296): Added the `repeat`
  directive, which traverses arbitrarily nested structures such as
  `QuestionnaireResponse.item` without knowing their depth in advance.
- [#311](https://github.com/HL7/sql-on-fhir/pull/311): Added the `%rowIndex`
  environment variable, which exposes the position of an element during
  iteration, so FHIR ordering can be preserved and surrogate keys derived.
- [#265](https://github.com/HL7/sql-on-fhir/issues/265): Added
  `ViewDefinition.profile`, so a view can declare the profiles its input
  resources are expected to conform to.
- [#268](https://github.com/HL7/sql-on-fhir/pull/268): Derived ViewDefinition
  from `CanonicalResource` rather than declaring its metadata elements locally,
  which brings the standard publication metadata with it. This is additive for
  every element except `identifier`, listed above.
- [#290](https://github.com/HL7/sql-on-fhir/pull/290): Added default FHIR type
  to SQL type and FHIRPath type to SQL type mappings, so two runners produce
  comparable column types for the same view when no type hint is given.
- [ff21894](https://github.com/HL7/sql-on-fhir/commit/ff21894): Replaced the
  repository's MIT licence text with the verbatim CC0 1.0 Universal dedication,
  matching the `CC0-1.0` the guide already declared, and added the contribution
  statement required by section 09.01.02 of the HL7 Governance and Operations
  Manual ([3093259](https://github.com/HL7/sql-on-fhir/commit/3093259)).

#### Non-Substantive Changes

- [8431595](https://github.com/HL7/sql-on-fhir/commit/8431595): The `cnl-0` and
  `dom-6` constraints inherited from `CanonicalResource` and `DomainResource`
  ([#268](https://github.com/HL7/sql-on-fhir/pull/268)) are now reported against
  the ViewDefinition examples. Neither is a conformance change:
  `cnl-0` expects a name beginning with an uppercase letter, whereas view names
  are deliberately `snake_case` so they can be used directly as SQL identifiers,
  and `dom-6` recommends a generated narrative, which logical-model instances
  carried as `Binary` do not have. Both are suppressed in
  `input/ignoreWarnings.txt`.
- [#379](https://github.com/HL7/sql-on-fhir/issues/379): Replaced links to
  `build.fhir.org` continuous builds with links to published versions, so the
  guide does not depend on transient build output.
- [#376](https://github.com/HL7/sql-on-fhir/issues/376): Assigned OIDs to the
  code systems and value sets, from the root arc registered for this guide.
- [#358](https://github.com/HL7/sql-on-fhir/issues/358): Reconciled
  inconsistencies across the four operations, covering the return type, whether a
  returned Bundle is unwrapped, `Accept` header semantics, the supported
  `_format` values, streaming guidance and the completion status code. See also
  [#359](https://github.com/HL7/sql-on-fhir/issues/359),
  [#360](https://github.com/HL7/sql-on-fhir/issues/360),
  [#361](https://github.com/HL7/sql-on-fhir/issues/361),
  [#362](https://github.com/HL7/sql-on-fhir/issues/362) and
  [#363](https://github.com/HL7/sql-on-fhir/issues/363).
- [48f3607](https://github.com/HL7/sql-on-fhir/commit/48f3607): Moved the
  JavaScript reference implementation, the shared test suite and the test report
  site out to [FHIR/sql-on-fhir.js](https://github.com/FHIR/sql-on-fhir.js), so
  this repository now holds the specification alone. The repository itself moved
  to [HL7/sql-on-fhir](https://github.com/HL7/sql-on-fhir), and the references to
  its old location were updated
  ([8a9c98f](https://github.com/HL7/sql-on-fhir/commit/8a9c98f)).
- [#325](https://github.com/HL7/sql-on-fhir/pull/325): Restructured the
  introduction around the three components of the specification, and added the
  query and API sections
  ([#300](https://github.com/HL7/sql-on-fhir/pull/300)). The API page, since
  renamed to Operations, was also copy edited
  ([#275](https://github.com/HL7/sql-on-fhir/pull/275)).
