#### HTTP Methods

- **GET**: For simple invocations without request body
- **POST**: Required when providing ViewDefinition resource or resources to transform

#### GET Method Limitations

When using the GET method, the following limitations apply:

1. **No Request Body Parameters**: GET requests cannot include parameters that require a request body:
   - Cannot provide `viewResource` parameter (inline ViewDefinition)
   - Cannot provide `resource` parameter (direct resources to transform)
2. **Available Parameters**: Only parameters that can be passed as query parameters are supported:
   - `viewCanonical` - Canonical URL of the ViewDefinition, with any `|` percent-encoded as `%7C`
   - `viewReference` - Literal location of a ViewDefinition on the server
   - `_format` - Output format specification
   - `header` - Include CSV headers (for CSV format)
   - `patient` - Filter by patient reference, repeated to name several patients
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

#### Output Format

This operation uses the shared output-format enumeration (`json`, `ndjson`,
`csv`, `parquet`, `fhir`), content-negotiation rules, and return-representation
rules defined once in
[Common Operation Behavior](operations-common.html). Only a summary is repeated
here.

The format is selected by (in order of precedence):

- **`_format` parameter**: shortened format names (`json`, `ndjson`, `csv`, `parquet`, `fhir`)
- **`Accept` header**: standard MIME types (`application/json`, `application/x-ndjson`, `text/csv`, `application/octet-stream`, `application/fhir+json`)

Examples:

- `_format=json` or `Accept: application/json`
- `_format=ndjson` or `Accept: application/x-ndjson`
- `_format=csv` or `Accept: text/csv`
- `_format=parquet` or `Accept: application/octet-stream`
- `_format=fhir` or `Accept: application/fhir+json`

The `Accept` header also governs a second, independent axis - whether the body
is the **raw payload** (the default) or a serialized `Binary` resource envelope.
See [Content Negotiation](operations-common.html#content-negotiation).

#### Filtering

Optional filtering parameters, specified once in
[Filtering](operations-common.html#filtering) and identical on all four data
operations:

- [`patient`](operations-common.html#patient-filter) - restrict to the patient compartments of the supplied patients
- [`group`](operations-common.html#group-filter) - restrict to members of the supplied Groups
- [`_since`](operations-common.html#since-filter) - restrict to resources whose state changed after the supplied instant

`_limit` is not a filter: it caps the rows returned to the client rather than
constraining the data the view sees. Its semantics - the server's option to
impose a smaller maximum, the application of the cap after the view has been
evaluated, and that returning fewer rows is not an error - are specified once in
[Row limit](operations-common.html#row-limit) and apply identically here.

#### Response Format

- **Success (200 OK)**: Returns the raw payload in the requested format, with `Content-Type` set to the format's native media type (not a serialized `Binary` envelope unless a FHIR media type is requested - see [Return Representation](operations-common.html#return-representation))
- **Error (4xx/5xx)**: Returns `OperationOutcome` resource
- **Transfer framing**: The response of **any** format MAY use `Transfer-Encoding: chunked`. Chunked transfer is an HTTP transport choice, independent of the format; it is distinct from incremental result production. See [Streaming and Transfer Encoding](operations-common.html#streaming)
- **JSON format**: Returns an array of objects

#### Parameters

##### Input Parameters

###### Core Parameters

| Name          | Type           | Scope        | Required     | Max | Description                                                                                 |
| ------------- | -------------- | ------------ | ------------ | --- | ------------------------------------------------------------------------------------------- |
| viewCanonical | canonical      | system, type | Conditional¹ | 1   | Canonical URL of the ViewDefinition. [Details](#viewreference-clarification)                |
| viewReference | Reference      | system, type | Conditional¹ | 1   | Literal location of a ViewDefinition on the server. [Details](#viewreference-clarification) |
| viewResource  | ViewDefinition² | system, type | Conditional¹ | 1   | Inline ViewDefinition resource. [Details](#viewreference-clarification)                    |

{:.table-data}

¹ Exactly one of `viewCanonical`, `viewReference` or `viewResource` is required at
the system and type levels; none is allowed at the instance level, where the
ViewDefinition is identified by the request path. See
[Identifying the ViewDefinition](#viewreference-clarification).

² Declared as `CanonicalResource` in the OperationDefinition; see
[Why the declared type is `CanonicalResource`](operations-common.html#declared-type).

###### Output Control

| Name     | Type    | Scope                  | Required | Max | Description                                                                                           |
| -------- | ------- | ---------------------- | -------- | --- | ----------------------------------------------------------------------------------------------------- |
| \_format | code    | system, type, instance | No       | 1   | Output format: `json`, `ndjson`, `csv`, `parquet`, `fhir`. [Details](#format-parameter-clarification) |
| header   | boolean | system, type, instance | No       | 1   | Include CSV headers (default: true). Only applies to `csv` format                                     |

{:.table-data}

###### Filtering

| Name    | Type      | Scope                  | Required | Max | Description                                                                                                      |
| ------- | --------- | ---------------------- | -------- | --- | ---------------------------------------------------------------------------------------------------------------- |
| patient | Reference | system, type, instance | No       | \*  | Filter by patient reference, repeated to name several patients. [Details](operations-common.html#patient-filter) |
| group   | Reference | system, type, instance | No       | \*  | Filter by group membership. [Details](operations-common.html#group-filter)                                       |
| \_since | instant   | system, type, instance | No       | 1   | Include only resources modified after this time. [Details](operations-common.html#since-filter)                  |
| \_limit | integer   | system, type, instance | No       | 1   | Maximum number of rows to return                                                                                 |

{:.table-data}

###### Data Source

| Name     | Type     | Scope                  | Required | Max | Description                                              |
| -------- | -------- | ---------------------- | -------- | --- | -------------------------------------------------------- |
| resource | Resource | system, type, instance | No       | \*  | FHIR resources to transform (alternative to server data) |
| source   | string   | system, type, instance | No       | 1   | External data source (e.g., URI, bucket name)            |

{:.table-data}

##### Output Parameter

| Name   | Type   | Description                                                                                                                                                                                                                                  |
| ------ | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| return | Binary | Transformed data as a raw stream in the format's native media type, not a serialized `Binary` envelope (a `Parameters` resource when `_format=fhir` is requested). See [Return Representation](operations-common.html#return-representation) |

{:.table-data}

##### Identifying the ViewDefinition {#viewreference-clarification}

The ViewDefinition to execute is named in exactly one of three ways, each with
its own parameter so that the intended meaning is carried by the parameter's type
rather than inferred from the shape of a string:

| Parameter       | Type             | Names the view by                                                                                                                                                                                                                                                                                   |
| --------------- | ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `viewCanonical` | `canonical`      | Its canonical URL, optionally with a `\|version` suffix pinning a version (e.g. `http://example.org/ViewDefinition/patient_demographics\|2.0.0`). Absent a suffix, the server selects a version according to FHIR's [canonical resolution](https://hl7.org/fhir/R5/references.html#canonical) rules |
| `viewReference` | `Reference`      | A literal location: a relative URL on this server (e.g. `ViewDefinition/123`) or an absolute URL (e.g. `http://example.org/fhir/ViewDefinition/123`). This is not a canonical URL                                                                                                                   |
| `viewResource`  | `ViewDefinition`² | Carrying the ViewDefinition itself in the request                                                                                                                                                                                                                                                   |

{:.table-data}


² Declared as `CanonicalResource` in the OperationDefinition; see
[Why the declared type is `CanonicalResource`](operations-common.html#declared-type).

At the system and type levels, a request SHALL supply exactly one of the three.
Supplying none, or more than one, is rejected with `400 Bad Request` and an
`OperationOutcome` naming the problem.

At the instance level
(`[base]/ViewDefinition/[id]/$viewdefinition-run`) the ViewDefinition is
identified by the request path, so none of the three applies; supplying any of
them is rejected with `400 Bad Request`.

A `viewCanonical` or `viewReference` the server cannot resolve is rejected with
`404 Not Found` and an `OperationOutcome`. A resolved artefact that is not a
conformant ViewDefinition is rejected with `422 Unprocessable Entity`.

How a server resolves a canonical URL or an absolute reference - from a local
artefact registry, by dereferencing the URL, or not at all - is an implementation
matter. A server that supports only some of these parameters declares the subset
it supports as described in
[Declaring partial operation support](operations-capability.html#partial-operation-support).

##### Format Parameter Clarification

The supported formats (`json`, `ndjson`, `csv`, `parquet`, `fhir`), the default,
the `Accept`-vs-`_format` precedence rule, and the optional `fhir` shape are
defined in [Common Operation Behavior](operations-common.html#output-formats)
and apply to this operation:

- It is RECOMMENDED to support `json`, `ndjson` and `csv` by default; servers MAY
  support `parquet` and `fhir`, and SHALL document supported formats in the
  CapabilityStatement.
- If `_format` is omitted (and no format is derivable from `Accept`), the server
  SHALL return the result in `ndjson` format.
- When `_format` is supplied, its value SHALL take precedence over `Accept`.
- `_format=fhir` returns a `Parameters` resource with one repeating `row` per
  result row, using the
  [SQL to FHIR type mapping](OperationDefinition-SQLQueryRun.html#sql-to-fhir-type-mapping).

##### Filtering Parameter Clarification

`patient`, `group` and `_since` carry the same meaning on all four data
operations, and are specified once in
[Filtering](operations-common.html#filtering):
[`patient`](operations-common.html#patient-filter),
[`group`](operations-common.html#group-filter) and
[`_since`](operations-common.html#since-filter).

##### Resource Parameter and Bundle Inputs {#resource-parameter-clarification}

The `resource` parameter is repeatable and carries the discrete FHIR resources
to transform instead of using server data. Because a `Bundle` is itself a
`Resource`, a `Bundle` satisfies the parameter's `Resource` type. To avoid
ambiguity, the following rule applies:

When a `resource` value is a `Bundle`, the server SHALL **unwrap** it and run the
ViewDefinition against each `Bundle.entry[*].resource`, exactly as if those
entries had been supplied as individual repeated `resource` values. The
`Bundle` itself is not treated as an input resource for the ViewDefinition.

Unwrapping is applied one level deep. Resources within the bundle are evaluated
against the ViewDefinition's `resource` type just like directly supplied
resources: entries whose type does not match the ViewDefinition's `resource` are
ignored. Mixing discrete `resource` values and `Bundle` values in the same
request is permitted; the effective input is the union of the discrete
resources and every unwrapped bundle entry.

#### Examples

##### Successful Requests

###### Example 1: Instance-level GET with CSV output

```http
GET /ViewDefinition/patient-demographics/$viewdefinition-run HTTP/1.1
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

###### Example 2: Type-level POST with inline ViewDefinition

```http
POST /ViewDefinition/$viewdefinition-run HTTP/1.1
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

###### Example 3: POST with direct resources

```http
POST /ViewDefinition/$viewdefinition-run HTTP/1.1
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

###### Example 4: GET naming the view by canonical URL

`viewCanonical` is available over GET as a query parameter. The `|` that
separates the version is percent-encoded as `%7C`.

```http
GET /ViewDefinition/$viewdefinition-run?viewCanonical=http%3A%2F%2Fexample.org%2FViewDefinition%2Fpatient_demographics%7C2.0.0&_format=ndjson HTTP/1.1
```

```http
HTTP/1.1 200 OK
Content-Type: application/x-ndjson
Transfer-Encoding: chunked

{"id":"pt-1","birthDate":"1990-01-15","family":"Smith","given":"John"}
{"id":"pt-2","birthDate":"1985-03-22","family":"Johnson","given":"Mary"}
```

Omitting `%7C2.0.0` selects a version according to FHIR's canonical resolution
rules. A canonical URL the server cannot resolve returns `404 Not Found`.

###### Example 5: GET with filters

```http
GET /ViewDefinition/encounters/$viewdefinition-run?patient=Patient/123&_limit=10&_format=ndjson HTTP/1.1
```

```http
HTTP/1.1 200 OK
Content-Type: application/x-ndjson
Transfer-Encoding: chunked

{"id":"enc-1","patient":"Patient/123","status":"finished","class":"ambulatory","period_start":"2023-01-15T10:00:00Z"}
{"id":"enc-2","patient":"Patient/123","status":"finished","class":"emergency","period_start":"2023-02-20T14:30:00Z"}
{"id":"enc-3","patient":"Patient/123","status":"in-progress","class":"inpatient","period_start":"2023-03-01T08:00:00Z"}
```

###### Example 6: GET naming two patients

`patient` repeats, so a cohort of a few known patients needs no `Group`:

```http
GET /ViewDefinition/encounters/$viewdefinition-run?patient=Patient/123&patient=Patient/456&_format=csv HTTP/1.1
```

```http
HTTP/1.1 200 OK
Content-Type: text/csv

id,patient,status,period_start
enc-1,Patient/123,finished,2023-01-15T10:00:00Z
enc-4,Patient/456,finished,2023-04-02T09:00:00Z
```

The result is restricted to those two patients' compartments. Over POST the same
filter is expressed by repeating the `patient` parameter in the `Parameters` body.

###### Example 7: POST with a Bundle of resources

A `Bundle` supplied as a `resource` value is unwrapped; the ViewDefinition runs
against each entry. This request is equivalent to Example 3, which passed the
two Patients as discrete `resource` values.

```http
POST /ViewDefinition/$viewdefinition-run HTTP/1.1
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
      "resourceType": "Bundle",
      "type": "collection",
      "entry": [
        { "resource": { "resourceType": "Patient", "id": "pt-1", "name": [{"family": "Cole", "given": ["Joanie"]}], "birthDate": "2012-03-30" } },
        { "resource": { "resourceType": "Patient", "id": "pt-2", "name": [{"family": "Doe", "given": ["John"]}], "birthDate": "2012-03-30" } }
      ]
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

#### Error Handling

##### HTTP Status Codes

The operation uses standard HTTP status codes to indicate the outcome:

| Status Code               | Description          | When to Use                                                                                                                                                                   |
| ------------------------- | -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 200 OK                    | Success              | Operation completed successfully, results returned                                                                                                                            |
| 400 Bad Request           | Client Error         | Invalid parameters, unsupported parameters, or malformed request; no subject form supplied at system or type level, more than one supplied, or any supplied at instance level; a `patient` or `group` naming a resource the server cannot find (see [Status code for a value that cannot be resolved](operations-common.html#filter-resolution-errors)) |
| 404 Not Found             | Not Found            | ViewDefinition not found: the instance named by the request path, or an unresolvable `viewCanonical` or `viewReference`                                                       |
| 422 Unprocessable Entity  | Business Logic Error | Valid request but ViewDefinition is invalid or cannot be processed                                                                                                            |
| 500 Internal Server Error | Server Error         | Unexpected server error during processing                                                                                                                                     |

{:.table-data}

All error responses (4xx and 5xx) SHOULD include an `OperationOutcome` resource providing details about the error.

##### Common Error Scenarios

###### 1. Unsupported Parameters

When the server does not support certain parameters, it should return `400 Bad Request`:

```http
GET /ViewDefinition/123/$viewdefinition-run?_since=2021-01-01 HTTP/1.1
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

###### 2. Invalid ViewDefinition

When the provided ViewDefinition is invalid, return `422 Unprocessable Entity`:

```http
POST /ViewDefinition/$viewdefinition-run HTTP/1.1
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

###### 3. ViewDefinition Not Found

When the referenced ViewDefinition does not exist:

```http
GET /ViewDefinition/non-existent/$viewdefinition-run HTTP/1.1
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

###### 4. Missing Required Parameters

When required parameters are missing:

```http
POST /ViewDefinition/$viewdefinition-run HTTP/1.1
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
      "diagnostics": "Exactly one of viewCanonical, viewReference or viewResource is required when invoking at type level"
    }
  ]
}
```

###### 5. Invalid Format

When an unsupported format is requested:

```http
GET /ViewDefinition/123/$viewdefinition-run?_format=xml HTTP/1.1
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
      "diagnostics": "Format 'xml' is not supported. Supported formats: json, ndjson, csv, parquet, fhir",
      "expression": ["_format"]
    }
  ]
}
```

###### 6. Patient Not Found

When filtering by a patient that doesn't exist:

```http
GET /ViewDefinition/lab-results/$viewdefinition-run?patient=Patient/non-existent HTTP/1.1
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

The same condition returns `400 Bad Request` on all four data operations,
because a filter value scopes the data rather than naming what the operation is
about; see
[Status code for a value that cannot be resolved](operations-common.html#filter-resolution-errors).

###### 7. Resource Processing Errors

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
