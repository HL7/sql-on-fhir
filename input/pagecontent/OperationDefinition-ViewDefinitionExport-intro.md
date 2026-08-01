Export FHIR data transformed by one or more ViewDefinitions asynchronously,
using the FHIR Asynchronous Interaction Request Pattern. Several ViewDefinitions
can be exported in a single operation, and the exported data is written in one
of the supported flat formats (CSV, NDJSON, Parquet, JSON).

**Use Cases:**

- Large-scale data extraction for analytics and reporting
- Loading transformed FHIR data into data warehouses
- Batch processing of ViewDefinition transformations
- Exporting filtered subsets of transformed data

**Endpoints:**

| Level    | Endpoint                                                 | View Source                                                                                                 |
| -------- | -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| System   | `POST [base]/$viewdefinition-export`                     | `view` parameter (1..\*), each naming a ViewDefinition by `viewCanonical`, `viewReference` or `viewResource` |
| Type     | `POST [base]/ViewDefinition/$viewdefinition-export`      | `view` parameter (1..\*), each naming a ViewDefinition by `viewCanonical`, `viewReference` or `viewResource` |
| Instance | `POST [base]/ViewDefinition/[id]/$viewdefinition-export` | The ViewDefinition instance named by the path                                                               |

**Execution Flow:**

1. Client sends request with `Prefer: respond-async` header
2. Server returns `202 Accepted` with `Content-Location` polling URL
3. Client polls for status until the poll returns `303 See Other` with the result URL in the `Location` header
4. Client fetches the result URL, which returns the manifest with `200 OK`
5. Client downloads exported files from the `output.location` URLs in the manifest

**Key Features:**

- **Multiple views** per export via the repeating `view` parameter, each optionally given a friendly `name` for its output entry
- **Filtering** by `patient`, `group` and `_since`, applied to the resources feeding each view before projection
- **Client-side job tracking** via `clientTrackingId`, echoed in the manifest

Where the exported files are delivered is not constrained by this
specification. Servers commonly write them to object storage or to a local file
system and expose them through the `output.location` download URLs; the manifest
is the only interface this specification defines. Any storage product named
elsewhere on this page is an informative example, not a requirement.
