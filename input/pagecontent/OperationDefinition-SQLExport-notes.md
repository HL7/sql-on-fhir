#### HTTP Methods

- **POST**: required. The operation creates a job, so it cannot be expressed as a
  safe `GET`; a `GET` on the operation endpoint is rejected with
  `400 Bad Request`.

#### Asynchronous Pattern

This operation follows the [FHIR Asynchronous Interaction Request Pattern](https://build.fhir.org/ig/HL7/api-incubator-ig/branches/simplified-async-interaction/async-interaction.html); the asynchronous flow is specified once in [Common Operation Behavior - Asynchronous Delivery](operations-common.html#asynchronous-delivery):

1. Client sends request with `Prefer: respond-async` header and one or more `subject` parameters
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
    C->>S: POST /$sql-export<br/>Prefer: respond-async<br/>Body: Parameters{subject, subject, _format, ...}
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
    C->>S: GET /export/abc123/bp_summary.csv
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

#### One Job, One Snapshot {#one-snapshot}

One invocation is one job: one set of subjects, one set of filters, one supplied
`context`, one manifest. Four guarantees hold across it.

**One snapshot.** The server SHALL compute every subject in the job against a
single consistent view of the data. Two outputs of one job can therefore be
joined on a shared key without a skew window, whatever changes to the data occur
while the job runs. This is what makes one job different from two jobs submitted
together.

**No ordering.** Neither the order of the `output` entries in the manifest nor
the order in which subjects are computed is guaranteed, and servers MAY compute
subjects in parallel. The shared snapshot is the only consistency guarantee
offered. Clients correlate manifest entries with the subjects they requested by
[`output.name`](#output-name-clarification), never by position.

**One resolution per canonical URL.** A canonical URL appearing as a dependency
of more than one subject is resolved once for the job, and every subject
depending on it sees the same resolved artefact; see
[Supporting artefacts](operations-common.html#context). Whether that artefact is
then materialised once or several times is not constrained, consistent with what
this specification already leaves to implementations.

**One `output` per subject.** The manifest carries exactly one `output` entry per
`subject` repetition and none for any other supplied artefact. A `context` entry
is a supporting artefact rather than a subject, so it never produces one.

#### Data Sources

The operation can export data from:

1. **Server resources** - From the server's data store (default)
2. **External source** - Specified via `source` parameter

#### Filtering

`patient`, `group` and `_since` restrict the data every subject in the job sees.
They are stated once for the whole job - there is no way to scope one subject
differently from another - and carry the same meaning here as on
[`$sql-run`](OperationDefinition-SQLRun.html), specified once in
[Filtering](operations-common.html#filtering):

- `patient` - restrict to the patient compartments of the supplied patients ([details](operations-common.html#patient-filter))
- `group` - restrict to members of the supplied Groups ([details](operations-common.html#group-filter))
- `_since` - restrict to resources whose state changed after the supplied instant ([details](operations-common.html#since-filter))

The filter applies to the FHIR resources feeding a view before projection. Where
a subject is a SQLQuery or SQLView, that means it applies to the resources
feeding that subject's dependency views, before the SQL executes: the SQL sees
tables already narrowed to the requested scope, rather than being expected to
express the filter itself.

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

###### Subjects - `subject` Parameter (1..\*)

Each repetition names a single artefact to export - a ViewDefinition, a SQLQuery
Library or a SQLView Library - and produces exactly one `output` entry in the
manifest. One job may name any mixture of the three. At least one `subject` is
required; a request supplying none is rejected with `400 Bad Request`.

| Part Name        | Type                                   | Min | Max | Description                                                                      |
| ---------------- | -------------------------------------- | --- | --- | ---------------------------------------------------------------------------------- |
| name             | string                                 | 0   | 1   | Name for this subject's output entry. [Details](#output-name-clarification)      |
| subjectCanonical | canonical                              | 0¹  | 1   | Canonical URL of the subject. [Details](#subject-clarification)                  |
| subjectReference | Reference                              | 0¹  | 1   | Literal location of the subject on the server. [Details](#subject-clarification) |
| subjectResource  | ViewDefinition \| SQLQuery \| SQLView² | 0¹  | 1   | Inline subject resource. [Details](#subject-clarification)                       |
| parameters       | Parameters                             | 0   | 1   | Input parameter values for this subject. [Details](#parameter-passing)           |

{:.table-data}

¹ Exactly one of `subjectCanonical`, `subjectReference` or `subjectResource` is
required per `subject` repetition. See
[Naming each subject](#subject-clarification).

² Declared as `CanonicalResource` in the OperationDefinition; see
[Why the declared type is `CanonicalResource`](operations-common.html#declared-type).

`parameters` binds to the parameters the subject's Library declares, so it is
permitted only where that repetition's subject is a SQLQuery or SQLView.
Supplying it where the subject is a ViewDefinition is rejected with
`400 Bad Request`, because a ViewDefinition declares no parameters.

###### Supporting artefacts - `context` Parameter

A subject's dependencies are named by its `relatedArtifact` entries and are
normally resolved by the server. Where the server cannot resolve one - typically
because the artefact exists only on the client - the client supplies it inline
with `context`.

| Name    | Type                       | Min | Max | Description                                                                                                     |
| ------- | -------------------------- | --- | --- | ----------------------------------------------------------------------------------------------------------------- |
| context | ViewDefinition \| SQLView² | 0   | \*  | Inline supporting artefact, matched to a dependency by canonical URL. [Details](operations-common.html#context) |

{:.table-data}

`context` applies to the job as a whole rather than to one subject, so an
artefact several subjects depend on is supplied once and
[resolved once](#one-snapshot). The matching, precedence and error rules are
specified once in
[Supporting artefacts](operations-common.html#context) and apply identically here
and on [`$sql-run`](OperationDefinition-SQLRun.html). That section governs; in
outline, the supplied entries are matched by canonical URL against every
dependency of every subject in the request, a supplied entry outranks an artefact
the server could itself resolve, an entry that cannot be bound or matches nothing
is rejected with `400 Bad Request`, and a dependency neither supplied nor
resolvable is rejected with `404 Not Found`.

A `context` entry is a supporting artefact, not an export subject: it produces no
`output` entry in the manifest, which carries one entry per `subject` and nothing
else.

###### Export Control

| Name             | Type    | Min | Max | Description                                                                                   |
| ---------------- | ------- | --- | --- | --------------------------------------------------------------------------------------------- |
| clientTrackingId | string  | 0   | 1   | Client-provided tracking ID for the export job, echoed in the manifest                        |
| \_format         | code    | 0   | 1   | Output format: `csv`, `ndjson`, `parquet`, `json`. [Details](#format-parameter-clarification) |
| header           | boolean | 0   | 1   | Include CSV headers (default true). Applies only when csv output is requested                 |

{:.table-data}

###### Filtering

| Name    | Type      | Min | Max | Description                                                                                   |
| ------- | --------- | --- | --- | --------------------------------------------------------------------------------------------- |
| patient | Reference | 0   | \*  | Filter by patient reference. [Details](operations-common.html#patient-filter)                 |
| group   | Reference | 0   | \*  | Filter by group membership. [Details](operations-common.html#group-filter)                    |
| \_since | instant   | 0   | 1   | Include only resources whose state changed after this instant. [Details](operations-common.html#since-filter) |

{:.table-data}

###### Data Source

| Name   | Type   | Min | Max | Description                                                                |
| ------ | ------ | --- | --- | -------------------------------------------------------------------------- |
| source | string | 0   | 1   | External data source (e.g., URI, bucket name). If absent, uses server data |

{:.table-data}

`resource` and `_limit` are not offered on this operation, and `fhir` is not an
available output format; see
[Parameters that do not apply to every operation](operations-common.html#parameter-asymmetries).

A server that does not support a parameter declares that through the mechanism
described in
[Declaring partial operation support](operations-capability.html#partial-operation-support),
and rejects a request supplying it as specified there.

###### Naming each subject {#subject-clarification}

Each `subject` repetition names the artefact to export in exactly one of three
ways, each with its own part so that the intended meaning is carried by the
part's type rather than inferred from the shape of a string. All three admit a
[ViewDefinition](StructureDefinition-ViewDefinition.html), a
[SQLQuery](StructureDefinition-SQLQuery.html) Library or a
[SQLView](StructureDefinition-SQLView.html) Library, so the naming form is chosen
independently of the subject's kind:

| Part                       | Type                                   | Names the subject by                                                                                                                                                                                                                                                              |
| -------------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `subject.subjectCanonical` | `canonical`                            | Its canonical URL, optionally with a `\|version` suffix pinning a version (e.g. `http://example.org/Library/bp-summary\|2.1.0`). Absent a suffix, the server selects a version according to FHIR's [canonical resolution](https://hl7.org/fhir/R5/references.html#canonical) rules |
| `subject.subjectReference` | `Reference`                            | A literal location: a relative URL on this server (e.g. `Library/patient-bp-query`) or an absolute URL (e.g. `http://example.org/fhir/Library/patient-bp-query`). This is not a canonical URL                                                                                      |
| `subject.subjectResource`  | ViewDefinition \| SQLQuery \| SQLView² | Carrying the artefact itself in the request                                                                                                                                                                                                                                        |

{:.table-data}

² `subjectResource` is declared as `CanonicalResource` in the
OperationDefinition. ViewDefinition is a logical model in this guide rather than
a FHIR resource, so `ViewDefinition` is not a value `parameter.type` accepts;
`CanonicalResource` is the narrowest declared type admitting all three kinds, and
the real constraint is carried by `targetProfile`. See
[Why the declared type is `CanonicalResource`](operations-common.html#declared-type).

Each `subject` repetition SHALL supply exactly one of the three. Supplying none,
or more than one, in a single repetition is rejected with `400 Bad Request` and
an `OperationOutcome` naming the problem.

A `subject.subjectCanonical` or `subject.subjectReference` the server cannot
resolve is rejected with `404 Not Found` and an `OperationOutcome`. A resolved
artefact conforming to none of the three profiles is rejected with
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
this operation. The `fhir` format is available on the run operation only, because
an export produces flat files; requesting it here is rejected with
`400 Bad Request`.

- It is RECOMMENDED to support `json`, `ndjson` and `csv` by default; servers MAY
  support `parquet`, and SHALL document supported formats in the
  CapabilityStatement.
- If `_format` is omitted, the server SHALL produce the export output in `ndjson`
  format, irrespective of `Accept`.
- When `_format` is supplied, its value SHALL take precedence over `Accept`
  (which here negotiates the format of the _status and result_ responses, not
  the exported files).

###### Filtering Parameter Clarification

`patient`, `group` and `_since` carry the same meaning on both data operations,
and are specified once in
[Filtering](operations-common.html#filtering):
[`patient`](operations-common.html#patient-filter),
[`group`](operations-common.html#group-filter) and
[`_since`](operations-common.html#since-filter). On this operation they are
stated once and apply to every subject in the job.

#### Parameter Passing {#parameter-passing}

Parameter values are passed as a nested `Parameters` resource within each
`subject` repetition, following the same pattern as
[`$sql-run`](OperationDefinition-SQLRun.html#parameter-passing) and the
[CQL `$evaluate` operation](https://hl7.org/fhir/uv/cql/OperationDefinition-cql-library-evaluate.html).
Binding is per subject because one job may carry several subjects, each declaring
its own parameters, so a single top-level set would be ambiguous across them.

See [Parameter Types](StructureDefinition-SQLQuery.html#parameter-types) on the
SQLQuery profile for the binding rules and the mapping from
`Library.parameter.type` to the `value[x]` element to use. A parameter name the
subject does not declare, or a value whose type does not match the declared type,
is rejected with `400 Bad Request` and an `OperationOutcome` naming the
parameter.

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
| exportStartTime | instant | 0   | 1   | When the export job began                                        |
| exportEndTime   | instant | 0   | 1   | When the export job completed                                    |
| exportDuration  | integer | 0   | 1   | The actual duration of the export in seconds                     |

{:.table-data}

##### Export Results

| Name            | Type    | Min | Max | Description                                                                                                   |
| --------------- | ------- | --- | --- | ----------------------------------------------------------------------------------------------------------------- |
| output          | complex | 0   | \*  | Output information for each exported subject: exactly one entry per `subject`, and none for a `context` entry |
| output.name     | string  | 1   | 1   | The name of the exported output. [Details](#output-name-clarification)                                        |
| output.location | uri     | 1   | \*  | URL(s) to download the exported file(s). [Details](#output-partitioning)                                      |

{:.table-data}

##### Status Polling Parameters (interim)

During status polling (`202 Accepted` responses), servers MAY include the following in the response body:

| Name                   | Type    | Min | Max | Description                        |
| ---------------------- | ------- | --- | --- | ---------------------------------- |
| exportId               | string  | 0   | 1   | Server-generated export ID         |
| estimatedTimeRemaining | integer | 0   | 1   | Estimated seconds until completion |

{:.table-data}

Servers MAY also include partial/interim results during polling. The format of interim responses is implementation-defined.

##### Output Name Clarification {#output-name-clarification}

`output.name` identifies which subject an entry belongs to. Because the manifest
states no ordering, it is the only way a client correlates an entry with the
subject it requested. The value is determined in three steps:

1. If a `name` was supplied in that `subject` repetition, the server SHOULD use it
2. Otherwise, the server MAY use the subject's own `name` element
3. If neither is available, the server SHALL generate a unique identifier for the output

Output names SHALL be unique across the job. A request in which two `subject`
repetitions would produce the same `output.name` is rejected with
`400 Bad Request` and an `OperationOutcome` whose `expression` names `subject`,
because manifest entries a client cannot tell apart are of no use to it. Where
the client names its subjects explicitly the collision is visible in the request;
where it does not, the collision is between two subjects whose own `name`
elements agree, and supplying an explicit `name` on either resolves it.

##### Output Partitioning {#output-partitioning}

For large exports, servers MAY partition the output into multiple files. When partitioning occurs:

1. **Multiple Locations**: The `output.location` parameter can repeat within a single output entry
2. **File Naming**: Partitioned files SHOULD use a consistent naming convention (e.g., `filename.part1.parquet`, `filename.part2.parquet`)
3. **Complete Set**: All parts together represent the complete export for that subject

**Example of partitioned output:**

```json
{
  "name": "output",
  "part": [
    {
      "name": "name",
      "valueString": "bp_summary"
    },
    {
      "name": "location",
      "valueUri": "https://example.com/export/123/bp_summary.part1.csv"
    },
    {
      "name": "location",
      "valueUri": "https://example.com/export/123/bp_summary.part2.csv"
    }
  ]
}
```

Clients MUST download all parts to obtain the complete dataset.

#### Error Handling

##### Flow Status Codes

| Status Code   | Meaning                                                                              |
| ------------- | -------------------------------------------------------------------------------------- |
| 202 Accepted  | Kick-off accepted, export still in progress during polling, or cancellation accepted |
| 303 See Other | Export finished, successfully or not; `Location` header carries the result URL       |
| 200 OK        | Result URL returns the manifest `Parameters`; download URLs return the files         |

{:.table-data}

##### Rejected Requests

| Status                      | `issue.code`    | `expression`  | Condition                                                                                                                                                    |
| --------------------------- | --------------- | ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `400 Bad Request`           | `required`      | -             | `Prefer: respond-async` absent, or the operation invoked with `GET`                                                                                          |
| `400 Bad Request`           | `required`      | `subject`     | No `subject` supplied                                                                                                                                        |
| `400 Bad Request`           | `invalid`       | `subject`     | A repetition supplying none of the three naming forms, or more than one                                                                                      |
| `400 Bad Request`           | `invalid`       | `subject`     | Two repetitions that would produce the same `output.name`                                                                                                    |
| `400 Bad Request`           | `invalid`       | `parameters`  | Supplied where that repetition's subject is a ViewDefinition                                                                                                 |
| `400 Bad Request`           | `invalid`       | `parameters`  | A parameter name the subject does not declare, or a value whose type does not match the declared type                                                        |
| `400 Bad Request`           | `invalid`       | `context`     | An entry with no `url`, two entries sharing a `url`, or an entry matching no dependency of any subject                                                       |
| `400 Bad Request`           | `not-found`     | `patient`     | A `patient` naming a resource the server cannot find (see [Status code for a value that cannot be resolved](operations-common.html#filter-resolution-errors)) |
| `400 Bad Request`           | `not-found`     | `group`       | A `group` naming a resource the server cannot find                                                                                                           |
| `400 Bad Request`           | `not-supported` | the parameter | A parameter the server does not support (see [Declaring partial operation support](operations-capability.html#partial-operation-support))                    |
| `400 Bad Request`           | `not-supported` | `_format`     | A format the server does not support                                                                                                                         |
| `400 Bad Request`           | `invalid`       | `_format`     | `fhir` requested, which this operation does not offer                                                                                                        |
| `400 Bad Request`           | `invalid`       | `_limit`      | Supplied, which this operation does not offer                                                                                                                |
| `404 Not Found`             | `not-found`     | `subject`     | An unresolvable `subjectCanonical` or `subjectReference`                                                                                                     |
| `404 Not Found`             | `not-found`     | -             | A dependency neither supplied as a `context` entry nor resolvable by the server                                                                              |
| `404 Not Found`             | `not-found`     | -             | A status URL for a cancelled job                                                                                                                             |
| `422 Unprocessable Entity`  | `invalid`       | `subject`     | A resolved artefact conforming to none of ViewDefinition, SQLQuery or SQLView                                                                                |
| `422 Unprocessable Entity`  | `invalid`       | `subject`     | A conformant subject that cannot be processed, such as an SQL syntax error or an invalid FHIRPath expression                                                 |
| `429 Too Many Requests`     | `throttled`     | -             | Excessive polling; back off exponentially, guided by `Retry-After`                                                                                           |
| `500 Internal Server Error` | `exception`     | -             | Unexpected server error; on the result URL, the failure outcome of the job                                                                                   |

{:.table-data}

All error responses (4xx and 5xx) SHOULD include an `OperationOutcome` resource providing details about the error.

Where a request carries both an unresolvable subject and an unresolvable filter
value, the subject failure is the more fundamental: the response is
`404 Not Found` and the `OperationOutcome` reports both issues.

##### Timing of Rejection

Invalid requests are rejected **synchronously at kick-off** - bad or unsupported
parameters, authorisation failures, unresolvable subjects, unresolvable
dependencies and unmatched `context` entries alike. Rejection is never deferred
to the status URL. The status endpoint reflects polling machinery only; it never
communicates the job's outcome, which is why a finished job returns
`303 See Other` whether it succeeded or failed.

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

###### 2. Colliding Output Names

Two `subject` repetitions naming the same output leave the client unable to tell
the manifest entries apart:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "invalid",
      "diagnostics": "Two subject repetitions would produce the output name 'demographics'",
      "expression": ["subject"]
    }
  ]
}
```

###### 3. Subject Not Found

When a named subject does not exist:

```http
HTTP/1.1 404 Not Found
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "not-found",
      "diagnostics": "Subject with reference 'Library/non-existent' not found",
      "expression": ["subject.subjectReference"]
    }
  ]
}
```

###### 4. Parameter Type Mismatch

When a supplied parameter value type does not match the declared `Library.parameter.type`:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "invalid",
      "diagnostics": "Parameter 'from_date' expects type 'date' but received 'valueString'",
      "expression": ["subject.parameters"]
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

1. **Kick-off Request**: Client sends `POST [base]/$sql-export` with `Prefer: respond-async` header and one or more `subject` parameters.
2. **Kick-off Response**: Server responds with:
   - `202 Accepted` status code
   - `Content-Location` header with the absolute URL for subsequent status requests (polling location)
   - Parameters resource with `status` parameter set to `accepted` and `location` parameter
   - If the request is not valid or cannot be processed, the server responds with the relevant `4xx` status code and an `OperationOutcome` resource in the body.
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
     containing `status` = `completed`, the export metadata, and one `output`
     entry per subject with its download `location`s
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
   - Same authorisation context as the original request (servers SHOULD limit
     access to the client that initiated the export), OR
   - Non-guessable URLs (e.g., cryptographically random tokens)
   - Unauthorised access attempts return `401 Unauthorized` or `403 Forbidden`
9. **File Download**: Client downloads the output from URLs in the `output.location` parameters.

#### Examples

##### Mixed Batch Export

The motivating case: two ViewDefinitions and one SQLQuery exported as one job,
filtered to two patients, as CSV. The three subjects are named by canonical URL,
by literal reference, and by canonical URL with bound parameters respectively,
showing that the naming form is chosen per subject and independently of the
subject's kind.

**Step 1: Kick-off Request**

```http
POST /$sql-export HTTP/1.1
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
      "valueString": "bundle-2026-08"
    },
    {
      "name": "subject",
      "part": [
        { "name": "name", "valueString": "demographics" },
        {
          "name": "subjectCanonical",
          "valueCanonical": "http://example.org/ViewDefinition/patient_demographics|2.1.0"
        }
      ]
    },
    {
      "name": "subject",
      "part": [
        { "name": "name", "valueString": "encounters" },
        {
          "name": "subjectReference",
          "valueReference": { "reference": "ViewDefinition/encounters" }
        }
      ]
    },
    {
      "name": "subject",
      "part": [
        { "name": "name", "valueString": "bp_summary" },
        {
          "name": "subjectCanonical",
          "valueCanonical": "http://example.org/Library/bp-summary|1.0.0"
        },
        {
          "name": "parameters",
          "resource": {
            "resourceType": "Parameters",
            "parameter": [
              { "name": "min_systolic", "valueInteger": 140 }
            ]
          }
        }
      ]
    },
    { "name": "patient", "valueReference": { "reference": "Patient/123" } },
    { "name": "patient", "valueReference": { "reference": "Patient/456" } },
    { "name": "_format", "valueCode": "csv" }
  ]
}
```

The two `patient` filters apply to all three subjects; there is no way to scope
one subject differently from another.

**Step 2: Kick-off Response**

The server accepts the request and provides one polling location for the whole
job:

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
      "valueString": "bundle-2026-08"
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

**Step 3: Status Poll (In Progress)**

```http
GET /fhir/export/550e8400-e29b-41d4-a716-446655440000/status HTTP/1.1
Host: example.com
Accept: application/fhir+json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

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
      "valueString": "bundle-2026-08"
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
      "valueInstant": "2026-08-03T14:30:00Z"
    },
    {
      "name": "estimatedTimeRemaining",
      "valueInteger": 25
    }
  ]
}
```

**Step 4: Final Status Poll (Completed)**

The export has finished, so the status poll returns `303 See Other` with the
result URL in the `Location` header and no body:

```http
GET /fhir/export/550e8400-e29b-41d4-a716-446655440000/status HTTP/1.1
Host: example.com
Accept: application/fhir+json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

```http
HTTP/1.1 303 See Other
Location: https://example.com/fhir/export/550e8400-e29b-41d4-a716-446655440000/result
```

**Step 5: Fetch the Result**

The client fetches the result URL; the manifest `Parameters` resource is
returned:

```http
GET /fhir/export/550e8400-e29b-41d4-a716-446655440000/result HTTP/1.1
Host: example.com
Accept: application/fhir+json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

```http
HTTP/1.1 200 OK
Content-Type: application/fhir+json
Expires: Tue, 04 Aug 2026 14:31:15 GMT

{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "exportId",
      "valueString": "550e8400-e29b-41d4-a716-446655440000"
    },
    {
      "name": "clientTrackingId",
      "valueString": "bundle-2026-08"
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
      "valueInstant": "2026-08-03T14:30:00Z"
    },
    {
      "name": "exportEndTime",
      "valueInstant": "2026-08-03T14:31:15Z"
    },
    {
      "name": "exportDuration",
      "valueInteger": 75
    },
    {
      "name": "output",
      "part": [
        { "name": "name", "valueString": "demographics" },
        {
          "name": "location",
          "valueUri": "https://example.com/fhir/export/550e8400-e29b-41d4-a716-446655440000/demographics.csv"
        }
      ]
    },
    {
      "name": "output",
      "part": [
        { "name": "name", "valueString": "encounters" },
        {
          "name": "location",
          "valueUri": "https://example.com/fhir/export/550e8400-e29b-41d4-a716-446655440000/encounters.csv"
        }
      ]
    },
    {
      "name": "output",
      "part": [
        { "name": "name", "valueString": "bp_summary" },
        {
          "name": "location",
          "valueUri": "https://example.com/fhir/export/550e8400-e29b-41d4-a716-446655440000/bp_summary.csv"
        }
      ]
    }
  ]
}
```

One `exportId`, one echoed `clientTrackingId`, and exactly three `output`
entries - one per subject. The manifest states no order, so the client finds each
entry by `name`. All three were computed against one snapshot, so `bp_summary`
joins to `demographics` on the patient key without a skew window.

**Step 6: Download Files**

The client downloads each file:

```http
GET /fhir/export/550e8400-e29b-41d4-a716-446655440000/bp_summary.csv HTTP/1.1
Host: example.com
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

```http
HTTP/1.1 200 OK
Content-Type: text/csv
Content-Disposition: attachment; filename="bp_summary.csv"

patient_id,systolic,effective_date
Patient/123,145,2026-01-15
Patient/456,152,2026-01-20
```

##### Inline Subject Resource

Pass the artefact inline for an ad-hoc export, with nothing stored on the server:

```http
POST /$sql-export HTTP/1.1
Host: example.com
Content-Type: application/fhir+json
Prefer: respond-async

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "_format", "valueCode": "ndjson" },
    {
      "name": "subject",
      "part": [
        { "name": "name", "valueString": "active-patients" },
        {
          "name": "subjectResource",
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
    { "name": "_since", "valueInstant": "2026-01-01T00:00:00Z" }
  ]
}
```

##### A Shared Supporting Artefact, Supplied Once

Two SQLQuery subjects both depend on a ViewDefinition that exists only on the
client. It is supplied once as a `context` entry, resolved once for the job, and
satisfies both subjects' dependencies:

```http
POST /$sql-export HTTP/1.1
Host: example.com
Content-Type: application/fhir+json
Prefer: respond-async

{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "subject",
      "part": [
        { "name": "name", "valueString": "cohort_bp" },
        { "name": "subjectCanonical", "valueCanonical": "http://example.org/Library/cohort-bp" }
      ]
    },
    {
      "name": "subject",
      "part": [
        { "name": "name", "valueString": "cohort_labs" },
        { "name": "subjectCanonical", "valueCanonical": "http://example.org/Library/cohort-labs" }
      ]
    },
    {
      "name": "context",
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
    { "name": "_format", "valueCode": "csv" }
  ]
}
```

The completed manifest carries exactly two `output` entries, `cohort_bp` and
`cohort_labs`. The supplied `context` entry produces none. Had the server been
able to resolve `local_cohort` itself, the supplied entry would still take
precedence.
