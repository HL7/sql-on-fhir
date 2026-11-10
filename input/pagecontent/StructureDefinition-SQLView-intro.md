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

SQLView does not define table schemas, data extraction, execution behavior, or
APIs; those belong to ViewDefinition and its operations. An SQLView references
ViewDefinitions, other SQLViews, ValueSets and ConceptMaps; execution
environments resolve these to physical or virtual tables. A ValueSet is exposed
to the SQL as a relation of its member codes, and a ConceptMap as a relation of
its mappings (see [Terminology in SQL](terminology-in-sql.html)).

### Resource Content

#### Dependencies

Use `relatedArtifact` with `type = "depends-on"` to list the ViewDefinitions,
SQLViews, ValueSets and ConceptMaps this view builds upon. Each `resource` is
the canonical URL of a ViewDefinition, another SQLView, a ValueSet or a
ConceptMap, and each `label` defines the table name used in the SQL.

```json
"relatedArtifact": [
  { "type": "depends-on", "resource": "https://example.org/ViewDefinition/patient_view", "label": "patient_view" },
  { "type": "depends-on", "resource": "http://hl7.org/fhir/uv/sql-on-fhir/Library/ActivePatientsView", "label": "active_patients" },
  { "type": "depends-on", "resource": "http://example.org/ValueSet/cardiovascular-disease|2026", "label": "cvd_codes" },
  { "type": "depends-on", "resource": "http://example.org/ConceptMap/sct-to-icd10|2026", "label": "sct_to_icd10" }
]
```

The allowed targets are recorded as a `targetProfile` on
`relatedArtifact.resource`
(`Canonical(ViewDefinition or SQLView or ValueSet or ConceptMap)`). Validators
enforce this whenever the canonical resolves to a known resource; for canonicals
that cannot be resolved the constraint is advisory. A ValueSet dependency is
read as a relation with the columns `system`, `version`, `code`, `display` and
`inactive`, and a ConceptMap dependency as a relation with the columns
`source_system`, `source_version`, `source_code`, `source_display`,
`target_system`, `target_version`, `target_code`, `target_display` and
`relationship`, as specified in [Terminology in SQL](terminology-in-sql.html).

#### No Parameters

<span class="fhir-conformance" id="sqlview-2">Unlike SQLQuery, an SQLView SHALL NOT declare
`Library.parameter` entries (`parameter` is constrained to `0..0`).</span> A view
is a fixed, reusable building block; callers compose with it by referencing it
from a parameterized SQLQuery.

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
  ViewDefinition, SQLView, ValueSet or ConceptMap</span>

For notes on query composition, see the Notes tab below.
