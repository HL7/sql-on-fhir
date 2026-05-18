# SQL on FHIR API


## Overview

This document defines a standard HTTP API for interacting with SQL on FHIR systems, 
including FHIR servers and ViewDefinition runners.

This is a normative specification that defines conformance 
requirements for implementing ViewDefinition functionality in compliant systems.

The following list of API endpoints are defined:

- CapabilityStatement
- Operation $viewdefinition-export of ViewDefinition
- Operation $run of ViewDefinition


## Use Cases


### Use Case 1: Discovery

Clients can discover supported capabilities of the server by requesting the CapabilityStatement resource
on standard FHIR server endpoint - `/metadata`.

* Discover supported operations
* Discover supported ViewDefinitions
* Discover supported output formats

[See CapabilityStatement](#capabilitystatement)

### Use Case 2: Bulk Export for Reporting and Analysis

Clients can efficiently transform and export FHIR data in flattened format (csv, parquet, ndjson) 
described in ViewDefinitions into file storage (like S3, GCS, Azure Blob Storage, etc).
And use standard tools like Apache Spark, AWS Athena or other tools to analyze data or load data into data warehouses.

**Flow:**

1. The client initiates an asynchronous bulk export operation by submitting
   a list of ViewDefinitions to the server with `Prefer: respond-async` header.
2. The server returns `202 Accepted` with `Content-Location` header pointing to status URL.
3. The client polls the status URL:
   - Server returns `202 Accepted` while processing (MAY include interim results)
   - Server returns `303 See Other` with `Location` header when complete
4. The client follows the `Location` header to retrieve final results with output URLs.
5. The client can then:
   - Download exported files from the output URLs
   - Load them into a data warehouse or analyze with tools like Apache Spark or Amazon Athena

[See Async Bulk Export](#async-bulk-export)

### Use Case 3: Real-time Evaluation of ViewDefinition

Client can request real-time evaluation of ViewDefinition and process streamed results. For example, 
AI applications can use this to process patient data in real-time by requesting flat conditions, 
observations and medications as they are recorded.

**Flow:**

1. The client initiates a real-time evaluation of a ViewDefinition by submitting it to the server.
2. The server:
   - Processes the ViewDefinition
   - Responds with the results of the evaluation
3. The client can process streamed results on fly.

[See Run ViewDefinition](#run-viewdefinition)

### Use Case 4: Authoring & Debugging ViewDefinition

Developers or developer tools can test and refine ViewDefinitions interactively by evaluating them in real-time.

**Flow:**

1. The client initiates a real-time evaluation of a ViewDefinition by submitting it to the server.
2. The server:
   - Processes the ViewDefinition
   - Responds with the results of the evaluation

[See Run ViewDefinition](#run-viewdefinition)

### Use Case 5: Bulk Reports and Analytics

Client can submit an asynchronous job to the server to build views and run queries to 
produce reports, quality dashboards and analytics. What's going on server is abstracted from the client.
Administrative bodies can request bulk reports for different populations and metrics from hospital systems.

**Flow:**

1. The client initiates an asynchronous request to run queries on specific views.
2. The server:
   - Processes the request
   - Builds views and runs queries
   - Responds with the results
3. The client can poll results

[See Run Bulk Queries](#run-bulk-queries)

## API

### CapabilityStatement

Server MUST support CapabilityStatement API for discovery of supported operations.

See [CapabilityStatement for SQL-on-FHIR API](./api/capability.md)

### Operation $viewdefinition-export of ViewDefinition

The `$viewdefinition-export` operation enables bulk export of FHIR data transformed through ViewDefinitions into various formats including CSV, NDJSON, and Parquet.
This asynchronous operation accepts a list of ViewDefinitions to export and returns a list of export tasks that can be monitored for progress and completion.
The operation supports filtering by patient, group, or source system, and allows specification of output format and destination.

The export process consists of four main endpoints: start export, get export status, cancel export, and get export results. 
The operation is designed for large-scale data extraction scenarios where clients need to export transformed FHIR data for analysis, reporting, or loading into data warehouses.
The server processes the ViewDefinitions asynchronously and provides progress updates through polling mechanisms, making it suitable for handling large datasets without blocking the client.

See [Operation $viewdefinition-export of ViewDefinition](./operations-export.md)

### Operation $run of ViewDefinition

The `$run` operation provides real-time, synchronous evaluation of ViewDefinitions to transform FHIR resources into tabular format. 
This operation is designed for interactive development, debugging of ViewDefinitions, and real-time data streaming applications.
It can be invoked at either the type level (ViewDefinition/$run) or instance level (ViewDefinition/{id}/$run), with the ViewDefinition specified either in the request parameters or inferred from the URL path.

The operation supports multiple output formats including JSON, NDJSON, CSV, Parquet, and table formats, with the format determined by the Accept header or _format parameter. 
It can process either resources provided directly in the request or resources available on the server, with optional filtering by patient, group, or time parameters. The operation may use chunked transfer encoding for large result sets and includes comprehensive error handling through FHIR OperationOutcome resources for validation and processing errors.

See [Operation $run of ViewDefinition](./operations-run.md)