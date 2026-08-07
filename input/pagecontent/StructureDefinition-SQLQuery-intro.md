### Scope and Usage

Use SQLQuery for shareable SQL over ViewDefinition outputs and over reusable
[SQLView](StructureDefinition-SQLView.html) queries.
Each Library holds one query. For dialect-specific variants, use multiple
content attachments while keeping parameters and aliases consistent.

### Boundaries and Relationships

SQLQuery does not define table schemas, data extraction, execution behavior, or
APIs; those belong to ViewDefinition and its operations.
SQLQuery references ViewDefinitions and SQLViews; execution environments resolve
these to physical or virtual tables. An SQLView is itself a reusable named query
that other queries reference as a virtual table source, letting queries build on
one another like SQL views (see [Query Composition](StructureDefinition-SQLQuery.html#notes)
in the Notes tab).

### Resource Content

#### Dependencies

Use `relatedArtifact` with `type = "depends-on"` to list required ViewDefinitions
and SQLViews. Use `label` to define the table name in SQL. Each `resource` may
be the canonical URL of a ViewDefinition or of an
[SQLView](StructureDefinition-SQLView.html); the allowed targets are recorded as
a `targetProfile` on `relatedArtifact.resource`.

```json
"relatedArtifact": [
  { "type": "depends-on", "resource": "https://example.org/ViewDefinition/patient_view", "label": "patient" },
  { "type": "depends-on", "resource": "http://hl7.org/fhir/uv/sql-on-fhir/Library/ActivePatientsView", "label": "active_patients" }
]
```

#### Table Aliases

Each dependency requires a `label` that defines the table name used in SQL.
Labels SHALL be unique within the Library and valid SQL identifiers (start with
letter or underscore, contain only letters/digits/underscores, avoid reserved
words).

#### Parameters

Declare parameters in `Library.parameter` with `name`, `type`, and `use = "in"`.

```json
"parameter": [
  { "name": "patient_id", "type": "string", "use": "in" },
  { "name": "from_date", "type": "date", "use": "in" }
]
```

Reference parameters in SQL with colon-prefix placeholders (`:name`):

```sql
WHERE patient.id = :patient_id AND bp.effective_date >= :from_date
```

Implementations MUST ensure parameter values are safely bound to queries and not
subject to SQL injection. Use parameterized queries or equivalent safe binding
mechanisms where available. Simple string interpolation MUST NOT be used to
implement parameter binding.

#### SQL Attachments

Store the query in `content` with `contentType = "application/sql"`. The
`data` element (base64-encoded SQL) is required.
<span class="fhir-conformance" id="sqlquery-1">The
[`sql-text`](StructureDefinition-sql-text.html) extension MAY carry a
plain-text copy for human readability.</span>

```json
"content": [{
  "contentType": "application/sql",
  "extension": [{
    "url": "http://hl7.org/fhir/uv/sql-on-fhir/StructureDefinition/sql-text",
    "valueString": "SELECT patient.id, bp.systolic FROM ..."
  }],
  "data": "U0VMRUNUIHBhdGllbnQu..."
}]
```

The `sql-text` extension provides human-readable SQL; `data` provides
the machine-processable (base64-encoded) form.

#### Dialect Variants

For dialect-specific SQL, include separate attachments with a dialect parameter
in `contentType` (e.g., `application/sql;dialect=postgresql`). Keep aliases and
parameter names consistent across variants.

A `contentType` of `application/sql` (with no `dialect` parameter) represents a
default variant. It carries no dialect commitment and is intended to be broadly
portable, so <span class="fhir-conformance" id="sqlquery-2">authors SHOULD restrict it to
standard ANSI SQL constructs that work across the engines they expect to
target.</span> <span class="fhir-conformance" id="sqlquery-3">Implementations MAY treat the
default variant as roughly equivalent to ANSI SQL when no dialect-specific
variant matches.</span>

When a Library contains multiple `content` attachments, implementations choose
which attachment to execute as follows:

1. Prefer an attachment whose `contentType` declares a `dialect` parameter that
   matches the executing engine (for example, an engine running PostgreSQL
   selects `application/sql;dialect=postgresql`).
2. If no matching dialect-specific attachment is present, fall back to the
   default attachment with `contentType = "application/sql"`.
3. <span class="fhir-conformance" id="sqlquery-4">If neither a matching dialect nor a default
   attachment is available, implementations SHOULD return an error rather than
   guess at a translation between dialects.</span>

<span class="fhir-conformance" id="sqlquery-5">Authors SHOULD include a default `application/sql`
attachment whenever possible so that engines without a dedicated variant still
have a portable fallback.</span> <span class="fhir-conformance" id="sqlquery-6">All variants
within a single Library SHALL be functionally equivalent: they SHALL expose the
same parameters, reference the same table aliases, and produce the same logical
result set.</span>

### Conformance

**Terminology:** <span class="fhir-conformance" id="sqlquery-7">`contentType` SHOULD come from
[All SQL Content Type Codes](ValueSet-AllSQLContentTypeCodes.html).</span> The
binding is extensible: <span class="fhir-conformance" id="sqlquery-8">when one of these codes
covers the dialect, that code SHALL be used; otherwise, an alternative code MAY
be supplied (subject to the constraint that every `contentType` starts with
`application/sql`).</span>

**Constraints:**

- <span class="fhir-conformance" id="sqlquery-9">Library type SHALL be
  `LibraryTypesCodes#sql-query`</span>
- <span class="fhir-conformance" id="sqlquery-10">Every `content.contentType` SHALL start with
  `application/sql`</span>
- <span class="fhir-conformance" id="sqlquery-11">`content.data` SHALL be present; the `sql-text`
  extension MAY carry a plain-text copy</span>
- <span class="fhir-conformance" id="sqlquery-12">Dependencies SHALL use `relatedArtifact` with
  `type = "depends-on"` and `label`, each `resource` referencing a
  ViewDefinition or an SQLView</span>
- <span class="fhir-conformance" id="sqlquery-13">Parameters SHALL use `Library.parameter` with
  `use = "in"`</span>

For examples and tooling guidance, see the Notes tab below.
