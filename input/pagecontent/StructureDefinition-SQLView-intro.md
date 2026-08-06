### Scope and Usage

Use SQLView for a reusable, named SQL query that other queries reference as a
virtual table source, analogous to a SQL view. An SQLView is a near-twin of
[SQLQuery](StructureDefinition-SQLQuery.html): it bundles SQL and its
dependencies for sharing and versioning, but it is identified by its canonical
URL so that other SQLQueries and SQLViews can build upon it.

The key differences from SQLQuery are:

- The Library `type` is fixed to `LibraryTypesCodes#sql-view`.
- <span class="fhir-conformance" id="sqlview-1">An SQLView SHALL NOT declare parameters.</span>
  Dependent views cannot be parameterised in this iteration of the
  specification.

### Boundaries and Relationships

SQLView does not define table schemas, data extraction, execution behaviour, or
APIs; those belong to ViewDefinition and its operations. An SQLView references
ViewDefinitions and other SQLViews; execution environments resolve these to
physical or virtual tables.

### Resource Content

#### Dependencies

Use `relatedArtifact` with `type = "depends-on"` to list the ViewDefinitions and
SQLViews this view builds upon. Each `resource` is the canonical URL of a
ViewDefinition or another SQLView, and each `label` defines the table name used
in the SQL.

```json
"relatedArtifact": [
  { "type": "depends-on", "resource": "https://example.org/ViewDefinition/patient_view", "label": "patient_view" },
  { "type": "depends-on", "resource": "http://hl7.org/fhir/uv/sql-on-fhir/Library/ActivePatientsView", "label": "active_patients" }
]
```

The allowed targets are recorded as a `targetProfile` on
`relatedArtifact.resource` (`Canonical(ViewDefinition or SQLView)`). Validators
enforce this whenever the canonical resolves to a known resource; for canonicals
that cannot be resolved the constraint is advisory.

#### No Parameters

<span class="fhir-conformance" id="sqlview-2">Unlike SQLQuery, an SQLView SHALL NOT declare
`Library.parameter` entries (`parameter` is constrained to `0..0`).</span> A view
is a fixed, reusable building block; callers compose with it by referencing it
from a parameterised SQLQuery.

#### SQL Attachments

Store the view's SQL in `content` exactly as for SQLQuery:
`contentType` starting with `application/sql`, the base64-encoded `data` element,
and an optional [`sql-text`](StructureDefinition-sql-text.html) extension for
human readability. Dialect-specific variants follow the same selection rules as
SQLQuery.

### Conformance

**Constraints:**

- <span class="fhir-conformance" id="sqlview-3">Library type SHALL be
  `LibraryTypesCodes#sql-view`</span>
- <span class="fhir-conformance" id="sqlview-4">`Library.parameter` SHALL be absent</span>
- <span class="fhir-conformance" id="sqlview-5">Every `content.contentType` SHALL start with
  `application/sql`</span>
- <span class="fhir-conformance" id="sqlview-6">`content.data` SHALL be present; the `sql-text`
  extension MAY carry a plain-text copy</span>
- <span class="fhir-conformance" id="sqlview-7">Dependencies SHALL use `relatedArtifact` with
  `type = "depends-on"`, a `label`, and a `resource` referencing a
  ViewDefinition or SQLView</span>

For notes on query composition, see the Notes tab below.
