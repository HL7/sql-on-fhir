# Common Operation Behavior

This page defines behaviour that is **shared by all four SQL on FHIR data
operations** so that it is specified once and applied identically across them:

- [`$viewdefinition-run`](OperationDefinition-ViewDefinitionRun.html) - synchronous
- [`$sqlquery-run`](OperationDefinition-SQLQueryRun.html) - synchronous
- [`$viewdefinition-export`](OperationDefinition-ViewDefinitionExport.html) - asynchronous
- [`$sqlquery-export`](OperationDefinition-SQLQueryExport.html) - asynchronous

Each operation page references the relevant subsections below rather than
restating these rules. Where an operation needs to deviate, that operation's
page calls out the deviation explicitly.

## Output Formats (`_format`) {#output-formats}

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
- If `_format` is omitted and the format cannot be derived from the `Accept`
  header (see [Content Negotiation](#content-negotiation)), the server SHALL use
  `ndjson`.
- `header` applies only to `csv` and defaults to `true`.

Apart from `fhir`, this enumeration and the return-shape rules below are
identical for all four operations. The two delivery models differ only in
**how** the bytes reach the client - synchronously in the operation response
(the run operations) or asynchronously as downloadable files (the export
operations).

### FHIR Format (`_format=fhir`) {#fhir-format}

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

Two independent axes govern the response. They are specified separately so they
are not conflated:

**Axis 1 - which format (`_format` vs `Accept`).** When `_format` is supplied,
its value SHALL take precedence over the `Accept` header. When `_format` is not
supplied, the server MAY honour `Accept` to select an
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

This section applies to the two synchronous run operations, whose responses
carry the result payload. It does not apply to the export operations: their
responses follow the [asynchronous model](#asynchronous-delivery), and the
files they produce are downloaded as ordinary HTTP responses whose transfer
framing is governed by HTTP itself, not by this specification.

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
   JSON array needs bracket/comma bookkeeping; parquet must finalise its footer
   last but can still flush row groups progressively. Incremental production is
   neither required nor implied by chunked transfer encoding, and chunked
   transfer encoding is not reserved for "streamable" formats.

## Asynchronous Delivery {#asynchronous-delivery}

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
