Alias: $allowedType = http://hl7.org/fhir/StructureDefinition/operationdefinition-allowed-type

Instance: ViewDefinitionExport
Usage: #definition
InstanceOf: OperationDefinition
Title: "ViewDefinition Export"
Description: "Export a view definition. User can provide view definition references and/or resources as part of the input parameters."

* id = "ViewDefinitionExport"
* url = "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/ViewDefinitionExport"
* version = "0.0.1"
* name = "ViewDefinitionExport"
* status = #active
* kind = #operation
* code = #viewdefinition-export
* system = true
* type = true
* instance = true
// Hack: it should be #ViewDefinition, but we don't have that type yet
* resource[0] = #CanonicalResource

// Input parameters
* parameter[+].name = #view
* parameter[=].use = #in
* parameter[=].min = 1
* parameter[=].max = "*"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].documentation = "One or more ViewDefinitions to export. Each repetition identifies a single view."
* parameter[=].part[+].name = #name
* parameter[=].part[=].use = #in
* parameter[=].part[=].min = 0
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #string
* parameter[=].part[=].documentation = "Optional friendly name for the exported view output."
* parameter[=].part[+].name = #viewCanonical
* parameter[=].part[=].use = #in
* parameter[=].part[=].min = 0
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #canonical
* parameter[=].part[=].targetProfile = Canonical(ViewDefinition)
* parameter[=].part[=].documentation = "Canonical URL of the ViewDefinition to export, optionally with a |version suffix pinning a version."
* parameter[=].part[+].name = #viewReference
* parameter[=].part[=].use = #in
* parameter[=].part[=].min = 0
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #Reference
* parameter[=].part[=].targetProfile = Canonical(ViewDefinition)
* parameter[=].part[=].documentation = "Literal location of a ViewDefinition: a relative URL on this server, or an absolute URL. Not a canonical URL; use viewCanonical for that."
* parameter[=].part[+].name = #viewResource
* parameter[=].part[=].use = #in
* parameter[=].part[=].min = 0
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #CanonicalResource
* parameter[=].part[=].targetProfile = Canonical(ViewDefinition)
* parameter[=].part[=].documentation = "Inline ViewDefinition resource to export."

* parameter[+].name = #clientTrackingId
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #string
* parameter[=].documentation = "Client-provided tracking identifier for the export operation."

* parameter[+].name = #_format
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #code
* parameter[=].binding.strength = #extensible
* parameter[=].binding.valueSet = Canonical(ExportOutputFormatCodes)
* parameter[=].documentation = "Bulk export output format (csv, ndjson, parquet, json). Optional; if omitted, the server returns ndjson by default. See Common Operation Behavior (operations-common.html)."

* parameter[+].name = #header
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #boolean
* parameter[=].documentation = "Include CSV headers (default true). Applies only when csv output is requested."

* parameter[+].name = #patient
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #Reference
* parameter[=].documentation = "Filter exported data to the supplied patient(s)."

* parameter[+].name = #group
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #Reference
* parameter[=].documentation = "Filter exported data to members of the supplied group(s)."

* parameter[+].name = #_since
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #instant
* parameter[=].documentation = "Export only resources updated since this instant."

* parameter[+].name = #source
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #string
* parameter[=].documentation = "External data source to use for the export (for example a URI or bucket name)."

// Output parameters
* parameter[+].name = #exportId
* parameter[=].use = #out
* parameter[=].min = 1
* parameter[=].max = "1"
* parameter[=].type = #string
* parameter[=].documentation = "Server-generated identifier assigned to the export request."

* parameter[+].name = #clientTrackingId
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #string
* parameter[=].documentation = "Echoed client tracking identifier when provided."

* parameter[+].name = #status
* parameter[=].use = #out
* parameter[=].min = 1
* parameter[=].max = "1"
* parameter[=].type = #code
* parameter[=].binding.strength = #required
* parameter[=].binding.valueSet = Canonical(ExportStatusCodes)
* parameter[=].documentation = "Status of the export (accepted, in-progress, completed, cancelled, failed)."

* parameter[+].name = #location
* parameter[=].use = #out
* parameter[=].min = 1
* parameter[=].max = "1"
* parameter[=].type = #uri
* parameter[=].documentation = "URL to poll for export status updates."

* parameter[+].name = #cancelUrl
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #uri
* parameter[=].documentation = "Optional URL for cancelling the export."

* parameter[+].name = #_format
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #code
* parameter[=].binding.strength = #extensible
* parameter[=].binding.valueSet = Canonical(OutputFormatCodes)
* parameter[=].documentation = "Format of the exported files (echoed from input if supplied)."

* parameter[+].name = #exportStartTime
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #instant
* parameter[=].documentation = "Timestamp when the export operation began."

* parameter[+].name = #exportEndTime
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #instant
* parameter[=].documentation = "Timestamp when the export operation completed."

* parameter[+].name = #exportDuration
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #integer
* parameter[=].documentation = "Duration of the export in seconds."

* parameter[+].name = #estimatedTimeRemaining
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #integer
* parameter[=].documentation = "Estimated seconds remaining until completion."

* parameter[+].name = #output
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].documentation = "Output information for each exported view."
* parameter[=].part[+].name = #name
* parameter[=].part[=].use = #out
* parameter[=].part[=].min = 1
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #string
* parameter[=].part[=].documentation = "Name assigned to the exported view output."
* parameter[=].part[+].name = #location
* parameter[=].part[=].use = #out
* parameter[=].part[=].min = 1
* parameter[=].part[=].max = "*"
* parameter[=].part[=].type = #uri
* parameter[=].part[=].documentation = "Download URL(s) for the exported file(s)."

Instance: ViewDefinitionRun
Usage: #definition
InstanceOf: OperationDefinition
Title: "ViewDefinition Run"
Description: "Execute a view definition against supplied or server data."

* id = "ViewDefinitionRun"
* url = "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/ViewDefinitionRun"
* version = "0.0.1"
* versionAlgorithmString = "semver"
* name = "ViewDefinitionRun"
* status = #active
* kind = #operation
* code = #viewdefinition-run
* system = true
* type = true
* instance = true
// Hack: it should be #ViewDefinition, but we don't have that type yet
* resource[0] = #CanonicalResource

// Input parameters
* parameter[+].name = #_format
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #code
* parameter[=].binding.strength = #extensible
* parameter[=].binding.valueSet = Canonical(OutputFormatCodes)
* parameter[=].documentation = "Output format for the result (json, ndjson, csv, parquet, fhir). Use fhir to return results as a FHIR Parameters resource. Optional; if omitted, the server returns ndjson by default. See Common Operation Behavior (operations-common.html)."

* parameter[+].name = #header
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #boolean
* parameter[=].documentation = "Include CSV headers (default true). Applies only when csv output is requested."

* parameter[+].name = #viewCanonical
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #canonical
* parameter[=].targetProfile = Canonical(ViewDefinition)
* parameter[=].documentation = "Canonical URL of the ViewDefinition to execute, optionally with a |version suffix pinning a version."

* parameter[+].name = #viewReference
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #Reference
* parameter[=].targetProfile = Canonical(ViewDefinition)
* parameter[=].documentation = "Literal location of a ViewDefinition: a relative URL on this server, or an absolute URL. Not a canonical URL; use viewCanonical for that."

* parameter[+].name = #viewResource
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
//* parameter[=].type = #ViewDefinition
* parameter[=].type = #CanonicalResource
* parameter[=].targetProfile = Canonical(ViewDefinition)
* parameter[=].documentation = "Inline ViewDefinition resource to execute."

* parameter[+].name = #patient
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #Reference
* parameter[=].documentation = "Restrict execution to the specified patient."

* parameter[+].name = #group
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #Reference
* parameter[=].documentation = "Restrict execution to members of the given group(s)."

* parameter[+].name = #source
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #string
* parameter[=].documentation = "External data source to use (for example a URI or bucket name)."

* parameter[+].name = #resource
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #Resource
* parameter[=].documentation = "FHIR resources to transform instead of using server data. Repeatable. A Bundle supplied here is unwrapped: the ViewDefinition runs against each Bundle.entry[*].resource rather than against the Bundle itself. See OperationDefinition-ViewDefinitionRun notes (Resource Parameter and Bundle Inputs)."

* parameter[+].name = #_limit
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #integer
* parameter[=].documentation = "Maximum number of rows to return."

* parameter[+].name = #_since
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #instant
* parameter[=].documentation = "Include only resources modified after this instant."

// Output parameter
* parameter[+].name = #return
* parameter[=].use = #out
* parameter[=].min = 1
* parameter[=].max = "1"
* parameter[=].type = #Binary
* parameter[=].documentation = "Transformed data in the requested output format, returned as a raw binary stream in the format's native media type, not a serialized Binary resource envelope. When _format=fhir is requested, the response is a Parameters resource instead. See Common Operation Behavior (operations-common.html)."

Instance: SQLQueryRun
Usage: #definition
InstanceOf: OperationDefinition
Title: "SQLQuery Run"
Description: "Execute a SQLQuery Library against ViewDefinition tables."

* id = "SQLQueryRun"
* url = "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/SQLQueryRun"
* version = "0.0.1"
* versionAlgorithmString = "semver"
* name = "SQLQueryRun"
* status = #active
* kind = #operation
* code = #sqlquery-run
* system = true
* type = true
* instance = true
* resource[0] = #Library

// Input parameters
* parameter[+].name = #_format
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #code
* parameter[=].binding.strength = #extensible
* parameter[=].binding.valueSet = Canonical(OutputFormatCodes)
* parameter[=].documentation = "Output format for the result (json, ndjson, csv, parquet, fhir). Use fhir to return results as a FHIR Parameters resource. Optional; if omitted, the server returns ndjson by default. See Common Operation Behavior (operations-common.html)."

* parameter[+].name = #header
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #boolean
* parameter[=].documentation = "Include CSV headers (default true). Applies only when csv output is requested."

* parameter[+].name = #queryCanonical
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #canonical
* parameter[=].targetProfile[0] = Canonical(SQLQuery)
* parameter[=].targetProfile[1] = Canonical(SQLView)
* parameter[=].documentation = "Canonical URL of the SQLQuery or SQLView Library to execute, optionally with a |version suffix pinning a version."

* parameter[+].name = #queryReference
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #Reference
* parameter[=].targetProfile[0] = Canonical(SQLQuery)
* parameter[=].targetProfile[1] = Canonical(SQLView)
* parameter[=].documentation = "Literal location of a SQLQuery or SQLView Library: a relative URL on this server, or an absolute URL. Not a canonical URL; use queryCanonical for that."

* parameter[+].name = #queryResource
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #Library
* parameter[=].targetProfile[0] = Canonical(SQLQuery)
* parameter[=].targetProfile[1] = Canonical(SQLView)
* parameter[=].documentation = "Inline SQLQuery or SQLView Library resource to execute."

* parameter[+].name = #viewResource
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #CanonicalResource
* parameter[=].targetProfile[0] = Canonical(ViewDefinition)
* parameter[=].targetProfile[1] = Canonical(SQLView)
* parameter[=].documentation = "Inline ViewDefinition or SQLView resources supplying table sources the server cannot itself resolve. Matched by canonical URL against the dependencies in the query's transitive relatedArtifact graph. See Common Operation Behavior (operations-common.html#table-sources)."

* parameter[+].name = #parameters
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #Parameters
* parameter[=].documentation = "Input parameters for the query. Parameters are bound by name to parameters declared in the SQLQuery Library (Library.parameter.name). Parameter types are mapped using the appropriate value[x] type matching the declared parameter type."

* parameter[+].name = #source
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #string
* parameter[=].documentation = "External data source containing the ViewDefinition tables."

* parameter[+].name = #_limit
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #integer
* parameter[=].documentation = "Maximum number of rows to return."

// Output parameter
* parameter[+].name = #return
* parameter[=].use = #out
* parameter[=].min = 1
* parameter[=].max = "1"
* parameter[=].type = #Binary
* parameter[=].documentation = "Query results in the requested output format, returned as a raw binary stream in the format's native media type, not a serialized Binary resource envelope. When _format=fhir is requested, the response is a Parameters resource instead. See Common Operation Behavior (operations-common.html)."

Instance: SQLQueryExport
Usage: #definition
InstanceOf: OperationDefinition
Title: "SQLQuery Export"
Description: "Export SQLQuery Library results asynchronously using the FHIR Asynchronous Interaction Request Pattern."

* id = "SQLQueryExport"
* url = "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/SQLQueryExport"
* version = "0.0.1"
* versionAlgorithmString = "semver"
* name = "SQLQueryExport"
* status = #active
* kind = #operation
* code = #sqlquery-export
* system = true
* type = true
* instance = true
* resource[0] = #Library

// Input parameters - query source (repeating, like view in $viewdefinition-export)
* parameter[+].name = #query
* parameter[=].use = #in
* parameter[=].min = 1
* parameter[=].max = "*"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].documentation = "One or more SQLQuery or SQLView Libraries to export. Each repetition identifies a single query. Applies at system and type level only; at instance level the bound Library identified by the request URL is the query source and this parameter does not apply."
* parameter[=].part[+].name = #name
* parameter[=].part[=].use = #in
* parameter[=].part[=].min = 0
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #string
* parameter[=].part[=].documentation = "Optional friendly name for the exported query output."
* parameter[=].part[+].name = #queryCanonical
* parameter[=].part[=].use = #in
* parameter[=].part[=].min = 0
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #canonical
* parameter[=].part[=].targetProfile[0] = Canonical(SQLQuery)
* parameter[=].part[=].targetProfile[1] = Canonical(SQLView)
* parameter[=].part[=].documentation = "Canonical URL of the SQLQuery or SQLView Library to export, optionally with a |version suffix pinning a version."
* parameter[=].part[+].name = #queryReference
* parameter[=].part[=].use = #in
* parameter[=].part[=].min = 0
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #Reference
* parameter[=].part[=].targetProfile[0] = Canonical(SQLQuery)
* parameter[=].part[=].targetProfile[1] = Canonical(SQLView)
* parameter[=].part[=].documentation = "Literal location of a SQLQuery or SQLView Library: a relative URL on this server, or an absolute URL. Not a canonical URL; use queryCanonical for that."
* parameter[=].part[+].name = #queryResource
* parameter[=].part[=].use = #in
* parameter[=].part[=].min = 0
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #Library
* parameter[=].part[=].targetProfile[0] = Canonical(SQLQuery)
* parameter[=].part[=].targetProfile[1] = Canonical(SQLView)
* parameter[=].part[=].documentation = "Inline SQLQuery or SQLView Library resource to execute."
* parameter[=].part[+].name = #parameters
* parameter[=].part[=].use = #in
* parameter[=].part[=].min = 0
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #Parameters
* parameter[=].part[=].documentation = "Input parameters for this query. Parameters are bound by name to parameters declared in the SQLQuery Library (Library.parameter.name)."

// Input parameters - inline ViewDefinition or SQLView table sources
* parameter[+].name = #viewResource
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].scope[2] = #instance
* parameter[=].type = #CanonicalResource
* parameter[=].targetProfile[0] = Canonical(ViewDefinition)
* parameter[=].targetProfile[1] = Canonical(SQLView)
* parameter[=].documentation = "Inline ViewDefinition or SQLView resources supplying table sources the server cannot itself resolve. Matched by canonical URL against the dependencies in the query's transitive relatedArtifact graph. Supplied resources produce no output entries; only query results do. See Common Operation Behavior (operations-common.html#table-sources)."

// Input parameters - export control (from $viewdefinition-export)
* parameter[+].name = #clientTrackingId
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #string
* parameter[=].documentation = "Client-provided tracking identifier for the export operation."

* parameter[+].name = #_format
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #code
* parameter[=].binding.strength = #extensible
* parameter[=].binding.valueSet = Canonical(ExportOutputFormatCodes)
* parameter[=].documentation = "Output format for the exported files (csv, ndjson, parquet, json). See Common Operation Behavior (operations-common.html)."

* parameter[+].name = #header
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #boolean
* parameter[=].documentation = "Include CSV headers (default true). Applies only when csv output is requested."

// Input parameters - filtering (from $viewdefinition-export)
* parameter[+].name = #patient
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #Reference
* parameter[=].documentation = "Filter exported data to the supplied patient(s)."

* parameter[+].name = #group
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #Reference
* parameter[=].documentation = "Filter exported data to members of the supplied group(s)."

* parameter[+].name = #_since
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #instant
* parameter[=].documentation = "Export only resources updated since this instant."

// Input parameters - data source
* parameter[+].name = #source
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].scope[0] = #system
* parameter[=].scope[1] = #type
* parameter[=].type = #string
* parameter[=].documentation = "External data source containing the ViewDefinition tables."

// Output parameters (same as $viewdefinition-export)
* parameter[+].name = #exportId
* parameter[=].use = #out
* parameter[=].min = 1
* parameter[=].max = "1"
* parameter[=].type = #string
* parameter[=].documentation = "Server-generated identifier assigned to the export request."

* parameter[+].name = #clientTrackingId
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #string
* parameter[=].documentation = "Echoed client tracking identifier when provided."

* parameter[+].name = #status
* parameter[=].use = #out
* parameter[=].min = 1
* parameter[=].max = "1"
* parameter[=].type = #code
* parameter[=].binding.strength = #required
* parameter[=].binding.valueSet = Canonical(ExportStatusCodes)
* parameter[=].documentation = "Status of the export (accepted, in-progress, completed, cancelled, failed)."

* parameter[+].name = #location
* parameter[=].use = #out
* parameter[=].min = 1
* parameter[=].max = "1"
* parameter[=].type = #uri
* parameter[=].documentation = "URL to poll for export status updates."

* parameter[+].name = #cancelUrl
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #uri
* parameter[=].documentation = "Optional URL for cancelling the export."

* parameter[+].name = #_format
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #code
* parameter[=].binding.strength = #extensible
* parameter[=].binding.valueSet = Canonical(OutputFormatCodes)
* parameter[=].documentation = "Format of the exported files (echoed from input if supplied)."

* parameter[+].name = #exportStartTime
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #instant
* parameter[=].documentation = "Timestamp when the export operation began."

* parameter[+].name = #exportEndTime
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #instant
* parameter[=].documentation = "Timestamp when the export operation completed."

* parameter[+].name = #exportDuration
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #integer
* parameter[=].documentation = "Duration of the export in seconds."

* parameter[+].name = #estimatedTimeRemaining
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #integer
* parameter[=].documentation = "Estimated seconds remaining until completion."

* parameter[+].name = #output
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].documentation = "Output information for each exported SQL query result. One entry per query; resources supplied via the viewResource parameter do not produce output entries."
* parameter[=].part[+].name = #name
* parameter[=].part[=].use = #out
* parameter[=].part[=].min = 1
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #string
* parameter[=].part[=].documentation = "Name assigned to the exported output."
* parameter[=].part[+].name = #location
* parameter[=].part[=].use = #out
* parameter[=].part[=].min = 1
* parameter[=].part[=].max = "*"
* parameter[=].part[=].type = #uri
* parameter[=].part[=].documentation = "Download URL(s) for the exported file(s)."
