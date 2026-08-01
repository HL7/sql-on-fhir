# Common Operation Behavior

This page defines behavior that is **shared by all four SQL on FHIR data
operations** so that it is specified once and applied identically across them:

- [`$viewdefinition-run`](OperationDefinition-ViewDefinitionRun.html) - synchronous
- [`$sqlquery-run`](OperationDefinition-SQLQueryRun.html) - synchronous
- [`$viewdefinition-export`](OperationDefinition-ViewDefinitionExport.html) - asynchronous
- [`$sqlquery-export`](OperationDefinition-SQLQueryExport.html) - asynchronous

Each operation page references the relevant subsections below rather than
restating these rules. Where an operation needs to deviate, that operation's
page calls out the deviation explicitly.

Every section below opens with an **Applies to** line naming the operations it
governs: all four, the run operations only, or the export operations only. A
section without such a line is a defect in this page.

## Parameters that do not apply to every operation {#parameter-asymmetries}

**Applies to:** all four operations.

Apart from the parameters that name an operation's subject, which necessarily
differ, the four operations offer the same input parameters at the same
invocation levels. The exceptions are recorded here in full, so that none reads
as an oversight. Every input parameter absent from at least one of the four, or
offered in a different shape on different operations, appears in this table.

| Parameter          | Offered on                                        | Why not on the others, or why the shape differs                                                                                                                                                                                                            |
| ------------------ | ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `_limit`           | `$viewdefinition-run`, `$sqlquery-run`            | It caps the rows returned to the client in the operation response. An export delivers files rather than rows in a response, so there is nothing for it to cap                                                                                              |
| `resource`         | `$viewdefinition-run`                             | It carries inline FHIR resources to transform instead of using server data. Accepting it on the SQLQuery operations would need its own semantics for how supplied resources reach each dependency view, so it is deliberately deferred rather than omitted |
| `clientTrackingId` | `$viewdefinition-export`, `$sqlquery-export`      | It identifies an asynchronous job across kick-off, polling and result retrieval. A run operation completes within its own response, so there is no job to track                                                                                            |
| `tableSource`      | `$sqlquery-run`, `$sqlquery-export`               | It supplies the dependency views a query reads from. The view operations' subject is a ViewDefinition rather than a query over one, so they have no dependency graph to satisfy                                                                            |
| `parameters`       | `$sqlquery-run` (all levels), `$sqlquery-export` (per `query`, plus a top-level form at instance level) | Both SQLQuery operations bind query parameters, but not in the same shape. At system and type level `$sqlquery-export` may carry several queries, each with its own declared parameters, so binding is per `query`; a single top-level set would be ambiguous across them. At instance level there is exactly one query and no `query` parameter, so a top-level `parameters` is unambiguous and is the form offered |

{:.table-data}

Extending `resource` to `$sqlquery-run` is a new capability rather than an
alignment fix, and is left to a separate proposal.

### Why the declared type is `CanonicalResource` {#declared-type}

**Applies to:** all four operations.

The parameter tables on the operation pages give the type of an inline
ViewDefinition as `ViewDefinition`, because that is what a client sends. The
generated OperationDefinitions declare it as `CanonicalResource`, which is a
consequence of how this guide models ViewDefinition rather than a difference in
meaning.

ViewDefinition is defined here as a FHIR **logical model**, not as a resource in
the FHIR specification, so `ViewDefinition` is not a value `parameter.type`
accepts: that element is bound to the list of FHIR-defined types.
`CanonicalResource` is the narrowest of those that admits a ViewDefinition, and
the actual constraint is carried by `parameter.targetProfile`, which names this
guide's [ViewDefinition](StructureDefinition-ViewDefinition.html) profile. A
validator therefore enforces exactly what the prose says; only the type code
reads more loosely.

The same applies to `tableSource`, whose `targetProfile` names both
[ViewDefinition](StructureDefinition-ViewDefinition.html) and
[SQLView](StructureDefinition-SQLView.html). It does not apply to
`queryResource` or `query.queryResource`, which carry a `Library` and so declare
that type directly.

## Output Formats (`_format`) {#output-formats}

**Applies to:** all four operations, except where a rule below names a subset.

The four operations share a single enumeration of output formats, with one
exception: `fhir` applies to the run operations only. The supported values,
their native media types, and the shape they produce are:

| `_format` | Native media type                | Shape                                                                                                                       |
| --------- | -------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `csv`     | `text/csv`                       | Header row (unless `header=false`) followed by one row per result row                                                       |
| `json`    | `application/json`               | A single JSON array of row objects                                                                                          |
| `ndjson`  | `application/x-ndjson`           | One JSON object per line, one line per result row                                                                           |
| `parquet` | `application/vnd.apache.parquet` | Apache Parquet file                                                                                                         |
| `fhir`    | `application/fhir+json`          | A FHIR `Parameters` resource with one repeating `row` per result row; run operations only (see [FHIR Format](#fhir-format)) |

{:.table-data}

Conformance rules that apply to every operation:

- It is RECOMMENDED to support `json`, `ndjson` and `csv` by default. Servers
  MAY support `parquet`, and MAY support `fhir` on the run operations; any
  format a server supports SHALL be declared in its CapabilityStatement, and
  any format it does not support SHALL be rejected with `400 Bad Request` and
  an `OperationOutcome`.
- A supplied `_format` SHALL take precedence over the `Accept` header.
- `header` applies only to `csv` and defaults to `true`.

What happens when `_format` is omitted differs between the two delivery models,
because `Accept` describes the response the client is about to receive and only
the run operations return the result in that response:

- **Run operations** (`$viewdefinition-run`, `$sqlquery-run`): the server MAY
  derive the format from the `Accept` header (see
  [Content Negotiation](#content-negotiation)); if neither `_format` nor
  `Accept` selects one, the server SHALL use `ndjson`.
- **Export operations** (`$viewdefinition-export`, `$sqlquery-export`): the
  server SHALL use `ndjson`, irrespective of `Accept`. On these operations
  `Accept` governs only the representation of the kick-off, status and result
  responses; it never selects the format of the exported files, which are
  fetched later from the `output.location` URLs as independent HTTP responses.

Apart from `fhir`, this enumeration and the return-shape rules below are
identical for all four operations. The two delivery models differ only in
**how** the bytes reach the client - synchronously in the operation response
(the run operations) or asynchronously as downloadable files (the export
operations).

### FHIR Format (`_format=fhir`) {#fhir-format}

**Applies to:** the run operations only.

`fhir` is an OPTIONAL format that returns result rows as typed FHIR values
rather than as text or binary. It is available, at the server's option, on the
two synchronous run operations only; it is not available on the export
operations, whose outputs are flat files.

The result is a `Parameters` resource with one repeating `row` parameter per
result row; each row's columns are `part`s carrying the appropriate `value[x]`.
A query that yields no rows returns a `Parameters` resource with no `parameter`
elements. SQL `NULL` is represented by omitting the corresponding `part`. The
column-type-to-`value[x]` mapping is defined in
[SQL to FHIR type mapping](OperationDefinition-SQLQueryRun.html#sql-to-fhir-type-mapping).

## Return Representation and the `Binary` Parameter {#return-representation}

**Applies to:** the run operations only. The export operations return no result
payload in the operation response; see
[Asynchronous Delivery](#asynchronous-delivery).

The run operations declare their `return` parameter as `Binary`. The `Binary`
type denotes a **binary stream**, not a serialized FHIR `Binary` resource
envelope. When `_format=fhir` is requested, the response is a `Parameters`
resource rather than a binary stream (see [FHIR Format](#fhir-format)).

Accordingly - and exactly as for a FHIR `Binary` read over the RESTful API (see
[Serving Binary Resources](https://www.hl7.org/fhir/binary.html#rest)) - the
default response body is the **raw payload** in the format's native media type
(`text/csv`, `application/x-ndjson`, the parquet media type, …), with
`Content-Type` set to that media type. The server does **not**, by default, wrap
the payload in a `{"resourceType":"Binary", "contentType":"…", "data":"<base64>"}`
envelope.

A serialized `Binary` resource (with base64-encoded `data`) is returned **only**
when the client explicitly asks for a FHIR representation via the `Accept`
header, and only for formats where the server chooses to support it - see
[Content Negotiation](#content-negotiation). For `_format=fhir`, the result is
already a FHIR `Parameters` resource, so the raw-vs-envelope question does not
arise.

The worked examples on each operation page are normative for the default
(raw-payload) case.

## Content Negotiation {#content-negotiation}

**Applies to:** the run operations only. Both axes below concern the response
body that carries the result payload, which on the export operations is not the
operation response at all but a separately fetched file; see
[Output Formats](#output-formats) and
[Asynchronous Delivery](#asynchronous-delivery).

Two independent axes govern the response. They are specified separately so they
are not conflated:

**Axis 1 - which format (`_format` vs `Accept`).** When `_format` is supplied,
its value SHALL take precedence over the `Accept` header. When `_format` is not
supplied, the server MAY honor `Accept` to select an
[output format](#output-formats); if neither selects a format, the server uses
`ndjson`.

**Axis 2 - representation (raw payload vs FHIR envelope).** Once the format is
chosen, the `Accept` header further selects how the payload is represented:

- `Accept: application/octet-stream`, the format's native media type, or no
  `Accept` header (the default) → the **raw payload** in the chosen format, with
  `Content-Type` set to the format's native media type. Chunked framing is
  permitted (see [Streaming](#streaming)).
- `Accept: application/fhir+json` or `application/fhir+xml` → a serialized
  `Binary` resource whose `contentType` is the format's native media type and
  whose `data` is the base64-encoded payload.

Axis 2 applies only to the flat formats (`csv`, `json`, `ndjson`, `parquet`).
When the chosen format is `fhir`, the response is always the `Parameters`
resource itself, serialized according to the FHIR media type in the `Accept`
header (`application/fhir+json` by default); neither the raw-payload nor the
`Binary`-envelope representation applies.

Because base64 inflates the payload by roughly a third and defeats streaming,
servers MAY decline the envelope representation for the large/streaming formats
(`parquet`, `ndjson`): a server that does not support the envelope form for a
given format SHALL respond `406 Not Acceptable` with an `OperationOutcome`
rather than silently returning raw bytes under a FHIR media type. Support for
the envelope representation per format SHOULD be documented in the
CapabilityStatement.

These two axes are distinct: Axis 1 decides _what_ is encoded, Axis 2 decides
_how_ it is wrapped.

## Streaming and Transfer Encoding {#streaming}

**Applies to:** the run operations only, whose responses carry the result
payload. The export operations follow the
[asynchronous model](#asynchronous-delivery), and the files they produce are
downloaded as ordinary HTTP responses whose transfer framing is governed by HTTP
itself, not by this specification.

Two further concepts are independent of each other and of the format:

1. **Transfer framing** - `Transfer-Encoding: chunked` (RFC 9112 §7.1) is an
   HTTP/1.1 message-framing mechanism. It is independent of `Content-Type` and
   of `_format`: _any_ payload - CSV, JSON, NDJSON, parquet,
   `application/octet-stream`, or a `Binary` envelope - MAY be sent chunked. The
   choice between `Content-Length` and chunked framing depends solely on whether
   the server knows the body size before emitting the first byte, never on the
   format. Servers MAY use chunked transfer encoding for the response of any
   format on either run operation.

2. **Incremental result production** - whether the server can emit output before
   the full result set is materialized. This is a server/engine capability that
   genuinely varies by format: NDJSON and CSV are trivially row-incremental; a
   JSON array needs bracket/comma bookkeeping; parquet must finalize its footer
   last but can still flush row groups progressively. Incremental production is
   neither required nor implied by chunked transfer encoding, and chunked
   transfer encoding is not reserved for "streamable" formats.

## Filtering {#filtering}

**Applies to:** all four operations.

All four accept the same three filtering parameters, with the same
cardinalities, the same invocation levels, and the same meaning:

| Parameter | Type        | Card  | Restricts the data to                                    |
| --------- | ----------- | ----- | -------------------------------------------------------- |
| `patient` | `Reference` | 0..\* | The patient compartments of the supplied patients        |
| `group`   | `Reference` | 0..\* | Members of the supplied Groups                           |
| `_since`  | `instant`   | 0..1  | Resources whose state changed after the supplied instant |

{:.table-data}

They constrain the FHIR resources that feed a view before projection, and hence
what appears in the result. On the two SQLQuery operations that means the filter
applies to the resources feeding the query's dependency views, before the SQL
executes: the SQL sees tables already narrowed to the requested scope, rather than
being expected to express the filter itself.

`_limit` is deliberately not one of these. It caps the rows returned to the
client rather than constraining the data feeding a view, which is also why it is
offered on the run operations only (see
[Parameters that do not apply to every operation](#parameter-asymmetries)).

### `patient` {#patient-filter}

**Applies to:** all four operations.

When provided, the server SHALL NOT return resources in the patient compartments
belonging to patients outside of this list.

If a client supplies a `patient` naming a resource the server cannot find, the
server SHALL respond `400 Bad Request` with an `OperationOutcome` whose
`expression` names the `patient` parameter (see
[Status code for a value that cannot be resolved](#filter-resolution-errors)).

### `group` {#group-filter}

**Applies to:** all four operations.

When provided, the server SHALL NOT return resources that are not a member of the
supplied `Group`.

If a client supplies a `group` naming a resource the server cannot find, the
server SHALL respond `400 Bad Request` with an `OperationOutcome` whose
`expression` names the `group` parameter (see
[Status code for a value that cannot be resolved](#filter-resolution-errors)).

### `_since` {#since-filter}

**Applies to:** all four operations.

Resources will be included in the response if their state has changed after the
supplied time (e.g., if `Resource.meta.lastUpdated` is later than the supplied
`_since` time).

For a Group-scoped request, the server MAY return additional resources modified
prior to the supplied time if the resources belong to the patient compartment of a
patient added to the Group after the supplied time; this behavior SHOULD be
clearly documented by the server.

For patient- and Group-scoped requests, the server MAY return resources that are
referenced by the resources being returned, regardless of when the referenced
resources were last updated.

For resources where the server does not maintain a last updated time, the server
MAY include these resources in a response irrespective of the `_since` value
supplied by a client.

### Status code for a value that cannot be resolved {#filter-resolution-errors}

**Applies to:** all four operations.

A filter value that names a resource the server cannot find is rejected with
`400 Bad Request`, not `404 Not Found`. The distinction rests on a single
principle, which applies to every unresolvable artefact named in a request to
any of the four operations:

- An artefact the operation is **about**, or **requires in order to run**,
  yields `404 Not Found` when it cannot be resolved. That covers the subject
  named by `viewCanonical`, `viewReference`, `queryCanonical` or
  `queryReference`, the instance named by the request path, and a query
  dependency neither supplied as a `tableSource` nor resolvable by the server.
- A value that merely **scopes** the data yields `400 Bad Request`. That covers
  `patient` and `group`.

The operation in the first case cannot proceed because the thing it would act on
is missing; in the second it was routed and understood, and a parameter value is
at fault. HTTP ties `404` to the request target, which at system and type level
is the operation endpoint rather than the patient, so reporting a missing
`patient` as `404` would misdescribe what was not found.

The response SHALL carry an `OperationOutcome` whose `expression` names the
parameter at fault. `issue.code` remains `not-found`, since that describes the
underlying condition accurately even where the HTTP status does not.

Where a request supplies both an unresolvable filter value and an unresolvable
subject, the subject failure is the more fundamental, so the response is
`404 Not Found` and the `OperationOutcome` reports both issues.

## Row limit (`_limit`) {#row-limit}

**Applies to:** the run operations only. The export operations do not offer
`_limit`; see
[Parameters that do not apply to every operation](#parameter-asymmetries).

When supplied, `_limit` is the maximum number of rows the server returns to the
client.

- Servers MAY enforce a maximum value, silently capping a client-supplied
  `_limit` at that maximum. A server that does so SHOULD document the cap.
- The limit is applied **after** the query has been evaluated, so it truncates
  the result set rather than changing what the query computes. A `_limit` never
  alters an aggregate, an ordering or a join.
- Returning fewer rows than the requested `_limit` is not an error: it means the
  result set was smaller than the limit, or the server capped it.

Each run operation page shows a worked example.

## ViewDefinition table sources {#table-sources}

**Applies to:** the two SQLQuery operations,
[`$sqlquery-run`](OperationDefinition-SQLQueryRun.html) and
[`$sqlquery-export`](OperationDefinition-SQLQueryExport.html). Not the view
operations, whose subject is a ViewDefinition rather than a query over one.

A SQLQuery names the tables it selects from through its `relatedArtifact` entries:
each entry with `type = depends-on` carries the dependency's canonical URL in
`resource` and the SQL identifier the query selects from in `label`. A dependency
resolves to either a ViewDefinition, which projects FHIR resources into a table,
or a [SQLView](StructureDefinition-SQLView.html), which wraps a query over other
table sources and so carries dependencies of its own. The graph is therefore
transitive, and its leaves are always ViewDefinitions.

A server may be unable to resolve every dependency: a client may hold a view that
exists only locally. The repeating `tableSource` parameter carries such views
inline. It accepts a ViewDefinition or a SQLView, applies at the system, type and
instance levels, and is available on both SQLQuery operations with identical
meaning.

`tableSource` accepts inline resources only. There is deliberately no
`tableSourceCanonical` or `tableSourceReference` sibling, even though the
parameters naming an operation's subject come in exactly that trio. Dependencies
are matched to the pool _by_ canonical URL, and the parameter exists precisely
for dependencies the server cannot resolve, so naming one by canonical URL would
hand the server the same URL it has already failed to resolve. The absence is a
consequence of what the parameter is for, not an oversight.

### Matching supplied resources to dependencies {#table-source-matching}

**Applies to:** the two SQLQuery operations.

The `tableSource` entries in one request form a single **pool**, matched against
the dependency graph as follows:

1. Seed a worklist with the invoked query's `depends-on` entries. Where an
   operation invokes several queries, seed it with the entries of all of them.
2. Take a dependency from the worklist and resolve it, in this order:
   1. A pool member whose `url` equals the dependency's canonical URL and, where
      the dependency pins a version, whose `version` equals that version.
   2. Failing that, an artefact the server can resolve for that canonical URL.
   3. Failing that, the request fails with `404 Not Found` and an
      `OperationOutcome` naming the unresolved canonical URL.
3. If the resolved artefact is a SQLView, add its own `depends-on` entries to the
   worklist. If it is a ViewDefinition, it is a leaf.
4. Repeat from step 2 until the worklist is empty.
5. If any pool member was never selected at step 2.1, the request fails with
   `400 Bad Request` and an `OperationOutcome` identifying it.
6. Bind each resolved artefact to the SQL identifier in the `label` of the
   dependency that reached it.

Step 2.1 preceding step 2.2 is the precedence rule: a supplied `tableSource`
takes precedence over an artefact with the same canonical URL that the server
could itself resolve. Step 5 runs after the traversal rather than during it,
because a pool member may match a dependency reached only through a supplied
SQLView.

A dependency whose `relatedArtifact.resource` carries a version is matched only by
a pool member whose `version` agrees. A pool member that matches no dependency
anywhere in the graph is almost always a typo in its `url`; rejecting it reports
the mistake where it was made, rather than letting it resurface later as an SQL
error naming a table the client believes it supplied.

### Rejected requests {#table-source-errors}

**Applies to:** the two SQLQuery operations.

| Status            | Condition                                                                     |
| ----------------- | ----------------------------------------------------------------------------- |
| `400 Bad Request` | A `tableSource` entry with no `url`, which cannot be bound to any dependency |
| `400 Bad Request` | Two `tableSource` entries sharing a `url`, which makes the binding ambiguous |
| `400 Bad Request` | A `tableSource` entry matching no dependency in the transitive graph         |
| `404 Not Found`   | A dependency neither present in the pool nor resolvable by the server         |

{:.table-data}

Every such response carries an `OperationOutcome` identifying the offending
resource or the unresolved canonical URL.

### What remains implementation-defined {#table-source-undefined}

**Applies to:** the two SQLQuery operations.

Supplied resources are table sources, not export subjects: on
`$sqlquery-export` they produce no `output` entries in the manifest, which
carries one entry per query and nothing else.

Consistent with what the [SQLQuery](StructureDefinition-SQLQuery.html) and
[SQLView](StructureDefinition-SQLView.html) profiles already state, this
specification requires nothing of servers on the following points, and they
remain implementation decisions:

- Cycle detection. Authors SHOULD keep the dependency graph acyclic.
- Any limit on dependency depth.
- Whether intermediate results are materialized as tables or inlined into the
  enclosing query.

### Worked example {#table-source-example}

**Applies to:** the two SQLQuery operations.

An invoked SQLQuery declares two dependencies:

```json
{
  "relatedArtifact": [
    {
      "type": "depends-on",
      "resource": "https://example.org/SQLView/active_pts",
      "label": "ap"
    },
    {
      "type": "depends-on",
      "resource": "https://example.org/ViewDefinition/addresses",
      "label": "ad"
    }
  ]
}
```

The request supplies two pool members: a SQLView with
`url = https://example.org/SQLView/active_pts`, which itself declares a dependency
on `https://example.org/ViewDefinition/patients` with label `p`; and a
ViewDefinition with `url = https://example.org/ViewDefinition/patients`. The
traversal resolves:

| Step | Dependency                                | Resolved by   | Table |
| ---- | ----------------------------------------- | ------------- | ----- |
| 1    | `SQLView/active_pts`                      | pool member 1 | `ap`  |
| 2    | `ViewDefinition/addresses`                | the server    | `ad`  |
| 3    | `ViewDefinition/patients` (from member 1) | pool member 2 | `p`   |

{:.table-data}

Both pool members were selected, so no entry is unmatched; every dependency
resolved, so nothing is unresolvable. The SQL executes against tables `ap`, `ad`
and `p`.

## Asynchronous Delivery {#asynchronous-delivery}

**Applies to:** the export operations only.

The two export operations conform to the
[FHIR Asynchronous Interaction Request Pattern](https://build.fhir.org/ig/HL7/api-incubator-ig/branches/simplified-async-interaction/async-interaction.html):

- **Kick-off** → the client sends the request with a `Prefer: respond-async`
  header; the server responds `202 Accepted` with a `Content-Location` header
  carrying the status (polling) URL. An informative `Parameters` body MAY be
  included. Invalid requests (bad or unsupported parameters, authorisation
  failures, referenced resources not found) are rejected synchronously with the
  relevant `4xx`/`5xx` status code and an `OperationOutcome` body - rejection
  is never deferred to the status URL.
- **Polling while processing** → `GET` on the status URL returns
  `202 Accepted`, with a `Retry-After` header (recommended), an `X-Progress`
  header (optional), and an optional, informative, implementation-defined
  interim status body. A server MAY respond `429 Too Many Requests` to a client
  that polls excessively; clients SHOULD apply exponential backoff, guided by
  `Retry-After` where present.
- **Completion and failure** → once the job has finished - whether it succeeded
  or failed - the status poll returns `303 See Other` with a `Location` header
  carrying the result URL and an empty body. The status endpoint reflects
  polling machinery only; it never communicates the job's outcome.
- **Result retrieval** → the client fetches the result URL with `GET`. For a
  successful export, the result is the manifest `Parameters` resource
  (`exportId`, `status`, `_format`, the export-timing parameters, and the
  repeating `output` entries with their `location` download URLs), returned
  with `200 OK`. For a failed export, the result URL returns the relevant error
  status code (e.g. `500 Internal Server Error`) with an `OperationOutcome`
  body explaining the failure; repeated fetches return the same outcome within
  the validity window.

Clients MUST treat the status and result URLs as opaque values. Note that many
HTTP libraries follow a `303` response to a `GET` automatically, so a polling
client may transparently receive the result response; this is benign.

The result URL and all `output.location` download URLs SHALL remain valid for
at least 24 hours after job completion. Servers SHOULD support multiple
retrievals within that window and MAY include an `Expires` header indicating
when the URLs expire.

The same access control applies to status-URL and result-URL requests as to
the original kick-off request, and servers SHOULD limit access to the client
that initiated the job; non-guessable URLs (e.g. cryptographically random
tokens) remain documented as an alternative control. Unauthorised access
attempts return `401 Unauthorized` or `403 Forbidden`.

File downloads referenced by `output.location` are independent HTTP responses;
their transfer framing is governed by HTTP itself and is not constrained by
this specification.
