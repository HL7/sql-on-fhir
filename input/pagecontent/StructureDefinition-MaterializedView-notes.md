## Notes

### Activation

Creation follows the `Subscription` pattern. A client `POST`s the MaterializedView
with `status = requested`; the server MAY build it immediately and return
`status = ready`, or accept it and build **asynchronously** — returning
`requested`/`building` and flipping to `ready` when the build completes. This
mirrors how a server MAY activate a Subscription *"immediately on creation … or
after some additional process."* The client learns it is ready by reading the
resource (`GET` or search on `status`) — there is no bulk-data `Content-Location`,
status URL, or manifest.

### Status

`status` is the server-managed lifecycle, observed by reading the resource:
`requested` → `building` → `ready`, with `stale` when the view or an upstream
dependency changes, `failed` on a build/refresh error (detail in `error`), and
back to `building` on refresh.

### Freshness

`staleness` sets the maximum time the relation may lag behind its view before
the server refreshes it (e.g. 1 hour; `PT0S` = live/continuous). The server is
free to choose the mechanism — scheduled rebuild, triggers, CDC, or incremental
matview refresh. If `staleness` is absent, the relation is refreshed only on
demand — by re-creating it (`PUT` the resource).

### Identity and destinations

A materialization is identified by its `destination` and `view` together — read it
like a schema-qualified table name, `<namespace>.<table>`: the `destination` is the
namespace and the `view` is what lives in it. So a given view has **at most one**
materialization per destination. The same view MAY still be materialized on
*several* destinations — e.g. an `unlogged-table` in Postgres and a Parquet file in
object storage. (`name` — the physical relation name — is likewise unique within a
destination.) A server MAY support only a single default destination, in which case
there is exactly one materialization per view.

**Why constrain it this way.** Allowing many materializations of one view *on the
same destination* would make dependency resolution ambiguous ("which one does a
dependent build on?") and turn query execution into a materialized-view
query-optimizer problem (picking the best variant per query). One-per-(view,
destination) keeps resolution a deterministic lookup and defers the optimizer
entirely. It is a deliberate, **relaxable** starting point: widening it later (a
selection policy / query rewrite) is an additive change, whereas starting permissive
and tightening later is the expensive direction. The genuinely useful part of
one-to-many — the *same* definition across *different* destinations — is kept; only
same-destination multiplicity is dropped.

### Dependencies

Dependencies exist at two layers. **Logical** dependencies are between *definitions*
— declared in the view's `relatedArtifact[depends-on]`, describing the DAG shape
independent of where anything runs. **Physical** dependencies (`dependsOn`) are
between *materializations* — references to upstreams that physically exist on a
destination. Materializing a DAG walks the logical graph and resolves each node to a
physical materialization. If `dependsOn` is omitted, the server resolves each logical
dependency to the materialization of that definition **on the same destination**
(deterministic, thanks to one-per-(view, destination)) and builds the DAG in
topological order; provide explicit references to pin specific upstreams. Staleness
flows downstream.

### Key elements

* **view** — canonical of the ViewDefinition/SQLView (the recipe). At most one materialization per `(destination, view)`.
* **destination** — opaque, server-interpreted location (schema / database / bucket); no structure. Absent → server default.
* **name** — relation name within the destination (table/view/file); server-derived if absent; unique per `(destination, name)`.
* **type** — materialization kind/format, vendor-extensible (e.g. `postgres#unlogged-table`, `parquet`).
* **staleness** — freshness target; absent = on-demand only.
* **dependsOn** — physical references to upstream materializations (optional; default resolves per destination).
* **refreshedAt / rowCount / error** — server-managed observable metadata; `error` only when `status = failed`.

## Search Parameters

A server that exposes MaterializedView as a queryable endpoint SHOULD support the
following searches. These are **illustrative**: as MaterializedView is a logical
model, this guide does not (yet) define formal `SearchParameter` resources for it.

| Name | Type | Expression | Description |
|------|------|------------|-------------|
| `view` | uri | `MaterializedView.view` | Find materializations of a given ViewDefinition/SQLView. |
| `destination` | string | `MaterializedView.destination` | Find materializations on a destination. |
| `name` | string | `MaterializedView.name` | Find by relation name. |
| `status` | token | `MaterializedView.status` | Filter by lifecycle status (e.g. `ready`, `stale`, `failed`). |
| `identifier` | token | `MaterializedView.identifier` | Find by business identifier. |

## Examples

Create a materialization (the server builds it asynchronously — see Activation):

```http
POST [base]/MaterializedView
{ "resourceType": "MaterializedView",
  "view": "https://ex.org/ViewDefinition/Diagnoses",
  "destination": "analytics",
  "name": "diagnoses",
  "type": { "system": "postgres", "code": "unlogged-table" },
  "staleness": { "value": 1, "unit": "h", "code": "h", "system": "http://unitsofmeasure.org" } }

→ 201 Created   Location: [base]/MaterializedView/mv-1
  { "resourceType": "MaterializedView", "id": "mv-1",
    "view": "https://ex.org/ViewDefinition/Diagnoses", "destination": "analytics",
    "name": "diagnoses", "status": "building" }
```

Poll until ready, then query the relation via `$sqlquery-run`:

```http
GET [base]/MaterializedView/mv-1
→ 200  { ... "status": "ready", "rowCount": 15234, "refreshedAt": "2026-06-28T10:00:00Z" }
```

> Non-normative wire sketches: MaterializedView is a logical model, so these are
> illustrative rather than IG-validated example instances.

## Conformance

* A server **SHALL** keep at most one materialization per `(view, destination)` and per `(destination, name)`; a second on the same destination is an error (`409`).
* A server **MAY** support only a single default destination — then there is one materialization per view.
* A server **MAY** support `staleness` (including `PT0S` = live) and multiple destinations; it rejects `type`/`destination`/`staleness` values it does not support with `400`.
