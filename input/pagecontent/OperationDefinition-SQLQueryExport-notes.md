#### HTTP Methods

- **POST**: Required for providing export parameters and SQLQuery Libraries

#### Asynchronous Pattern

This operation follows the FHIR Asynchronous Interaction Request Pattern:

1. Client sends request with `Prefer: respond-async` header and query source parameters
2. Server returns `202 Accepted` with `Content-Location` header pointing to status URL
3. Client polls the status URL for export progress
4. Server responds with `202 Accepted` while export is in progress (MAY include interim results)
5. Upon completion, server returns `303 See Other` with `Location` header pointing to result URL
6. Client GETs the result URL to retrieve final output (identical to synchronous response format)

**Note**: This operation uses Parameters resource format instead of Bundle format to:

- Provide structured status reporting and metadata
- Allow extensible output metadata specific to export operations
- Maintain consistency with other FHIR operations

**Note**: The `303 See Other` redirect pattern cleanly separates status polling from result retrieval, eliminating ambiguity around error handling and request header scope.

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
    S-->>C: 303 See Other<br/>Location: /result/abc123
    end

    rect rgb(255, 255, 240)
    Note over C,S: Step 4: Result
    C->>S: GET /result/abc123
    S-->>C: 200 OK<br/>Body: Parameters{output: [{name, location}]}
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
    S-->>C: 303 See Other<br/>Location: /result/abc123
    C->>S: GET /result/abc123
    S-->>C: 500 Internal Server Error<br/>Body: OperationOutcome{severity: error, diagnostics: ...}
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

- `Accept` (recommended) - Specifies the format of the status response

##### Result Request

- `Accept` (recommended) - Specifies the format of the final result response

##### Header Scope

Request headers sent during status polling apply **only to the status response**, not to the final operation result. This separation:

- Allows different content negotiation for status vs. result responses
- Enables servers to use different formats for interim status (e.g., minimal JSON) vs. final results (e.g., detailed Parameters)
- Eliminates ambiguity about which response the headers apply to

#### Parameters

#### Input Parameters

##### Query Source — `query` Parameter (1..\*, system+type scope)

Each repetition identifies a single SQLQuery Library to export. At least one `query` is required at system/type level.

At the instance level (`POST [base]/Library/[id]/$sqlquery-export`), the bound Library identified by the request URL serves as the single query source and the `query` parameter does not apply. The export targets that one Library, optionally combined with the export control, filtering, and data source parameters listed below. Instance-level invocation does not provide a slot for per-query parameter binding; clients that need to pass parameters should use the system or type level with a `query.parameters` part.

| Part Name      | Type       | Min | Max | Description                                                                             |
| -------------- | ---------- | --- | --- | --------------------------------------------------------------------------------------- |
| name           | string     | 0   | 1   | Optional friendly name for the exported query output                                    |
| queryReference | Reference  | 0¹  | 1   | Reference to a SQLQuery Library on the server. [Details](#queryreference-clarification) |
| queryResource  | Resource   | 0¹  | 1   | Inline SQLQuery Library resource                                                        |
| parameters     | Parameters | 0   | 1   | Input parameters for this query. [Details](#parameter-passing)                          |

{:.table-data}

¹ Either queryReference or queryResource is required per `query` repetition.

##### ViewDefinition Table Sources — `view` Parameter (0..\*, system+type scope)

Provides ViewDefinitions that serve as table sources for the SQL queries. These are the ViewDefinitions referenced in the Library's `relatedArtifact` entries. ViewDefinitions supplied here are materialized as tables for the SQL to query against — they do **not** produce separate output entries. Only the SQL query results appear in the export output.

| Part Name     | Type      | Min | Max | Description                                        |
| ------------- | --------- | --- | --- | -------------------------------------------------- |
| name          | string    | 0   | 1   | Optional friendly name for the ViewDefinition      |
| viewReference | Reference | 0²  | 1   | Reference to a ViewDefinition stored on the server |
| viewResource  | Resource  | 0²  | 1   | Inline ViewDefinition resource                     |

{:.table-data}

² Either viewReference or viewResource is required per `view` repetition.

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

##### QueryReference Clarification

The `queryReference` parameter MAY be specified using any of the following formats:

- A relative URL on the server (e.g. "Library/patient-bp-query")
- A canonical URL (e.g. "http://example.org/fhir/Library/patient-bp-query|1.0.0")
- An absolute URL (e.g. "http://example.org/fhir/Library/patient-bp-query")

Servers MAY choose which reference formats they support.
Servers SHALL document which reference formats they support in their CapabilityStatement.

##### Format Parameter Clarification

It is RECOMMENDED to support 'json', 'ndjson' and 'csv' formats by default.
Servers may support other formats, but they should be explicitly documented in the CapabilityStatement.

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

#### Parameter Passing

Query parameters are passed as a nested `Parameters` resource within each
`query` repetition (per-query binding via the `parameters` part), following the
same pattern as [`$sqlquery-run`](OperationDefinition-SQLQueryRun.html) and the
[CQL `$evaluate` operation](https://build.fhir.org/ig/HL7/cql-ig/en/OperationDefinition-cql-library-evaluate.html).
See [Parameter Types](StructureDefinition-SQLQuery.html#parameter-types) on the
SQLQuery profile for the binding rules and the mapping from
`Library.parameter.type` to the `value[x]` element to use.

#### Output Parameters

Output parameters appear in the **result response** (after following the `303 See Other` redirect), not in status polling responses.

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

| Name            | Type    | Min | Max | Description                                                                                                                                |
| --------------- | ------- | --- | --- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| output          | complex | 0   | \*  | Output information for each exported SQL query result (one per `query`; ViewDefinitions supplied via `view` do not produce output entries) |
| output.name     | string  | 1   | 1   | The name of the exported output. [Details](#output-name-clarification)                                                                     |
| output.location | uri     | 1   | \*  | URL(s) to download the exported file(s). [Details](#output-partitioning)                                                                   |

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

| Status Code               | Description          | When to Use                                                          |
| ------------------------- | -------------------- | -------------------------------------------------------------------- |
| 202 Accepted              | In Progress          | Export request accepted or still in progress during polling          |
| 303 See Other             | Complete             | Export complete, follow `Location` header to retrieve results        |
| 400 Bad Request           | Client Error         | Invalid parameters, unsupported parameters, missing required headers |
| 404 Not Found             | Not Found            | SQLQuery Library not found, or cancelled export status URL           |
| 422 Unprocessable Entity  | Business Logic Error | Valid request but query is invalid or cannot be executed             |
| 500 Internal Server Error | Server Error         | Unexpected server error (at result URL indicates operation failure)  |

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

##### 2. Invalid SQLQuery Library

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

##### 3. SQLQuery Library Not Found

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

##### 4. Parameter Type Mismatch

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

##### 5. Patient or Group Not Found

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
4. **Completion**: When export is ready, server responds with:
    - `303 See Other` status code
    - `Location` header pointing to the result URL
    - Response body is optional (MAY be empty or contain minimal status)
5. **Result Retrieval**: Client GETs the result URL from the `Location` header:
    - `200 OK` status code with Parameters resource containing `output` locations
    - Response format is identical to what a synchronous call would return
6. **Error Handling**: If export fails:
    - Status endpoint still returns `303 See Other` with `Location` header
    - Result URL returns appropriate error status code (e.g., `500 Internal Server Error`)
    - Result response contains `OperationOutcome` with error details
    - This cleanly separates polling errors from operation errors
7. **Cancellation** (Recommended):
   Servers SHOULD support export cancellation via DELETE request to the status URL:
    - Client sends `DELETE` request to the status polling URL
    - Server responds with `202 Accepted`
    - Subsequent status requests return `404 Not Found`
    - Server SHOULD clean up any partial results
8. **Result URL Lifetime**:
   Result URLs SHALL remain valid for at least 24 hours after export completion:
    - Servers SHOULD support multiple retrievals of the same result
    - Servers MAY include an `Expires` header to indicate result URL expiration
    - Clients should retrieve results promptly but can retry within the validity window
9. **Access Control**:
   Servers SHALL protect status and result URLs with appropriate access controls:
    - Same authorization context as the original request, OR
    - Non-guessable URLs (e.g., cryptographically random tokens)
    - Unauthorized access attempts return `401 Unauthorized` or `403 Forbidden`
10. **File Download**: Client downloads the output from URLs in the `output.location` parameters.

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

Response indicates completion with redirect to result URL:

```http
HTTP/1.1 303 See Other
Location: https://example.com/fhir/export/550e8400-e29b-41d4-a716-446655440000/result
```

**Step 6: Result Retrieval**

Client follows the `Location` header to retrieve the final results:

```http
GET /fhir/export/550e8400-e29b-41d4-a716-446655440000/result HTTP/1.1
Host: example.com
Accept: application/fhir+json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
```

Response contains the export results:

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
            "meta": { "profile": ["https://sql-on-fhir.org/ig/StructureDefinition/SQLQuery"] },
            "type": { "coding": [{ "system": "https://sql-on-fhir.org/ig/CodeSystem/LibraryTypesCodes", "code": "sql-query" }] },
            "status": "active",
            "relatedArtifact": [
              { "type": "depends-on", "resource": "https://example.org/ViewDefinition/patient_view", "label": "p" }
            ],
            "content": [{
              "contentType": "application/sql",
              "title": "SELECT p.id, p.name FROM p WHERE p.active = true",
              "data": "U0VMRUNUIHAuaWQsIHAubmFtZSBGUk9NIHAgV0hFUkUgcC5hY3RpdmUgPSB0cnVl"
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

Export multiple queries in one operation, providing a ViewDefinition table source inline:

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
          "name": "queryReference",
          "valueReference": {
            "reference": "Library/bp-summary-query"
          }
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
      "name": "view",
      "part": [
        {
          "name": "viewReference",
          "valueReference": {
            "reference": "Binary/UsCoreBloodPressures"
          }
        }
      ]
    },
    {
      "name": "_format",
      "valueCode": "csv"
    }
  ]
}
```
