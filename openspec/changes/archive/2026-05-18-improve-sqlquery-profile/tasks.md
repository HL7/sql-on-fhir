# Tasks: Improve SQLQuery Profile Documentation

## 1. Expand Intro Page

- [x] 1.1 Add "Table Aliasing" section to `StructureDefinition-SQLQuery-intro.md`
  - Explain `relatedArtifact.label` usage
  - Show that label defines table name in SQL
  - Note: required when ViewDefinitions share names

- [x] 1.2 Add "Query Parameters" section
  - Explain `Library.parameter` structure (name, type, use)
  - Document `:parameter_name` placeholder syntax
  - List common FHIR types (string, integer, date, boolean)

- [x] 1.3 Add "ViewDefinition Dependencies" section
  - Document `relatedArtifact` with `type = #depends-on`
  - Show complete structure: type, resource, label, display

- [x] 1.4 Expand "Conformance Summary"
  - Add requirement for label when names collide
  - Add parameter declaration requirement

## 2. Create Notes Page

- [x] 2.1 Create `StructureDefinition-SQLQuery-notes.md`

- [x] 2.2 Add "Table Aliasing Details" section
  - Problem statement (OMOP Patient vs FHIR Patient collision)
  - Solution with `relatedArtifact.label`
  - Complete FSH example showing disambiguation

- [x] 2.3 Add "Parameter Syntax" section
  - Comparison table: `:name` vs `@name` vs `$1` vs `?`
  - Recommendation for colon-prefix as canonical form
  - Dialect-specific variants note

- [x] 2.4 Add "FHIR-to-SQL Type Mappings" table
  - string → VARCHAR/TEXT
  - integer → INTEGER
  - decimal → DECIMAL/NUMERIC
  - boolean → BOOLEAN/BIT
  - date → DATE
  - dateTime → TIMESTAMP

- [x] 2.5 Add "SQL Annotations" section
  - Annotation table with FHIR mappings
  - Block comment and line comment examples
  - Note: annotations are informational, Library elements authoritative

## 3. Update Existing Examples

- [x] 3.1 Add `label` to `UniquePatientAddressesQuery` in `sql-query-examples.fsh`
  ```fsh
  * relatedArtifact[+]
    * type = #depends-on
    * resource = "...PatientDemographics"
    * label = "patient_demographics"
  * relatedArtifact[+]
    * type = #depends-on
    * resource = "...PatientAddresses"
    * label = "patient_addresses"
  ```

- [x] 3.2 Add `label` to `SqlOnFhirExample` relatedArtifacts
  - Same pattern as 3.1

## 4. Add Disambiguation Example

- [x] 4.1 Create `OmopFhirPatientJoin` example in `sql-query-examples.fsh`
  - Two ViewDefinitions with similar names (Person/Patient)
  - Different labels: `omop_person`, `fhir_patient`
  - Parameter: `source_system` (string)
  - SQL joining both tables with parameter filter

## 5. Profile Constraints

- [x] 5.1 Make `relatedArtifact.label` required (1..1) in `library-profiles.fsh`
  - ViewDefinition dependencies must have a table alias
  - Updated documentation in intro page

- [x] 5.2 Make `content.title` required (1..1) in `library-profiles.fsh`
  - SQL attachments must have plain text SQL in title
  - `data` contains base64-encoded SQL
  - Updated conformance section in intro page

- [x] 5.3 Update Tooling section in notes page
  - Added "Generate `content.title` with SQL text" to Builders SHALL list

## 6. Create $sqlquery-run Operation

- [x] 6.1 Add `SQLQueryRun` operation definition in `operations.fsh`
  - Instance-level: `POST [base]/Library/[id]/$sqlquery-run`
  - Type-level: `POST [base]/Library/$sqlquery-run`
  - System-level: `POST [base]/$sqlquery-run`

- [x] 6.2 Define input parameters
  - `_format` (required): Output format (json, ndjson, csv, parquet)
  - `header`: Include CSV headers (boolean)
  - `queryReference`: Reference to stored SQLQuery Library
  - `queryResource`: Inline SQLQuery Library
  - `parameter`: Query parameter values (name + polymorphic value using DataType)
  - `source`: External data source

- [x] 6.3 Define output parameter
  - `return`: Binary with query results in requested format

- [x] 6.4 Create `OperationDefinition-SQLQueryRun-intro.md`
  - Use cases, endpoints table, execution flow

- [x] 6.5 Create `OperationDefinition-SQLQueryRun-notes.md`
  - Instance-level example
  - Type-level with queryReference example
  - Type-level with inline queryResource example
  - Parameter type mapping table
  - Error handling table

## 7. Simplify Operation Parameters

- [x] 7.1 Remove `_limit` parameter from `$sqlquery-run`
  - Not needed for initial version

- [x] 7.2 Remove `dialect` parameter from `$sqlquery-run`
  - Server selects appropriate dialect
  - Removed "Dialect Selection" section from notes

- [x] 7.3 Update inline example in notes
  - Removed `_limit` from queryResource example

## 8. Validation

- [x] 8.1 Run SUSHI to verify FSH compiles: `sushi .`
- [x] 8.2 SUSHI completed: 0 Errors, 1 Warning (pre-existing)
- [x] 8.3 Build IG: `npm run build:ig`
- [x] 8.4 IG build completed: 11 Errors (pre-existing), 46 Warnings
- [ ] 8.5 Review generated pages in `output/`
