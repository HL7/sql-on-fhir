Execute a SQLQuery Library against ViewDefinition tables synchronously.

**Use Cases:**
* Run ad-hoc analytics queries
* Interactive query development and testing
* Real-time data retrieval with parameters

**Endpoints:**

| Level | Endpoint | Query Source |
|-------|----------|--------------|
| System | `POST [base]/$sqlquery-run` | `queryReference` or `queryResource` |
| Type | `POST [base]/Library/$sqlquery-run` | `queryReference` or `queryResource` |
| Instance | `POST [base]/Library/[id]/$sqlquery-run` | The Library instance |

**Execution Flow:**

1. Resolve ViewDefinitions from `relatedArtifact`
2. Materialize each ViewDefinition as a table
3. Bind `parameters` values to SQL placeholders
4. Execute SQL query
5. Return results in requested format (Binary for flat formats, Parameters for `_format=fhir`)

Implementations MUST ensure parameter values are safely bound to queries and not
subject to SQL injection. Use parameterized queries or equivalent safe binding
mechanisms where available. Simple string interpolation MUST NOT be used to
implement parameter binding.
