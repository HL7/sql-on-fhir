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
- Constrain both `SQLQuery` and `SQLView` so `relatedArtifact.resource` may
  reference only ViewDefinitions or SQLViews, forming a dependency graph that
  authors should keep acyclic.
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

**Decision: Constrain `relatedArtifact.resource` with a `targetProfile`.**
FHIR `relatedArtifact.resource` is a `canonical`, and a canonical-typed element
may carry `targetProfile` (the same mechanism `Reference` uses). Each profile
therefore declares `relatedArtifact.resource only Canonical(ViewDefinition or
SQLView)`, recording both allowed targets with OR semantics. This is
machine-readable and is enforced by the validator whenever the canonical
resolves to a concrete resource in this IG or a loaded dependency. Enforcement
is partial: when a canonical cannot be resolved (for example the external
`https://example.org/...` URLs used by the existing examples) the validator
reports an unresolved-reference warning and skips the type check rather than
failing. The element `^short` is retained as the human-facing fallback.
Alternative considered: leaving the canonical unconstrained and documenting the
rule in prose only - rejected because the `targetProfile` captures the intent
for tooling and provides real validation whenever targets resolve, at a
one-line cost.

`ViewDefinition` is a logical model (parent `CanonicalResource`), so using it as
a canonical `targetProfile` is unusual; the build must confirm SUSHI compiles
`Canonical(ViewDefinition or SQLView)` and the IG Publisher does not emit
non-actionable errors for the logical-model target. `SQLView` is a `Library`
profile and validates normally.

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
  constrained `only Canonical(ViewDefinition or SQLView)`, `label` `1..1`
  obeying `sql-name`.
- `obeys sql-must-be-sql-expressions`.

Modified profile `SQLQuery`: `relatedArtifact.resource` is constrained
`only Canonical(ViewDefinition or SQLView)` and its `^short` updated to match.
The element cardinality is unchanged, and the existing examples reference
ViewDefinitions (a permitted target), so all existing instances stay valid - the
`targetProfile` only narrows the canonical to targets that were already the
intended usage.

New code system concept: `LibraryTypesCodes#sql-view` "SQL View Definition".

## UI Screens

Not applicable - this change adds FHIR conformance resources and IG
documentation pages, with no interactive user interface. The new
`SQLView` profile renders as a standard IG StructureDefinition page, and a menu
entry links to it; these follow the existing IG template.

## Risks / Trade-offs

- [Canonical target type is only validated when the canonical resolves] →
  Accept; the `targetProfile` enforces the rule for in-IG and dependency targets,
  and the `^short` documents it for unresolvable external canonicals, which the
  validator reports as resolution warnings rather than type errors.
- [`ViewDefinition` is a logical model used as a canonical `targetProfile`] →
  Verify during the build that SUSHI and the IG Publisher accept it; fall back to
  documentation-only if it produces non-actionable errors.
- [Duplication between SQLQuery and SQLView FSH] → Accept for two profiles;
  revisit with a shared parent only if a third variant appears.
- [Circular references between views are not detected by the spec] → By design;
  the issue resolution defers this to implementations (a SQL engine rejects
  cyclic view creation; a CTE-based implementation detects loops itself).

## Migration Plan

Additive change. Deploy by merging the FSH/docs updates and rebuilding the IG.
No existing instances become invalid. Rollback is removal of the new profile,
code, example, and docs plus reverting the SQLQuery `relatedArtifact.resource`
constraint and documentation edit.

## Open Questions

None outstanding - the issue's open questions were resolved in the maintainer's
final comment (no separate intermediate/final distinction beyond the profile
itself, implementation-dependent cycle handling and depth limits, and
implementation choice on materialisation).
