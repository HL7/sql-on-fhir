# Materialize (superseded draft)

> **This page is superseded.** The earlier `$materialize` draft on this page
> (`POST /ViewDefinition/$materialize` with `targetName`, `updatePolicy`, and an
> async bulk-status flow of `accepted`/`in-progress`/`completed`) no longer
> reflects the current design and is kept only to avoid a broken link.

Materialization is now modeled as the **[MaterializedView](StructureDefinition-MaterializedView.html)**
resource: a server-managed, persisted relation built from a `ViewDefinition` or
`SQLView`, identified by the pair (`view`, `destination`), with status-driven
asynchronous creation (`requested | building | ready | stale | failed`). See the
[MaterializedView resource page](StructureDefinition-MaterializedView.html) for
the model, lifecycle, freshness, dependencies, and search. The lifecycle is plain
FHIR REST (`POST` / `GET` / `PUT` / `DELETE` + search) — there are no custom
materialize operations.
