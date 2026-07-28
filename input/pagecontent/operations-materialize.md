# Operation $materialize on ViewDefinition

## Overview

The `$materialize` operation is an asynchronous operation that creates and manages a persistent, queryable view from a ViewDefinition. The server becomes responsible for keeping the materialized view up-to-date based on a defined policy, allowing clients to reliably query the transformed data without needing to re-execute the transformation logic.

**Canonical URL:** `http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/Materialize`

**Use Cases:**
* Creating stable, analytics-ready tables from FHIR data.
* Providing a consistent, queryable endpoint for complex views.
* Offloading the management and refresh logic of data transformations to the server.
* Caching the results of frequently used or slow-running views.

## Invocation

### Endpoints

The operation can be invoked at two levels:

| Level | Endpoint | Description |
|-------|----------|-------------|
| Type | `POST /ViewDefinition/$materialize` | Creates a managed view from a ViewDefinition provided in the body. |
| Instance | `POST /ViewDefinition/{id}/$materialize` | Creates a managed view from the `ViewDefinition` identified by `{id}`. |

### HTTP Methods

* **POST**: Required for providing the ViewDefinition and materialization parameters.

### Asynchronous Pattern

This operation follows the FHIR Asynchronous Interaction Request Pattern:
1. Client sends a request with the `Prefer: respond-async` header.
2. Server accepts the request and returns a `202 Accepted` status with a `Content-Location` header pointing to a status URL.
3. Client polls the status URL to monitor the materialization process (`accepted`, `in-progress`, `completed`, `failed`).
4. Upon completion, the server provides a reference to the newly created and managed `MaterializedView` resource.

### Data Sources

The operation can materialize data from:
1. **Server resources** - From the server's data store (default).
2. **External source** - Specified via the `source` parameter for the initial creation.

## Required Headers

### Kick-off Request
* `Prefer: respond-async` (required) - Specifies that the response should be asynchronous.
* `Accept` (recommended) - Specifies the format of the response body (e.g., `application/fhir+json`).

### Status Request
* `Accept` (recommended) - Specifies the format of the response body.

## Parameters

### Input Parameters

When invoking this operation at the instance level (`/ViewDefinition/{id}/$materialize`), the `view` parameter is not required and SHALL be ignored if provided, as the ViewDefinition is inferred from the URL. At the type level, the `view` parameter is required.

#### Core Parameters

| Name | Type | Min | Max | Description |
|------|------|-----|-----|-------------|
| view | complex | 0¹ | 1 | The ViewDefinition to materialize. See [ViewDefinition Parameter](#viewdefinition-parameter) |
| targetName | string | 1 | 1 | A unique name for the target materialized view. This will be used to identify the view for future queries. |

¹ Required at type-level, not allowed at instance-level.

#### ViewDefinition Parameter

The `view` parameter is a complex type with the following parts:

| Name | Type | Min | Max | Description |
|------|------|-----|-----|-------------|
| viewReference | Reference | 0² | 1 | Reference to a ViewDefinition on the server. |
| viewResource | ViewDefinition | 0² | 1 | An inline ViewDefinition resource. |

² Either `viewReference` or `viewResource` is required when the `view` parameter is present.

#### Update Policy

| Name | Type | Min | Max | Description |
|------|------|-----|-----|-------------|
| updatePolicy | code | 1 | 1 | How the view is kept up-to-date: `manual` (only updates on re-invocation), `scheduled`. |
| schedule | string | 0 | 1 | A CRON string defining the refresh schedule. Required if `updatePolicy` is `scheduled`. |

#### Filtering (for initial creation)

| Name | Type | Min | Max | Description |
|------|------|-----|-----|-------------|
| patient | Reference | 0 | * | Filter by patient reference for the initial build. |
| group | Reference | 0 | * | Filter by group membership for the initial build. |
| _since | instant | 0 | 1 | Include only resources updated since this time for the initial build. |

#### Data Source (for initial creation)

| Name | Type | Min | Max | Description |
|------|------|-----|-----|-------------|
| source | string | 0 | 1 | External data source (e.g., URI, bucket name). If absent, uses server data. |


### Output Parameters

#### Job Identifiers

| Name | Type | Min | Max | Description |
|------|------|-----|-----|-------------|
| jobId | string | 1 | 1 | Server-generated ID for the materialization job. |

#### Job Status

| Name | Type | Min | Max | Description |
|------|------|-----|-----|-------------|
| status | code | 1 | 1 | The status of the job: `accepted`, `in-progress`, `completed`, `failed`. |
| location | uri | 1 | 1 | The URL to poll for the status of the job. |

#### Materialization Result (in `completed` status)

| Name | Type | Min | Max | Description |
|------|------|-----|-----|-------------|
| materializedView | Reference | 1 | 1 | A reference to the created `MaterializedView` resource, which can be used for querying. |
| lastUpdated | instant | 1 | 1 | The timestamp of the last successful refresh. |
| nextUpdate | instant | 0 | 1 | The timestamp of the next scheduled refresh (if applicable). |


## Error Handling

Error responses (4xx and 5xx) SHOULD include an `OperationOutcome` resource.

| Status Code | Description | When to Use |
|-------------|-------------|-------------|
| 202 Accepted | Success | Job accepted, poll for status. |
| 400 Bad Request | Client Error | Invalid or unsupported parameters (e.g., invalid `targetName`, missing `schedule` for a scheduled policy). |
| 404 Not Found | Not Found | Referenced `ViewDefinition`, `patient`, or `group` not found. |
| 409 Conflict | Conflict | A materialized view with the given `targetName` already exists. |
| 422 Unprocessable Entity | Business Logic Error | The provided `ViewDefinition` is invalid. |
| 500 Internal Server Error | Server Error | Unexpected server error during materialization. |

## Operation Flow

1.  **Kick-off Request**: Client sends `POST /ViewDefinition/$materialize` (or `POST /ViewDefinition/{id}/$materialize`) with `Prefer: respond-async`, providing materialization parameters.
2.  **Kick-off Response**: Server validates the parameters. If valid, it responds with `202 Accepted` and a `Content-Location` header for polling. If a view with `targetName` already exists, it returns `409 Conflict`.
3.  **Status Polling**: Client polls the location URL. The server responds with `202 Accepted` and a status of `in-progress`.
4.  **Completion**: When the initial view is built, the server responds to the poll with `200 OK`. The response body is a `Parameters` resource with a `status` of `completed` and a `materializedView` reference.
5.  **Querying**: The client can now use the `materializedView` reference to query the data directly.
6.  **Background Updates**: The server continues to refresh the view in the background according to the `updatePolicy`.

## Examples

### Example 1: Create a view (Type-Level)

Client requests the creation of a materialized view of patient demographics, scheduled to update nightly, by providing a reference to a `ViewDefinition`.

```http
POST /ViewDefinition/$materialize HTTP/1.1
Host: example.com
Content-Type: application/fhir+json
Prefer: respond-async
Accept: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "targetName",
      "valueString": "daily_patient_demographics"
    },
    {
      "name": "view",
      "part": [
        {
          "name": "viewReference",
          "valueReference": {
            "reference": "ViewDefinition/patient-demographics-v2"
          }
        }
      ]
    },
    {
      "name": "updatePolicy",
      "valueCode": "scheduled"
    },
    {
      "name": "schedule",
      "valueString": "0 0 * * *"
    }
  ]
}
```

### Example 2: Create a view (Instance-Level)

Client requests to materialize a specific `ViewDefinition`. The request body is simpler as the `view` parameter is not needed.

```http
POST /ViewDefinition/patient-demographics-v2/$materialize HTTP/1.1
Host: example.com
Content-Type: application/fhir+json
Prefer: respond-async
Accept: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "targetName",
      "valueString": "daily_patient_demographics_inst"
    },
    {
      "name": "updatePolicy",
      "valueCode": "manual"
    }
  ]
}
```

The subsequent polling and response flow would be the same as in the type-level example.
