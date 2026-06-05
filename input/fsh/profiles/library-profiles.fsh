Extension: SqlText
Id: sql-text
Title: "SQL Text"
Description: "Plain-text SQL query for human readability. Supplements the base64-encoded Attachment.data."
Context: Attachment
* value[x] only string
* valueString 1..1

Invariant: sql-must-be-sql-expressions
Description: "The content of the Library must be SQL expressions."
Severity: #error
Expression: "content.all(contentType.startsWith('application/sql'))"

Profile: SQLQuery
Title: "SQL Query Library"
Parent: Library
Description: """
The SQLQuery profile represents a SQL query that runs against ViewDefinition
tables. It bundles the SQL, dependencies, and parameters for sharing and
versioning.
"""
* obeys sql-must-be-sql-expressions
* type = LibraryTypesCodes#sql-query

// Content constraints - SQL attachment(s)
* content 1..* MS
* content.contentType 1..1 MS
* content.contentType ^short = "application/sql or application/sql;dialect=..."
* content.contentType from http://hl7.org/fhir/ValueSet/mimetypes (required)
* content.contentType ^binding.additional[+].purpose = #extensible
* content.contentType ^binding.additional[=].valueSet = Canonical(AllSQLContentTypeCodes)
* content.contentType ^binding.additional[=].documentation = "SQLQuery content types, including dialect-specific variants. Authors SHOULD use a code from this value set when one applies; codes outside this value set MAY be used for SQL dialects not yet enumerated, subject to the sql-must-be-sql-expressions invariant."
* content.extension contains sql-text named sqlText 0..1 MS
* content.extension[sqlText] ^short = "Plain-text SQL for readability"
* content.data 1..1 MS
* content.data ^short = "SQL query (base64-encoded)"

// ViewDefinition and SQLView dependencies
* relatedArtifact MS
* relatedArtifact.type 1..1 MS
* relatedArtifact.type = #depends-on
* relatedArtifact.type ^short = "depends-on for ViewDefinition or SQLView references"
* relatedArtifact.resource 1..1 MS
* relatedArtifact.resource only Canonical(ViewDefinition or SQLView)
* relatedArtifact.resource ^short = "Canonical URL of a ViewDefinition or SQLView"
* relatedArtifact.label 1..1 MS
* relatedArtifact.label ^short = "Table name used in SQL query"
* relatedArtifact.label obeys sql-name

// Query parameters
* parameter MS
* parameter.name 1..1 MS
* parameter.type 1..1 MS
* parameter.use 1..1 MS
* parameter.use ^short = "in (query parameters are always input)"

Profile: SQLView
Title: "SQL View Library"
Parent: Library
Description: """
The SQLView profile represents a reusable, named SQL query that other queries
reference as a virtual table source, analogous to a SQL view. It bundles the
SQL and its dependencies for sharing and versioning. Unlike SQLQuery, an
SQLView cannot declare parameters.
"""
* obeys sql-must-be-sql-expressions
* type = LibraryTypesCodes#sql-view

// Parameters are not permitted on views.
* parameter 0..0
* parameter ^short = "Not permitted (views cannot be parameterised)"

// Content constraints - SQL attachment(s)
* content 1..* MS
* content.contentType 1..1 MS
* content.contentType ^short = "application/sql or application/sql;dialect=..."
* content.contentType from http://hl7.org/fhir/ValueSet/mimetypes (required)
* content.contentType ^binding.additional[+].purpose = #extensible
* content.contentType ^binding.additional[=].valueSet = Canonical(AllSQLContentTypeCodes)
* content.contentType ^binding.additional[=].documentation = "SQLView content types, including dialect-specific variants. Authors SHOULD use a code from this value set when one applies; codes outside this value set MAY be used for SQL dialects not yet enumerated, subject to the sql-must-be-sql-expressions invariant."
* content.extension contains sql-text named sqlText 0..1 MS
* content.extension[sqlText] ^short = "Plain-text SQL for readability"
* content.data 1..1 MS
* content.data ^short = "SQL view (base64-encoded)"

// ViewDefinition and SQLView dependencies
* relatedArtifact MS
* relatedArtifact.type 1..1 MS
* relatedArtifact.type = #depends-on
* relatedArtifact.type ^short = "depends-on for ViewDefinition or SQLView references"
* relatedArtifact.resource 1..1 MS
* relatedArtifact.resource only Canonical(ViewDefinition or SQLView)
* relatedArtifact.resource ^short = "Canonical URL of a ViewDefinition or SQLView"
* relatedArtifact.label 1..1 MS
* relatedArtifact.label ^short = "Table name used in SQL view"
* relatedArtifact.label obeys sql-name
