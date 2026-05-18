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
Expression: "content.contentType.startsWith('application/sql')"

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
* content.contentType from AllSQLContentTypeCodes (required)
* content.extension contains sql-text named sqlText 0..1 MS
* content.extension[sqlText] ^short = "Plain-text SQL for readability"
* content.data 1..1 MS
* content.data ^short = "SQL query (base64-encoded)"

// ViewDefinition dependencies
* relatedArtifact MS
* relatedArtifact.type 1..1 MS
* relatedArtifact.type ^short = "depends-on for ViewDefinition references"
* relatedArtifact.resource 1..1 MS
* relatedArtifact.resource ^short = "Canonical URL of ViewDefinition"
* relatedArtifact.label 1..1 MS
* relatedArtifact.label ^short = "Table name used in SQL query"
* relatedArtifact.label obeys sql-name

// Query parameters
* parameter MS
* parameter.name 1..1 MS
* parameter.type 1..1 MS
* parameter.use 1..1 MS
* parameter.use ^short = "in (query parameters are always input)"
