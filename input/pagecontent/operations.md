# SQL on FHIR API

## Overview

This document defines a standard HTTP API for interacting with SQL on FHIR systems,
including FHIR servers and ViewDefinition runners.

This is a normative specification that defines conformance
requirements for implementing ViewDefinition functionality in compliant systems.

The following list of API endpoints are defined:

- CapabilityStatement
- Operation $sql-run, at the system level
- Operation $sql-export, at the system level

Both data operations act on a **subject**: a ViewDefinition, a
[SQLQuery](StructureDefinition-SQLQuery.html) Library or a
[SQLView](StructureDefinition-SQLView.html) Library. The subject is named by a
parameter rather than by the request path, so one operation serves all three
artefact kinds.

## Use Cases

### Use Case 1: Discovery

Clients can discover supported capabilities of the server by requesting the CapabilityStatement resource
on standard FHIR server endpoint - `/metadata`.

- Discover supported operations
- Discover supported ViewDefinitions
- Discover supported output formats

[See CapabilityStatement](#capabilitystatement)

### Use Case 2: Exporting a Mixed Analytics Bundle

An analytics team maintains a reporting bundle of ViewDefinitions that flatten
FHIR resources into tables, and SQLQuery Libraries that join and aggregate those
tables. The whole bundle is exported as one job.

The point of one job is the shared snapshot. Every subject in a job is computed
against a single consistent view of the data, so a view output and a query output
can be joined on a shared key without a skew window - which two separate export
jobs, seeing the data at two different points in time, cannot offer. One job also
means one set of filters, one polling loop, one export identifier and one
manifest.

**Flow:**

1. The client submits one `$sql-export` request naming every artefact as a
   repetition of the `subject` parameter, with `patient`, `group` and `_since`
   stated once for the job and `Prefer: respond-async`.
2. The server returns `202 Accepted` with a `Content-Location` header pointing to
   one status URL.
3. The client polls that URL until it returns `303 See Other` with the result URL.
4. The client fetches the result URL and receives one manifest carrying one
   `output` entry per subject, correlated by name.
5. The client downloads each output and joins them.

[See Async Bulk Export](OperationDefinition-SQLExport.html)

### Use Case 3: Bulk Export for Reporting and Analysis

Clients can efficiently transform and export FHIR data in flattened format (csv, parquet, ndjson)
described in ViewDefinitions into file storage (like S3, GCS, Azure Blob Storage, etc).
And use standard tools like Apache Spark, AWS Athena or other tools to analyze data or load data into data warehouses.

**Flow:**

1. The client initiates an asynchronous bulk export operation by submitting
   a list of subjects to the server with `Prefer: respond-async` header.
2. The server returns `202 Accepted` with `Content-Location` header pointing to status URL.
3. The client polls the status URL:
   - <span class="fhir-conformance" id="ops-1">Server returns `202 Accepted` while processing (MAY include interim results)</span>
   - Server returns `303 See Other` with a `Location` header carrying the result URL when the export has finished
4. The client fetches the result URL, which returns the manifest (output URLs) with `200 OK`.
5. The client reads the output URLs from the manifest.
6. The client can then:
   - Download exported files from the output URLs
   - Load them into a data warehouse or analyze with tools like Apache Spark or Amazon Athena

[See Async Bulk Export](OperationDefinition-SQLExport.html)

### Use Case 4: Real-time Evaluation of ViewDefinition

Client can request real-time evaluation of ViewDefinition and process streamed results. For example,
AI applications can use this to process patient data in real-time by requesting flat conditions,
observations and medications as they are recorded.

**Flow:**

1. The client initiates a real-time evaluation of a ViewDefinition by naming it as the subject of a run request.
2. The server:
   - Processes the ViewDefinition
   - Responds with the results of the evaluation
3. The client can process streamed results on fly.

[See Run](OperationDefinition-SQLRun.html)

### Use Case 5: Authoring & Debugging ViewDefinition

Developers or developer tools can test and refine ViewDefinitions interactively by evaluating them in real-time.

**Flow:**

1. The client initiates a real-time evaluation of a ViewDefinition by supplying it inline as the subject of a run request.
2. The server:
   - Processes the ViewDefinition
   - Responds with the results of the evaluation

[See Run](OperationDefinition-SQLRun.html)

### Use Case 6: Bulk Reports and Analytics

Client can submit an asynchronous job to the server to build views and run queries to
produce reports, quality dashboards and analytics. What's going on server is abstracted from the client.
Administrative bodies can request bulk reports for different populations and metrics from hospital systems.

**Flow:**

1. The client initiates an asynchronous request naming the queries, and the views they read from where the server cannot resolve them.
2. The server:
   - Processes the request
   - Builds views and runs queries
   - Responds with the results
3. The client can poll results

[See Async Bulk Export](OperationDefinition-SQLExport.html)

## API

Behavior shared by the two data operations (`$sql-run` and `$sql-export`) - the
output format set, subject naming, filtering, `context` matching, return
representation, content negotiation, transfer framing, the error contract and
the asynchronous delivery flow - is specified once in
[Common Operation Behavior](operations-common.html). The operation pages below
reference it rather than restating it.

### CapabilityStatement

<span class="fhir-conformance" id="ops-2">Server SHALL support CapabilityStatement API for
discovery of supported operations.</span>

See [CapabilityStatement for SQL-on-FHIR API](operations-capability.html)

### Operation $sql-run

The `$sql-run` operation provides real-time, synchronous evaluation of a single
subject, returning the result in the requested output format. Where the subject
is a ViewDefinition it is evaluated directly, over server data or over resources
supplied inline; where it is a SQLQuery or SQLView Library its dependency graph
is resolved first and the SQL is executed against the resulting tables. The
operation suits interactive development, debugging and real-time data streaming.

It is invoked at the system level (`[base]/$sql-run`), with the subject named by
`subjectCanonical`, `subjectReference` or `subjectResource`. Both `GET` and
`POST` are supported: `GET` is available whenever every supplied parameter is
primitive, which is what keeps the operation usable from a browser or a command
line.

The operation supports the shared output formats (`json`, `ndjson`, `csv`, `parquet`) plus `fhir`, selected by the \_format parameter or, where \_format is absent, derived from the Accept header. See [Output Formats](operations-common.html#output-formats).
It can process either resources provided directly in the request or resources available on the server, with optional filtering by patient, group, or time parameters. The operation may use chunked transfer encoding for large result sets and includes comprehensive error handling through FHIR OperationOutcome resources for validation and processing errors.

See [Operation $sql-run](OperationDefinition-SQLRun.html) and the shared [Common Operation Behavior](operations-common.html).

### Operation $sql-export

The `$sql-export` operation is the asynchronous counterpart to `$sql-run`,
exporting the results of one or more subjects into formats such as CSV, NDJSON or
Parquet using the FHIR Asynchronous Interaction Request Pattern. It suits
large-scale extraction where results are delivered to file storage for analysis,
reporting or loading into a data warehouse.

It is invoked at the system level (`[base]/$sql-export`) with `POST`, since it
creates a job. Each repetition of the `subject` parameter names an artefact by
canonical URL, by a literal reference, or supplies it inline, and any mixture of
ViewDefinitions, SQLQuery Libraries and SQLView Libraries may be named in one
request. Every subject is computed against a single snapshot of the data, under
one set of filters, and produces exactly one entry in one manifest.

The export process consists of four main endpoints: start export, get export status, cancel export, and get export results.
The server processes the subjects asynchronously and provides progress updates through polling mechanisms, making it suitable for handling large datasets without blocking the client.

See [Operation $sql-export](OperationDefinition-SQLExport.html) and the shared [Common Operation Behavior](operations-common.html).
