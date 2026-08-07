<!-- The Kramdown table-of-contents marker must stay unindented for Kramdown to
     recognise it as an inline attribute list, which is not how Prettier would
     format a list continuation. -->
<!-- prettier-ignore -->
- Contents
{:toc}

This page records what changed in each version of this specification.

The record starts at 3.0.0-ballot. Published version 2.0.0 shipped without a
changelog, and reconstructing one is out of scope. Everything below is stated
relative to that release. For the earlier specifications, see
[version 2.0.0](https://sql-on-fhir.org/ig/2.0.0), released 2024-10-09, and the
[original SQL on FHIR draft](https://github.com/FHIR/sql-on-fhir-archived/blob/master/sql-on-fhir.md).

## In short

**The expressive part of a view did not change.** `select`, `column`, `path`,
`forEach`, `forEachOrNull`, `where`, `constant` and `unionAll` mean exactly what
they meant in 2.0.0, and a 2.0.0 view produces the same rows on a 3.0.0 runner.
What broke sits around the view, not inside it: how ViewDefinition is defined,
how it is identified, and the metadata envelope it carries.

**What broke, and what to do about it.** Four things, and each is a mechanical
edit rather than a rewrite.

ViewDefinition is now an additional resource instead of a logical model, so the
guide targets R6. A view names its type the way any resource does, so
`resourceType` becomes the plain token `ViewDefinition`, and your tooling
follows when its FHIR version allows.

Every canonical URL moved with the specification. ViewDefinition went to the
core FHIR namespace, and everything else the guide publishes to
`http://hl7.org/fhir/uv/sql-on-fhir`; the package is now
`hl7.fhir.uv.sql-on-fhir`. Rewrite those URLs wherever they appear, including in
`meta.profile`.

`ViewDefinition.identifier` repeats, which in JSON turns an object into an
array, so wrap what you have.

A `select` now carries at most one of `forEach`, `forEachOrNull` and `repeat`.
If one of yours sets two, keep the directive you meant and delete the other.

**What is new: the specification now covers the whole stack, not just
flattening.** Version 2.0.0 standardised one layer, the flat view. A view alone
is half a bridge: the queries built on it, the cohort definition, the quality
measure, the dashboard query, stayed in wikis and notebooks, tied to one site's
schema, and there was no standard way to ask a server to run any of it.

3.0.0 adds the two missing layers.

- **Queries become artefacts.** `SQLQuery` packages one logical SQL query as a
  FHIR resource, with its dependencies declared as aliases, its parameters bound
  rather than interpolated, and dialect variants where they are needed. `SQLView`
  is the same idea for an intermediate table, so transformations stack instead of
  being copied.
- **The API becomes standard.** `$sql-run` returns rows synchronously and
  `$sql-export` produces files asynchronously, over views and queries alike.

Together these separate authoring from implementation and implementation from
use: one person describes the analytics, any conforming engine runs it, any tool
consumes the result, and the whole set travels as an implementation guide like
any other FHIR artefact. The expressive part gains two optional additions,
`select.repeat` and the `%rowIndex` environment variable.

**Can 2.0.0 and 3.0.0 coexist?** Yes. The releases have different package
identifiers and different canonical URLs, so they install side by side and
neither shadows the other. See [Migrating from 2.0.0](#migrating-from-200).

## STU 3 Ballot (version 3.0.0-ballot)

### Breaking changes

#### From logical model to additional resource

In 2.0.0, ViewDefinition was a logical model: a description of a structure. It
could not be stored, searched or exchanged like a resource, so every server that
wanted to keep views had to invent a container for them.

It is now an **additional resource**. It specialises `DomainResource`,
implements `MetadataResource`, and carries the canonical URL
`http://hl7.org/fhir/StructureDefinition/ViewDefinition`. That is the core FHIR
namespace rather than this guide's, which is the convention for a resource
incubated outside core; whether it is adopted into core is a decision for FHIR
Infrastructure and the FMG, not something this release settles.

Additional resources are a mechanism introduced in FHIR R6, which is itself
still in ballot, so the guide declares `fhirVersion: 6.0.0-ballot3` and will
track R6 as it progresses.

The body of a view is untouched. `select`, `column`, `where`, `constant` and
`unionAll` nest and mean the same. The envelope around it moves in two ways.
`resourceType` was the canonical URL of the logical model,
`https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition`, and is now the
plain resource type token `ViewDefinition`, because that is how a resource
identifies itself. And the publication metadata is no longer this guide's own:
it now follows `MetadataResource`, which is where the `identifier` change below
comes from.

**Migration.** In each view, set `resourceType` to `ViewDefinition`. For tooling,
see [Your tooling](#your-tooling).

Delivered by [#397](https://github.com/HL7/sql-on-fhir/pull/397), tracked in
[#395](https://github.com/HL7/sql-on-fhir/issues/395), which stays open for the
follow-up in `hapifhir/org.hl7.fhir.core`.

#### New canonical base and package identifier

The canonical base moved from `https://sql-on-fhir.org/ig` to
`http://hl7.org/fhir/uv/sql-on-fhir`. The package identifier moved from
`org.sql-on-fhir.ig` to `hl7.fhir.uv.sql-on-fhir`.

Three things move with it. Every artefact the guide publishes gets a new
canonical URL, including the `ShareableViewDefinition` and
`TabularViewDefinition` profiles and the `SQLQuery` and `SQLView` profiles. Any
resource claiming conformance to one of them needs a new `meta.profile` value.
Downstream guides need the new package identifier in their `dependencies`.
ViewDefinition itself is the exception, for the reason given above.

**Why.** The specification is now an HL7 Universal Realm product, and HL7
publishes under its own canonicals and package names. A canonical URL is an
identity, so changing stewardship reissues it.

**Migration.** Replace `https://sql-on-fhir.org/ig` with
`http://hl7.org/fhir/uv/sql-on-fhir`, except where the old URL names
ViewDefinition itself: a canonical reference to
`https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition` becomes
`http://hl7.org/fhir/StructureDefinition/ViewDefinition`, and in an instance it
becomes the plain `resourceType` token. Depend on `hl7.fhir.uv.sql-on-fhir`
instead of `org.sql-on-fhir.ig`. Version 2.0.0 stays published at its original
canonical, so anything that still claims conformance to 2.0.0 keeps the old
URL.

Delivered by [#387](https://github.com/HL7/sql-on-fhir/pull/387), tracked in
[#377](https://github.com/HL7/sql-on-fhir/issues/377).

#### `identifier` becomes repeating

The element was declared locally as `0..1` in 2.0.0. It is now `0..*`, matching
`MetadataResource`. In JSON, an object becomes an array.

**Why.** ViewDefinition stopped defining its own publication metadata and took
the standard definitions instead, where `identifier` repeats. The 2.0.0
cardinality was a local narrowing that nothing on the record explains, so it was
not carried forward.

**Migration.** Wrap the existing object in an array. A reader that accepts both
forms is correct against either version.

Issue: [#268](https://github.com/HL7/sql-on-fhir/pull/268).

#### One iteration directive per `select`

A `select` now carries at most one of `forEach`, `forEachOrNull` and `repeat`.

The 2.0.0 invariant read `(forEach | forEachOrNull).count() <= 1`. In FHIRPath,
`|` is union, which discards duplicates, so a `select` that gave `forEach` and
`forEachOrNull` the same expression collapsed to one item and passed. The
invariant now counts the elements present, so any two of the three are an error
whatever their values.

**Why.** A `select` was always meant to iterate one way. The old expression said
so in a form that did not hold, and the case it let through has no defined
meaning.

**Migration.** Keep the directive you meant and delete the other. A view that
set only one is unaffected.

Issue: [#301](https://github.com/HL7/sql-on-fhir/pull/301).

#### The conformance test suite is no longer in the package

Version 2.0.0 shipped the shared test suite inside the package, twenty JSON
files under `tests/`. It is not in the 3.0.0 package. The suite now lives in
[FHIR/sql-on-fhir.js](https://github.com/FHIR/sql-on-fhir.js) and is versioned
with the reference implementation rather than with the specification.

**Why.** The specification moved to HL7 and was relicensed CC0; the
implementation and the suite stayed with the FHIR Foundation under MIT. Keeping
them in one package would have meant one licence for both.

**Migration.** A build that reads its cases from the installed package takes
them from the repository instead.

([48f3607](https://github.com/HL7/sql-on-fhir/commit/48f3607))

### New capabilities

#### Two operations: `$sql-run` and `$sql-export`

Version 2.0.0 defined no operations, so both are new.

`$sql-run` evaluates one subject and returns the rows. `$sql-export` takes a
repeating `subject` parameter and exports a mixed set of views and queries as
one asynchronous job. A subject is a ViewDefinition, a SQLQuery Library or a
SQLView Library, named by canonical URL, by reference, or supplied inline. Both
operations are invoked at the system level.

Four operations were developed during this cycle and collapsed into these two
before ballot. `$viewdefinition-run`, `$viewdefinition-export`,
`$sqlquery-run` and `$sqlquery-export` existed only in the continuous build and
were never published, so nothing conformant depends on them.

**Why the collapse.** Once aligned, the four differed only in which artefact
they named, and that is a parameter, not an operation. The split also blocked
the case that matters most: exporting views together with the queries built on
them took two jobs, two manifests, filters stated twice, and two readings of the
data taken at different moments, so the outputs could not safely be joined.
`$sql-export` computes every subject in one job against a single snapshot.

Issues: [#392](https://github.com/HL7/sql-on-fhir/pull/392),
[#394](https://github.com/HL7/sql-on-fhir/issues/394),
[#369](https://github.com/HL7/sql-on-fhir/pull/369).

#### SQLQuery and SQLView

`SQLQuery` is a profile on `Library` that carries one logical SQL query as a
FHIR resource: dialect-specific variants, declared parameters, and
`relatedArtifact` entries naming the views it reads. The SQL is readable in the
`sql-text` extension as well as base64 in `content.data`.

`SQLView` is the same idea one step further: its result serves as a table for
other queries, so queries compose instead of duplicating each other.

**Why.** A view flattens FHIR into tables. The analytics built on those tables
stayed as SQL strings inside applications, unshareable and unversioned. These
profiles give that layer the portability the view layer already had.

SQLQuery: [#293](https://github.com/HL7/sql-on-fhir/pull/293) and
[#309](https://github.com/HL7/sql-on-fhir/pull/309), requested in
[#291](https://github.com/HL7/sql-on-fhir/issues/291). SQLView:
[#364](https://github.com/HL7/sql-on-fhir/pull/364), requested in
[#329](https://github.com/HL7/sql-on-fhir/issues/329).

#### `repeat`

`select.repeat` walks arbitrarily nested structures, such as
`QuestionnaireResponse.item`, without knowing their depth in advance. With
`%rowIndex` it is one of the two additions to the expressive part of the model;
everything else added to ViewDefinition describes the view rather than what it
computes.
([#296](https://github.com/HL7/sql-on-fhir/pull/296))

#### `%rowIndex`

`%rowIndex` gives the position of an element during iteration, so FHIR's
ordering can be preserved in the output and surrogate keys derived from it.
([#311](https://github.com/HL7/sql-on-fhir/pull/311))

#### `ViewDefinition.profile`

A view can declare the profiles its input resources are expected to conform to.
It describes the view rather than changing what the view computes, so a runner
that ignores it produces the same rows.
([#267](https://github.com/HL7/sql-on-fhir/pull/267), requested in
[#265](https://github.com/HL7/sql-on-fhir/issues/265))

#### Search parameters for ViewDefinition

Becoming a resource brings the ordinary FHIR read and search machinery with it.
The guide publishes the standard metadata search parameters for ViewDefinition,
so a server can be asked for views by `url`, `identifier`, `name`, `status`,
`publisher`, `date`, `context` and the rest, in the same way as for any other
canonical resource. Version 2.0.0 had no answer to "which views does this server
have", because a logical model has no endpoint.
([#397](https://github.com/HL7/sql-on-fhir/pull/397))

#### Default type mappings

FHIR types and FHIRPath types now have default mappings to SQL types, so two
runners give the same view comparable column types when no type hint is present.
([#290](https://github.com/HL7/sql-on-fhir/pull/290))

#### Publication metadata on ViewDefinition

Taking the standard metadata arrived in two steps. Deriving from
`CanonicalResource` brought `version`, `versionAlgorithm[x]`, `date`, `purpose`
and `copyrightLabel`. Implementing `MetadataResource` alongside the move to a
resource brought `approvalDate`, `lastReviewDate`, `effectivePeriod`, `topic`,
`author`, `editor`, `reviewer`, `endorser` and `relatedArtifact`, and
`jurisdiction`, which R6 marks deprecated in favour of `useContext`. All are
optional. `identifier` is the one element where this was not additive.
([#268](https://github.com/HL7/sql-on-fhir/pull/268),
[#397](https://github.com/HL7/sql-on-fhir/pull/397))

#### Code systems and value sets

`LibraryTypesCodes` marks a Library as a SQL query or a reusable SQL view.
`ExportStatusCodes` names the states an asynchronous export passes through.
`SQLContentTypeCodes` and the `AllSQLContentTypeCodes` value set name the SQL
dialect a query is written in. They are offered as an extensible vocabulary
alongside the required core mime-type binding that `Attachment.contentType`
carries.

Output formats are bound per operation kind: `$sql-run` binds
`OutputFormatCodes`, `$sql-export` the narrower `ExportOutputFormatCodes`, which
omits the `fhir` format only a run can produce.

Issues: [#293](https://github.com/HL7/sql-on-fhir/pull/293),
[#309](https://github.com/HL7/sql-on-fhir/pull/309),
[#351](https://github.com/HL7/sql-on-fhir/issues/351),
[#365](https://github.com/HL7/sql-on-fhir/pull/365).

### Editorial and process changes

#### ViewDefinition is authored in XML, not FSH

SUSHI does not support additional resources, so ViewDefinition, its profiles and
its examples are now authored directly as XML and JSON. The authoring format
carries no semantics of its own, but the change that it made possible does: the
examples are now published as ViewDefinition resources rather than as `Binary`,
and the guide gained search parameters for ViewDefinition and a list of its
operations. ([#397](https://github.com/HL7/sql-on-fhir/pull/397))

#### Validation messages inherent to the additional-resource design

Defining ViewDefinition outside the core specification puts it outside what the
IG Publisher's machinery expects, and a family of QA messages follows that no
change to this repository can remove. `SearchParameter.base` is validated
against a core value set that cannot contain a type defined outside core; a
`StructureDefinition.type` of `ViewDefinition` is rejected as not defined in
FHIR; `Library.relatedArtifact.resource` does not recognise an additional
resource as canonical; the inherited `cnl-1` invariant carries
`MetadataResource` as its source; and every instance is asked for a
`resourceDefinition` property that would put tooling metadata into the published
examples. Alongside these, the publisher's generic FHIRPath evaluator cannot
resolve `%rowIndex` or names evaluated inside a `forEach` scope, and no R6 build
of `hl7.fhir.uv.extensions`, `hl7.terminology` or `hl7.fhir.uv.tools` exists, so
the publisher reports a package-version mismatch this repository cannot resolve.

None of these is a conformance change. Each is suppressed in
`input/ignoreWarnings.txt` with a written justification and a link to the
discussion that established it.
([#399](https://github.com/HL7/sql-on-fhir/pull/399))

#### Publishing housekeeping

Links to `build.fhir.org` were replaced with links to published versions
([#386](https://github.com/HL7/sql-on-fhir/pull/386)). Code systems and value
sets were given OIDs from the root arc registered for this guide
([#381](https://github.com/HL7/sql-on-fhir/pull/381)). The repository licence
text was replaced with the verbatim CC0 1.0 Universal dedication, matching the
`CC0-1.0` the guide already declared, and the contribution statement required by
the HL7 Governance and Operations Manual was added
([ff21894](https://github.com/HL7/sql-on-fhir/commit/ff21894),
[3093259](https://github.com/HL7/sql-on-fhir/commit/3093259)).

#### Reference implementation moved to its own repository

The JavaScript reference implementation, the shared test suite and the test
report site now live in
[FHIR/sql-on-fhir.js](https://github.com/FHIR/sql-on-fhir.js). This repository
holds the specification alone, and moved to
[HL7/sql-on-fhir](https://github.com/HL7/sql-on-fhir).
([48f3607](https://github.com/HL7/sql-on-fhir/commit/48f3607),
[8a9c98f](https://github.com/HL7/sql-on-fhir/commit/8a9c98f))

#### Documentation

The introduction was restructured around the three components of the
specification, and the query and operations sections were added. Inconsistencies
across the operation definitions were reconciled: return type, Bundle
unwrapping, `Accept` semantics, supported `_format` values, streaming guidance
and the completion status code.
([#325](https://github.com/HL7/sql-on-fhir/pull/325),
[#300](https://github.com/HL7/sql-on-fhir/pull/300),
[#365](https://github.com/HL7/sql-on-fhir/pull/365) closing
[#358](https://github.com/HL7/sql-on-fhir/issues/358)-[#363](https://github.com/HL7/sql-on-fhir/issues/363))

## Migrating from 2.0.0

### Your existing ViewDefinitions

**The expressive part did not change.** `resource`, `select`, `column`, `path`,
`forEach`, `forEachOrNull`, `where`, `constant` and `unionAll` mean what they
meant in 2.0.0, and a 2.0.0 view produces the same rows on a 3.0.0 runner. The
only additions to that part are `select.repeat` and `%rowIndex`. Everything else added to
ViewDefinition describes the view rather than what it computes, and none of it
is required.

What needs editing is the envelope. One change applies to every view, and three
more only if your views use them.

**`resourceType` becomes the plain token.** `"resourceType":
"https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition"` becomes
`"resourceType": "ViewDefinition"`, because a resource names its type rather
than a logical model's canonical URL.

**`identifier` is now an array.** A view carrying `"identifier": { ... }` needs
`"identifier": [{ ... }]`. If you both produce and consume views, accept either
form while your producers catch up.

**A `select` now carries at most one of `forEach`, `forEachOrNull` and
`repeat`.** The
2.0.0 invariant let two through when they held the same expression. Such a view
was already ambiguous, since it states two iteration behaviours at once. Keep
the one you meant.

**`meta.profile` needs rewriting.** A view claiming
`https://sql-on-fhir.org/ig/StructureDefinition/ShareableViewDefinition` or
`.../TabularViewDefinition` names the profile's new canonical instead. A view
that claims no profile needs no change.

Everything else is a string replacement rather than a change to your views:
`https://sql-on-fhir.org/ig` becomes the new canonical base, and the package
`org.sql-on-fhir.ig` becomes `hl7.fhir.uv.sql-on-fhir`.

### Your tooling

This is where the two versions genuinely part company. In 2.0.0 ViewDefinition
was a logical model against FHIR R5. In 3.0.0 it is an additional resource, and
the guide declares `fhirVersion: 6.0.0-ballot3`. A runner that validates views
through R5 tooling cannot load the 3.0.0 package, even when its views are
unaffected.

Nothing forces that upgrade at once. The two releases have different package
identifiers and different canonical URLs, so **they install side by side and
neither shadows the other**. A deployment can keep 2.0.0 tooling over views that
are already valid against both, and move when its stack reads R6 structure
definitions. R6 is itself still in ballot, so that wait is real and this
specification tracks it rather than getting ahead of it.
