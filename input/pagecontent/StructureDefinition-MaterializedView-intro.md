<table class="grid" style="margin-bottom:1rem"><tbody>
<tr><td><b>Maturity Level</b>: 1</td><td><b>Standards Status</b>: Draft</td></tr>
<tr><td><b>Security Category</b>: Patient</td><td><b>Compartments</b>: Patient, Group</td></tr>
</tbody></table>

## Scope and Usage

A MaterializedView is a "configuration" and "infrastructure" resource that allows to configure and manage the materialized view and its dependencies.

For performance reasons, it is often necessary to materialize a ViewDefinition or SQLView into a table, view, file, or other persisent representation, to not rebuild the view every time it is needed. 

Servers may keep the materialized view up to date by refreshing it periodically or streaming updates real-time or near real-time.

By creating a MaterializedView, you are declaring the intent to materialize the view and its dependencies. The server is responsible for building and refreshing the materialized view and its dependencies. Throught the search and read API you can introspect the state of the materialized views. 

The same view can be materialized in more than one **destination** — for example a table in a database for fast analytics, and a file in a bucket for batch reporting. Within one destination, though, a view has **at most one** materialization.

**Why:** with one materialization per destination, "the materialization of this view here" is always exactly one thing. So when another view depends on it, or a query needs it, there is nothing to choose between — the lookup is unambiguous.


When a view depends on other views, a server may either require their materializations to exist first — so you materialize the dependencies before the view that uses them — or create them for you automatically.

Server may support multiple destinations - like databases, buckets, etc.


```json
{
  "resourceType": "MaterializedView",
  "view": "http://example.com/fhir/ViewDefinition/Diagnoses",
  "destination": "analytics",
  "name": "diagnoses",
  "type": {"system": "postgres", "code": "unlogged-table"},
  "staleness": {"value": 1, "unit": "hours", "system": "http://unitsofmeasure.org"}
}
```

`destination` is an opaque, server-interpreted string (a schema, database, or
bucket); `name` is the relation name within it. Identity is the pair
(`view`, `destination`). Dependencies are omitted here — the server resolves the
view's upstream views to materializations on the same destination (or you can
pin them explicitly with `dependsOn`).

## Boundaries and Relationships

The specification works in two layers:

- **Definitions** — `ViewDefinition` and `SQLView` are the logical, portable *recipe*: what to project, independent of where it runs. They are canonical, shareable, versioned content.
- **Materializations** — a `MaterializedView` is the *physical instance* of a definition on one server's `destination`. It is operational state, not shareable content, and does not define how data is projected — that stays with the definition.

A materialization points at its definition through `view`. The relationship is
one-to-many: one definition can have several materializations — at most one per
destination (addressed by `destination` + `view`, like a `<namespace>.<table>`
name; see the [Notes](#notes)). A server MAY support only a single default
destination, giving one materialization per view.

Whether `$viewdefinition-run` / `$sqlquery-run` and the `…-export` operations use
a materialization to answer a request — or recompute from the underlying data — is
**up to the server**; the result is the same either way.

## References to this Resource

A MaterializedView MAY reference upstream MaterializedViews via `dependsOn`. No
other resource in this guide references it; downstream SQL consumes the
*relation* it produces — by its `name` — rather than by a FHIR reference.
