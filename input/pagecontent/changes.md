<!-- The Kramdown table-of-contents marker must stay unindented for Kramdown to
     recognize it as an inline attribute list, which is not how Prettier would
     format a list continuation. -->
<!-- prettier-ignore -->
- Contents
{:toc}

This page records the changes made in each version of this specification.

The record begins at 3.0.0-ballot. Published version 2.0.0 shipped without a
changelog, and reconstruction of one is out of scope. All changes below are
stated relative to that release. For earlier material, see
[version 2.0.0](https://sql-on-fhir.org/ig/2.0.0), released 2024-10-09, and the
[original SQL on FHIR draft](https://github.com/FHIR/sql-on-fhir-archived/blob/master/sql-on-fhir.md).

## Summary

**The expressive part of a view is unchanged.** `select`, `column`, `path`,
`forEach`, `forEachOrNull`, `where`, `constant` and `unionAll` retain the
semantics they had in 2.0.0, and a 2.0.0 view produces the same rows on a 3.0.0
runner. The breaking changes concern how ViewDefinition is defined, how it is
identified, and the metadata it carries, rather than the view logic itself.

**Breaking changes.** There are four. Each requires a mechanical edit rather
than a rewrite.

- ViewDefinition is now an additional resource rather than a logical model, and
  the guide consequently targets FHIR R6. A view identifies its type in the
  same way as any other resource, so `resourceType` becomes the plain token
  `ViewDefinition`. Tooling must be able to read R6 structure definitions to
  load the package.
- Every canonical URL published by this guide has changed. ViewDefinition moved
  to the core FHIR namespace, and all other artifacts moved to
  `http://hl7.org/fhir/uv/sql-on-fhir`. The package identifier is now
  `hl7.fhir.uv.sql-on-fhir`. These URLs must be rewritten wherever they appear,
  including in `meta.profile`.
- `ViewDefinition.identifier` is now a repeating element. In JSON, an object
  becomes an array.
- A `select` now carries at most one of `forEach`, `forEachOrNull` and
  `repeat`. A view that sets two must retain the intended directive and remove
  the other.

**New capabilities.** Version 2.0.0 standardized a single layer, the flat view.
The queries built on views, and the interface for asking a server to evaluate
them, remained outside the specification. Version 3.0.0 adds both layers:

- **Queries as artifacts.** `SQLQuery` packages one logical SQL query as a FHIR
  resource, with its dependencies declared as aliases, its parameters bound
  rather than interpolated, and dialect variants where required. `SQLView`
  applies the same approach to an intermediate table, allowing transformations
  to be composed rather than duplicated.
- **A standard API.** `$sql-run` returns rows synchronously and `$sql-export`
  produces files asynchronously, over both views and queries.

These additions separate authoring from implementation and implementation from
use: one party defines the analytics, any conforming engine evaluates them, any
tool consumes the result, and the complete set is distributable as an
implementation guide in the same manner as any other FHIR artifact. The
expressive part of the model gains two optional additions, `select.repeat` and
the `%rowIndex` environment variable.

**Coexistence of 2.0.0 and 3.0.0.** The two releases have different package
identifiers and different canonical URLs, so they install side by side and
neither shadows the other. See [Migrating from 2.0.0](#migrating-from-200).

## STU 3 ballot (version 3.0.0-ballot)

### Breaking changes

#### From logical model to additional resource

In 2.0.0, ViewDefinition was a logical model: a description of a structure that
could not be stored, searched or exchanged as a resource, so servers holding
views had to define their own containers for them.

ViewDefinition is now an **additional resource**. It specializes
`DomainResource`, implements `MetadataResource`, and carries the canonical URL
`http://hl7.org/fhir/StructureDefinition/ViewDefinition`. That URL is in the
core FHIR namespace rather than this guide's, following the convention for a
resource incubated outside core. Whether the resource is adopted into core is a
decision for FHIR Infrastructure and the FMG, and is not settled by this
release.

Additional resources are a mechanism introduced in FHIR R6, which is itself in
ballot, so the guide declares `fhirVersion: 6.0.0-ballot3` and will track R6 as
it progresses.

The body of a view is unaffected: `select`, `column`, `where`, `constant` and
`unionAll` nest and behave as before. Two changes apply to the surrounding
structure. First, `resourceType` was previously the canonical URL of the
logical model, `https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition`,
and is now the plain resource type token `ViewDefinition`, consistent with how
any resource identifies its type. Second, the publication metadata is no longer
defined locally by this guide and instead follows `MetadataResource`, which is
the origin of the `identifier` change below.

**Migration.** In each view, set `resourceType` to `ViewDefinition`. For
tooling implications, see [Tooling](#tooling).

Delivered by [#397](https://github.com/HL7/sql-on-fhir/pull/397), tracked in
[#395](https://github.com/HL7/sql-on-fhir/issues/395), which remains open for
follow-up work in `hapifhir/org.hl7.fhir.core`.

#### New canonical base and package identifier

The canonical base changed from `https://sql-on-fhir.org/ig` to
`http://hl7.org/fhir/uv/sql-on-fhir`. The package identifier changed from
`org.sql-on-fhir.ig` to `hl7.fhir.uv.sql-on-fhir`.

Three consequences follow. Every artifact published by the guide has a new
canonical URL, including the `ShareableViewDefinition` and
`TabularViewDefinition` profiles and the `SQLQuery` and `SQLView` profiles, so
any resource claiming conformance to one of them requires a new `meta.profile`
value. Downstream guides require the new package identifier in their
`dependencies`. ViewDefinition itself is the exception, for the reason given
above.

**Rationale.** The specification is now an HL7 Universal Realm product, and HL7
publishes under its own canonical base and package names. A canonical URL is an
identity, so a change of stewardship reissues it.

**Migration.** Replace `https://sql-on-fhir.org/ig` with
`http://hl7.org/fhir/uv/sql-on-fhir`, except where the old URL names
ViewDefinition itself: a canonical reference to
`https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition` becomes
`http://hl7.org/fhir/StructureDefinition/ViewDefinition`, and in an instance it
becomes the plain `resourceType` token. Depend on `hl7.fhir.uv.sql-on-fhir`
rather than `org.sql-on-fhir.ig`. Version 2.0.0 remains published at its
original canonical, so any artifact that continues to claim conformance to
2.0.0 retains the old URL.

Delivered by [#387](https://github.com/HL7/sql-on-fhir/pull/387), tracked in
[#377](https://github.com/HL7/sql-on-fhir/issues/377).

#### `identifier` becomes repeating

The element was declared locally as `0..1` in 2.0.0. It is now `0..*`, matching
`MetadataResource`. In JSON, an object becomes an array.

**Rationale.** ViewDefinition no longer defines its own publication metadata
and takes the standard definitions instead, in which `identifier` repeats. The
2.0.0 cardinality was a local narrowing with no recorded justification, so it
was not carried forward.

**Migration.** Wrap the existing object in an array. A reader that accepts both
forms is correct against either version.

Issue: [#268](https://github.com/HL7/sql-on-fhir/pull/268).

#### One iteration directive per `select`

A `select` now carries at most one of `forEach`, `forEachOrNull` and `repeat`.

The 2.0.0 invariant read `(forEach | forEachOrNull).count() <= 1`. In FHIRPath,
`|` is a union operator, which discards duplicates, so a `select` that gave
`forEach` and `forEachOrNull` the same expression collapsed to a single item
and passed validation. The invariant now counts the elements present, so any
two of the three are an error regardless of their values.

**Rationale.** A `select` was always intended to specify a single iteration
behavior. The previous expression stated this in a form that did not hold, and
the case it admitted has no defined meaning.

**Migration.** Retain the intended directive and remove the other. A view that
set only one directive is unaffected.

Issue: [#301](https://github.com/HL7/sql-on-fhir/pull/301).

#### The conformance test suite is no longer in the package

Version 2.0.0 shipped the shared test suite inside the package, as twenty JSON
files under `tests/`. The suite is not included in the 3.0.0 package. It now
resides in [FHIR/sql-on-fhir.js](https://github.com/FHIR/sql-on-fhir.js) and is
versioned with the reference implementation rather than with the
specification.

**Rationale.** The specification moved to HL7 and was relicensed under CC0; the
implementation and the test suite remained with the FHIR Foundation under the
MIT license. Retaining both in one package would have required a single license
for both.

**Migration.** A build that reads test cases from the installed package must
read them from the repository instead.

([48f3607](https://github.com/HL7/sql-on-fhir/commit/48f3607))

### New capabilities

#### Two operations: `$sql-run` and `$sql-export`

Version 2.0.0 defined no operations, so both are new.

`$sql-run` evaluates a single subject and returns the rows. `$sql-export`
takes a repeating `subject` parameter and exports a mixed set of views and
queries as one asynchronous job. A subject is a ViewDefinition, a SQLQuery
Library or a SQLView Library, named by canonical URL, by reference, or supplied
inline. Both operations are invoked at the system level.

Four operations were developed during this cycle and consolidated into these
two before ballot. `$viewdefinition-run`, `$viewdefinition-export`,
`$sqlquery-run` and `$sqlquery-export` existed only in the continuous build and
were never published, so no conformant implementation depends on them.

**Rationale for the consolidation.** Once aligned, the four operations differed
only in the kind of artifact they named, which is a parameter rather than an
operation. The split also prevented a significant use case: exporting views
together with the queries built on them required two jobs, two manifests,
filters stated twice, and two readings of the data taken at different moments,
so the outputs could not safely be joined. `$sql-export` computes every subject
in one job against a single snapshot.

Issues: [#392](https://github.com/HL7/sql-on-fhir/pull/392),
[#394](https://github.com/HL7/sql-on-fhir/issues/394),
[#369](https://github.com/HL7/sql-on-fhir/pull/369).

#### SQLQuery and SQLView

`SQLQuery` is a profile on `Library` that carries one logical SQL query as a
FHIR resource: dialect-specific variants, declared parameters, and
`relatedArtifact` entries naming the views it reads. The SQL is readable in the
`sql-text` extension as well as base64-encoded in `content.data`.

`SQLView` extends the same approach: its result serves as a table for other
queries, so queries compose rather than duplicate one another.

**Rationale.** A view flattens FHIR into tables, but the analytics built on
those tables previously existed only as SQL strings inside applications,
neither shareable nor versioned. These profiles give that layer the portability
the view layer already had.

SQLQuery: [#293](https://github.com/HL7/sql-on-fhir/pull/293) and
[#309](https://github.com/HL7/sql-on-fhir/pull/309), requested in
[#291](https://github.com/HL7/sql-on-fhir/issues/291). SQLView:
[#364](https://github.com/HL7/sql-on-fhir/pull/364), requested in
[#329](https://github.com/HL7/sql-on-fhir/issues/329).

#### `repeat`

`select.repeat` traverses arbitrarily nested structures, such as
`QuestionnaireResponse.item`, without prior knowledge of their depth. Together
with `%rowIndex` it is one of the two additions to the expressive part of the
model; every other addition to ViewDefinition describes the view rather than
what it computes.
([#296](https://github.com/HL7/sql-on-fhir/pull/296))

#### `%rowIndex`

`%rowIndex` provides the position of an element during iteration, so that the
ordering of elements in FHIR resources can be preserved in the output and
surrogate keys derived from it.
([#311](https://github.com/HL7/sql-on-fhir/pull/311))

#### `ViewDefinition.profile`

A view can declare the profiles its input resources are expected to conform
to. The element describes the view rather than changing what the view computes,
so a runner that ignores it produces the same rows.
([#267](https://github.com/HL7/sql-on-fhir/pull/267), requested in
[#265](https://github.com/HL7/sql-on-fhir/issues/265))

#### Search parameters for ViewDefinition

Becoming a resource brings the standard FHIR read and search machinery with it.
The guide publishes the standard metadata search parameters for ViewDefinition,
so a server can be queried for views by `url`, `identifier`, `name`, `status`,
`publisher`, `date`, `context` and the remaining metadata parameters, in the
same manner as any other canonical resource. Version 2.0.0 provided no means of
discovering the views held by a server, because a logical model has no
endpoint.
([#397](https://github.com/HL7/sql-on-fhir/pull/397))

#### Default type mappings

FHIR types and FHIRPath types now have default mappings to SQL types, so that
two runners evaluating the same view produce comparable column types when no
type hint is present.
([#290](https://github.com/HL7/sql-on-fhir/pull/290))

#### Publication metadata on ViewDefinition

Adoption of the standard metadata occurred in two steps. Deriving from
`CanonicalResource` brought `version`, `versionAlgorithm[x]`, `date`, `purpose`
and `copyrightLabel`. Implementing `MetadataResource`, alongside the move to a
resource, brought `approvalDate`, `lastReviewDate`, `effectivePeriod`, `topic`,
`author`, `editor`, `reviewer`, `endorser` and `relatedArtifact`, and
`jurisdiction`, which R6 deprecates in favor of `useContext`. All are
optional. `identifier` is the one element for which this change was not
additive.
([#268](https://github.com/HL7/sql-on-fhir/pull/268),
[#397](https://github.com/HL7/sql-on-fhir/pull/397))

#### Code systems and value sets

`LibraryTypesCodes` identifies a Library as a SQL query or a reusable SQL view.
`ExportStatusCodes` names the states through which an asynchronous export
passes. `SQLContentTypeCodes` and the `AllSQLContentTypeCodes` value set name
the SQL dialect in which a query is written. They are offered as an extensible
vocabulary alongside the required core mime-type binding carried by
`Attachment.contentType`.

Output formats are bound per operation kind: `$sql-run` binds
`OutputFormatCodes`, and `$sql-export` binds the narrower
`ExportOutputFormatCodes`, which omits the `fhir` format that only a run can
produce.

Issues: [#293](https://github.com/HL7/sql-on-fhir/pull/293),
[#309](https://github.com/HL7/sql-on-fhir/pull/309),
[#351](https://github.com/HL7/sql-on-fhir/issues/351),
[#365](https://github.com/HL7/sql-on-fhir/pull/365).

### Editorial and process changes

#### ViewDefinition is authored in XML, not FSH

SUSHI does not support additional resources, so ViewDefinition, its profiles
and its examples are now authored directly as XML and JSON. The authoring
format carries no semantics of its own, but the change it enabled does: the
examples are now published as ViewDefinition resources rather than as `Binary`,
and the guide gained search parameters for ViewDefinition and a list of its
operations. ([#397](https://github.com/HL7/sql-on-fhir/pull/397))

#### Validation messages inherent to the additional-resource design

Defining ViewDefinition outside the core specification places it outside the
assumptions of the IG Publisher's validation machinery, and a family of QA
messages follows that no change to this repository can remove.
`SearchParameter.base` is validated against a core value set that cannot
contain a type defined outside core; a `StructureDefinition.type` of
`ViewDefinition` is rejected as not defined in FHIR;
`Library.relatedArtifact.resource` does not recognize an additional resource as
canonical; the inherited `cnl-1` invariant carries `MetadataResource` as its
source; and every instance is asked for a `resourceDefinition` property that
would place tooling metadata in the published examples. In addition, the
publisher's generic FHIRPath evaluator cannot resolve `%rowIndex` or names
evaluated inside a `forEach` scope, and no R6 build of
`hl7.fhir.uv.extensions`, `hl7.terminology` or `hl7.fhir.uv.tools` exists, so
the publisher reports a package-version mismatch that this repository cannot
resolve.

None of these messages reflects a conformance change. Each is suppressed in
`input/ignoreWarnings.txt` with a written justification and a link to the
discussion that established it.
([#399](https://github.com/HL7/sql-on-fhir/pull/399))

#### Publishing housekeeping

Links to `build.fhir.org` were replaced with links to published versions
([#386](https://github.com/HL7/sql-on-fhir/pull/386)). Code systems and value
sets were assigned OIDs from the root arc registered for this guide
([#381](https://github.com/HL7/sql-on-fhir/pull/381)). The repository license
text was replaced with the verbatim CC0 1.0 Universal dedication, matching the
`CC0-1.0` license the guide already declared, and the contribution statement
required by the HL7 Governance and Operations Manual was added
([ff21894](https://github.com/HL7/sql-on-fhir/commit/ff21894),
[3093259](https://github.com/HL7/sql-on-fhir/commit/3093259)).

#### Reference implementation moved to its own repository

The JavaScript reference implementation, the shared test suite and the test
report site now reside in
[FHIR/sql-on-fhir.js](https://github.com/FHIR/sql-on-fhir.js). This repository
holds the specification alone, and moved to
[HL7/sql-on-fhir](https://github.com/HL7/sql-on-fhir).
([48f3607](https://github.com/HL7/sql-on-fhir/commit/48f3607),
[8a9c98f](https://github.com/HL7/sql-on-fhir/commit/8a9c98f))

#### Documentation

The introduction was restructured around the three components of the
specification, and the query and operations sections were added.
Inconsistencies across the operation definitions were reconciled: return type,
Bundle unwrapping, `Accept` semantics, supported `_format` values, streaming
guidance and the completion status code.
([#325](https://github.com/HL7/sql-on-fhir/pull/325),
[#300](https://github.com/HL7/sql-on-fhir/pull/300),
[#365](https://github.com/HL7/sql-on-fhir/pull/365) closing
[#358](https://github.com/HL7/sql-on-fhir/issues/358)-[#363](https://github.com/HL7/sql-on-fhir/issues/363))

## Migrating from 2.0.0

### Existing ViewDefinitions

**The expressive part is unchanged.** `resource`, `select`, `column`, `path`,
`forEach`, `forEachOrNull`, `where`, `constant` and `unionAll` retain their
2.0.0 semantics, and a 2.0.0 view produces the same rows on a 3.0.0 runner. The
only additions to that part are `select.repeat` and `%rowIndex`. Every other
addition to ViewDefinition describes the view rather than what it computes, and
none is required.

What requires editing is the surrounding structure. One change applies to every
view; three more apply only where a view uses the affected element.

- **`resourceType` becomes the plain token.** `"resourceType":
  "https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition"` becomes
  `"resourceType": "ViewDefinition"`, because a resource names its type rather
  than a logical model's canonical URL.
- **`identifier` is now an array.** A view carrying `"identifier": { ... }`
  requires `"identifier": [{ ... }]`. Systems that both produce and consume
  views should accept either form during the transition.
- **A `select` carries at most one of `forEach`, `forEachOrNull` and
  `repeat`.** The 2.0.0 invariant admitted two directives when they held the
  same expression. Such a view was already ambiguous, since it states two
  iteration behaviors at once. Retain the intended directive.
- **`meta.profile` requires rewriting.** A view claiming
  `https://sql-on-fhir.org/ig/StructureDefinition/ShareableViewDefinition` or
  `.../TabularViewDefinition` must name the profile's new canonical instead. A
  view that claims no profile requires no change.

All remaining changes are string replacements rather than changes to views:
`https://sql-on-fhir.org/ig` becomes the new canonical base, and the package
`org.sql-on-fhir.ig` becomes `hl7.fhir.uv.sql-on-fhir`.

### Tooling

This is where the two versions diverge most. In 2.0.0, ViewDefinition was a
logical model against FHIR R5. In 3.0.0, it is an additional resource, and the
guide declares `fhirVersion: 6.0.0-ballot3`. A runner that validates views
through R5 tooling cannot load the 3.0.0 package, even where its views are
unaffected.

The upgrade is not forced. The two releases have different package identifiers
and different canonical URLs, so **they install side by side and neither
shadows the other**. A deployment can retain 2.0.0 tooling over views that are
already valid against both versions, and move when its stack reads R6
structure definitions. R6 is itself still in ballot, and this specification
tracks its progress rather than anticipating it.
