Export one or more subjects - ViewDefinitions, SQLQuery Libraries and SQLView
Libraries, in any mixture - as a single asynchronous job, using the FHIR
Asynchronous Interaction Request Pattern.

**Use Cases:**

- Exporting a mixed analytics bundle, the views and the queries over them, as one job whose outputs can be joined
- Large-scale SQL query execution against ViewDefinition tables
- Long-running analytical queries that would time out synchronously
- Exporting subjects that depend on artefacts the server cannot itself resolve

**Endpoint:**

The operation is invoked at the system level only. Subjects are named by the
repeating `subject` parameter rather than by the request path.

| Endpoint                  | Subjects named by                                                                                                                                                     |
| ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `POST [base]/$sql-export` | `subject` parameter (1..\*), each repetition naming a ViewDefinition, SQLQuery or SQLView by `subjectCanonical`, `subjectReference` or `subjectResource` |

**Execution Flow:**

1. Client sends request with `Prefer: respond-async` header
2. Server returns `202 Accepted` with `Content-Location` polling URL
3. Client polls for status until the poll returns `303 See Other` with the result URL in the `Location` header
4. Client fetches the result URL, which returns the manifest with `200 OK`
5. Client downloads exported files from the `output.location` URLs in the manifest

**Key Features:**

- **Mixed-subject batching** - one job exports any mixture of ViewDefinitions, SQLQuery Libraries and SQLView Libraries, each named by a `subject` repetition and each producing one manifest entry
- **One snapshot** - every subject in the job is computed against a single consistent view of the data, so two outputs of one job can be joined without a skew window
- **One set of filters** - `patient`, `group` and `_since` are stated once and apply to every subject
- **Job-wide supporting artefacts** - the repeating `context` parameter supplies artefacts the server cannot itself resolve, once for the whole job however many subjects depend on them
- **Per-subject parameters** - each `subject` repetition carries its own `parameters` resource
- **Client tracking** - `clientTrackingId` is echoed in the manifest, correlating the job with the client's own records
