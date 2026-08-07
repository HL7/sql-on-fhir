Execute one subject - a ViewDefinition, a SQLQuery Library or a SQLView Library -
synchronously, returning the result in the requested output format.

**Use Cases:**

- Interactive development and debugging of ViewDefinitions
- Running ad-hoc analytics queries
- Interactive query development and testing
- Real-time data retrieval with bound parameters

**Endpoint:**

The operation is invoked at the system level only. The subject is named by a
parameter rather than by the request path, so one endpoint serves all three
artefact kinds.

| Endpoint                | Subject named by                                                                                    |
| ----------------------- | ----------------------------------------------------------------------------------------------------- |
| `GET [base]/$sql-run`   | `subjectCanonical` or `subjectReference`, naming a ViewDefinition, SQLQuery or SQLView               |
| `POST [base]/$sql-run`  | `subjectCanonical`, `subjectReference` or `subjectResource`, naming a ViewDefinition, SQLQuery or SQLView |

`GET` is available whenever every supplied input parameter is primitive.
`subjectResource`, `parameters`, `context` and `resource` each carry a resource
and so require `POST`.

**Execution Flow:**

1. Resolve the subject named by `subjectCanonical`, `subjectReference` or `subjectResource`
2. Branch on what it resolves to:
   - A **ViewDefinition** is evaluated directly, against the supplied `resource` values where present and otherwise against server data
   - A **SQLQuery** or **SQLView** Library has each `relatedArtifact` dependency resolved first, preferring an artefact supplied inline via `context` over one the server can itself resolve, and each resolved artefact bound to the SQL identifier in the dependency's `label`
3. Bind `parameters` values to the SQL placeholders the Library declares (SQL subjects only)
4. Evaluate the view, or execute the SQL
5. Return results in the requested format (a raw stream for flat formats, a `Parameters` resource for `_format=fhir`)

<span class="fhir-conformance" id="run-intro-1">Implementations SHALL ensure parameter values are
safely bound to queries and not subject to SQL injection.</span> Use parameterized
queries or equivalent safe binding mechanisms where available.
<span class="fhir-conformance" id="run-intro-2">Simple string interpolation SHALL NOT be used to
implement parameter binding.</span>
