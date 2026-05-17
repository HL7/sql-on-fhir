### Scope and Usage

Use SQLQuery for shareable SQL over ViewDefinition outputs.
Each Library holds one query. For dialect-specific variants, use multiple
content attachments while keeping parameters and aliases consistent.

### Boundaries and Relationships

SQLQuery does not define table schemas, data extraction, execution behavior, or
APIs; those belong to ViewDefinition and its operations.
SQLQuery references ViewDefinitions; execution environments resolve these to
physical tables.

### Resource Content

#### ViewDefinition Dependencies

Use `relatedArtifact` with `type = "depends-on"` to list required ViewDefinitions.
Use `label` to define the table name in SQL.

```json
"relatedArtifact": [
  { "type": "depends-on", "resource": "https://example.org/ViewDefinition/patient_view", "label": "patient" },
  { "type": "depends-on", "resource": "https://example.org/ViewDefinition/bp_view", "label": "bp" }
]
```

#### Table Aliases

Each dependency requires a `label` that defines the table name used in SQL.
Labels must be unique within the Library and valid SQL identifiers (start with
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
`data` element (base64-encoded SQL) is required. The
[`sql-text`](StructureDefinition-sql-text.html) extension MAY carry a
plain-text copy for human readability.

```json
"content": [{
  "contentType": "application/sql",
  "extension": [{
    "url": "https://sql-on-fhir.org/ig/StructureDefinition/sql-text",
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
portable, so authors SHOULD restrict it to standard ANSI SQL constructs that
work across the engines they expect to target. Implementations MAY treat the
default variant as roughly equivalent to ANSI SQL when no dialect-specific
variant matches.

When a Library contains multiple `content` attachments, implementations choose
which attachment to execute as follows:

1. Prefer an attachment whose `contentType` declares a `dialect` parameter that
   matches the executing engine (for example, an engine running PostgreSQL
   selects `application/sql;dialect=postgresql`).
2. If no matching dialect-specific attachment is present, fall back to the
   default attachment with `contentType = "application/sql"`.
3. If neither a matching dialect nor a default attachment is available,
   implementations SHOULD return an error rather than guess at a translation
   between dialects.

Authors SHOULD include a default `application/sql` attachment whenever possible
so that engines without a dedicated variant still have a portable fallback. All
variants within a single Library SHALL be functionally equivalent: they SHALL
expose the same parameters, reference the same table aliases, and produce the
same logical result set.

### Conformance

**Terminology:** `contentType` SHALL come from
[All SQL Content Type Codes](ValueSet-AllSQLContentTypeCodes.html).

**Constraints:**

- Library type SHALL be `LibraryTypesCodes#sql-query`
- Every `content.contentType` SHALL start with `application/sql`
- `content.data` SHALL be present; the `sql-text` extension MAY carry a plain-text copy
- Dependencies SHALL use `relatedArtifact` with `type = "depends-on"` and `label`
- Parameters SHALL use `Library.parameter` with `use = "in"`

For examples and tooling guidance, see the Notes tab below.
