Alias: $allowedType = http://hl7.org/fhir/StructureDefinition/operationdefinition-allowed-type

Instance: ViewDefinitionExport
Usage: #definition
InstanceOf: OperationDefinition
Title: "ViewDefinition Export"
Description: "Export a view definition. User can provide view definition references and/or resources as part of the input parameters."

* id = "ViewDefinitionExport"
* url = "http://sql-on-fhir.org/OperationDefinition/$viewdefinition-export"
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
* parameter[0].name = #view
* parameter[0].use = #in
* parameter[0].min = 1
* parameter[0].max = "*"
* parameter[0].scope[0] = #system
* parameter[0].scope[1] = #type
* parameter[0].documentation = "One or more ViewDefinitions to export. Each repetition identifies a single view."
* parameter[0].part[0].name = #name
* parameter[0].part[0].use = #in
* parameter[0].part[0].min = 0
* parameter[0].part[0].max = "1"
* parameter[0].part[0].type = #string
* parameter[0].part[0].documentation = "Optional friendly name for the exported view output."
* parameter[0].part[1].name = #viewReference
* parameter[0].part[1].use = #in
* parameter[0].part[1].min = 0
* parameter[0].part[1].max = "1"
* parameter[0].part[1].type = #Reference
* parameter[0].part[1].documentation = "Reference to a ViewDefinition stored on the server."
* parameter[0].part[2].name = #viewResource
* parameter[0].part[2].use = #in
* parameter[0].part[2].min = 0
* parameter[0].part[2].max = "1"
* parameter[0].part[2].type = #Resource
* parameter[0].part[2].documentation = "Inline ViewDefinition resource to export."
* parameter[0].part[2].extension[$allowedType].valueUri = "https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition"

* parameter[1].name = #clientTrackingId
* parameter[1].use = #in
* parameter[1].min = 0
* parameter[1].max = "1"
* parameter[1].scope[0] = #system
* parameter[1].scope[1] = #type
* parameter[1].type = #string
* parameter[1].documentation = "Client-provided tracking identifier for the export operation."

* parameter[2].name = #_format
* parameter[2].use = #in
* parameter[2].min = 0
* parameter[2].max = "1"
* parameter[2].scope[0] = #system
* parameter[2].scope[1] = #type
* parameter[2].type = #code
* parameter[2].binding.strength = #extensible
* parameter[2].binding.valueSet = Canonical(OutputFormatCodes)
* parameter[2].documentation = "Bulk export output format (for example csv, ndjson, parquet, json)."

* parameter[3].name = #header
* parameter[3].use = #in
* parameter[3].min = 0
* parameter[3].max = "1"
* parameter[3].scope[0] = #system
* parameter[3].scope[1] = #type
* parameter[3].type = #boolean
* parameter[3].documentation = "Include CSV headers (default true). Applies only when csv output is requested."

* parameter[4].name = #patient
* parameter[4].use = #in
* parameter[4].min = 0
* parameter[4].max = "*"
* parameter[4].scope[0] = #system
* parameter[4].scope[1] = #type
* parameter[4].type = #Reference
* parameter[4].documentation = "Filter exported data to the supplied patient(s)."

* parameter[5].name = #group
* parameter[5].use = #in
* parameter[5].min = 0
* parameter[5].max = "*"
* parameter[5].scope[0] = #system
* parameter[5].scope[1] = #type
* parameter[5].type = #Reference
* parameter[5].documentation = "Filter exported data to members of the supplied group(s)."

* parameter[6].name = #_since
* parameter[6].use = #in
* parameter[6].min = 0
* parameter[6].max = "1"
* parameter[6].scope[0] = #system
* parameter[6].scope[1] = #type
* parameter[6].type = #instant
* parameter[6].documentation = "Export only resources updated since this instant."

* parameter[7].name = #source
* parameter[7].use = #in
* parameter[7].min = 0
* parameter[7].max = "1"
* parameter[7].scope[0] = #system
* parameter[7].scope[1] = #type
* parameter[7].type = #string
* parameter[7].documentation = "External data source to use for the export (for example a URI or bucket name)."

// Output parameters
* parameter[8].name = #exportId
* parameter[8].use = #out
* parameter[8].min = 1
* parameter[8].max = "1"
* parameter[8].type = #string
* parameter[8].documentation = "Server-generated identifier assigned to the export request."

* parameter[9].name = #clientTrackingId
* parameter[9].use = #out
* parameter[9].min = 0
* parameter[9].max = "1"
* parameter[9].type = #string
* parameter[9].documentation = "Echoed client tracking identifier when provided."

* parameter[10].name = #status
* parameter[10].use = #out
* parameter[10].min = 1
* parameter[10].max = "1"
* parameter[10].type = #code
* parameter[10].binding.strength = #required
* parameter[10].binding.valueSet = Canonical(ExportStatusCodes)
* parameter[10].documentation = "Status of the export (accepted, in-progress, completed, cancelled, failed)."

* parameter[11].name = #location
* parameter[11].use = #out
* parameter[11].min = 1
* parameter[11].max = "1"
* parameter[11].type = #uri
* parameter[11].documentation = "URL to poll for export status updates."

* parameter[12].name = #cancelUrl
* parameter[12].use = #out
* parameter[12].min = 0
* parameter[12].max = "1"
* parameter[12].type = #uri
* parameter[12].documentation = "Optional URL for cancelling the export."

* parameter[13].name = #_format
* parameter[13].use = #out
* parameter[13].min = 0
* parameter[13].max = "1"
* parameter[13].type = #code
* parameter[13].binding.strength = #extensible
* parameter[13].binding.valueSet = Canonical(OutputFormatCodes)
* parameter[13].documentation = "Format of the exported files (echoed from input if supplied)."

* parameter[14].name = #exportStartTime
* parameter[14].use = #out
* parameter[14].min = 0
* parameter[14].max = "1"
* parameter[14].type = #instant
* parameter[14].documentation = "Timestamp when the export operation began."

* parameter[15].name = #exportEndTime
* parameter[15].use = #out
* parameter[15].min = 0
* parameter[15].max = "1"
* parameter[15].type = #instant
* parameter[15].documentation = "Timestamp when the export operation completed."

* parameter[16].name = #exportDuration
* parameter[16].use = #out
* parameter[16].min = 0
* parameter[16].max = "1"
* parameter[16].type = #integer
* parameter[16].documentation = "Duration of the export in seconds."

* parameter[17].name = #estimatedTimeRemaining
* parameter[17].use = #out
* parameter[17].min = 0
* parameter[17].max = "1"
* parameter[17].type = #integer
* parameter[17].documentation = "Estimated seconds remaining until completion."

* parameter[18].name = #output
* parameter[18].use = #out
* parameter[18].min = 0
* parameter[18].max = "*"
* parameter[18].documentation = "Output information for each exported view."
* parameter[18].part[0].name = #name
* parameter[18].part[0].use = #out
* parameter[18].part[0].min = 1
* parameter[18].part[0].max = "1"
* parameter[18].part[0].type = #string
* parameter[18].part[0].documentation = "Name assigned to the exported view output."
* parameter[18].part[1].name = #location
* parameter[18].part[1].use = #out
* parameter[18].part[1].min = 1
* parameter[18].part[1].max = "*"
* parameter[18].part[1].type = #uri
* parameter[18].part[1].documentation = "Download URL(s) for the exported file(s)."

Instance: ViewDefinitionRun
Usage: #definition
InstanceOf: OperationDefinition
Title: "ViewDefinition Run"
Description: "Execute a view definition against supplied or server data."

* id = "ViewDefinitionRun"
* url = "http://sql-on-fhir.org/OperationDefinition/$viewdefinition-run"
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
* parameter[0].name = #_format
* parameter[0].use = #in
* parameter[0].min = 1
* parameter[0].max = "1"
* parameter[0].scope[0] = #system
* parameter[0].scope[1] = #type
* parameter[0].scope[2] = #instance
* parameter[0].type = #code
* parameter[0].binding.strength = #extensible
* parameter[0].binding.valueSet = Canonical(OutputFormatCodes)
* parameter[0].documentation = "Output format for the result (for example json, ndjson, csv, parquet)."

* parameter[1].name = #header
* parameter[1].use = #in
* parameter[1].min = 0
* parameter[1].max = "1"
* parameter[1].scope[0] = #system
* parameter[1].scope[1] = #type
* parameter[1].scope[2] = #instance
* parameter[1].type = #boolean
* parameter[1].documentation = "Include CSV headers (default true). Applies only when csv output is requested."

* parameter[2].name = #viewReference
* parameter[2].use = #in
* parameter[2].min = 0
* parameter[2].max = "1"
* parameter[2].scope[0] = #system
* parameter[2].scope[1] = #type
* parameter[2].type = #Reference
* parameter[2].documentation = "Reference to a ViewDefinition stored on the server."

* parameter[3].name = #viewResource
* parameter[3].use = #in
* parameter[3].min = 0
* parameter[3].max = "1"
* parameter[3].scope[0] = #system
* parameter[3].scope[1] = #type
//* parameter[3].type = #ViewDefinition
* parameter[3].type = #CanonicalResource
* parameter[3].targetProfile = Canonical(ViewDefinition)
* parameter[3].documentation = "Inline ViewDefinition resource to execute."
* parameter[3].extension[$allowedType].valueUri = "https://sql-on-fhir.org/ig/StructureDefinition/ViewDefinition"

* parameter[4].name = #patient
* parameter[4].use = #in
* parameter[4].min = 0
* parameter[4].max = "1"
* parameter[4].scope[0] = #system
* parameter[4].scope[1] = #type
* parameter[4].scope[2] = #instance
* parameter[4].type = #Reference
* parameter[4].documentation = "Restrict execution to the specified patient."

* parameter[5].name = #group
* parameter[5].use = #in
* parameter[5].min = 0
* parameter[5].max = "*"
* parameter[5].scope[0] = #system
* parameter[5].scope[1] = #type
* parameter[5].scope[2] = #instance
* parameter[5].type = #Reference
* parameter[5].documentation = "Restrict execution to members of the given group(s)."

* parameter[6].name = #source
* parameter[6].use = #in
* parameter[6].min = 0
* parameter[6].max = "1"
* parameter[6].scope[0] = #system
* parameter[6].scope[1] = #type
* parameter[6].scope[2] = #instance
* parameter[6].type = #string
* parameter[6].documentation = "External data source to use (for example a URI or bucket name)."

* parameter[7].name = #resource
* parameter[7].use = #in
* parameter[7].min = 0
* parameter[7].max = "*"
* parameter[7].scope[0] = #system
* parameter[7].scope[1] = #type
* parameter[7].scope[2] = #instance
* parameter[7].type = #Resource
* parameter[7].documentation = "FHIR resources to transform instead of using server data."

* parameter[8].name = #_limit
* parameter[8].use = #in
* parameter[8].min = 0
* parameter[8].max = "1"
* parameter[8].scope[0] = #system
* parameter[8].scope[1] = #type
* parameter[8].scope[2] = #instance
* parameter[8].type = #integer
* parameter[8].documentation = "Maximum number of rows to return."

* parameter[9].name = #_since
* parameter[9].use = #in
* parameter[9].min = 0
* parameter[9].max = "1"
* parameter[9].scope[0] = #system
* parameter[9].scope[1] = #type
* parameter[9].scope[2] = #instance
* parameter[9].type = #instant
* parameter[9].documentation = "Include only resources modified after this instant."

// Output parameter
* parameter[10].name = #return
* parameter[10].use = #out
* parameter[10].min = 1
* parameter[10].max = "1"
* parameter[10].type = #Binary
* parameter[10].documentation = "Transformed data encoded in the requested output format."

Instance: SQLQueryRun
Usage: #definition
InstanceOf: OperationDefinition
Title: "SQLQuery Run"
Description: "Execute a SQLQuery Library against ViewDefinition tables."

* id = "SQLQueryRun"
* url = "http://sql-on-fhir.org/OperationDefinition/$sqlquery-run"
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
* parameter[0].name = #_format
* parameter[0].use = #in
* parameter[0].min = 1
* parameter[0].max = "1"
* parameter[0].scope[0] = #system
* parameter[0].scope[1] = #type
* parameter[0].scope[2] = #instance
* parameter[0].type = #code
* parameter[0].binding.strength = #extensible
* parameter[0].binding.valueSet = Canonical(SQLQueryRunOutputFormatCodes)
* parameter[0].documentation = "Output format for the result (json, ndjson, csv, parquet, fhir). Use fhir to return results as a FHIR Parameters resource."

* parameter[1].name = #header
* parameter[1].use = #in
* parameter[1].min = 0
* parameter[1].max = "1"
* parameter[1].scope[0] = #system
* parameter[1].scope[1] = #type
* parameter[1].scope[2] = #instance
* parameter[1].type = #boolean
* parameter[1].documentation = "Include CSV headers (default true). Applies only when csv output is requested."

* parameter[2].name = #queryReference
* parameter[2].use = #in
* parameter[2].min = 0
* parameter[2].max = "1"
* parameter[2].scope[0] = #system
* parameter[2].scope[1] = #type
* parameter[2].type = #Reference
* parameter[2].documentation = "Reference to a SQLQuery Library stored on the server."

* parameter[3].name = #queryResource
* parameter[3].use = #in
* parameter[3].min = 0
* parameter[3].max = "1"
* parameter[3].scope[0] = #system
* parameter[3].scope[1] = #type
* parameter[3].type = #Resource
* parameter[3].documentation = "Inline SQLQuery Library resource to execute."
* parameter[3].extension[$allowedType].valueUri = "https://sql-on-fhir.org/ig/StructureDefinition/SQLQuery"

* parameter[4].name = #parameters
* parameter[4].use = #in
* parameter[4].min = 0
* parameter[4].max = "1"
* parameter[4].scope[0] = #system
* parameter[4].scope[1] = #type
* parameter[4].scope[2] = #instance
* parameter[4].type = #Parameters
* parameter[4].documentation = "Input parameters for the query. Parameters are bound by name to parameters declared in the SQLQuery Library (Library.parameter.name). Parameter types are mapped using the appropriate value[x] type matching the declared parameter type."

* parameter[5].name = #source
* parameter[5].use = #in
* parameter[5].min = 0
* parameter[5].max = "1"
* parameter[5].scope[0] = #system
* parameter[5].scope[1] = #type
* parameter[5].scope[2] = #instance
* parameter[5].type = #string
* parameter[5].documentation = "External data source containing the ViewDefinition tables."

// Output parameter
* parameter[6].name = #return
* parameter[6].use = #out
* parameter[6].min = 1
* parameter[6].max = "1"
* parameter[6].type = #Resource
* parameter[6].extension[$allowedType][0].valueUri = "Binary"
* parameter[6].extension[$allowedType][+].valueUri = "Parameters"
* parameter[6].documentation = "Query results. Returns Binary for flat formats (csv, json, ndjson, parquet) or Parameters for _format=fhir."
