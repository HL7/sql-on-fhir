#### HTTP Methods

- **GET**: for invocations in which every supplied input parameter is primitive.
- **POST**: required when `subjectResource`, `parameters`, `context` or
  `resource` is supplied, since each carries a resource that cannot be expressed
  as a query string.

`$sql-run` is a safe operation, so base FHIR permits `GET` whenever the supplied
in-parameters are all primitive. The subject is named by a parameter at every
invocation, so a `GET` is available for a ViewDefinition subject and a SQL
subject alike.

##### GET Method Limitations

1. **Available parameters**: only those that can be passed as query parameters
   are supported over `GET`:
   - `subjectCanonical` - canonical URL of the ViewDefinition, SQLQuery or
     SQLView, with any `|` percent-encoded as `%7C`
   - `subjectReference` - literal location of the subject on the server
   - `_format` - output format specification
   - `header` - include CSV headers (for CSV format)
   - `patient` - filter by patient reference, repeated to name several patients
   - `group` - filter by group membership
   - `_since` - filter by last updated time
   - `_limit` - limit the number of result rows
   - `source` - external data source

2. **When POST is required**: use `POST` instead of `GET` when you need to:
   - name the subject inline via `subjectResource`
   - bind parameter values via `parameters`
   - supply a supporting artefact inline via `context`
   - supply FHIR resources to transform via `resource`

   Each of those four carries a resource, which is the reason it cannot be
   expressed as a query string. Supplying one over `GET` is rejected with
   `400 Bad Request`.

#### Data Sources

The operation can process data from:

1. **Direct resources** - Provided via the `resource` parameter in the request, where the subject is a ViewDefinition
2. **Server resources** - From the server's data store (default)
3. **External source** - Specified via the `source` parameter

#### Input Parameters

The following input parameters are passed as query parameters on a `GET`, or
inside a `Parameters` resource in the request body on a `POST`.

| Name             | Type                                   | Min | Max | Description                                                                                       |
| ---------------- | -------------------------------------- | --- | --- | ----------------------------------------------------------------------------------------------- |
| subjectCanonical | canonical                              | 0¹  | 1   | Canonical URL of the subject. [Details](#subject-clarification)                                   |
| subjectReference | Reference                              | 0¹  | 1   | Literal location of the subject on the server. [Details](#subject-clarification)                  |
| subjectResource  | ViewDefinition \| SQLQuery \| SQLView² | 0¹  | 1   | Inline subject resource. [Details](#subject-clarification)                                        |
| parameters       | Parameters                             | 0   | 1   | Parameter values bound by name to those the Library declares; requires a SQL subject. [Details](#parameter-passing) |
| context          | ViewDefinition \| SQLView²             | 0   | \*  | Inline supporting artefact, matched to a dependency by canonical URL. [Details](#supporting-artefacts) |
| resource         | Resource                               | 0   | \*  | FHIR resources to transform; requires a ViewDefinition subject. [Details](#resource-parameter-clarification) |
| \_format         | code                                   | 0   | 1   | Output format: `json`, `ndjson`, `csv`, `parquet`, `fhir`. [Details](#format-parameter-clarification) |
| header           | boolean                                | 0   | 1   | Include CSV headers (default: true). Only applies to `csv` format                                 |
| patient          | Reference                              | 0   | \*  | Filter by patient reference, repeated to name several patients. [Details](#filtering)             |
| group            | Reference                              | 0   | \*  | Filter by group membership. [Details](#filtering)                                                 |
| \_since          | instant                                | 0   | 1   | Include only resources whose state changed after this instant. [Details](#filtering)              |
| source           | string                                 | 0   | 1   | External data source (e.g. URI, bucket name). If absent, uses server data                         |
| \_limit          | integer                                | 0   | 1   | Maximum number of rows to return. [Details](#row-limit)                                           |

{:.table-data}

¹ Exactly one of `subjectCanonical`, `subjectReference` or `subjectResource` is
required. See [Naming the subject](#subject-clarification).

² Declared as `CanonicalResource` in the OperationDefinition; see
[Why the declared type is `CanonicalResource`](operations-common.html#declared-type).

`clientTrackingId` is not offered on this operation, and it accepts one subject
rather than a repeating set; see
[Parameters that do not apply to every operation](operations-common.html#parameter-asymmetries).

##### Output Parameter

| Name   | Type   | Description                                                                                                                                                                                                                              |
| ------ | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| return | Binary | Result rows as a raw stream in the format's native media type, not a serialized `Binary` envelope (a `Parameters` resource when `_format=fhir` is requested). See [Return Representation](operations-common.html#return-representation) |

{:.table-data}

##### Naming the subject {#subject-clarification}

The artefact to execute is named in exactly one of three ways, each with its own
parameter so that the intended meaning is carried by the parameter's type rather
than inferred from the shape of a string. All three admit a
[ViewDefinition](StructureDefinition-ViewDefinition.html), a
[SQLQuery](StructureDefinition-SQLQuery.html) Library or a
[SQLView](StructureDefinition-SQLView.html) Library, so the naming form is chosen
independently of the subject's kind:

| Parameter          | Type                                   | Names the subject by                                                                                                                                                                                                                                                                        |
| ------------------ | -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `subjectCanonical` | `canonical`                            | Its canonical URL, optionally with a `\|version` suffix pinning a version (e.g. `http://example.org/ViewDefinition/patient_demographics\|2.0.0`). Absent a suffix, the server selects a version according to FHIR's [canonical resolution](https://hl7.org/fhir/R5/references.html#canonical) rules |
| `subjectReference` | `Reference`                            | A literal location: a relative URL on this server (e.g. `ViewDefinition/123` or `Library/patient-bp-query`) or an absolute URL. This is not a canonical URL                                                                                                                                 |
| `subjectResource`  | ViewDefinition \| SQLQuery \| SQLView² | Carrying the artefact itself in the request                                                                                                                                                                                                                                                  |

{:.table-data}

² `subjectResource` is declared as `CanonicalResource` in the
OperationDefinition. ViewDefinition is a logical model in this guide rather than
a FHIR resource, so `ViewDefinition` is not a value `parameter.type` accepts;
`CanonicalResource` is the narrowest declared type admitting all three kinds, and
the real constraint is carried by `targetProfile`. See
[Why the declared type is `CanonicalResource`](operations-common.html#declared-type).

<span class="fhir-conformance" id="run-1">A request SHALL supply exactly one of the
three.</span> Supplying none, or more than one, is rejected with
`400 Bad Request` and an `OperationOutcome` naming the problem.

A `subjectCanonical` or `subjectReference` the server cannot resolve is rejected
with `404 Not Found` and an `OperationOutcome`. A resolved artefact conforming to
none of the three profiles is rejected with `422 Unprocessable Entity`.

What the subject resolves to determines how it is processed, and which of the
conditional parameters apply: a ViewDefinition is evaluated directly and may be
fed inline resources through [`resource`](#resource-parameter-clarification); a
SQLQuery or SQLView has its dependency graph resolved first and may have values
bound through [`parameters`](#parameter-passing).

How a server resolves a canonical URL or an absolute reference - from a local
artefact registry, by dereferencing the URL, or not at all - is an implementation
matter. A server that supports only some of these parameters declares the subset
it supports as described in
[Declaring partial operation support](operations-capability.html#partial-operation-support).

##### Supporting artefacts (`context`) {#supporting-artefacts}

Where the subject is a SQLQuery or SQLView, the tables it selects from are named
by its `relatedArtifact` entries and are normally resolved by the server. Where
the server cannot resolve one - typically because the artefact exists only on the
client - the client supplies it inline with the repeating `context` parameter,
which accepts a ViewDefinition or a
[SQLView](StructureDefinition-SQLView.html).

The matching, precedence and error rules are specified once in
[Supporting artefacts](operations-common.html#context) and apply identically here
and on [`$sql-export`](OperationDefinition-SQLExport.html). That section governs;
in outline, the supplied entries are matched by canonical URL against every
dependency in the subject's transitive dependency graph, a supplied entry
outranks an artefact the server could itself resolve, an entry that cannot be
bound or matches nothing is rejected with `400 Bad Request`, and a dependency
neither supplied nor resolvable is rejected with `404 Not Found`.

Supplying every dependency inline alongside an inline `subjectResource` makes a
fully ad-hoc query possible, with nothing stored on the server.

`context` supplies the _views_ a query reads from, not the FHIR resources those
views project. The [`resource`](#resource-parameter-clarification) parameter
carries the latter, and requires a ViewDefinition subject: extending it to a SQL
subject would need its own semantics for how supplied resources reach each
dependency view, which is deliberately deferred. See
[Parameters that do not apply to every operation](operations-common.html#parameter-asymmetries).

A ViewDefinition subject contributes no dependencies at all, so a request naming
one has nothing for `context` to match; a supplied entry would be unmatched and
rejected with `400 Bad Request`.

##### Resource parameter and Bundle inputs {#resource-parameter-clarification}

The `resource` parameter is repeatable and carries the discrete FHIR resources
to transform instead of using server data. It is permitted **only where the
subject is a ViewDefinition**; supplying it with a SQLQuery or SQLView subject is
rejected with `400 Bad Request` and an `OperationOutcome` naming `resource`,
because how inline resources would reach each dependency view of a query is not
specified.

Because a `Bundle` is itself a `Resource`, a `Bundle` satisfies the parameter's
`Resource` type. To avoid ambiguity, the following rule applies:

<span class="fhir-conformance" id="run-2">When a `resource` value is a `Bundle`, the server
SHALL **unwrap** it and run the ViewDefinition against each
`Bundle.entry[*].resource`, exactly as if those entries had been supplied as
individual repeated `resource` values.</span> The `Bundle` itself is not treated
as an input resource for the ViewDefinition.

Unwrapping is applied one level deep. Resources within the bundle are evaluated
against the ViewDefinition's `resource` type just like directly supplied
resources: entries whose type does not match the ViewDefinition's `resource` are
ignored. Mixing discrete `resource` values and `Bundle` values in the same
request is permitted; the effective input is the union of the discrete resources
and every unwrapped bundle entry.

##### Filtering {#filtering}

`patient`, `group` and `_since` restrict the data the subject sees. They carry
the same meaning here as on
[`$sql-export`](OperationDefinition-SQLExport.html), and are specified once in
[Filtering](operations-common.html#filtering):

| Parameter | Max | Restricts the data to                                                                                     |
| --------- | --- | --------------------------------------------------------------------------------------------------------- |
| `patient` | \*  | The patient compartments of the supplied patients ([details](operations-common.html#patient-filter))      |
| `group`   | \*  | Members of the supplied Groups ([details](operations-common.html#group-filter))                           |
| `_since`  | 1   | Resources whose state changed after the supplied instant ([details](operations-common.html#since-filter)) |

{:.table-data}

The filter applies to the FHIR resources feeding a view before projection. Where
the subject is a SQLQuery or SQLView, that means it applies to the resources
feeding the query's dependency views, before the SQL executes: the SQL sees
tables already narrowed to the requested scope, rather than being expected to
express the filter itself.

A `patient` or `group` naming a resource the server cannot find is rejected with
`400 Bad Request`; see
[Status code for a value that cannot be resolved](operations-common.html#filter-resolution-errors).

##### Row Limit {#row-limit}

`_limit` caps the rows the server returns to the client. Its semantics - the
server's option to impose a smaller maximum, the application of the cap after the
subject has been evaluated, and that returning fewer rows is not an error - are
specified once in
[Row limit](operations-common.html#row-limit) and apply identically here.

Where the subject is a SQLQuery or SQLView, "after the subject has been
evaluated" includes any in-query `LIMIT`: implementations are free to push the
cap down into the SQL as an optimisation, but the observable behaviour is
post-evaluation. A worked example is given under
[Capping result rows with `_limit`](#limit-example).

##### Format Parameter Clarification

The supported formats (`json`, `ndjson`, `csv`, `parquet`, `fhir`), the default,
the `Accept`-vs-`_format` precedence rule, the raw-vs-envelope representation
axis, and transfer framing are defined in
[Common Operation Behavior](operations-common.html) and apply identically to
this operation:

- <span class="fhir-conformance" id="run-3">It is RECOMMENDED to support `json`, `ndjson` and
  `csv` by default; servers MAY support `parquet` and `fhir`, and SHALL document
  supported formats in the CapabilityStatement.</span>
- <span class="fhir-conformance" id="run-4">If `_format` is omitted (and no format is
  derivable from `Accept`), the server SHALL return the result in `ndjson`
  format.</span>
- <span class="fhir-conformance" id="run-5">When `_format` is supplied, its value SHALL take
  precedence over `Accept`.</span>
- `_format=fhir` returns a `Parameters` resource with one repeating `row` per
  result row, using the
  [SQL to FHIR type mapping](#sql-to-fhir-type-mapping).
- <span class="fhir-conformance" id="run-6">The response of any format MAY use
  `Transfer-Encoding: chunked`;</span> chunked transfer is independent of the
  format. See
  [Streaming and Transfer Encoding](operations-common.html#streaming).

#### Examples

##### Running a ViewDefinition over GET

Every parameter here is primitive, so the invocation fits in a query string. The
`|` separating the canonical URL from its version is percent-encoded as `%7C`:

```http
GET /$sql-run?subjectCanonical=http%3A%2F%2Fexample.org%2FViewDefinition%2Fpatient_demographics%7C2.0.0&patient=Patient/123&_limit=10&_format=csv HTTP/1.1
```

```http
HTTP/1.1 200 OK
Content-Type: text/csv
Transfer-Encoding: chunked

id,birthDate,family,given
pt-1,1990-01-15,Smith,John
pt-2,1985-03-22,Johnson,Mary
```

Omitting `%7C2.0.0` selects a version according to FHIR's canonical resolution
rules. A canonical URL the server cannot resolve returns `404 Not Found`.

##### Running a SQLQuery over GET

The same endpoint and the same parameter serve a SQL subject; only what the
canonical URL resolves to differs:

```http
GET /$sql-run?subjectCanonical=http%3A%2F%2Fexample.org%2FLibrary%2Fpatient-bp-query%7C1.0.0&_format=csv HTTP/1.1
Accept: text/csv
```

```http
HTTP/1.1 200 OK
Content-Type: text/csv

patient_id,systolic,effective_date
Patient/123,120,2024-01-15
Patient/123,118,2024-02-20
```

Supplying `parameters`, `context`, `resource` or `subjectResource` takes the
request outside the `GET`-available subset, because each carries a resource; use
`POST` in that case.

##### Running a SQLQuery with bound parameters over POST

```http
POST /$sql-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "subjectCanonical", "valueCanonical": "http://example.org/Library/patient-bp-query|1.0.0" },
    { "name": "parameters", "resource": {
      "resourceType": "Parameters",
      "parameter": [
        { "name": "from_date", "valueDate": "2026-01-01" }
      ]
    }},
    { "name": "_format", "valueCode": "ndjson" }
  ]
}
```

```http
HTTP/1.1 200 OK
Content-Type: application/x-ndjson

{"patient_id":"Patient/123","systolic":120,"effective_date":"2026-01-15"}
{"patient_id":"Patient/123","systolic":118,"effective_date":"2026-02-20"}
```

The values are bound by name to the parameters the Library declares. Supplying
`parameters` where the subject is a ViewDefinition is rejected with
`400 Bad Request`.

##### Naming the subject by literal reference

```http
POST /$sql-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "_format", "valueCode": "json" },
    { "name": "subjectReference", "valueReference": {
      "reference": "Library/patient-bp-query"
    }},
    { "name": "parameters", "resource": {
      "resourceType": "Parameters",
      "parameter": [
        { "name": "patient_id", "valueString": "Patient/123" }
      ]
    }}
  ]
}
```

##### Running an inline ViewDefinition

Pass the ViewDefinition itself in the request as `subjectResource`:

```http
POST /$sql-run HTTP/1.1
Accept: application/json
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [{
    "name": "subjectResource",
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

##### Running a ViewDefinition over inline resources

The subject is an inline ViewDefinition and the data is supplied in the same
request, so nothing is stored on the server:

```http
POST /$sql-run HTTP/1.1
Accept: text/csv
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [{
    "name": "subjectResource",
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
      "name": [{ "use": "official", "family": "Cole", "given": ["Joanie"] }],
      "birthDate": "2012-03-30"
    }
  },
  {
    "name": "resource",
    "resource": {
      "resourceType": "Patient",
      "id": "pt-2",
      "name": [{ "use": "official", "family": "Doe", "given": ["John"] }],
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

##### Supplying inline resources as a Bundle

A `Bundle` supplied as a `resource` value is unwrapped one level; the
ViewDefinition runs against each entry. This request is equivalent to the one
above, which passed the two Patients as discrete `resource` values:

```http
POST /$sql-run HTTP/1.1
Accept: text/csv
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [{
    "name": "subjectResource",
    "resource": {
      "resourceType": "ViewDefinition",
      "resource": "Patient",
      "select": [{
        "column": [
          {"name": "id", "type": "id", "path": "getResourceKey()"},
          {"name": "family", "type": "string", "path": "name.family"}
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
        { "resource": { "resourceType": "Patient", "id": "pt-1", "name": [{"family": "Cole"}] } },
        { "resource": { "resourceType": "Patient", "id": "pt-2", "name": [{"family": "Doe"}] } }
      ]
    }
  },
  { "name": "_format", "valueCode": "csv" }]
}
```

```http
HTTP/1.1 200 OK
Content-Type: text/csv

id,family
pt-1,Cole
pt-2,Doe
```

Supplying `resource` alongside a SQLQuery or SQLView subject is rejected with
`400 Bad Request`.

##### Fully ad-hoc: an inline query with an inline supporting artefact

Nothing is stored on the server. The query is supplied as `subjectResource` and
the ViewDefinition its `relatedArtifact` entry depends on is supplied as
`context`, matched to that entry by `url` and bound to table `p`:

```http
POST /$sql-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "_format", "valueCode": "csv" },
    { "name": "subjectResource", "resource": {
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
    }},
    { "name": "context", "resource": {
      "resourceType": "ViewDefinition",
      "url": "https://example.org/ViewDefinition/patient_view",
      "status": "active",
      "resource": "Patient",
      "select": [{ "column": [
        { "name": "id", "path": "getResourceKey()", "type": "string" },
        { "name": "name", "path": "name.family.first()", "type": "string" },
        { "name": "active", "path": "active", "type": "boolean" }
      ]}]
    }}
  ]
}
```

```http
HTTP/1.1 200 OK
Content-Type: text/csv

id,name
pt-1,Smith
pt-2,Johnson
```

##### Transitive resolution through a supplied SQLView

A supplied SQLView brings dependencies of its own, so the entries are matched
against the whole transitive graph. Here the first entry binds to table `ap`;
traversing it reveals a dependency that the second entry satisfies as table `p`.
Both entries were selected, so neither is unmatched. The resources are
abbreviated to the elements that drive matching:

```http
POST /$sql-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "subjectResource", "resource": {
      "resourceType": "Library",
      "relatedArtifact": [
        { "type": "depends-on", "resource": "https://example.org/SQLView/active_patients", "label": "ap" }
      ]
    }},
    { "name": "context", "resource": {
      "resourceType": "Library",
      "url": "https://example.org/SQLView/active_patients",
      "relatedArtifact": [
        { "type": "depends-on", "resource": "https://example.org/ViewDefinition/patient_view", "label": "p" }
      ]
    }},
    { "name": "context", "resource": {
      "resourceType": "ViewDefinition",
      "url": "https://example.org/ViewDefinition/patient_view"
    }}
  ]
}
```

##### An unmatched context entry is rejected

A typo in a supplied `url` binds to no dependency, and is reported where the
mistake was made rather than resurfacing later as an SQL error naming table `p`
as missing:

```http
POST /$sql-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "subjectResource", "resource": {
      "resourceType": "Library",
      "relatedArtifact": [
        { "type": "depends-on", "resource": "https://example.org/ViewDefinition/patient_view", "label": "p" }
      ]
    }},
    { "name": "context", "resource": {
      "resourceType": "ViewDefinition",
      "url": "https://example.org/ViewDefinition/patient_veiw"
    }}
  ]
}
```

```http
HTTP/1.1 400 Bad Request
Content-Type: application/fhir+json

{
  "resourceType": "OperationOutcome",
  "issue": [{
    "severity": "error",
    "code": "invalid",
    "diagnostics": "Supplied context entry 'https://example.org/ViewDefinition/patient_veiw' does not match any relatedArtifact dependency of the subject",
    "expression": ["context"]
  }]
}
```

##### Naming two patients over GET

`patient` repeats, so a cohort of a few known patients needs no `Group`:

```http
GET /$sql-run?subjectCanonical=http%3A%2F%2Fexample.org%2FViewDefinition%2Fencounters&patient=Patient/123&patient=Patient/456&_format=csv HTTP/1.1
```

```http
HTTP/1.1 200 OK
Content-Type: text/csv

id,patient,status,period_start
enc-1,Patient/123,finished,2023-01-15T10:00:00Z
enc-4,Patient/456,finished,2023-04-02T09:00:00Z
```

The result is restricted to those two patients' compartments. Over `POST` the
same filter is expressed by repeating the `patient` parameter in the
`Parameters` body. The filters apply to the resources feeding the view before
projection, and where the subject is a query, before the SQL executes.

##### Capping result rows with `_limit` {#limit-example}

Use `_limit` to ask the server to return at most a given number of rows. The
server may return fewer rows if the subject yields fewer or if its configured
maximum is smaller; see [Row Limit](#row-limit) for the full semantics.

```http
POST /$sql-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "subjectReference", "valueReference": { "reference": "Library/patient-bp-query" } },
    { "name": "_format", "valueCode": "csv" },
    { "name": "_limit", "valueInteger": 100 }
  ]
}
```

##### Default format (`_format` omitted)

When `_format` is omitted and no format is derivable from `Accept`, the server
returns the result in `ndjson` format:

```http
POST /$sql-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "subjectReference", "valueReference": { "reference": "Library/patient-bp-query" } },
    { "name": "parameters", "resource": {
      "resourceType": "Parameters",
      "parameter": [
        { "name": "patient_id", "valueString": "Patient/123" }
      ]
    }}
  ]
}
```

```http
HTTP/1.1 200 OK
Content-Type: application/x-ndjson

{"patient_id":"Patient/123","systolic":120,"effective_date":"2024-01-15"}
{"patient_id":"Patient/123","systolic":118,"effective_date":"2024-02-20"}
```

##### Response

For flat formats (`csv`, `json`, `ndjson`, `parquet`), the response body is the
raw payload in the format's native media type (the `Binary` stream), not a
serialized `Binary` resource envelope; `Content-Type` is set to that media type.
<span class="fhir-conformance" id="run-7">The response MAY be sent with
`Transfer-Encoding: chunked` regardless of format.</span>
See [Return Representation](operations-common.html#return-representation) and
[Streaming](operations-common.html#streaming).

```http
HTTP/1.1 200 OK
Content-Type: text/csv

patient_id,systolic,effective_date
Patient/123,120,2024-01-15
Patient/123,118,2024-02-20
```

##### FHIR Format Response

When `_format=fhir`, the response is a FHIR Parameters resource with each row as a
repeating `row` parameter.

```http
POST /$sql-run HTTP/1.1
Content-Type: application/fhir+json

{
  "resourceType": "Parameters",
  "parameter": [
    { "name": "subjectReference", "valueReference": { "reference": "Library/patient-bp-query" } },
    { "name": "_format", "valueCode": "fhir" },
    { "name": "parameters", "resource": {
      "resourceType": "Parameters",
      "parameter": [
        { "name": "patient_id", "valueString": "Patient/123" }
      ]
    }}
  ]
}
```

Response:

```json
{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "row",
      "part": [
        { "name": "patient_id", "valueString": "Patient/123" },
        { "name": "systolic", "valueInteger": 120 },
        { "name": "effective_date", "valueDate": "2024-01-15" }
      ]
    },
    {
      "name": "row",
      "part": [
        { "name": "patient_id", "valueString": "Patient/123" },
        { "name": "systolic", "valueInteger": 118 },
        { "name": "effective_date", "valueDate": "2024-02-20" }
      ]
    }
  ]
}
```

When a subject returns zero rows, the response is a Parameters resource with no
`parameter` elements:

```json
{
  "resourceType": "Parameters"
}
```

#### SQL to FHIR type mapping

When `_format=fhir`, each result column SHALL be encoded using a FHIR `value[x]`
type. The following table defines the mapping from
[ISO/IEC 9075](https://www.iso.org/standard/76583.html) SQL types to FHIR
parameter value types.

| ISO/IEC 9075 SQL type                                | FHIR value type     |
| ---------------------------------------------------- | ------------------- |
| BOOLEAN                                              | `valueBoolean`      |
| TINYINT, SMALLINT, INT, INTEGER                      | `valueInteger`      |
| BIGINT                                               | `valueInteger64`    |
| DECIMAL, NUMERIC                                     | `valueDecimal`      |
| REAL                                                 | `valueDecimal`      |
| FLOAT, DOUBLE PRECISION                              | `valueDecimal`      |
| CHARACTER, CHARACTER VARYING, CHARACTER LARGE OBJECT | `valueString`       |
| BINARY, BINARY VARYING, BINARY LARGE OBJECT          | `valueBase64Binary` |
| DATE                                                 | `valueDate`         |
| TIME, TIME WITH TIME ZONE                            | `valueTime`         |
| TIMESTAMP                                            | `valueDateTime`     |
| TIMESTAMP WITH TIME ZONE                             | `valueInstant`      |

{:.table-data}

SQL NULL values are represented by omitting the corresponding part from the row
parameter.

Conversion of REAL, FLOAT, and DOUBLE PRECISION values to `valueDecimal` may
introduce representation artifacts due to the difference between binary and
decimal floating point.

TIMESTAMP WITH TIME ZONE values may carry sub-millisecond precision (e.g.
microseconds), but FHIR `instant` supports at most millisecond precision.
<span class="fhir-conformance" id="run-8">Implementations SHOULD round to the nearest
millisecond when converting to `valueInstant`.</span>

TIMESTAMP (without time zone) values are converted to `valueDateTime` without a
timezone offset. FHIR `dateTime` permits values with or without a timezone, so
the absence of timezone information is preserved rather than trying to infer a
time zone.

ISO/IEC 9075 types not listed in this table (such as INTERVAL, ARRAY, XML, ROW,
and MULTISET) are not supported. If a query produces a result column with an
unsupported type, the server MUST return a `422 Unprocessable Entity` error.
Query authors can work around this by casting unsupported types to a supported
type within the SQL query.

#### Parameter Passing

Parameter values are passed as a nested `Parameters` resource, following the same
pattern as the
[CQL `$evaluate` operation](https://hl7.org/fhir/uv/cql/OperationDefinition-cql-library-evaluate.html).
See [Parameter Types](StructureDefinition-SQLQuery.html#parameter-types) on the
SQLQuery profile for the binding rules and the mapping from
`Library.parameter.type` to the `value[x]` element to use.

`parameters` binds by name to the parameters the subject declares in
`Library.parameter`, so it requires a SQLQuery or SQLView subject. A
ViewDefinition declares no `Library.parameter`, so there is nothing for a value
to bind to, and supplying `parameters` alongside a ViewDefinition subject is
rejected with `400 Bad Request` and an `OperationOutcome` naming `parameters`.

Binding values to a ViewDefinition's `constant` elements is deliberately out of
scope. A `ViewDefinition.constant` already carries a value, so supplying one
here would be substitution of a set value rather than binding of an unbound
placeholder - a different semantic that deserves its own proposal.

#### Error Handling

| Status                      | `issue.code`    | `expression`  | Condition                                                                                                                                     |
| --------------------------- | --------------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `400 Bad Request`           | `required`      | subject       | No subject supplied                                                                                                                           |
| `400 Bad Request`           | `invalid`       | subject       | More than one of `subjectCanonical`, `subjectReference` and `subjectResource` supplied                                                        |
| `400 Bad Request`           | `invalid`       | `parameters`  | Supplied where the subject is a ViewDefinition                                                                                                |
| `400 Bad Request`           | `invalid`       | `parameters`  | A parameter name the subject does not declare, or a value whose type does not match the declared type                                         |
| `400 Bad Request`           | `invalid`       | `resource`    | Supplied where the subject is a SQLQuery or SQLView                                                                                           |
| `400 Bad Request`           | `invalid`       | `context`     | An entry with no `url`, two entries sharing a `url`, or an entry matching no dependency of the subject                                        |
| `400 Bad Request`           | `invalid`       | the parameter | A resource-carrying parameter supplied over `GET`                                                                                             |
| `400 Bad Request`           | `not-found`     | `patient`     | A `patient` naming a resource the server cannot find (see [Status code for a value that cannot be resolved](operations-common.html#filter-resolution-errors)) |
| `400 Bad Request`           | `not-found`     | `group`       | A `group` naming a resource the server cannot find                                                                                            |
| `400 Bad Request`           | `not-supported` | the parameter | A parameter the server does not support (see [Declaring partial operation support](operations-capability.html#partial-operation-support))     |
| `400 Bad Request`           | `not-supported` | `_format`     | A format the server does not support                                                                                                          |
| `404 Not Found`             | `not-found`     | subject       | An unresolvable `subjectCanonical` or `subjectReference`                                                                                      |
| `404 Not Found`             | `not-found`     | -             | A dependency neither supplied as a `context` entry nor resolvable by the server                                                               |
| `406 Not Acceptable`        | `not-supported` | -             | An envelope representation the server declines for the chosen format (see [Content Negotiation](operations-common.html#content-negotiation))  |
| `422 Unprocessable Entity`  | `invalid`       | subject       | A resolved artefact conforming to none of ViewDefinition, SQLQuery or SQLView                                                                 |
| `422 Unprocessable Entity`  | `invalid`       | subject       | A conformant subject that cannot be processed, such as an invalid FHIRPath expression or an SQL syntax error                                  |
| `422 Unprocessable Entity`  | `invalid`       | -             | A result column of an SQL type with no `value[x]` mapping, where `_format=fhir` (see [type mapping](#sql-to-fhir-type-mapping))               |
| `500 Internal Server Error` | `exception`     | -             | Unexpected server error                                                                                                                       |

{:.table-data}

<span class="fhir-conformance" id="run-9">All error responses (4xx and 5xx) SHOULD include
an `OperationOutcome` resource providing details about the error.</span> Where a
request carries both an unresolvable subject and an unresolvable filter value,
the subject failure is the more fundamental: the response is `404 Not Found` and
the `OperationOutcome` reports both issues.
