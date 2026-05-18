# SQLQuery Profile Specification

## ADDED Requirements

### Requirement: Table Aliasing via RelatedArtifact Label

SQLQuery resources SHALL support table aliasing through the `relatedArtifact.label` element. When referencing ViewDefinitions, the label value:

1. SHOULD be a valid SQL identifier (alphanumeric characters and underscores, not starting with a digit)
2. SHOULD match the table name used in the SQL query content
3. SHOULD be unique within the Library (no duplicate labels)
4. SHALL be provided when the ViewDefinition's `name` may be ambiguous (e.g., multiple ViewDefinitions with same name)

#### Scenario: Simple table aliasing
- **GIVEN** a SQLQuery that references two ViewDefinitions
- **WHEN** the relatedArtifact entries include label values "patient_demographics" and "patient_addresses"
- **THEN** the SQL query MAY use "patient_demographics" and "patient_addresses" as table names
- **AND** query executors SHALL map these labels to the referenced ViewDefinition tables

#### Scenario: Disambiguating same-named ViewDefinitions
- **GIVEN** two ViewDefinitions both with name "Patients"
- **WHEN** a SQLQuery needs to reference both (e.g., OMOP Patients and FHIR Patients)
- **THEN** the Library SHALL use different label values for each (e.g., "omop_patients" and "fhir_patients")
- **AND** the SQL query SHALL reference these distinct label values

#### Scenario: Label matches SQL query table name
- **GIVEN** a SQLQuery with `relatedArtifact.label = "demographics"`
- **WHEN** the SQL content references `FROM demographics`
- **THEN** the query executor SHALL resolve "demographics" to the ViewDefinition in `relatedArtifact.resource`

### Requirement: Query Parameter Declaration

SQLQuery resources SHALL declare query parameters using the `Library.parameter` element. Each parameter:

1. SHALL have a `name` that matches the placeholder used in SQL
2. SHALL specify `use = #in` for input parameters
3. SHALL specify a `type` that maps to an appropriate SQL type
4. MAY include `documentation` describing the parameter's purpose

#### Scenario: Declaring a string parameter
- **GIVEN** a SQLQuery with a city filter
- **WHEN** the SQL contains `WHERE city = :city_name`
- **THEN** the Library SHALL include a parameter with:
  - `name = #city_name`
  - `type = #string`
  - `use = #in`

#### Scenario: Declaring a date parameter
- **GIVEN** a SQLQuery filtering by date range
- **WHEN** the SQL contains `WHERE date >= :start_date`
- **THEN** the Library SHALL include a parameter with:
  - `name = #start_date`
  - `type = #date` or `#dateTime`
  - `use = #in`

### Requirement: Parameter Placeholder Syntax

SQL queries in SQLQuery resources SHALL use a recognizable parameter placeholder syntax. The colon-prefix syntax (`:parameter_name`) is RECOMMENDED. This syntax:

1. Is widely supported across SQL databases
2. Clearly distinguishes parameters from column names
3. Matches the parameter `name` declared in `Library.parameter`

#### Scenario: Colon-prefix parameter
- **GIVEN** a parameter declared as `name = #city`
- **THEN** the SQL query SHOULD reference it as `:city`
- **AND** executors SHALL substitute the parameter value

#### Scenario: Alternative at-sign syntax
- **GIVEN** a database that uses `@parameter` syntax (e.g., SQL Server)
- **THEN** the SQL dialect variant MAY use `@city` instead
- **AND** the parameter declaration remains `name = #city`

### Requirement: ViewDefinition Dependency Structure

Each ViewDefinition dependency SHALL be declared using a `relatedArtifact` element with the following structure:

1. `type` SHALL be `#depends-on`
2. `resource` SHALL be the canonical URL of the ViewDefinition
3. `label` SHOULD be the table alias used in SQL (see Table Aliasing requirement)
4. `display` MAY provide a human-readable description

#### Scenario: Complete dependency declaration
- **GIVEN** a query referencing PatientDemographics ViewDefinition
- **THEN** the relatedArtifact SHALL have:
  - `type = #depends-on`
  - `resource = "https://example.org/ViewDefinition/PatientDemographics"`
  - `label = "patient_demographics"` (recommended)
  - `display = "Patient demographics view"` (optional)

#### Scenario: Versioned ViewDefinition reference
- **GIVEN** a query requiring a specific ViewDefinition version
- **WHEN** version matters for compatibility
- **THEN** the resource MAY include version: `"https://example.org/ViewDefinition/PatientDemographics|1.0"`

### Requirement: SQL Annotations

Tooling that processes SQLQuery resources SHALL recognize annotations in SQL comments. Supported annotations:

| Annotation | Description | Example |
|------------|-------------|---------|
| `@title` | Query title | `@title: Patient Address Report` |
| `@description` | Query description | `@description: Retrieves unique patient addresses` |
| `@version` | Query version | `@version: 1.2.0` |
| `@author` | Author name | `@author: Clinical Informatics Team` |
| `@param` | Parameter declaration | `@param: city string` |
| `@relatedDependency` | ViewDefinition reference | `@relatedDependency: https://example.org/ViewDefinition/Patients` |

Annotations in SQL comments are informational and MAY be used by tooling to generate Library metadata.

#### Scenario: Annotation in block comment
- **GIVEN** SQL content with:
  ```sql
  /*
  @title: Patient Report
  @param: city string
  */
  SELECT * FROM patients WHERE city = :city
  ```
- **THEN** tooling MAY extract `title` and `param` for Library generation

#### Scenario: Annotation in line comment
- **GIVEN** SQL content with:
  ```sql
  -- @relatedDependency: https://example.org/ViewDefinition/Patients
  SELECT * FROM patients
  ```
- **THEN** tooling MAY extract dependency information

### Requirement: SQL Identifier Validation

Implementations SHALL validate that table alias labels conform to common SQL identifier rules to ensure portability:

1. Start with a letter (a-z, A-Z) or underscore (_)
2. Contain only letters, digits (0-9), and underscores
3. Be case-insensitive for matching (though case may be preserved)
4. Not be a SQL reserved word (implementations SHOULD warn)

#### Scenario: Valid SQL identifier
- **GIVEN** a label value "patient_demographics_v2"
- **THEN** validation SHALL succeed

#### Scenario: Invalid identifier - starts with digit
- **GIVEN** a label value "2nd_table"
- **THEN** validation SHOULD produce a warning

#### Scenario: Invalid identifier - contains hyphen
- **GIVEN** a label value "patient-data"
- **THEN** validation SHOULD produce a warning recommending "patient_data"

### Requirement: Multi-Dialect Support

SQLQuery resources SHALL support multiple SQL content attachments for different dialects. Each dialect:

1. SHALL be specified via `contentType` parameter (e.g., `application/sql;dialect=postgresql`)
2. SHALL represent the same logical query
3. SHOULD use the same table aliases and parameter names
4. MAY use dialect-specific SQL syntax

#### Scenario: Multiple dialects
- **GIVEN** a query with PostgreSQL and BigQuery variants
- **THEN** the Library SHALL include:
  - `content[0].contentType = #application/sql;dialect=postgresql`
  - `content[1].contentType = #application/sql;dialect=bigquery`
- **AND** both contents SHALL implement the same logical query

## MODIFIED Requirements

### Requirement: Library Type Code

SQLQuery resources SHALL use `type = LibraryTypesCodes#sql-query` to identify the Library as containing SQL query logic.

#### Scenario: Correct type code
- **GIVEN** a SQLQuery Library
- **THEN** `Library.type` SHALL be `LibraryTypesCodes#sql-query`

### Requirement: SQL Content Type

The content attachment SHALL have `contentType` starting with `application/sql`. Dialect MAY be specified as a parameter.

#### Scenario: Standard SQL
- **GIVEN** an ANSI SQL query
- **THEN** `contentType` SHALL be `#application/sql`

#### Scenario: Dialect-specific SQL
- **GIVEN** a PostgreSQL-specific query
- **THEN** `contentType` SHALL be `#application/sql;dialect=postgresql`
- **AND** the `contentType` SHALL be from the AllSQLContentTypeCodes value set
