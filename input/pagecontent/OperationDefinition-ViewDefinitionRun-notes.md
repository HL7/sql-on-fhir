#### HTTP Methods

* **GET**: For simple invocations without request body
* **POST**: Required when providing ViewDefinition resource or resources to transform

#### GET Method Limitations

When using the GET method, the following limitations apply:

1. **No Request Body Parameters**: GET requests cannot include parameters that require a request body:
   - Cannot provide `viewResource` parameter (inline ViewDefinition)
   - Cannot provide `resource` parameter (direct resources to transform)
   
2. **Available Parameters**: Only parameters that can be passed as query parameters are supported:
   - `_format` - Output format specification
   - `header` - Include CSV headers (for CSV format)
   - `patient` - Filter by patient reference
   - `group` - Filter by group membership
   - `_since` - Filter by last updated time
   - `_limit` - Limit number of result rows
   - `source` - External data source

3. **Use Cases**: GET is suitable for:
   - Instance-level invocations where the ViewDefinition is identified by the URL path
   - Simple filtering and formatting of server data
   - Quick queries without complex configuration

4. **When POST is Required**: Use POST instead of GET when you need to:
   - Provide an inline ViewDefinition via `viewResource` parameter
   - Supply resources directly via `resource` parameter for transformation
   - Pass complex parameter values that cannot be represented as query strings

#### Data Sources

The operation can process data from:
1. **Direct resources** - Provided via `resource` parameter in the request
2. **Server resources** - From the server's data store (default)
3. **External source** - Specified via `source` parameter

#### Request Format

#### Output Format

The response format is determined by (in order of precedence):

- **`_format` parameter**: Use shortened format names (`json`, `ndjson`, `csv`, `parquet`)
- **`Accept` header**: Use standard MIME types (`application/json`, `application/x-ndjson`, `text/csv`, `application/octet-stream`)

Examples:
- `_format=json` or `Accept: application/json`
- `_format=ndjson` or `Accept: application/x-ndjson`
- `_format=csv` or `Accept: text/csv`
- `_format=parquet` or `Accept: application/octet-stream`

#### Filtering

Optional filtering parameters:
* `patient` - Filter by patient reference
* `group` - Filter by group membership  
* `_since` - Filter by last updated time
* `_limit` - Limit number of result rows

#### Response Format

* **Success (200 OK)**: Returns data in requested format
* **Error (4xx/5xx)**: Returns `OperationOutcome` resource
* **Streaming**: MAY use chunked transfer encoding for large result sets
* **JSON format**: Returns an array of objects

#### Parameters

##### Input Parameters

##### Core Parameters

| Name          | Type           | Scope          | Required     | Max | Description                                                                        |
|---------------|----------------|----------------|--------------|-----|------------------------------------------------------------------------------------|
| viewReference | Reference      | type, instance | Conditional¹ | 1   | Reference to ViewDefinition on the server. [Details](#viewreference-clarification) |
| viewResource  | ViewDefinition | type           | Conditional¹ | 1   | Inline ViewDefinition resource                                                     |
{:.table-data}

¹ Either viewReference or viewResource is required at type level; neither allowed at instance level

##### Output Control

| Name    | Type    | Scope          | Required | Max | Description                                                       |
|---------|---------|----------------|----------|-----|-------------------------------------------------------------------|
| _format | code    | type, instance | Yes      | 1   | Output format: `json`, `ndjson`, `csv`, `parquet`                 |
| header  | boolean | type, instance | No       | 1   | Include CSV headers (default: true). Only applies to `csv` format |
{:.table-data}

##### Filtering

| Name    | Type      | Scope          | Required | Max | Description                                                                                |
|---------|-----------|----------------|----------|-----|--------------------------------------------------------------------------------------------|
| patient | Reference | type, instance | No       | 1   | Filter by patient reference. [Details](#patient-parameter-clarification)                   |
| group   | Reference | type, instance | No       | *   | Filter by group membership. [Details](#group-parameter-clarification)                      |
| _since  | instant   | type, instance | No       | 1   | Include only resources modified after this time. [Details](#since-parameter-clarification) |
| _limit  | integer   | type, instance | No       | 1   | Maximum number of rows to return                                                           |
{:.table-data}

##### Data Source

| Name     | Type     | Scope          | Required | Max | Description                                              |
|----------|----------|----------------|----------|-----|----------------------------------------------------------|
| resource | Resource | type, instance | No       | *   | FHIR resources to transform (alternative to server data) |
| source   | string   | type, instance | No       | 1   | External data source (e.g., URI, bucket name)            |
{:.table-data}

##### Output Parameter

| Name   | Type   | Description                                  |
|--------|--------|----------------------------------------------|
| return | Binary | The transformed data in the requested format |
{:.table-data}

##### View Reference/Resource Clarification

Only one of the `viewReference` or `viewResource` parameters can be provided.
When invoking this operation at the instance level (e.g. ViewDefinition/{id}/$run), the server SHALL automatically infer the `viewReference` parameter from the path parameter.

The `viewReference` parameter MAY be specified using any of the following formats:
* A relative URL on the server (e.g. "ViewDefinition/123")
* A canonical URL (e.g. "http://specification.org/fhir/ViewDefinition/123|1.0.0") 
* An absolute URL (e.g. "http://example.org/fhir/ViewDefinition/123")

Servers MAY choose which reference formats they support. 
Servers SHALL document which reference formats they support in their CapabilityStatement.

For servers that want to support all types of references, it is recommended to use the following algorithm:

1. If the reference is a relative URL, resolve it on the server side.
2. If the reference is an absolute URL, look up the available server Artifact registry for
   a resource with the same canonical URL and version if provided.
3. Otherwise, try to load the ViewDefinition from the provided absolute URL.

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

#### Examples

##### Successful Requests

##### Example 1: Instance-level GET with CSV output

```http
GET /ViewDefinition/patient-demographics/$run HTTP/1.1
Accept: text/csv
```

```http
HTTP/1.1 200 OK
Content-Type: text/csv
Transfer-Encoding: chunked

id,birthDate,family,given
pt-1,1990-01-15,Smith,John
pt-2,1985-03-22,Johnson,Mary
pt-3,1992-07-08,Williams,Robert
```

##### Example 2: Type-level POST with inline ViewDefinition

```http
POST /ViewDefinition/$run HTTP/1.1
Accept: application/json
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [{
    "name": "viewResource",
    "resource": {
      "resourceType": "ViewDefinition",
      "resource": "Patient",
      "select": [{
        "column": [
          {"name": "id", "type": "id", "path": "getResourceKey()"},
          {"name": "birthDate", "type": "date", "path": "birthDate"},
          {"name": "family", "type": "string", "path": "name.family"},
          {"name": "given", "type": "string", "path": "name.given"}
        ]
      }]
    }
  }]
}
```

```http
HTTP/1.1 200 OK
Content-Type: application/json

[
  {"id": "pt-1", "birthDate": "1990-01-15", "family": "Smith", "given": "John"},
  {"id": "pt-2", "birthDate": "1985-03-22", "family": "Johnson", "given": "Mary"},
  {"id": "pt-3", "birthDate": "1992-07-08", "family": "Williams", "given": "Robert"}
]
```

##### Example 3: POST with direct resources

```http
POST /ViewDefinition/$run HTTP/1.1
Accept: text/csv
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [{
    "name": "viewResource",
    "resource": {
      "resourceType": "ViewDefinition",
      "resource": "Patient",
      "select": [{
        "column": [
          {"name": "id", "type": "id", "path": "getResourceKey()"},
          {"name": "birthDate", "type": "date", "path": "birthDate"},
          {"name": "family", "type": "string", "path": "name.family"},
          {"name": "given", "type": "string", "path": "name.given"}
        ]
      }]
    }
  },
  {
    "name": "resource",
    "resource": {
      "resourceType": "Patient",
      "id": "pt-1",
      "name": [{
        "use": "official",
        "family": "Cole",
        "given": ["Joanie"]
      }],
      "birthDate": "2012-03-30"
    }
  },
  {
    "name": "resource",
    "resource": {
      "resourceType": "Patient",
      "id": "pt-2",
      "name": [{
        "use": "official",
        "family": "Doe",
        "given": ["John"]
      }],
      "birthDate": "2012-03-30"
    }
  }]
}
```

```http
HTTP/1.1 200 OK
Content-Type: text/csv

id,birthDate,family,given
pt-1,2012-03-30,Cole,Joanie
pt-2,2012-03-30,Doe,John
```

##### Example 4: GET with filters

```http
GET /ViewDefinition/encounters/$run?patient=Patient/123&_limit=10&_format=ndjson HTTP/1.1
```

```http
HTTP/1.1 200 OK
Content-Type: application/x-ndjson
Transfer-Encoding: chunked

{"id":"enc-1","patient":"Patient/123","status":"finished","class":"ambulatory","period_start":"2023-01-15T10:00:00Z"}
{"id":"enc-2","patient":"Patient/123","status":"finished","class":"emergency","period_start":"2023-02-20T14:30:00Z"}
{"id":"enc-3","patient":"Patient/123","status":"in-progress","class":"inpatient","period_start":"2023-03-01T08:00:00Z"}
```

#### Error Handling

##### HTTP Status Codes

The operation uses standard HTTP status codes to indicate the outcome:

| Status Code               | Description          | When to Use                                                        |
|---------------------------|----------------------|--------------------------------------------------------------------|
| 200 OK                    | Success              | Operation completed successfully, results returned                 |
| 400 Bad Request           | Client Error         | Invalid parameters, unsupported parameters, or malformed request   |
| 404 Not Found             | Not Found            | ViewDefinition resource not found (instance-level invocation)      |
| 422 Unprocessable Entity  | Business Logic Error | Valid request but ViewDefinition is invalid or cannot be processed |
| 500 Internal Server Error | Server Error         | Unexpected server error during processing                          |
{:.table-data}

All error responses (4xx and 5xx) SHOULD include an `OperationOutcome` resource providing details about the error.

##### Common Error Scenarios

##### 1. Unsupported Parameters

When the server does not support certain parameters, it should return `400 Bad Request`:

```http
GET /ViewDefinition/123/$run?_since=2021-01-01 HTTP/1.1
Accept: application/json
```

```http
HTTP/1.1 400 Bad Request
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "not-supported",
      "diagnostics": "The server does not support the _since parameter",
      "expression": ["_since"]
    }
  ]
}
```

##### 2. Invalid ViewDefinition

When the provided ViewDefinition is invalid, return `422 Unprocessable Entity`:

```http
POST /ViewDefinition/$run HTTP/1.1
Content-Type: application/fhir+json
Accept: application/json

{
  "resourceType": "Parameters",
  "parameter": [{
    "name": "viewResource",
    "resource": {
      "resourceType": "ViewDefinition",
      "resource": "Patient",
      "select": [{
        "column": [
          {"name": "id", "path": "invalid.path.syntax"}
        ]
      }]
    }
  }]
}
```

```http
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "invalid",
      "diagnostics": "The ViewDefinition is invalid: column 'id' contains invalid FHIRPath expression",
      "expression": ["viewResource.select[0].column[0].path"]
    }
  ]
}
```

##### 3. ViewDefinition Not Found

When the referenced ViewDefinition does not exist:

```http
GET /ViewDefinition/non-existent/$run HTTP/1.1
Accept: application/json
```

```http
HTTP/1.1 404 Not Found
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "not-found",
      "diagnostics": "ViewDefinition with id 'non-existent' not found"
    }
  ]
}
```

##### 4. Missing Required Parameters

When required parameters are missing:

```http
POST /ViewDefinition/$run HTTP/1.1
Content-Type: application/fhir+json
Accept: text/csv

{
  "resourceType": "Parameters",
  "parameter": []
}
```

```http
HTTP/1.1 400 Bad Request
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "required",
      "diagnostics": "Either viewReference or viewResource parameter is required when invoking at type level"
    }
  ]
}
```

##### 5. Invalid Format

When an unsupported format is requested:

```http
GET /ViewDefinition/123/$run?_format=xml HTTP/1.1
```

```http
HTTP/1.1 400 Bad Request
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "not-supported",
      "diagnostics": "Format 'xml' is not supported. Supported formats: json, ndjson, csv, parquet",
      "expression": ["_format"]
    }
  ]
}
```

##### 6. Patient Not Found

When filtering by a patient that doesn't exist:

```http
GET /ViewDefinition/lab-results/$run?patient=Patient/non-existent HTTP/1.1
Accept: application/json
```

```http
HTTP/1.1 400 Bad Request
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "not-found",
      "diagnostics": "Patient with id 'non-existent' not found",
      "expression": ["patient"]
    }
  ]
}
```

##### 7. Resource Processing Errors

When errors occur during data transformation:

```http
HTTP/1.1 500 Internal Server Error
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [
    {
      "severity": "error",
      "code": "processing",
      "diagnostics": "Error processing Patient/123: Required field 'birthDate' is missing",
      "expression": ["resource[2]"]
    }
  ]
}
```
