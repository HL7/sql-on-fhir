// =====================================================================
// MaterializedView — logical model (infrastructure resource)
//
// A MaterializedView is a server-managed, persisted relation built from a
// single ViewDefinition or SQLView (a SQLQuery Library). It is
// modeled as a logical model (an "infrastructure/configuration resource"
// like Subscription) rather than a canonical resource: it has its own
// lifecycle, identity, and dependency graph, but is NOT itself reusable,
// versioned content.
//
// The whole lifecycle rides on the logical model via plain REST:
//   - POST   /MaterializedView           create (async; observe via status)
//   - GET    /MaterializedView/{id}       read / poll status
//   - PUT    /MaterializedView/{id}       update config / trigger rebuild
//   - GET    /MaterializedView?view=…    search (identity = view + destination)
//   - DELETE /MaterializedView/{id}       drop the materialization
// =====================================================================

// ---------------------------------------------------------------------
// Terminology
// ---------------------------------------------------------------------

CodeSystem: MaterializationStatusCodes
Title: "Materialization Status Code System"
Description: "Lifecycle status of a MaterializedView, observed by polling MaterializedView.status (Subscription-style async)."
* ^experimental = false
* ^caseSensitive = true
* #requested "Requested" "The materialization has been requested and is queued; the table does not yet exist."
* #building "Building" "The server is currently building (or rebuilding) the table from the view."
* #ready "Ready" "The table is built and current; query results reflect the view as of refreshedAt."
* #stale "Stale" "The table exists but is out of date relative to its view or upstream dependencies and is scheduled to be (or awaiting) rebuild."
* #failed "Failed" "The most recent build or refresh failed; see the error field for details."

ValueSet: MaterializationStatusCodes
Title: "Materialization Status Codes"
Description: "ValueSet of all codes from the Materialization Status Code System."
* ^experimental = false
* codes from system MaterializationStatusCodes

// ---------------------------------------------------------------------
// Logical model — MaterializedView (infrastructure/configuration resource)
//
// Modeled on DomainResource (NOT CanonicalResource): a MaterializedView
// is operational state, not reusable canonical content. Identity is the pair
// (view, destination): at most one materialization per (view, destination).
// ---------------------------------------------------------------------

Logical: MaterializedView
Title: "Materialized View"
Parent: DomainResource
Characteristics: #can-be-target
Description: """
A MaterializedView is a server-managed, persisted representation of the output of a single ViewDefinition or SQLView (a SQLQuery `Library`) — its data processed into an efficient form for future query or load, such as a SQL table or view, or a Parquet/CSV file.
"""
* ^url = "https://sql-on-fhir.org/ig/StructureDefinition/MaterializedView"
* ^status = #draft
* ^kind = #logical
* ^abstract = false
// FHIR resource-page metadata, rendered as header badges (cf. Subscription)
* ^extension[0].url = "http://hl7.org/fhir/StructureDefinition/structuredefinition-standards-status"
* ^extension[0].valueCode = #draft
* ^extension[1].url = "http://hl7.org/fhir/StructureDefinition/structuredefinition-fmm"
* ^extension[1].valueInteger = 1
* identifier 0..* Identifier "Business identifier(s) for this materialization" """
  External/business identifiers for the materialization, independent of the server-assigned `id`.
"""
* name 0..1 string "Name of the materialized relation within its destination (server-derived if absent)" """
  Name of the materialized output within its `destination` (e.g. a table/view/file name); server-derived
  from `view` if absent. **Unique within a destination**: `(destination, name)` SHALL be unique. When
  the destination is a SQL table or view, it must be a valid SQL identifier.
"""
* name obeys sql-name
* view 1..1 Canonical(ViewDefinition or SQLView) "View being materialized — a ViewDefinition or SQLView (the recipe)" """
  Canonical URL of the view the relation is materialized from (a ViewDefinition or SQLView/SQLQuery
  `Library`). A view MAY be materialized on **several destinations**, but **at most one** per
  destination: `(destination, view)` SHALL be unique. The pair (`view`, `destination`) is the
  materialization's logical identity, used to resolve dependencies.
"""
* status 0..1 code "requested | building | ready | stale | failed" """
  Server-managed lifecycle status. Creation and refresh are asynchronous; clients observe progress by
  reading this field (Subscription-style): `requested` -> `building` -> `ready`, `stale` when the
  view or an upstream dependency changes, and `failed` on a build/refresh error.
"""
* status from MaterializationStatusCodes (required)
* refreshedAt 0..1 instant "When the relation was last successfully (re)built (server-managed)"
* rowCount 0..1 integer "Number of rows as of refreshedAt, when known (server-managed)"
* error 0..1 string "Failure detail when status = failed (server-managed)"
* destination 0..1 string "Opaque destination identifier — where the materialization lives (server-interpreted)" """
  Opaque, server-interpreted identifier of where the materialization lives — e.g. a schema, a
  database/connection, or a bucket. The spec gives it no structure. It participates in both uniqueness
  keys, `(destination, view)` and `(destination, name)`. If absent, the server's **default
  destination** is used; a server MAY support only a single default destination, in which case there is
  at most one materialization per `view`.
"""
* dependsOn 0..* Reference(MaterializedView) "Physical upstream materializations this is built on (optional; default = the upstream on the same destination)" """
  Physical dependencies: references to the upstream materializations this one is built on. Logical
  dependencies live in the view's `relatedArtifact[depends-on]` (between definitions); `dependsOn` is
  their physical resolution (between materializations). If absent, the server resolves each logical
  dependency to the materialization of that definition **on the same destination** — deterministic,
  because at most one exists per (`view`, `destination`) — and materializes the DAG in topological
  order. Provide explicit references to pin specific upstreams.
"""
* type 0..1 Coding "Materialization type / format (vendor-extensible)" """
  The kind of materialization, as a vendor-extensible Coding. The codes shown here — e.g.
  `{system: postgres, code: unlogged-table}`, a database `materialized-view`, or a file format such as
  `parquet`/`csv` — are **examples only**; servers MAY define their own systems and codes.
"""
* staleness 0..1 Duration "Maximum tolerated staleness before the server refreshes" """
  Maximum time the relation may lag behind its view before the server refreshes it (e.g. 1 hour;
  `PT0S` = live/continuous). If absent, the relation is refreshed only on demand — by re-creating it
  (`PUT` the resource).
"""
* parameter 0..* BackboneElement "Additional materialization options as name/value pairs" """
  Open bag of additional, vendor-specific materialization options.
"""
  * ^type.extension[+].url = "http://hl7.org/fhir/StructureDefinition/structuredefinition-explicit-type-name"
  * ^type.extension[=].valueString = "MaterializedViewParameter"
  * name 1..1 string "Option name."
  * value[x] 0..1 string or boolean or integer or decimal or Quantity or code "Option value."
