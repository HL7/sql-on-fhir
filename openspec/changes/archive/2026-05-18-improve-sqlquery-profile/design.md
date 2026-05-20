# Design: SQLQuery Profile Improvements

## Context

The SQLQuery profile (Library-based Query) enables SQL queries to be represented as FHIR Library resources. This allows:
- Sharing queries across organizations
- Version control and metadata for SQL
- Integration with FHIR Clinical Reasoning module
- Multi-dialect support for the same logical query

Current gaps identified through community discussions:
1. Table name disambiguation when ViewDefinitions share names
2. Query parameter syntax not standardized
3. ViewDefinition dependency management incomplete
4. SQL annotations informal

### Stakeholders

- Query authors writing SQL against ViewDefinitions
- Query execution engines resolving table names and parameters
- Tooling authors building SQL-to-Library converters
- ViewDefinition authors (minimal impact - no changes required)

## Prior Art: Brian Kaney's SQL FHIR Library Builder

Brian Kaney (Reason Healthcare) created a reference implementation that demonstrates the SQL-to-FHIR-Library conversion pattern:

**Repository:** https://github.com/reason-healthcare/sql-fhir-library-builder

### Key Features

1. **Annotation Parsing** - Extracts metadata from SQL comments using `@annotation` syntax
2. **Flexible Syntax** - Supports `@key value`, `@key: value`, and `@key = value` formats
3. **Comment Styles** - Works with both `--` single-line and `/* */` block comments
4. **Type Conversion** - Automatic conversion of booleans, numbers, and lists
5. **Dialect Support** - SQL dialect specified via `@sqlDialect` and `@sqlDialectVersion`
6. **Dependency Tracking** - `@relatedDependency` creates `relatedArtifact` entries

### Supported Annotations

| Annotation | FHIR Mapping | Description |
|------------|--------------|-------------|
| `@title` | `Library.title` | Human-readable title |
| `@name` | `Library.name` | Machine identifier (auto-generated from title if omitted) |
| `@description` | `Library.description` | Detailed explanation |
| `@version` | `Library.version` | Version number |
| `@status` | `Library.status` | active/draft/retired |
| `@author` | `Library.author` | Creator identification |
| `@publisher` | `Library.publisher` | Publishing organization |
| `@sqlDialect` | `content.contentType` parameter | SQL dialect (postgres, hive, spark, etc.) |
| `@sqlDialectVersion` | `content.contentType` parameter | Dialect version |
| `@relatedDependency` | `relatedArtifact[type=depends-on]` | ViewDefinition/Library references |
| `@param` | `Library.parameter` | Query parameter declaration |
| `@tags` | (custom) | Comma-separated categories |

### Example SQL with Annotations

```sql
/*
@title: Trivial SQL on FHIR Example
@description: Demonstrating converting SQL to FHIR Library with basic annotations
@version: 4.2.0
@status: active
@author: Clinical Informatics Team
@publisher: Regional Medical Center
*/

-- @relatedDependency: https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition/PatientDemographics
-- @relatedDependency: https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition/PatientAddresses
-- @param: city string
WITH RankedAddresses AS (
    SELECT
        pd.*,
        pa.*,
        ROW_NUMBER() OVER (PARTITION BY pd.patient_id ORDER BY pa.address_id) AS address_rank
    FROM
        patient_demographics pd
    JOIN
        patient_addresses pa ON pd.patient_id = pa.patient_id
    WHERE
        pd.age > 18
        AND pa.city = :city
)
```

### Generated FHIR Library Structure

The tool generates:
- Base64-encoded SQL content in `content.data`
- Content type with dialect: `application/sql; dialect=postgres; version=15.4`
- Related artifacts from `@relatedDependency` with `type = "depends-on"`
- Parameters from `@param` annotations
- PascalCase name auto-generated when not provided

## Community Discussions

### Working Group Meeting Notes

**June 10, 2025 - Library-based Query Resource Proposal**
- Brian Kaney proposed using Library resource instead of creating a new query resource
- SQL stored as base64-encoded attachment with expression extension for plain text
- Dual format allows fallback for systems that don't understand expression extension
- Bashir suggested Library resource is only viable option for definitional containers
- Arjun created operation definition alternative to compare approaches
- Group discussed SQL dialect validation and interoperability challenges

**July 22, 2025 - Library Approach Gains Consensus**
- Brian presented library-based approach - gained strong consensus over creating new query resource
- Brian created Python tool with SQL annotations that compiles to FHIR Library resources automatically
- Group reached consensus that Library resources already provide needed functionality:
  - Parameters support (built into Library resource)
  - Dependencies and canonical URLs
  - Integration with existing FHIR ecosystem (measures, plan definitions, etc.)
- Brian argued that editing SQL embedded in JSON is impractical for 1000+ line queries
- Eugene suggested libraries could contain both CQL and SQL versions of same logic
- Nikolai agreed the library approach fits well with CRMI ecosystem
- **Action Item:** Brian to create draft PR for documenting library as query in spec

**August 26, 2025 - V2.1 Scope Definition**
- V2.1 release target: analytics conference in early December
- Scope includes: API operations (system-level), **query resource**, repeat directive, row index, SQL type hinting, and miscellaneous fixes

**October 21, 2025 - FHIR-I Project Inclusion**
- Arjun's comment: incorporating API and query resource into v2.1 for ballot
- Group may create tickets for mature topics like API, query resource, repeat directive at appropriate formalization points

**November 11, 2025 - Table Name Disambiguation Discussion**
- John questioned whether table name should be parameter in same sense as other parameters
- Gino raised collision concern when using multiple patient views from different contexts (e.g., FHIR patient, OMOP patient, IPS patient)
- Nikolai noted that in many FHIR resources, "code" is the technical name rather than "name" (e.g., search parameters use code)
- John proposed optional namespace field as separate element to group related views (e.g., "US Core" namespace)
- Group agreed implementation can translate abstract table names to actual backend table/schema names
- Nikolai noted query already references view definition canonical URL, which provides uniqueness context
- **Gino emphasized need for some code/ID/key to disambiguate full canonical plus version to table name used in SQL**
- Nikolai created Zulip thread for continued discussion

### Zulip: Analytics on FHIR

**Library-based Query Proposal** (July 2025)
- Brian Kaney presented revised proposal for queries leveraging Library resource
- Link: https://chat.fhir.org/#narrow/channel/179219-analytics-on-FHIR/topic/Library-based.20Query.20Proposal

**Table name and query parameters syntax** (November 2025)
- Discussion of table name disambiguation options
- Gino Canessa drafted options document
- Option 2 (library-local keys) selected by community
- Link: https://chat.fhir.org/#narrow/stream/179219-analytics-on-FHIR/topic/Table.20name.20and.20query.20parameters.20syntax

### HackMD Documents

**Table Name Options** by Gino Canessa
- URL: https://hackmd.io/@GinoCanessa/SoF-QueryTableNames
- Documents the table name disambiguation problem and four options
- Option 2 (library-local keys via relatedArtifact) was selected

## Goals / Non-Goals

### Goals
- Enable unambiguous table name resolution in SQLQuery
- Standardize query parameter declaration and syntax
- Use existing FHIR infrastructure (no extensions)
- Maintain backward compatibility with existing SQLQuery resources
- Support multiple dialects with consistent table naming and parameters
- Document annotations for tooling interoperability
- Align with Brian's sql-fhir-library-builder implementation

### Non-Goals
- Changing ViewDefinition structure
- Enforcing globally unique ViewDefinition names
- Inventing new SQL syntax
- Runtime query execution specification (focus is on representation)

## Decisions

### Decision 1: Use `relatedArtifact.label` for table aliases

The FHIR R5 RelatedArtifact datatype includes a `label` element (0..1, string) described as "Short label". This is ideal for table aliasing because:

1. It's already part of the FHIR standard - no extensions needed
2. It's designed for short identifiers (perfect for SQL table names)
3. It's local to the Library, allowing the same ViewDefinition to have different aliases in different contexts

**Alternatives considered** (from Gino's HackMD):

| Option | Approach | Pros | Cons |
|--------|----------|------|------|
| Option 1 | Globally unique ViewDefinition names | Simple | No uniqueness enforcement possible |
| Option 1.A | Add `code` element to ViewDefinition | Preserves name | Requires ViewDefinition changes |
| Option 2 (selected) | Use `relatedArtifact.label` | Uses existing FHIR, local scope | None significant |
| Option 3 | Use Library.parameter for mapping | Explicit parameters | More complex, redundant with relatedArtifact |

**Community consensus:** Option 2 won in November 2025 discussion. John Grimes noted Option 1 "has the problem that we don't have any way of ensuring global uniqueness."

### Decision 2: Colon-prefix for parameter syntax

Use `:parameter_name` syntax for SQL parameter placeholders (aligned with Brian's implementation):

1. Widely supported (Oracle, PostgreSQL with named parameters, many ORMs)
2. Clear visual distinction from column names
3. Simple to parse
4. Already used in sql-fhir-library-builder examples

**Alternatives considered:**

| Syntax | Support | Notes |
|--------|---------|-------|
| `:name` (selected) | Broad | Clear, widely recognized, used in Brian's impl |
| `@name` | SQL Server | Less universal, conflicts with some SQL functions |
| `$name` | PostgreSQL positional | Less readable |
| `?` | JDBC positional | No named support, order-dependent |

Allow dialect-specific variants in individual content attachments.

### Decision 2A: Parameter binding must be safe

Implementations MUST ensure parameter values are safely bound to queries and not
subject to SQL injection. Use parameterized queries or equivalent safe binding
mechanisms where available. Simple string interpolation MUST NOT be used to
implement parameter binding.

### Decision 3: Adopt Brian's annotation syntax

The `@annotation` syntax from sql-fhir-library-builder is adopted as the standard:

```sql
-- @param: city string
-- @relatedDependency: https://example.org/ViewDefinition/Patients
```

This provides:
- Tooling interoperability
- SQL file portability (metadata travels with the file)
- Clear, parseable format

### Decision 4: Labels are required (SHALL)

Labels are required (1..1) for ViewDefinition dependencies. This ensures unambiguous table name resolution.

**Rationale:**
- Explicit is better than implicit
- Avoids runtime resolution errors
- Ensures queries are self-contained and portable
- Aligns with ViewDefinition name constraints (valid identifier pattern)

### Decision 5: Annotation syntax is informational only

SQL annotations in comments are informational and MAY be used by tooling but are not normative. The authoritative metadata is in the Library resource elements.

Rationale:
- Allows SQL files to carry metadata when used outside FHIR
- Tooling (like Brian's) can extract annotations to generate Library resources
- No breaking changes to SQL syntax

### Decision 6: SQL identifier validation as SHOULD

Labels SHOULD follow SQL identifier rules (no hyphens, not starting with digit) but validation errors are warnings, not hard failures.

Rationale:
- Maximum portability across databases
- Some databases support quoted identifiers allowing special characters
- Warnings help authors while not breaking edge cases

### Decision 7: Both content.title and content.data are required

SQL attachments require both:
- `content.title` (1..1): Plain text SQL for human readability
- `content.data` (1..1): Base64-encoded SQL for machine processing

Rationale:
- Title provides quick visual inspection without decoding
- Data provides reliable machine-readable format
- Dual format supports both use cases without extensions
 
**Concerns raised (John Grimes):**
- Using `title` for plain-text SQL may be seen as co-opting an element with a different semantic purpose.
- Alternative approach: use an extension (e.g., `sqlText`) or require only `data` and rely on tooling/UI for display.

### Decision 8: Create $sqlquery-run operation

A synchronous operation for executing SQLQuery Libraries against ViewDefinition tables.

**Endpoints:**
| Level | Endpoint | Query Source |
|-------|----------|--------------|
| System | `POST [base]/$sqlquery-run` | `queryReference` or `queryResource` |
| Type | `POST [base]/Library/$sqlquery-run` | `queryReference` or `queryResource` |
| Instance | `POST [base]/Library/[id]/$sqlquery-run` | The Library instance |

**Input Parameters:**
- `_format` (required): Output format (json, ndjson, csv, parquet)
- `header`: Include CSV headers (boolean, default true)
- `queryReference`: Reference to stored SQLQuery Library (type-level only)
- `queryResource`: Inline SQLQuery Library (type-level only)
- `parameter`: Query parameter values (repeating, with name + polymorphic value)
- `source`: External data source URI

**Output:**
- `return`: Binary resource with results in requested format

**Design choices:**
- Uses `DataType` for parameter values to support proper typing (valueString, valueDate, valueInteger, etc.)
- No `_limit` parameter - SQL should include LIMIT clause if needed
- No `dialect` parameter - server selects appropriate variant
- Mirrors `$viewdefinition-run` operation pattern

## FHIR-to-SQL Type Mappings

| FHIR Type | SQL Type(s) | Notes |
|-----------|-------------|-------|
| string | VARCHAR, TEXT | Length unspecified |
| integer | INTEGER, INT | 32-bit |
| decimal | DECIMAL, NUMERIC | Precision/scale unspecified |
| boolean | BOOLEAN, BIT | Database-dependent |
| date | DATE | ISO format |
| dateTime | TIMESTAMP | ISO format with timezone |
| instant | TIMESTAMP WITH TIME ZONE | Full precision |
| code | VARCHAR | Short string |
| uri | VARCHAR, TEXT | URL/URN string |

Note: Exact mappings are implementation-specific. This table provides guidance.
**Concerns raised (John Grimes):** The table is incomplete for all FHIR types and needs clarification on whether it is normative or informative.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Breaking existing queries | Use SHOULD not SHALL for new requirements |
| Label/query mismatch | Document best practice, tooling can validate |
| Parameter syntax differences | Allow dialect variants, document canonical form |
| Case sensitivity issues | Document as case-insensitive for matching |
| Divergence from Brian's impl | Align spec with existing implementation |
| SQL injection risk | Require safe parameter binding; prohibit string interpolation |
| `contentType` dialect parsing | Consider extension-based dialect declaration (John Grimes) |

## Migration Plan

1. **Phase 1** (this change): Add documentation for all features as SHOULD
2. **Phase 2** (future): Add tooling to validate label/query consistency
3. **Phase 3** (future): Based on adoption, consider making some requirements SHALL

## References

### GitHub Repositories
- **sql-fhir-library-builder**: https://github.com/reason-healthcare/sql-fhir-library-builder
- **sql-on-fhir-v2**: https://github.com/FHIR/sql-on-fhir-v2

### HackMD Documents
- **Table Name Options** (Gino Canessa): https://hackmd.io/@GinoCanessa/SoF-QueryTableNames

### Zulip Discussions
- **Library-based Query Proposal**: https://chat.fhir.org/#narrow/channel/179219-analytics-on-FHIR/topic/Library-based.20Query.20Proposal
- **Table name and query parameters syntax**: https://chat.fhir.org/#narrow/stream/179219-analytics-on-FHIR/topic/Table.20name.20and.20query.20parameters.20syntax
- **FHIR-I Project Scope** (includes Library-based Queries): https://chat.fhir.org/#narrow/stream/179219-analytics-on-FHIR/topic/Proposed.3A.20SoF.20to.20become.20FHIR-I.20Project

### FHIR Specifications
- **RelatedArtifact Datatype**: http://hl7.org/fhir/R5/metadatatypes.html#RelatedArtifact
- **Library Resource**: http://hl7.org/fhir/R5/library.html
- **Clinical Reasoning Module**: https://hl7.org/fhir/clinicalreasoning-module.html

## Open Questions

1. Should we add FHIRPath invariant to validate SQL identifier pattern?
1. Should query executors be required to validate label/query correspondence?
1. How to handle versioned ViewDefinitions - does label need to include version context?
1. Should annotations support structured parameter types (e.g., `@param: city string "City name filter"`)?
   They should support structured parameter types!
1. Should `relatedArtifact.label` be constrained to the same identifier pattern as ViewDefinition `name`? (John Grimes)
   - Aligning constraints avoids inconsistent validation across resources.

1. **Should `relatedArtifact.label` be required (SHALL) or recommended (SHOULD)?**
   - Current decision: Required (1..1)
   - Pro: Ensures unambiguous table resolution, queries are self-contained
   - Con: Breaking change for existing SQLQuery resources without labels
   - Alternative: SHOULD with fallback to ViewDefinition.name
1. **How should output columns/schema be documented?**
   - Option A: Use `Library.parameter` with `use = "out"` for output columns
   - Option B: Add output schema in a separate content attachment (e.g., JSON Schema)
   - Option C: No formal output documentation - rely on SQL introspection
   - Option D: Use `Library.dataRequirement` to describe output structure
   - Considerations: Schema evolution, type mapping, tooling support
1. **Should the dialect be represented via extension instead of `contentType` parameter?** (John Grimes)
   - Pros: Easier profile validation, no parsing of `contentType`
   - Cons: Less aligned with MIME conventions; another extension to maintain
1. **Should plain-text SQL be stored in `content.title` or a dedicated extension?** (John Grimes)
   - Pros (title): human-readable without decoding; no new extension
   - Cons (title): semantic mismatch with `Attachment.title`
   - Alternative: require only `data` and rely on tooling/UI for display
1. **Should the FHIR-to-SQL type mapping table be marked informative and expanded?** (John Grimes)
   - Add missing FHIR types or scope it to commonly used scalar types

1. **Should `$sqlquery-run` support named query parameters directly?**
   - Current: Complex nested structure in Parameters resource
     ```json
     { "name": "parameter", "part": [
       { "name": "name", "valueString": "patient_id" },
       { "name": "value", "valueString": "Patient/123" }
     ]}
     ```
   - Desired: Simple named parameters in URL or flat Parameters
     ```
     GET /Library/123/$sqlquery-run?patient_id=Patient/123&from_date=2024-01-01
     ```
   - Option A: Define each Library parameter as a top-level operation parameter dynamically
   - Option B: Use FHIR search-style parameter passing (name=value pairs)
   - Option C: Keep current nested structure for type safety
   - Considerations:
     - FHIR operations typically have fixed parameter definitions
     - Dynamic parameters based on Library content is non-standard
     - Type coercion from string query params vs typed Parameters values
     - GET support for simple queries vs POST-only
