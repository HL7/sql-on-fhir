Export SQLQuery Library results asynchronously using the FHIR Asynchronous Bulk Data Request Pattern.

**Use Cases:**

- Large-scale SQL query execution against ViewDefinition tables
- Long-running analytical queries that would time out synchronously
- Batch export of multiple query results in a single operation
- Exporting queries with inline ViewDefinition table sources

**Endpoints:**

| Level    | Endpoint                                    | Query Source              |
| -------- | ------------------------------------------- | ------------------------- |
| System   | `POST [base]/$sqlquery-export`              | `query` parameter (1..\*) |
| Type     | `POST [base]/Library/$sqlquery-export`      | `query` parameter (1..\*) |
| Instance | `POST [base]/Library/[id]/$sqlquery-export` | Bound Library resource    |

**Execution Flow:**

1. Client sends request with `Prefer: respond-async` header
2. Server returns `202 Accepted` with `Content-Location` polling URL
3. Client polls for status until the poll returns `200 OK` with the manifest in the body
4. Client downloads exported files from the `output.location` URLs in the manifest

This operation combines the query source and parameter binding from
[`$sqlquery-run`](OperationDefinition-SQLQueryRun.html) with the asynchronous
export pattern from [`$viewdefinition-export`](OperationDefinition-ViewDefinitionExport.html).

**Key Features:**

- **Multiple queries** per export via the repeating `query` parameter — each with its own parameters
- **ViewDefinition table sources** via the `view` parameter — supply ViewDefinitions referenced in the Library's `relatedArtifact` entries (materialized as tables for SQL to query; only SQL query results appear in the export output)
- **Per-query parameters** — each `query` repetition can have its own `parameters` resource
