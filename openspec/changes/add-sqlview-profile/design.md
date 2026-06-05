## Context

The SQL on FHIR IG defines an `SQLQuery` Library profile
(`input/fsh/profiles/library-profiles.fsh`) that bundles a SQL statement, its
ViewDefinition dependencies (via `relatedArtifact`), and input parameters.
Dependencies are expressed as `relatedArtifact` entries of type `depends-on`
whose `resource` is the canonical URL of a ViewDefinition and whose `label`
becomes the table name in the SQL.

Issue [#329](https://github.com/HL7/sql-on-fhir/issues/329) asks for inter-query
dependencies so the output of one query can feed another. The maintainer
resolution is to introduce a sibling `SQLView` profile (a named, reusable query
analogous to a SQL view) and to widen the dependency rule on both profiles to
allow references to ViewDefinitions or SQLViews.

The artifacts are authored in FSH and compiled by SUSHI; the HL7 IG Publisher
validates the output. CI fails on any error or any unsuppressed warning read
from `output/qa.json`.

## Goals / Non-Goals

**Goals:**

- Add an `SQLView` profile that is a near-twin of `SQLQuery` but with a fixed
  `sql-view` type and no parameters.
- Add the `sql-view` code to `LibraryTypesCodes`.
- Document that both `SQLQuery` and `SQLView` may reference ViewDefinitions or
  SQLViews, forming an acyclic dependency graph.
- Provide a working example of an SQLQuery composing an SQLView.

**Non-Goals:**

- Mandating circular-dependency detection, depth limits, or a materialisation
  strategy - these remain implementation decisions per the issue resolution.
- Parameterised views (explicitly disallowed for now via `parameter 0..0`).
- Changing the `$sqlquery-run` / `$sqlquery-export` operation contracts.

## Decisions

**Decision: A separate `SQLView` profile rather than a flag on `SQLQuery`.**
The resolution calls for a distinct profile with its own type code. A separate
profile lets validators enforce the `0..0` parameter constraint on views while
leaving SQLQuery parameters intact, and gives authors a clear conformance
target. Alternative considered: a single profile distinguished by a type code
or extension - rejected because it cannot express the differing parameter
cardinality cleanly and muddies the conformance story.

**Decision: Keep `relatedArtifact.resource` as an unconstrained canonical.**
FHIR `relatedArtifact.resource` is a `canonical` (a URI). A profile cannot
restrict the resource _type_ that a canonical points to, because the target is
not dereferenced at validation time. The "ViewDefinition or SQLView" rule is
therefore expressed through documentation and the element `^short`, not a
machine-enforced constraint. This matches how the existing SQLQuery profile
already treats ViewDefinition references. Alternative considered: a custom
invariant - rejected as it cannot resolve canonical targets during validation
and would add complexity without enforcement value.

**Decision: Reuse SQLQuery's content and label rules verbatim on `SQLView`.**
Views carry SQL identically to queries (base64 `data`, optional `sql-text`
extension, `application/sql` content types, dialect variants). Reusing the same
rules keeps the two profiles consistent. The `sql-must-be-sql-expressions`
invariant and `sql-name` label invariant apply to both. If this duplication
grows, a shared abstract parent could be extracted later; for two profiles the
duplication is acceptable and simpler than introducing an abstract base now.

**Decision: Add `sql-view` to `LibraryTypesCodes` alongside `sql-query`.**
Single-line addition; keeps both type codes in one system.

## Contracts / External Interfaces

This change introduces one new conformance artifact and widens one existing
one. No runtime API changes.

New profile `SQLView` (canonical
`https://sql-on-fhir.org/ig/StructureDefinition/SQLView`):

- `type` fixed to `LibraryTypesCodes#sql-view`.
- `parameter` `0..0`.
- `content` `1..*`, each `contentType` from mimetypes (required binding) and
  starting with `application/sql`; `content.data` `1..1`; optional `sql-text`
  extension; same dialect-variant selection rules as SQLQuery.
- `relatedArtifact` entries: `type` fixed `depends-on`, `resource` `1..1`
  (canonical of a ViewDefinition or SQLView), `label` `1..1` obeying `sql-name`.
- `obeys sql-must-be-sql-expressions`.

Modified profile `SQLQuery`: `relatedArtifact.resource` documentation updated to
state the canonical may reference a ViewDefinition or an SQLView. The element
cardinality and types are unchanged, so all existing instances stay valid.

New code system concept: `LibraryTypesCodes#sql-view` "SQL View Definition".

## UI Screens

Not applicable - this change adds FHIR conformance resources and IG
documentation pages, with no interactive user interface. The new
`SQLView` profile renders as a standard IG StructureDefinition page, and a menu
entry links to it; these follow the existing IG template.

## Risks / Trade-offs

- [Resource-type of a canonical reference cannot be validated] → Accept;
  document the allowed targets in prose and `^short`, consistent with the
  current ViewDefinition handling.
- [Duplication between SQLQuery and SQLView FSH] → Accept for two profiles;
  revisit with a shared parent only if a third variant appears.
- [Circular references between views are not detected by the spec] → By design;
  the issue resolution defers this to implementations (a SQL engine rejects
  cyclic view creation; a CTE-based implementation detects loops itself).

## Migration Plan

Additive change. Deploy by merging the FSH/docs updates and rebuilding the IG.
No existing instances become invalid. Rollback is removal of the new profile,
code, example, and docs plus reverting the SQLQuery documentation edit.

## Open Questions

None outstanding - the issue's open questions were resolved in the maintainer's
final comment (no separate intermediate/final distinction beyond the profile
itself, implementation-dependent cycle handling and depth limits, and
implementation choice on materialisation).
