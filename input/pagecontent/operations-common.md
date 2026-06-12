# Common Operation Behavior

This page defines behaviour that is **shared by all four SQL on FHIR data
operations** so that it is specified once and applied identically across them:

- [`$viewdefinition-run`](OperationDefinition-ViewDefinitionRun.html) — synchronous
- [`$sqlquery-run`](OperationDefinition-SQLQueryRun.html) — synchronous
- [`$viewdefinition-export`](OperationDefinition-ViewDefinitionExport.html) — asynchronous
- [`$sqlquery-export`](OperationDefinition-SQLQueryExport.html) — asynchronous

Each operation page references the relevant subsections below rather than
restating these rules. Where an operation needs to deviate, that operation's
page calls out the deviation explicitly.

## Output Formats (`_format`) {#output-formats}

The four operations share a single enumeration of output formats. The supported
values, their native media types, and the shape they produce are:

| `_format`  | Native media type             | Shape                                                                 |
| ---------- | ----------------------------- | --------------------------------------------------------------------- |
| `csv`      | `text/csv`                    | Header row (unless `header=false`) followed by one row per result row |
| `json`     | `application/json`            | A single JSON array of row objects                                    |
| `ndjson`   | `application/x-ndjson`        | One JSON object per line, one line per result row                     |
| `parquet`  | `application/vnd.apache.parquet` | Apache Parquet file                                                |
| `fhir`     | `application/fhir+json`       | A FHIR `Parameters` resource with one repeating `row` per result row (see [FHIR Format](#fhir-format)) |

{:.table-data}

Conformance rules that apply to every operation:

- It is RECOMMENDED to support `json`, `ndjson` and `csv` by default. Servers
  MAY support `parquet` and `fhir`; any format a server supports SHALL be
  declared in its CapabilityStatement, and any format it does not support SHALL
  be rejected with `400 Bad Request` and an `OperationOutcome`.
- If `_format` is omitted and the format cannot be derived from the `Accept`
  header (see [Content Negotiation](#content-negotiation)), the server SHALL use
  `ndjson`.
- `header` applies only to `csv` and defaults to `true`.

This enumeration and the return-shape rules below are identical for all four
operations. The two delivery models differ only in **how** the bytes reach the
client — synchronously in the operation response (the run operations) or
asynchronously as downloadable files (the export operations).

### FHIR Format (`_format=fhir`) {#fhir-format}

`fhir` is an OPTIONAL format that returns result rows as typed FHIR values
rather than as text or binary. It is available, at the server's option, on all
four operations.

For the **synchronous** run operations, the result is a `Parameters` resource
with one repeating `row` parameter per result row; each row's columns are
`part`s carrying the appropriate `value[x]`. A query that yields no rows returns
a `Parameters` resource with no `parameter` elements. SQL `NULL` is represented
by omitting the corresponding `part`. The column-type-to-`value[x]` mapping is
defined in
[SQL to FHIR type mapping](OperationDefinition-SQLQueryRun.html#sql-to-fhir-type-mapping).

For the **asynchronous** export operations, each `output` entry is delivered as
a file of **newline-delimited `Parameters` resources** — one `Parameters`
resource per line, each structured exactly as a single synchronous `row`
parameter's `part` list (i.e. one line per result row). This keeps `fhir`
exports row-incremental and consistent with the other file formats, while
preserving FHIR typing. The file's media type is `application/fhir+ndjson`.

## Return Representation and the `Binary` Parameter {#return-representation}

The run operations declare their `return` as `Binary` (or, for `$sqlquery-run`,
`Resource` — `Binary` for the flat formats and `Parameters` for `_format=fhir`).
The `Binary` type denotes a **binary stream**, not a serialized FHIR `Binary`
resource envelope.

Accordingly — and exactly as for a FHIR `Binary` read over the RESTful API (see
[Serving Binary Resources](https://www.hl7.org/fhir/binary.html#rest)) — the
default response body is the **raw payload** in the format's native media type
(`text/csv`, `application/x-ndjson`, the parquet media type, …), with
`Content-Type` set to that media type. The server does **not**, by default, wrap
the payload in a `{"resourceType":"Binary", "contentType":"…", "data":"<base64>"}`
envelope.

A serialized `Binary` resource (with base64-encoded `data`) is returned **only**
when the client explicitly asks for a FHIR representation via the `Accept`
header, and only for formats where the server chooses to support it — see
[Content Negotiation](#content-negotiation). For `_format=fhir`, the result is
already a FHIR `Parameters` resource, so the raw-vs-envelope question does not
arise.

The worked examples on each operation page are normative for the default
(raw-payload) case.

## Content Negotiation {#content-negotiation}

Two independent axes govern the response. They are specified separately so they
are not conflated:

**Axis 1 — which format (`_format` vs `Accept`).** When `_format` is supplied,
its value SHALL take precedence over the `Accept` header. When `_format` is not
supplied, the server MAY honour `Accept` to select an
[output format](#output-formats); if neither selects a format, the server uses
`ndjson`.

**Axis 2 — representation (raw payload vs FHIR envelope).** Once the format is
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

These two axes are distinct: Axis 1 decides *what* is encoded, Axis 2 decides
*how* it is wrapped.

## Streaming and Transfer Encoding {#streaming}

This section applies to the two synchronous run operations, whose responses
carry the result payload. It does not apply to the export operations: their
responses follow the [asynchronous model](#asynchronous-delivery), and the
files they produce are downloaded as ordinary HTTP responses whose transfer
framing is governed by HTTP itself, not by this specification.

Two further concepts are independent of each other and of the format:

1. **Transfer framing** — `Transfer-Encoding: chunked` (RFC 9112 §7.1) is an
   HTTP/1.1 message-framing mechanism. It is independent of `Content-Type` and
   of `_format`: *any* payload — CSV, JSON, NDJSON, parquet,
   `application/octet-stream`, or a `Binary` envelope — MAY be sent chunked. The
   choice between `Content-Length` and chunked framing depends solely on whether
   the server knows the body size before emitting the first byte, never on the
   format. Servers MAY use chunked transfer encoding for the response of any
   format on either run operation.

2. **Incremental result production** — whether the server can emit output before
   the full result set is materialized. This is a server/engine capability that
   genuinely varies by format: NDJSON and CSV are trivially row-incremental; a
   JSON array needs bracket/comma bookkeeping; parquet must finalise its footer
   last but can still flush row groups progressively. Incremental production is
   neither required nor implied by chunked transfer encoding, and chunked
   transfer encoding is not reserved for "streamable" formats.

## Asynchronous Delivery {#asynchronous-delivery}

The two export operations conform to the
[FHIR Asynchronous Bulk Data Request Pattern](https://www.hl7.org/fhir/async-bulk.html).
In particular, on completion they follow that pattern's completion response
exactly:

- **Kick-off** → `202 Accepted` with a `Content-Location` header carrying the
  status (polling) URL.
- **Polling while processing** → `202 Accepted`, optionally with `Retry-After`
  and `X-Progress`, and an optional interim status body.
- **Completion** → `200 OK` whose body is the manifest `Parameters` resource
  (`exportId`, `status`, `_format`, the export-timing parameters, and the
  repeating `output` entries with their `location` download URLs). The manifest
  is returned **in the body of the status-poll response**; there is no
  `303 See Other` redirect and no separate result resource to follow.
- **Failure** → the status poll returns the relevant error status code (e.g.
  `500 Internal Server Error`) with an `OperationOutcome` body.

The deliberate deviation from that pattern is the manifest's representation:
it is a FHIR `Parameters` resource rather than the Bulk Data JSON manifest
object. The flow, status codes, and headers are otherwise as the pattern
specifies.

File downloads referenced by `output.location` are independent HTTP responses;
their transfer framing is governed by HTTP itself and is not constrained by
this specification.
