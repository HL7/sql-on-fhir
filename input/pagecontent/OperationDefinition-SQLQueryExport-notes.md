#### HTTP Methods

- **POST**: Required for providing export parameters and SQLQuery Libraries

#### Asynchronous Pattern

This operation follows the [FHIR Asynchronous Interaction Request Pattern](https://build.fhir.org/ig/HL7/api-incubator-ig/branches/simplified-async-interaction/async-interaction.html); the asynchronous flow is specified once in [Common Operation Behavior - Asynchronous Delivery](operations-common.html#asynchronous-delivery):

1. Client sends request with `Prefer: respond-async` header and query source parameters
2. Server returns `202 Accepted` with `Content-Location` header pointing to status URL
3. Client polls the status URL for export progress
4. Server responds with `202 Accepted` while export is in progress (MAY include interim results)
5. Once the export has finished (successfully or not), the status poll returns `303 See Other` with a `Location` header carrying the result URL and an empty body
6. Client fetches the result URL; a successful export returns `200 OK` with the manifest `Parameters` resource (`exportId`, `status`, `output`, …), and a failed export returns the error status code with an `OperationOutcome`
7. Client downloads the exported files from the `output.location` URLs in the manifest

The result resource for this operation is the manifest `Parameters` resource described under [Output Parameters](#output-parameters). Clients MUST treat the status and result URLs as opaque values.

##### Async Flow Diagram

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server

    rect rgb(240, 248, 255)
    Note over C,S: Step 1: Kick-off
    C->>S: POST /Library/$sqlquery-export<br/>Prefer: respond-async<br/>Body: Parameters{query, _format, ...}
    S-->>C: 202 Accepted<br/>Content-Location: /status/abc123<br/>Body: Parameters{exportId, status: accepted}
    end

    rect rgb(245, 245, 245)
    Note over C,S: Step 2: Polling (repeat while in progress)
    C->>S: GET /status/abc123
    S-->>C: 202 Accepted<br/>Retry-After: 10, X-Progress: 45%<br/>Body: Parameters{status: in-progress}
    end

    rect rgb(240, 255, 240)
    Note over C,S: Step 3: Completion
    C->>S: GET /status/abc123
    S-->>C: 303 See Other<br/>Location: /result/abc123<br/>(empty body)
    end

    rect rgb(255, 255, 240)
    Note over C,S: Step 4: Result fetch
    C->>S: GET /result/abc123
    S-->>C: 200 OK<br/>Body: Parameters{status: completed, output: [{name, location}]}
    end

    rect rgb(255, 248, 240)
    Note over C,S: Step 5: Download
    C->>S: GET /export/abc123/bp-results.csv
    S-->>C: 200 OK<br/>Content-Type: text/csv<br/>Body: patient_id,systolic,...
    end
```

##### Cancellation Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server

    C->>S: DELETE /status/abc123
    S-->>C: 202 Accepted
    C->>S: GET /status/abc123 (subsequent poll)
    S-->>C: 404 Not Found
```

##### Error Handling Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant S as Server

    C->>S: GET /status/abc123
    S-->>C: 303 See Other<br/>Location: /result/abc123<br/>(empty body)
    C->>S: GET /result/abc123
    S-->>C: 500 Internal Server Error<br/>Body: OperationOutcome{severity: error, diagnostics: ...}
```

#### Data Sources

The operation can export data from:

1. **Server resources** - From the server's data store (default)
2. **External source** - Specified via `source` parameter

#### Filtering

`patient`, `group` and `_since` restrict the data the queries see. They carry the
same meaning here as on the other three data operations, and are specified once in
[Filtering](operations-common.html#filtering):

- `patient` - restrict to the patient compartments of the supplied patients ([details](operations-common.html#patient-filter))
- `group` - restrict to members of the supplied Groups ([details](operations-common.html#group-filter))
- `_since` - restrict to resources whose state changed after the supplied instant ([details](operations-common.html#since-filter))

On this operation and on
[`$sqlquery-run`](OperationDefinition-SQLQueryRun.html), the filter applies to the
FHIR resources feeding the queries' dependency views, before the SQL executes. The
SQL therefore sees tables already narrowed to the requested scope, rather than
being expected to express the filter itself.

#### Required Headers

##### Kick-off Request

- `Prefer: respond-async` (required) - Specifies that the response should be asynchronous
- `Accept` (recommended) - Specifies the format of the kick-off response

##### Status Request

- `Accept` (recommended) - Specifies the format of interim status responses and error responses on the status URL; the completing poll returns `303 See Other` with an empty body

##### Result Request

- `Accept` (recommended) - Specifies the representation of the result: the manifest `Parameters` resource on success, or the `OperationOutcome` on failure

##### Header Scope

Each request's headers apply to **that request's response**. Because
completion is delivered as `303 See Other` with an empty body, the `Accept`
header that governs the representation of the manifest is the one sent on the
result `GET`, not the one sent on the completing status poll. This allows a
client to negotiate a different representation for interim status responses
(e.g. minimal JSON) than for the final manifest if it chooses.

#### Parameters

##### Input Parameters

###### Query Source - `query` Parameter (1..\*, system+type scope)

Each repetition identifies a single SQLQuery Library to export. At least one `query` is required at system/type level.

| Part Name      | Type       | Min | Max | Description                                                                                               |
| -------------- | ---------- | --- | --- | --------------------------------------------------------------------------------------------------------- |
| name           | string     | 0   | 1   | Optional friendly name for the exported query output                                                      |
| queryCanonical | canonical  | 0¹  | 1   | Canonical URL of the SQLQuery or SQLView Library. [Details](#queryreference-clarification)                |
| queryReference | Reference  | 0¹  | 1   | Literal location of a SQLQuery or SQLView Library on the server. [Details](#queryreference-clarification) |
| queryResource  | Library    | 0¹  | 1   | Inline SQLQuery or SQLView Library resource. [Details](#queryreference-clarification)                     |
| parameters     | Parameters | 0   | 1   | Input parameters for this query. [Details](#parameter-passing)                                            |

{:.table-data}

¹ Exactly one of `queryCanonical`, `queryReference` or `queryResource` is required
per `query` repetition. See [Identifying each query](#queryreference-clarification).

###### Instance-level invocation {#instance-level}

At the instance level (`POST [base]/Library/[id]/$sqlquery-export`), the bound
Library identified by the request URL serves as the single query source and the
`query` parameter does not apply: the subject is already named by the path, so
supplying `query` as well would be ambiguous. Exporting several queries in one
operation therefore requires the system or type level.

Every other input parameter does apply at the instance level, in addition to
system and type: `clientTrackingId`, `_format`, `header`, `patient`, `group`,
`_since` and `source`, along with `tableSource`.

A parameterised query is bound through the top-level `parameters` parameter,
which is available **at the instance level only**:

| Name         | Type         | Min | Max | Scope        | Description                                                              |
| ------------ | ------------ | --- | --- | ------------ | ------------------------------------------------------------------------ |
| `parameters` | `Parameters` | 0   | 1   | instance     | Values bound by name to the parameters the bound Library declares in `Library.parameter.name` |

{:.table-data}

Binding follows the same rules as
[`$sqlquery-run`](OperationDefinition-SQLQueryRun.html#parameter-passing): each
supplied value is matched by name to a `Library.parameter` entry, using the
`value[x]` type that corresponds to the declared `Library.parameter.type`. A
name the bound Library does not declare, or a value whose type does not match
the declared type, is rejected with `400 Bad Request` and an `OperationOutcome`
naming the parameter.

The restriction to the instance level is deliberate rather than an oversight. At
system and type level a request may carry several `query` repetitions, each
declaring its own parameters, so a single top-level set would be ambiguous: it
would need rules for whether it applies to every query or only to those
supplying none, for how it combines with a per-query set, and for what happens
when two queries declare the same name with different
`Library.parameter.type` - a case in which one binding would be simultaneously
valid against one query and a type mismatch against another. At the instance
level there is exactly one query and no `query` parameter, so none of these
questions arises. Supplying a top-level `parameters` at system or type level is
therefore rejected with `400 Bad Request`; use `query.parameters` there instead.

For example, exporting a stored query for two patients as CSV, under a client
tracking identifier:

```http
POST /Library/patient-bp-query/$sqlquery-export HTTP/1.1
Content-Type: application/fhir+json
Prefer: respond-async

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "clientTrackingId", "valueString": "bp-report-2026-07" },
    { "name": "patient", "valueReference": { "reference": "Patient/123" } },
    { "name": "patient", "valueReference": { "reference": "Patient/456" } },
    { "name": "_format", "valueCode": "csv" }
  ]
}
```

The response is `202 Accepted` with a `Content-Location` polling URL, the export
scoped to those two patients and delivered as CSV, and `clientTrackingId` echoed
in the manifest. Supplying `query` here is out of scope and is rejected with
`400 Bad Request` and an `OperationOutcome`.

Where the bound Library declares parameters, their values are supplied in the
same request. Given a Library declaring `min_systolic` as an `integer` and
`observation_status` as a `code`:

```http
POST /Library/bp-threshold-query/$sqlquery-export HTTP/1.1
Content-Type: application/fhir+json
Prefer: respond-async

{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "parameters",
      "resource": {
        "resourceType": "Parameters",
        "parameter": [
          { "name": "min_systolic", "valueInteger": 140 },
          { "name": "observation_status", "valueCode": "final" }
        ]
      }
    },
    { "name": "patient", "valueReference": { "reference": "Patient/123" } },
    { "name": "_format", "valueCode": "ndjson" }
  ]
}
```

The query executes with `min_systolic` bound to `140` and
`observation_status` to `final`, over the resources in `Patient/123`'s
compartment, and the result is exported as NDJSON. The equivalent request at
type level would carry a `query` repetition whose `parameters` part holds the
same inner `Parameters` resource.

###### ViewDefinition table sources

A query's table sources are named by its `relatedArtifact` entries and are
normally resolved by the server. Where the server cannot resolve one - typically
because the view exists only on the client - the client supplies it inline with
`tableSource`.

| Name         | Type                      | Min | Max | Description                                                                                                    |
| ------------ | ------------------------- | --- | --- | -------------------------------------------------------------------------------------------------------------- |
| tableSource | ViewDefinition \| SQLView² | 0   | \*  | Inline table source, matched to a dependency by canonical URL. [Details](operations-common.html#table-sources) |

{:.table-data}


² Declared as `CanonicalResource` in the OperationDefinition; see
[Why the declared type is `CanonicalResource`](operations-common.html#declared-type).

The matching, precedence and error rules are specified once in
[ViewDefinition table sources](operations-common.html#table-sources) and apply
identically here and on
[`$sqlquery-run`](OperationDefinition-SQLQueryRun.html). That section governs; in
outline, the supplied entries form one pool matched by canonical URL against every
dependency of every query in the request, a supplied resource outranks one the
server could itself resolve, an entry that cannot be bound or matches nothing is
rejected with `400 Bad Request`, and a dependency neither supplied nor resolvable
is rejected with `404 Not Found`.

Supplied resources are table sources, not export subjects: they produce no
`output` entries in the manifest, which carries one entry per query and nothing
else.

Unlike the `query` parameter, `tableSource` applies at the instance level as
well as at system and type level, because a stored query can depend on a view the
server cannot resolve.

###### Export Control

| Name             | Type    | Min | Max | Description                                                                                   |
| ---------------- | ------- | --- | --- | --------------------------------------------------------------------------------------------- |
| clientTrackingId | string  | 0   | 1   | Client-provided tracking ID for the export operation                                          |
| \_format         | code    | 0   | 1   | Output format: `csv`, `ndjson`, `parquet`, `json`. [Details](#format-parameter-clarification) |
| header           | boolean | 0   | 1   | Include CSV headers (default true). Applies only when csv output is requested                 |

{:.table-data}

###### Filtering

| Name    | Type      | Min | Max | Description                                                                                   |
| ------- | --------- | --- | --- | --------------------------------------------------------------------------------------------- |
| patient | Reference | 0   | \*  | Filter by patient reference. [Details](operations-common.html#patient-filter)                 |
| group   | Reference | 0   | \*  | Filter by group membership. [Details](operations-common.html#group-filter)                    |
| \_since | instant   | 0   | 1   | Export only resources updated since this time. [Details](operations-common.html#since-filter) |

{:.table-data}

###### Data Source

| Name   | Type   | Min | Max | Description                                                                |
| ------ | ------ | --- | --- | -------------------------------------------------------------------------- |
| source | string | 0   | 1   | External data source (e.g., URI, bucket name). If absent, uses server data |

{:.table-data}

A server that does not support a parameter declares that through the mechanism
described in
[Declaring partial operation support](operations-capability.html#partial-operation-support),
and rejects a request supplying it as specified there.

###### Identifying each query {#queryreference-clarification}

Each `query` repetition names the SQLQuery or SQLView Library to export in exactly
one of three ways, each with its own part so that the intended meaning is carried
by the part's type rather than inferred from the shape of a string:

| Part                   | Type        | Names the query by                                                                                                                                                                                                                                                                 |
| ---------------------- | ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `query.queryCanonical` | `canonical` | Its canonical URL, optionally with a `\|version` suffix pinning a version (e.g. `http://example.org/Library/bp-summary\|2.1.0`). Absent a suffix, the server selects a version according to FHIR's [canonical resolution](https://hl7.org/fhir/R5/references.html#canonical) rules |
| `query.queryReference` | `Reference` | A literal location: a relative URL on this server (e.g. `Library/patient-bp-query`) or an absolute URL (e.g. `http://example.org/fhir/Library/patient-bp-query`). This is not a canonical URL                                                                                      |
| `query.queryResource`  | `Library`   | Carrying the Library itself in the request                                                                                                                                                                                                                                         |

{:.table-data}

Each `query` repetition SHALL supply exactly one of the three. Supplying none, or
more than one, in a single repetition is rejected with `400 Bad Request` and an
`OperationOutcome` naming the problem.

A `query.queryCanonical` or `query.queryReference` the server cannot resolve is
rejected with `404 Not Found` and an `OperationOutcome`. A resolved artefact that
does not conform to the SQLQuery or SQLView profile is rejected with
`422 Unprocessable Entity`.

How a server resolves a canonical URL or an absolute reference - from a local
artefact registry, by dereferencing the URL, or not at all - is an implementation
matter. A server that supports only some of these parts declares the subset it
supports as described in
[Declaring partial operation support](operations-capability.html#partial-operation-support).

###### Format Parameter Clarification

The supported formats (`json`, `ndjson`, `csv`, `parquet`) and the default are
defined in
[Common Operation Behavior](operations-common.html#output-formats) and apply to
this operation. The `fhir` format is available on the run operations only:

- It is RECOMMENDED to support `json`, `ndjson` and `csv` by default; servers MAY
  support `parquet`, and SHALL document supported formats in the
  CapabilityStatement.
- If `_format` is omitted, the server SHALL produce the export output in `ndjson`
  format, irrespective of `Accept`.
- When `_format` is supplied, its value SHALL take precedence over `Accept`
  (which here negotiates the format of the _status and result_ responses, not
  the exported files).

###### Filtering Parameter Clarification

`patient`, `group` and `_since` carry the same meaning on all four data
operations, and are specified once in
[Filtering](operations-common.html#filtering):
[`patient`](operations-common.html#patient-filter),
[`group`](operations-common.html#group-filter) and
[`_since`](operations-common.html#since-filter). On this operation the filter
applies to the resources feeding the queries' dependency views, before the SQL
executes.

#### Parameter Passing

Query parameters are passed as a nested `Parameters` resource within each
`query` repetition (per-query binding via the `parameters` part), following the
same pattern as [`$sqlquery-run`](OperationDefinition-SQLQueryRun.html) and the
[CQL `$evaluate` operation](https://hl7.org/fhir/uv/cql/OperationDefinition-cql-library-evaluate.html).
See [Parameter Types](StructureDefinition-SQLQuery.html#parameter-types) on the
SQLQuery profile for the binding rules and the mapping from
`Library.parameter.type` to the `value[x]` element to use.

#### Output Parameters

Output parameters form the **manifest** - the `Parameters` resource returned
with `200 OK` from the result URL after the completing poll's `303 See Other`
redirect. They are not present in the `202 Accepted` responses returned while
the export is still in progress.

##### Export Identifiers

| Name             | Type   | Min | Max | Description                                                 |
| ---------------- | ------ | --- | --- | ----------------------------------------------------------- |
| exportId         | string | 1   | 1   | Server-generated export ID                                  |
| clientTrackingId | string | 0   | 1   | Client-provided tracking ID (echoed from input if provided) |

{:.table-data}

##### Export Metadata

| Name            | Type    | Min | Max | Description                                                      |
| --------------- | ------- | --- | --- | ---------------------------------------------------------------- |
| \_format        | code    | 0   | 1   | The format of the exported files (echoed from input if provided) |
| exportStartTime | instant | 0   | 1   | When the export operation began                                  |
| exportEndTime   | instant | 0   | 1   | When the export operation completed                              |
| exportDuration  | integer | 0   | 1   | The actual duration of the export in seconds                     |

{:.table-data}

##### Export Results

| Name            | Type    | Min | Max | Description                                                                                                                                  |
| --------------- | ------- | --- | --- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| output          | complex | 0   | \*  | Output information for each exported SQL query result (one per `query`; resources supplied via `tableSource` do not produce output entries) |
| output.name     | string  | 1   | 1   | The name of the exported output. [Details](#output-name-clarification)                                                                       |
| output.location | uri     | 1   | \*  | URL(s) to download the exported file(s). [Details](#output-partitioning)                                                                     |

{:.table-data}

##### Status Polling Parameters (interim)

During status polling (`202 Accepted` responses), servers MAY include the following in the response body:

| Name                   | Type    | Min | Max | Description                        |
| ---------------------- | ------- | --- | --- | ---------------------------------- |
| exportId               | string  | 0   | 1   | Server-generated export ID         |
| estimatedTimeRemaining | integer | 0   | 1   | Estimated seconds until completion |

{:.table-data}

Servers MAY also include partial/interim results during polling. The format of interim responses is implementation-defined.

##### Output Name Clarification

The `output.name` parameter identifies the exported query result. The value is determined as follows:

1. If a `name` was provided in the `query` part, the server SHOULD use it
2. Otherwise, the server MAY use the SQLQuery Library's `name` element
3. If neither is available, the server SHALL generate a unique identifier for the output

When multiple queries are exported, each produces a separate `output` entry with a distinct `name`.

##### Output Partitioning

For large exports, servers MAY partition the output into multiple files. When partitioning occurs:

1. **Multiple Locations**: The `output.location` parameter can repeat within a single output entry
2. **File Naming**: Partitioned files SHOULD use a consistent naming convention (e.g., `filename.part1.parquet`, `filename.part2.parquet`)
3. **Complete Set**: All parts together represent the complete export for that query

**Example of partitioned output:**

```json
{
  "name": "output",
  "part": [
    {
      "name": "name",
      "valueString": "patient_bp_results"
    },
    {
      "name": "location",
      "valueUri": "https://example.com/export/123/patient_bp_results.part1.csv"
    },
    {
      "name": "location",
      "valueUri": "https://example.com/export/123/patient_bp_results.part2.csv"
    }
  ]
}
```

Clients MUST download all parts to obtain the complete dataset.

#### Error Handling

##### HTTP Status Codes

The $sqlquery-export operation uses standard HTTP status codes to indicate the outcome:

| Status Code               | Description          | When to Use                                                                                                                                                                                                                                                     |
| ------------------------- | -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 202 Accepted              | In Progress          | Export request accepted, still in progress during polling, or cancellation accepted                                                                                                                                                                             |
| 303 See Other             | Job Finished         | Export finished (successfully or not); `Location` header carries the result URL                                                                                                                                                                                 |
| 200 OK                    | Result Available     | Result URL returns the manifest `Parameters`; download URLs return the files                                                                                                                                                                                    |
| 400 Bad Request           | Client Error         | Invalid parameters, unsupported parameters, missing required headers; a `query` repetition naming no subject form or more than one; `query` supplied at instance level; a top-level `parameters` supplied at system or type level; a parameter name the bound Library does not declare, or a value whose type does not match the declared type; a `tableSource` with no `url`, sharing a `url` with another, or matching no dependency; a `patient` or `group` naming a resource the server cannot find (see [Status code for a value that cannot be resolved](operations-common.html#filter-resolution-errors)) |
| 404 Not Found             | Not Found            | SQLQuery Library not found, a dependency neither supplied nor resolvable, or a cancelled export status URL                                                                                                                                                      |
| 422 Unprocessable Entity  | Business Logic Error | Valid request but query is invalid or cannot be executed                                                                                                                                                                                                        |
| 429 Too Many Requests     | Excessive Polling    | Client is polling too frequently; back off exponentially, guided by `Retry-After`                                                                                                                                                                               |
| 500 Internal Server Error | Server Error         | Unexpected server error; on the result URL, the failure outcome of the export                                                                                                                                                                                   |

{:.table-data}

All error responses (4xx and 5xx) SHOULD include an `OperationOutcome` resource providing details about the error.

##### Common Error Scenarios

###### 1. Unsupported Parameters

When the server does not support certain parameters, it returns `400 Bad Request`:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "not-supported",
      "diagnostics": "The server does not support the 'source' parameter"
    }
  ]
}
```

###### 2. Invalid SQLQuery Library

When a provided SQLQuery Library is invalid:

```http
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "invalid",
      "diagnostics": "The SQLQuery Library contains invalid SQL: syntax error near 'SELCT'"
    }
  ]
}
```

###### 3. SQLQuery Library Not Found

When a referenced SQLQuery Library does not exist:

```http
HTTP/1.1 404 Not Found
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "not-found",
      "diagnostics": "SQLQuery Library with reference 'Library/non-existent' not found"
    }
  ]
}
```

###### 4. Parameter Type Mismatch

When a query parameter value type does not match the declared Library.parameter.type:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "invalid",
      "diagnostics": "Parameter 'from_date' expects type 'date' but received 'valueString'"
    }
  ]
}
```

###### 5. Patient or Group Not Found

When filtering by patient or group that doesn't exist. A filter value scopes the
data rather than naming what the operation is about, so the rejection is
`400 Bad Request`; see
[Status code for a value that cannot be resolved](operations-common.html#filter-resolution-errors).

```http
HTTP/1.1 400 Bad Request
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "not-found",
      "diagnostics": "Patient with reference 'Patient/12345' not found",
      "expression": ["patient"]
    }
  ]
}
```

#### Operation Flow

1. **Kick-off Request**: Client sends `POST Library/$sqlquery-export` with `Prefer: respond-async` header and one or more `query` parameters.
2. **Kick-off Response**: Server responds with:
   - `202 Accepted` status code
   - `Content-Location` header with the absolute URL for subsequent status requests (polling location)
   - Parameters resource with `status` parameter set to `accepted` and `location` parameter
   - If request is not valid or cannot be processed, server responds with `400 Bad Request` and `OperationOutcome` resource in the body.
3. **Status Polling**: Client polls the polling location to get status of the export:
   - **In Progress**: `202 Accepted` with optional Parameters resource for interim status
   - **Progress Updates**: Server MAY include `X-Progress` header to indicate completion percentage
   - **Retry-After**: Server SHOULD include `Retry-After` header to indicate when to retry
   - **Interim Results**: Server MAY include partial/interim results in response body (implementation-defined)
   - **Excessive Polling**: Server MAY respond with `429 Too Many Requests`; clients SHOULD apply exponential backoff
4. **Completion**: When the export has finished - whether it succeeded or
   failed - the status poll returns:
   - `303 See Other` status code
   - `Location` header with the absolute result URL
   - An empty body
   - The status endpoint reflects polling machinery only; it never communicates
     the job's outcome. Clients MUST treat the status and result URLs as opaque
     values.
5. **Result Retrieval**: Client fetches the result URL with `GET`:
   - **Success**: `200 OK` with the manifest `Parameters` resource in the body
     containing `status` = `completed`, the export metadata, and the `output`
     entries with their download `location`s
   - **Failure**: the relevant error status code (e.g.
     `500 Internal Server Error`) with an `OperationOutcome` body explaining
     the failure; repeated fetches return the same outcome within the validity
     window
6. **Cancellation** (Recommended):
   Servers SHOULD support export cancellation via DELETE request to the status URL:
   - Client sends `DELETE` request to the status polling URL
   - Server responds with `202 Accepted`
   - Subsequent status requests return `404 Not Found`
   - Server SHOULD clean up any partial results
7. **Result Lifetime**:
   The result URL (which returns the manifest) and the
   `output.location` download URLs SHALL remain valid for at least 24 hours after
   export completion:
   - Servers SHOULD support multiple retrievals of the result
   - Servers MAY include an `Expires` header to indicate when the URLs expire
   - Clients should retrieve results promptly but can retry within the validity window
8. **Access Control**:
   Servers SHALL protect status, result, and download URLs with appropriate access controls:
   - Same authorization context as the original request (servers SHOULD limit
     access to the client that initiated the export), OR
   - Non-guessable URLs (e.g., cryptographically random tokens)
   - Unauthorized access attempts return `401 Unauthorized` or `403 Forbidden`
9. **File Download**: Client downloads the output from URLs in the `output.location` parameters.

#### Examples

##### Complete Export Flow Example

This example demonstrates the full lifecycle of a SQL query export from initiation through completion.

**Step 1: Kick-off Request**

Client initiates export of a SQLQuery Library with parameters and patient filtering:

```http
POST /Library/$sqlquery-export HTTP/1.1
Host: example.com
Content-Type: application/fhir+json
Prefer: respond-async
Accept: application/fhir+json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...

{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "clientTrackingId",
      "valueString": "bp-report-2026-03"
    },
    {
      "name": "query",
      "part": [
        {
          "name": "name",
          "valueString": "patient-bp-results"
        },
        {
          "name": "queryReference",
          "valueReference": {
            "reference": "Library/patient-bp-query"
          }
        },
        {
          "name": "parameters",
          "resource": {
            "resourceType": "Parameters",
            "parameter": [
              {
                "name": "from_date",
                "valueDate": "2024-01-01"
              }
            ]
          }
        }
      ]
    },
    {
      "name": "patient",
      "valueReference": {
        "reference": "Patient/123"
      }
    },
    {
      "name": "_since",
      "valueInstant": "2026-01-01T00:00:00Z"
    },
    {
      "name": "_format",
      "valueCode": "csv"
    }
  ]
}
```

**Step 2: Kick-off Response**

Server accepts the request and provides polling location:

```http
HTTP/1.1 202 Accepted
Content-Location: https://example.com/fhir/export/550e8400-e29b-41d4-a716-446655440000/status
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "exportId",
      "valueString": "550e8400-e29b-41d4-a716-446655440000"
    },
    {
      "name": "clientTrackingId",
      "valueString": "bp-report-2026-03"
    },
    {
      "name": "status",
      "valueCode": "accepted"
    },
    {
      "name": "location",
      "valueUri": "https://example.com/fhir/export/550e8400-e29b-41d4-a716-446655440000/status"
    }
  ]
}
```

**Step 3: First Status Poll (Starting)**

Client polls immediately:

```http
GET /fhir/export/550e8400-e29b-41d4-a716-446655440000/status HTTP/1.1
Host: example.com
Accept: application/fhir+json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

Response shows export is starting:

```http
HTTP/1.1 202 Accepted
Content-Type: application/fhir+json
Retry-After: 5
X-Progress: 0%

{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "exportId",
      "valueString": "550e8400-e29b-41d4-a716-446655440000"
    },
    {
      "name": "clientTrackingId",
      "valueString": "bp-report-2026-03"
    },
    {
      "name": "status",
      "valueCode": "in-progress"
    },
    {
      "name": "location",
      "valueUri": "https://example.com/fhir/export/550e8400-e29b-41d4-a716-446655440000/status"
    },
    {
      "name": "exportStartTime",
      "valueInstant": "2026-03-03T14:30:00Z"
    }
  ]
}
```

**Step 4: Second Status Poll (In Progress)**

After 5 seconds, client polls again:

```http
GET /fhir/export/550e8400-e29b-41d4-a716-446655440000/status HTTP/1.1
Host: example.com
Accept: application/fhir+json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

Response shows progress:

```http
HTTP/1.1 202 Accepted
Content-Type: application/fhir+json
Retry-After: 10
X-Progress: 65%

{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "exportId",
      "valueString": "550e8400-e29b-41d4-a716-446655440000"
    },
    {
      "name": "clientTrackingId",
      "valueString": "bp-report-2026-03"
    },
    {
      "name": "status",
      "valueCode": "in-progress"
    },
    {
      "name": "location",
      "valueUri": "https://example.com/fhir/export/550e8400-e29b-41d4-a716-446655440000/status"
    },
    {
      "name": "exportStartTime",
      "valueInstant": "2026-03-03T14:30:00Z"
    },
    {
      "name": "estimatedTimeRemaining",
      "valueInteger": 25
    }
  ]
}
```

**Step 5: Final Status Poll (Completed)**

After another 10 seconds:

```http
GET /fhir/export/550e8400-e29b-41d4-a716-446655440000/status HTTP/1.1
Host: example.com
Accept: application/fhir+json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

The export has finished, so the status poll returns `303 See Other` with the result URL in the `Location` header and no body:

```http
HTTP/1.1 303 See Other
Location: https://example.com/fhir/export/550e8400-e29b-41d4-a716-446655440000/result
```

**Step 6: Fetch the Result**

Client fetches the result URL; the manifest `Parameters` resource is returned:

```http
GET /fhir/export/550e8400-e29b-41d4-a716-446655440000/result HTTP/1.1
Host: example.com
Accept: application/fhir+json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

```http
HTTP/1.1 200 OK
Content-Type: application/fhir+json
Expires: Wed, 04 Mar 2026 14:30:42 GMT

{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "exportId",
      "valueString": "550e8400-e29b-41d4-a716-446655440000"
    },
    {
      "name": "clientTrackingId",
      "valueString": "bp-report-2026-03"
    },
    {
      "name": "status",
      "valueCode": "completed"
    },
    {
      "name": "_format",
      "valueCode": "csv"
    },
    {
      "name": "exportStartTime",
      "valueInstant": "2026-03-03T14:30:00Z"
    },
    {
      "name": "exportEndTime",
      "valueInstant": "2026-03-03T14:31:15Z"
    },
    {
      "name": "exportDuration",
      "valueInteger": 75
    },
    {
      "name": "output",
      "part": [
        {
          "name": "name",
          "valueString": "patient-bp-results"
        },
        {
          "name": "location",
          "valueUri": "https://example.com/fhir/export/550e8400-e29b-41d4-a716-446655440000/patient-bp-results.csv"
        }
      ]
    }
  ]
}
```

**Step 7: Download Files**

Client downloads each file:

```http
GET /fhir/export/550e8400-e29b-41d4-a716-446655440000/patient-bp-results.csv HTTP/1.1
Host: example.com
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

```http
HTTP/1.1 200 OK
Content-Type: text/csv
Content-Disposition: attachment; filename="patient-bp-results.csv"

patient_id,systolic,effective_date
Patient/123,120,2024-01-15
Patient/123,118,2024-02-20
Patient/456,135,2024-01-20
```

##### Type-Level with Inline SQLQuery Library

Pass the SQLQuery Library inline for ad-hoc queries:

```http
POST /Library/$sqlquery-export HTTP/1.1
Host: example.com
Content-Type: application/fhir+json
Prefer: respond-async

{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "_format",
      "valueCode": "ndjson"
    },
    {
      "name": "query",
      "part": [
        {
          "name": "name",
          "valueString": "active-patients"
        },
        {
          "name": "queryResource",
          "resource": {
            "resourceType": "Library",
            "meta": { "profile": ["http://hl7.org/fhir/uv/sql-on-fhir/StructureDefinition/SQLQuery"] },
            "type": { "coding": [{ "system": "http://hl7.org/fhir/uv/sql-on-fhir/CodeSystem/LibraryTypesCodes", "code": "sql-query" }] },
            "status": "active",
            "relatedArtifact": [
              { "type": "depends-on", "resource": "https://example.org/ViewDefinition/patient_view", "label": "p" }
            ],
            "content": [{
              "contentType": "application/sql",
              "data": "U0VMRUNUIHAuaWQsIHAubmFtZSBGUk9NIHAgV0hFUkUgcC5hY3RpdmUgPSB0cnVl",
              "extension": [{
                "url": "http://hl7.org/fhir/uv/sql-on-fhir/StructureDefinition/sql-text",
                "valueString": "SELECT p.id, p.name FROM p WHERE p.active = true"
              }]
            }]
          }
        }
      ]
    },
    {
      "name": "_since",
      "valueInstant": "2026-01-01T00:00:00Z"
    }
  ]
}
```

##### Multi-Query Export with ViewDefinition Table Sources

Export multiple queries in one operation, providing a ViewDefinition table source
inline. One pool of `tableSource` entries serves every query in the request: the
pool is matched against the transitive dependency graph of both queries, so an
entry matching either one's dependencies is bound, and an entry matching neither
is rejected with `400 Bad Request`.

The first query is named by canonical URL with a pinned version, the second by its
literal location on the server.

```http
POST /Library/$sqlquery-export HTTP/1.1
Host: example.com
Content-Type: application/fhir+json
Prefer: respond-async

{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "query",
      "part": [
        {
          "name": "name",
          "valueString": "bp-summary"
        },
        {
          "name": "queryCanonical",
          "valueCanonical": "http://example.org/Library/bp-summary|2.1.0"
        }
      ]
    },
    {
      "name": "query",
      "part": [
        {
          "name": "name",
          "valueString": "lab-summary"
        },
        {
          "name": "queryReference",
          "valueReference": {
            "reference": "Library/lab-summary-query"
          }
        },
        {
          "name": "parameters",
          "resource": {
            "resourceType": "Parameters",
            "parameter": [
              {
                "name": "loinc_code",
                "valueString": "2093-3"
              }
            ]
          }
        }
      ]
    },
    {
      "name": "tableSource",
      "resource": {
        "resourceType": "ViewDefinition",
        "url": "https://example.org/ViewDefinition/local_cohort",
        "status": "active",
        "resource": "Patient",
        "select": [
          {
            "column": [
              { "name": "id", "path": "getResourceKey()", "type": "string" }
            ]
          }
        ]
      }
    },
    {
      "name": "_format",
      "valueCode": "csv"
    }
  ]
}
```

The completed manifest carries exactly two `output` entries, `bp-summary` and
`lab-summary`. The supplied `tableSource` produces none.
