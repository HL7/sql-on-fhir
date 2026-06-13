#### HTTP Methods

- **POST**: Required for providing export parameters and ViewDefinitions

#### Asynchronous Pattern

This operation follows the [FHIR Asynchronous Interaction Request Pattern](https://build.fhir.org/ig/HL7/api-incubator-ig/branches/simplified-async-interaction/async-interaction.html); the asynchronous flow is specified once in [Common Operation Behavior - Asynchronous Delivery](operations-common.html#asynchronous-delivery):

1. Client sends request with `Prefer: respond-async` header and one or more `view` parameters
2. Server returns `202 Accepted` with `Content-Location` header pointing to status URL
3. Client polls the status URL for export progress
4. Server responds with `202 Accepted` while export is in progress (MAY include interim results)
5. Once the export has finished (successfully or not), the status poll returns `303 See Other` with a `Location` header carrying the result URL and an empty body
6. Client fetches the result URL; a successful export returns `200 OK` with the manifest `Parameters` resource (`exportId`, `status`, `output`, …), and a failed export returns the error status code with an `OperationOutcome`
7. Client downloads the exported files from the `output.location` URLs in the manifest

The result resource for this operation is the manifest `Parameters` resource described under [Output Parameters](#output-parameters). Clients MUST treat the status and result URLs as opaque values.

##### Async Flow Diagram

```
    Client                                          Server
      │                                               │
      │ ┌─────────────────────────────────────────┐   │
      │ │ POST /ViewDefinition/$viewdefinition-export│
      │ │ Content-Type: application/fhir+json     │   │
      │ │ Prefer: respond-async                   │   │
      │ │ Accept: application/fhir+json           │   │
      │ │                                         │   │
      │ │ { "resourceType": "Parameters",         │   │
      │ │   "parameter": [                        │   │
      │ │     {"name": "view", "part": [...]}     │   │
      │ │   ]}                                    │   │
      │ └─────────────────────────────────────────┘   │
      │ ─────────────────────────────────────────────>│
      │                                               │  Step 1: Kick-off
      │   ┌─────────────────────────────────────────┐ │
      │   │ 202 Accepted                            │ │
      │   │ Content-Location: /status/abc123        │ │
      │   │                                         │ │
      │   │ { "resourceType": "Parameters",         │ │
      │   │   "parameter": [                        │ │
      │   │     {"name": "exportId",                │ │
      │   │      "valueString": "abc123"},          │ │
      │   │     {"name": "status",                  │ │
      │   │      "valueCode": "accepted"}           │ │
      │   │   ]}                                    │ │
      │   └─────────────────────────────────────────┘ │
      │ <─────────────────────────────────────────────│
      │                                               │
      ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤
      │                                               │
      │ ┌─────────────────────────────────────────┐   │
      │ │ GET /status/abc123                      │   │
      │ │ Accept: application/fhir+json           │   │
      │ └─────────────────────────────────────────┘   │
      │ ─────────────────────────────────────────────>│
      │                                               │  Step 2: Polling
      │   ┌─────────────────────────────────────────┐ │  (repeat while
      │   │ 202 Accepted                            │ │   in progress)
      │   │ Retry-After: 10                         │ │
      │   │ X-Progress: 45%                         │ │
      │   │                                         │ │
      │   │ { "resourceType": "Parameters",         │ │
      │   │   "parameter": [                        │ │
      │   │     {"name": "status",                  │ │
      │   │      "valueCode": "in-progress"}        │ │
      │   │   ]}                                    │ │
      │   └─────────────────────────────────────────┘ │
      │ <─────────────────────────────────────────────│
      │                 ... (repeat) ...              │
      │                                               │
      ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤
      │                                               │
      │ ┌─────────────────────────────────────────┐   │
      │ │ GET /status/abc123                      │   │
      │ │ Accept: application/fhir+json           │   │
      │ └─────────────────────────────────────────┘   │
      │ ─────────────────────────────────────────────>│
      │                                               │  Step 3: Completion
      │   ┌─────────────────────────────────────────┐ │  (303 + result URL)
      │   │ 303 See Other                           │ │
      │   │ Location: /result/abc123                │ │
      │   │                                         │ │
      │   │ (empty body)                            │ │
      │   └─────────────────────────────────────────┘ │
      │ <─────────────────────────────────────────────│
      │                                               │
      ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤
      │                                               │
      │ ┌─────────────────────────────────────────┐   │
      │ │ GET /result/abc123                      │   │
      │ │ Accept: application/fhir+json           │   │
      │ └─────────────────────────────────────────┘   │
      │ ─────────────────────────────────────────────>│
      │                                               │  Step 4: Result fetch
      │   ┌─────────────────────────────────────────┐ │  (200 OK + manifest)
      │   │ 200 OK                                  │ │
      │   │ Content-Type: application/fhir+json    │ │
      │   │ Expires: Mon, 21 Jan 2026 16:00:00 GMT │ │
      │   │                                         │ │
      │   │ { "resourceType": "Parameters",         │ │
      │   │   "parameter": [                        │ │
      │   │     {"name": "status",                  │ │
      │   │      "valueCode": "completed"},         │ │
      │   │     {"name": "output", "part": [        │ │
      │   │       {"name": "name",                  │ │
      │   │        "valueString": "patients"},      │ │
      │   │       {"name": "location",              │ │
      │   │        "valueUrl": "/export/.../..."}   │ │
      │   │     ]}                                  │ │
      │   │   ]}                                    │ │
      │   └─────────────────────────────────────────┘ │
      │ <─────────────────────────────────────────────│
      │                                               │
      ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─┤
      │                                               │
      │ ┌─────────────────────────────────────────┐   │
      │ │ GET /export/abc123/patients.ndjson      │   │
      │ └─────────────────────────────────────────┘   │
      │ ─────────────────────────────────────────────>│
      │                                               │  Step 5: Download
      │   ┌─────────────────────────────────────────┐ │
      │   │ 200 OK                                  │ │
      │   │ Content-Type: application/x-ndjson     │ │
      │   │                                         │ │
      │   │ {"id":"pt1","name":[{"given":["John"]}]}│ │
      │   │ {"id":"pt2","name":[{"given":["Jane"]}]}│ │
      │   └─────────────────────────────────────────┘ │
      │ <─────────────────────────────────────────────│
      │                                               │
```

**Alternative Flows:**

```
  ┌─────────────────────────────────────────────────────────────────┐
  │  CANCELLATION (Recommended)                                      │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │  Client                                          Server         │
  │    │                                               │            │
  │    │ DELETE /status/abc123                         │            │
  │    │ ─────────────────────────────────────────────>│            │
  │    │                                               │            │
  │    │   202 Accepted                                │            │
  │    │ <─────────────────────────────────────────────│            │
  │    │                                               │            │
  │    │ GET /status/abc123  (subsequent poll)         │            │
  │    │ ─────────────────────────────────────────────>│            │
  │    │                                               │            │
  │    │   404 Not Found                               │            │
  │    │ <─────────────────────────────────────────────│            │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────────┐
  │  ERROR HANDLING (Operation Failure)                             │
  ├─────────────────────────────────────────────────────────────────┤
  │                                                                 │
  │  Client                                          Server         │
  │    │                                               │            │
  │    │ GET /status/abc123                            │            │
  │    │ ─────────────────────────────────────────────>│            │
  │    │                                               │            │
  │    │   303 See Other                               │            │
  │    │   Location: /result/abc123                    │            │
  │    │   (empty body)                                │            │
  │    │ <─────────────────────────────────────────────│            │
  │    │                                               │            │
  │    │ GET /result/abc123                            │            │
  │    │ ─────────────────────────────────────────────>│            │
  │    │                                               │            │
  │    │   500 Internal Server Error                   │            │
  │    │   { "resourceType": "OperationOutcome",       │            │
  │    │     "issue": [{                               │            │
  │    │       "severity": "error",                    │            │
  │    │       "code": "exception",                    │            │
  │    │       "diagnostics": "Export failed: ..."     │            │
  │    │     }]}                                       │            │
  │    │ <─────────────────────────────────────────────│            │
  │                                                                 │
  └─────────────────────────────────────────────────────────────────┘
```

#### Data Sources

The operation can export data from:

1. **Server resources** - From the server's data store (default)
2. **External source** - Specified via `source` parameter

#### Filtering

Optional filtering parameters:

- `patient` - Export only resources for this patient
- `group` - Export only resources for this group
- `_since` - Export only resources updated since this time

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

#### Input Parameters

##### Core Parameters

| Name | Type    | Min | Max | Description                                                                                                                                            |
| ---- | ------- | --- | --- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| view | complex | 1   | \*  | ViewDefinition(s) to export. Can be repeated to export multiple views in a single operation. See [ViewDefinition Parameter](#viewdefinition-parameter) |

{:.table-data}

##### ViewDefinition Parameter

The `view` parameter is a complex type that can be repeated multiple times to export several ViewDefinitions in a single operation. Each `view` parameter has the following parts:

| Name               | Type           | Min | Max | Description                                                                        |
| ------------------ | -------------- | --- | --- | ---------------------------------------------------------------------------------- |
| view               | complex        | 1   | \*  | A ViewDefinition to export                                                         |
| view.name          | string         | 0   | 1   | Name for the export output. If not provided, ViewDefinition name will be used      |
| view.viewReference | Reference      | 0¹  | 1   | Reference to ViewDefinition on the server. [Details](#viewreference-clarification) |
| view.viewResource  | ViewDefinition | 0¹  | 1   | Inline ViewDefinition resource                                                     |

{:.table-data}

¹ Either view.viewReference or view.viewResource is required

##### Export Control

| Name             | Type    | Min | Max | Description                                                                                   |
| ---------------- | ------- | --- | --- | --------------------------------------------------------------------------------------------- |
| clientTrackingId | string  | 0   | 1   | Client-provided tracking ID for the export operation                                          |
| \_format         | code    | 0   | 1   | Output format: `csv`, `ndjson`, `parquet`, `json`. [Details](#format-parameter-clarification) |
| header           | boolean | 0   | 1   | Include CSV headers (default true). Applies only when csv output is requested                 |

{:.table-data}

##### Filtering

| Name    | Type      | Min | Max | Description                                                                              |
| ------- | --------- | --- | --- | ---------------------------------------------------------------------------------------- |
| patient | Reference | 0   | \*  | Filter by patient reference. [Details](#patient-parameter-clarification)                 |
| group   | Reference | 0   | \*  | Filter by group membership. [Details](#group-parameter-clarification)                    |
| \_since | instant   | 0   | 1   | Export only resources updated since this time. [Details](#since-parameter-clarification) |

{:.table-data}

##### Data Source

| Name   | Type   | Min | Max | Description                                                                |
| ------ | ------ | --- | --- | -------------------------------------------------------------------------- |
| source | string | 0   | 1   | External data source (e.g., URI, bucket name). If absent, uses server data |

{:.table-data}

If server does not support a parameter, request should be rejected with `400 Bad Request`
and `OperationOutcome` resource in the body with clarification that the parameter is not supported.
Server should document which parameters it supports in its CapabilityStatement.

##### ViewReference Clarification

The `view.viewReference` parameter MAY be specified using any of the following formats:

- A relative URL on the server (e.g. "ViewDefinition/123")
- A canonical URL (e.g. "http://specification.org/fhir/ViewDefinition/123|1.0.0")
- An absolute URL (e.g. "http://example.org/fhir/ViewDefinition/123")

Servers MAY choose which reference formats they support.
Servers SHALL document which reference formats they support in their CapabilityStatement.

For servers that want to support all types of references, it is recommended to follow the following algorithm:

1. If the reference is a relative URL, resolve it on the server side.
2. If the reference is an absolute URL, look up the available server Artifact registry for
   a resource with the same canonical URL and version if provided.
3. Otherwise, try to load the ViewDefinition from the provided absolute URL.

##### Format Parameter Clarification

The supported formats (`json`, `ndjson`, `csv`, `parquet`) and the default are
defined in
[Common Operation Behavior](operations-common.html#output-formats) and apply to
this operation. The `fhir` format is available on the run operations only:

- It is RECOMMENDED to support `json`, `ndjson` and `csv` by default; servers MAY
  support `parquet`, and SHALL document supported formats in the
  CapabilityStatement.
- If `_format` is omitted, the server SHALL produce the export output in `ndjson`
  format.
- When `_format` is supplied, its value SHALL take precedence over `Accept`
  (which here negotiates the format of the _status and result_ responses, not
  the exported files).

##### Patient Parameter Clarification

When provided, the server SHALL NOT return resources
in the patient compartments belonging to patients outside of this list.

If a client requests patients who are not present on the server,
the server SHOULD return details via a FHIR `OperationOutcome` resource in an error response to the request.

##### Group Parameter Clarification

When provided, the server SHALL NOT return resources that are not a member of the supplied `Group`.

If a client requests groups that are not present on the server,
the server SHOULD return details via a FHIR `OperationOutcome` resource in an error response to the request.

##### Since Parameter Clarification

Resources will be included in the response if their state has changed after the supplied time
(e.g., if Resource.meta.lastUpdated is later than the supplied `_since` time).
In the case of a Group level export, the server MAY return additional resources modified prior to the supplied time
if the resources belong to the patient compartment of a patient added to the Group after the supplied time (this behavior SHOULD be clearly documented by the server).
For Patient- and Group-level requests, the server MAY return resources that are referenced by the resources being returned
regardless of when the referenced resources were last updated.
For resources where the server does not maintain a last updated time,
the server MAY include these resources in a response irrespective of the `_since` value supplied by a client.

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

| Name            | Type    | Min | Max | Description                                                              |
| --------------- | ------- | --- | --- | ------------------------------------------------------------------------ |
| output          | complex | 0   | \*  | Output information for each exported view                                |
| output.name     | string  | 1   | 1   | The name of the exported view. [Details](#output-name-clarification)     |
| output.location | uri     | 1   | \*  | URL(s) to download the exported file(s). [Details](#output-partitioning) |

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

The `output.name` parameter identifies each exported view in the results. The value is determined as follows:

1. If `view.name` was provided in the input parameters, that value is used
2. If `view.name` was not provided, the name is taken from the ViewDefinition resource's `name` element
3. If neither is available, the server SHALL generate a unique identifier for the output

This allows clients to correlate output files with their requested views and provides meaningful filenames for the exported data.

##### Output Partitioning

For large exports, servers MAY partition the output into multiple files. When partitioning occurs:

1. **Multiple Locations**: The `output.location` parameter can repeat within a single output entry
2. **File Naming**: Partitioned files SHOULD use a consistent naming convention (e.g., `filename.part1.parquet`, `filename.part2.parquet`)
3. **Complete Set**: All parts together represent the complete export for that view

**Example of partitioned output:**

```json
{
  "name": "output",
  "part": [
    {
      "name": "name",
      "valueString": "patient_demographics"
    },
    {
      "name": "location",
      "valueUri": "https://example.com/export/123/patient_demographics.part1.parquet"
    },
    {
      "name": "location",
      "valueUri": "https://example.com/export/123/patient_demographics.part2.parquet"
    },
    {
      "name": "location",
      "valueUri": "https://example.com/export/123/patient_demographics.part3.parquet"
    }
  ]
}
```

Clients MUST download all parts to obtain the complete dataset for a view.

#### Error Handling

##### HTTP Status Codes

The $viewdefinition-export operation uses standard HTTP status codes to indicate the outcome:

| Status Code               | Description          | When to Use                                                                         |
| ------------------------- | -------------------- | ----------------------------------------------------------------------------------- |
| 202 Accepted              | In Progress          | Export request accepted, still in progress during polling, or cancellation accepted |
| 303 See Other             | Job Finished         | Export finished (successfully or not); `Location` header carries the result URL     |
| 200 OK                    | Result Available     | Result URL returns the manifest `Parameters`; download URLs return the files        |
| 400 Bad Request           | Client Error         | Invalid parameters, unsupported parameters, missing required headers                |
| 404 Not Found             | Not Found            | ViewDefinition not found, or cancelled export status URL                            |
| 422 Unprocessable Entity  | Business Logic Error | Valid request but ViewDefinition is invalid or cannot be processed                  |
| 429 Too Many Requests     | Excessive Polling    | Client is polling too frequently; back off exponentially, guided by `Retry-After`   |
| 500 Internal Server Error | Server Error         | Unexpected server error; on the result URL, the failure outcome of the export       |

{:.table-data}

All error responses (4xx and 5xx) SHOULD include an `OperationOutcome` resource providing details about the error.

##### Common Error Scenarios

##### 1. Unsupported Parameters

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

##### 2. Invalid ViewDefinition

When a provided ViewDefinition is invalid:

```http
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "invalid",
      "diagnostics": "The ViewDefinition 'patient_summary' is invalid: column 'age' contains invalid FHIRPath expression",
      "expression": ["parameter[0].part[1].resource.select[0].column[1].path"]
    }
  ]
}
```

##### 3. ViewDefinition Not Found

When a referenced ViewDefinition does not exist:

```http
HTTP/1.1 404 Not Found
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "not-found",
      "diagnostics": "ViewDefinition with reference 'ViewDefinition/non-existent' not found"
    }
  ]
}
```

##### 4. Patient or Group Not Found

When filtering by patient or group that doesn't exist:

```http
HTTP/1.1 404 Not Found
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "not-found",
      "diagnostics": "Patient with reference 'Patient/12345' not found"
    }
  ]
}
```

For group references:

```http
HTTP/1.1 404 Not Found
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "not-found",
      "diagnostics": "Group with reference 'Group/diabetes-cohort' not found"
    }
  ]
}
```

##### 5. Multiple ViewDefinitions with Errors

When processing multiple ViewDefinitions, servers SHOULD validate all of them before starting the export:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "not-found",
      "diagnostics": "ViewDefinition 'patient-vitals' not found",
      "expression": ["parameter[1]"]
    },
    {
      "severity": "error",
      "code": "invalid",
      "diagnostics": "ViewDefinition 'lab-results' contains invalid resource type",
      "expression": ["parameter[2]"]
    }
  ]
}
```

#### Operation flow

1. **Kick-off Request**: Client sends `POST ViewDefinition/$viewdefinition-export` with `Prefer: respond-async` header.
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

This example demonstrates the full lifecycle of an export operation from initiation through completion.

**Step 1: Kick-off Request**

Client initiates export of two ViewDefinitions with patient filtering:

```http
POST /ViewDefinition/$viewdefinition-export HTTP/1.1
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
      "valueString": "monthly-report-2026-01"
    },
    {
      "name": "view",
      "part": [
        {
          "name": "name",
          "valueString": "demographics_summary"
        },
        {
          "name": "viewReference",
          "valueReference": {
            "reference": "ViewDefinition/patient-demographics-v2"
          }
        }
      ]
    },
    {
      "name": "view",
      "part": [
        {
          "name": "viewResource",
          "resource": {
            "resourceType": "ViewDefinition",
            "name": "active_medications",
            "resource": "MedicationRequest",
            "select": [
              {
                "column": [
                  {
                    "path": "id",
                    "name": "medication_id"
                  },
                  {
                    "path": "medication.concept.coding[0].display",
                    "name": "medication_name"
                  },
                  {
                    "path": "authoredOn",
                    "name": "prescribed_date"
                  },
                  {
                    "path": "subject.reference",
                    "name": "patient_ref"
                  }
                ]
              }
            ],
            "where": [
              {
                "path": "status",
                "op": "=",
                "value": "active"
              }
            ]
          }
        }
      ]
    },
    {
      "name": "patient",
      "valueReference": {
        "reference": "Patient/cohort-123"
      }
    },
    {
      "name": "_since",
      "valueInstant": "2026-01-01T00:00:00Z"
    },
    {
      "name": "_format",
      "valueCode": "parquet"
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
      "valueString": "monthly-report-2026-01"
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
      "valueString": "monthly-report-2026-01"
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
      "valueInstant": "2026-01-15T14:30:00Z"
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
      "valueString": "monthly-report-2026-01"
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
      "valueInstant": "2026-01-15T14:30:00Z"
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
Expires: Fri, 16 Jan 2026 14:30:42 GMT

{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "exportId",
      "valueString": "550e8400-e29b-41d4-a716-446655440000"
    },
    {
      "name": "clientTrackingId",
      "valueString": "monthly-report-2026-01"
    },
    {
      "name": "status",
      "valueCode": "completed"
    },
    {
      "name": "_format",
      "valueCode": "parquet"
    },
    {
      "name": "exportStartTime",
      "valueInstant": "2026-01-15T14:30:00Z"
    },
    {
      "name": "exportEndTime",
      "valueInstant": "2026-01-15T14:30:42Z"
    },
    {
      "name": "exportDuration",
      "valueInteger": 42
    },
    {
      "name": "output",
      "part": [
        {
          "name": "name",
          "valueString": "demographics_summary"
        },
        {
          "name": "location",
          "valueUri": "https://example.com/fhir/export/550e8400-e29b-41d4-a716-446655440000/demographics_summary.parquet"
        }
      ]
    },
    {
      "name": "output",
      "part": [
        {
          "name": "name",
          "valueString": "active_medications"
        },
        {
          "name": "location",
          "valueUri": "https://example.com/fhir/export/550e8400-e29b-41d4-a716-446655440000/active_medications.part1.parquet"
        },
        {
          "name": "location",
          "valueUri": "https://example.com/fhir/export/550e8400-e29b-41d4-a716-446655440000/active_medications.part2.parquet"
        }
      ]
    }
  ]
}
```

**Step 7: Download Files**

Client downloads each file:

```http
GET /fhir/export/550e8400-e29b-41d4-a716-446655440000/demographics_summary.parquet HTTP/1.1
Host: example.com
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

```http
HTTP/1.1 200 OK
Content-Type: application/octet-stream
Content-Disposition: attachment; filename="demographics_summary.parquet"
Content-Length: 1048576

[Binary parquet file content]
```
