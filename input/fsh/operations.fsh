Alias: $allowedType = http://hl7.org/fhir/StructureDefinition/operationdefinition-allowed-type

Instance: SQLRun
Usage: #definition
InstanceOf: OperationDefinition
Title: "SQL Run"
Description: "Execute a ViewDefinition, SQLQuery Library or SQLView Library and return the result in the requested output format."

* id = "SQLRun"
* url = "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/SQLRun"
* version = "0.0.1"
* versionAlgorithmString = "semver"
* name = "SQLRun"
* status = #active
* kind = #operation
* code = #sql-run
* system = true
* type = false
* instance = false

// Input parameters - naming the subject
* parameter[+].name = #subjectCanonical
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #canonical
* parameter[=].targetProfile[0] = Canonical(ViewDefinition)
* parameter[=].targetProfile[1] = Canonical(SQLQuery)
* parameter[=].targetProfile[2] = Canonical(SQLView)
* parameter[=].documentation = "Canonical URL of the ViewDefinition, SQLQuery Library or SQLView Library to execute, optionally with a |version suffix pinning a version. Exactly one of subjectCanonical, subjectReference and subjectResource is supplied; supplying none, or more than one, is rejected with 400 Bad Request."

* parameter[+].name = #subjectReference
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #Reference
* parameter[=].targetProfile[0] = Canonical(ViewDefinition)
* parameter[=].targetProfile[1] = Canonical(SQLQuery)
* parameter[=].targetProfile[2] = Canonical(SQLView)
* parameter[=].documentation = "Literal location of the subject to execute: a relative URL on this server, or an absolute URL. Not a canonical URL; use subjectCanonical for that. Exactly one of subjectCanonical, subjectReference and subjectResource is supplied; supplying none, or more than one, is rejected with 400 Bad Request."

* parameter[+].name = #subjectResource
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #CanonicalResource
* parameter[=].targetProfile[0] = Canonical(ViewDefinition)
* parameter[=].targetProfile[1] = Canonical(SQLQuery)
* parameter[=].targetProfile[2] = Canonical(SQLView)
* parameter[=].documentation = "Inline ViewDefinition, SQLQuery Library or SQLView Library to execute. Exactly one of subjectCanonical, subjectReference and subjectResource is supplied; supplying none, or more than one, is rejected with 400 Bad Request. Carries a resource, so it requires POST. The declared type is CanonicalResource because ViewDefinition is a logical model rather than a FHIR resource; see Common Operation Behavior (operations-common.html#declared-type)."

* parameter[+].name = #parameters
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #Parameters
* parameter[=].documentation = "Input parameter values for the subject, bound by name to the parameters the Library declares (Library.parameter.name), using the value[x] type matching each declared type. Permitted only where the subject is a SQLQuery or SQLView; supplying it where the subject is a ViewDefinition is rejected with 400 Bad Request, because a ViewDefinition declares no parameters. Carries a resource, so it requires POST."

* parameter[+].name = #context
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].type = #CanonicalResource
* parameter[=].targetProfile[0] = Canonical(ViewDefinition)
* parameter[=].targetProfile[1] = Canonical(SQLView)
* parameter[=].documentation = "Supporting artefacts the server cannot itself resolve, supplied inline and matched by canonical URL against the dependencies in the subject's transitive relatedArtifact graph. Accepts inline resources only; there is no context by canonical URL, because a URL is exactly what the server has already failed to resolve. Carries a resource, so it requires POST. See Common Operation Behavior (operations-common.html#context)."

* parameter[+].name = #resource
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].type = #Resource
* parameter[=].documentation = "FHIR resources to transform instead of using server data. Repeatable. A Bundle supplied here is unwrapped: the view runs against each Bundle.entry[*].resource rather than against the Bundle itself. Permitted only where the subject is a ViewDefinition; supplying it where the subject is a SQLQuery or SQLView is rejected with 400 Bad Request, because how inline resources reach each dependency view is not specified. Carries a resource, so it requires POST. See OperationDefinition-SQLRun notes (Resource parameter and Bundle inputs)."

// Input parameters - output shape
* parameter[+].name = #_format
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #code
* parameter[=].binding.strength = #extensible
* parameter[=].binding.valueSet = Canonical(OutputFormatCodes)
* parameter[=].documentation = "Output format for the result (json, ndjson, csv, parquet, fhir). Use fhir to return results as a FHIR Parameters resource. Optional; if omitted, the server returns ndjson by default. See Common Operation Behavior (operations-common.html)."

* parameter[+].name = #header
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #boolean
* parameter[=].documentation = "Include CSV headers (default true). Applies only when csv output is requested."

// Input parameters - filtering (identical on both data operations)
* parameter[+].name = #patient
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].type = #Reference
* parameter[=].documentation = "Restrict the FHIR resources feeding the view, before projection, to the supplied patient(s). Where the subject is a SQLQuery or SQLView, that means before the SQL executes. An unresolvable patient is rejected with 400 Bad Request. See Common Operation Behavior (operations-common.html#patient-filter)."

* parameter[+].name = #group
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].type = #Reference
* parameter[=].documentation = "Restrict the FHIR resources feeding the view, before projection, to members of the supplied group(s). Where the subject is a SQLQuery or SQLView, that means before the SQL executes. An unresolvable group is rejected with 400 Bad Request. See Common Operation Behavior (operations-common.html#group-filter)."

* parameter[+].name = #_since
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #instant
* parameter[=].documentation = "Include only resources whose state changed after this instant. See Common Operation Behavior (operations-common.html#since-filter)."

* parameter[+].name = #source
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #string
* parameter[=].documentation = "External data source to read from instead of the server's own data (for example a URI or bucket name). Where the subject is a SQLQuery or SQLView, this is where the ViewDefinition tables the query selects from are found."

* parameter[+].name = #_limit
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #integer
* parameter[=].documentation = "Maximum number of rows to return."

// Output parameter
* parameter[+].name = #return
* parameter[=].use = #out
* parameter[=].min = 1
* parameter[=].max = "1"
* parameter[=].type = #Binary
* parameter[=].documentation = "Result rows in the requested output format, returned as a raw binary stream in the format's native media type, not a serialized Binary resource envelope. When _format=fhir is requested, the response is a Parameters resource instead. See Common Operation Behavior (operations-common.html)."

Instance: SQLExport
Usage: #definition
InstanceOf: OperationDefinition
Title: "SQL Export"
Description: "Export one or more ViewDefinitions, SQLQuery Libraries and SQLView Libraries as a single asynchronous job, using the FHIR Asynchronous Interaction Request Pattern."

* id = "SQLExport"
* url = "http://hl7.org/fhir/uv/sql-on-fhir/OperationDefinition/SQLExport"
* version = "0.0.1"
* versionAlgorithmString = "semver"
* name = "SQLExport"
* status = #active
* kind = #operation
* code = #sql-export
* system = true
* type = false
* instance = false

// Input parameters - naming the subjects
* parameter[+].name = #subject
* parameter[=].use = #in
* parameter[=].min = 1
* parameter[=].max = "*"
* parameter[=].documentation = "One or more artefacts to export, in any mixture of ViewDefinitions, SQLQuery Libraries and SQLView Libraries. Each repetition names a single subject and produces exactly one output entry in the manifest. A request supplying no subject is rejected with 400 Bad Request, as is a request in which two repetitions would produce the same output name."
* parameter[=].part[+].name = #name
* parameter[=].part[=].use = #in
* parameter[=].part[=].min = 0
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #string
* parameter[=].part[=].documentation = "Name for this subject's output entry in the manifest. Where it is omitted the server uses the subject's own name element, and where the subject declares none, a server-generated identifier. Output names are unique across the job."
* parameter[=].part[+].name = #subjectCanonical
* parameter[=].part[=].use = #in
* parameter[=].part[=].min = 0
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #canonical
* parameter[=].part[=].targetProfile[0] = Canonical(ViewDefinition)
* parameter[=].part[=].targetProfile[1] = Canonical(SQLQuery)
* parameter[=].part[=].targetProfile[2] = Canonical(SQLView)
* parameter[=].part[=].documentation = "Canonical URL of the ViewDefinition, SQLQuery Library or SQLView Library to export, optionally with a |version suffix pinning a version. Exactly one of subjectCanonical, subjectReference and subjectResource is supplied in each repetition."
* parameter[=].part[+].name = #subjectReference
* parameter[=].part[=].use = #in
* parameter[=].part[=].min = 0
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #Reference
* parameter[=].part[=].targetProfile[0] = Canonical(ViewDefinition)
* parameter[=].part[=].targetProfile[1] = Canonical(SQLQuery)
* parameter[=].part[=].targetProfile[2] = Canonical(SQLView)
* parameter[=].part[=].documentation = "Literal location of the subject to export: a relative URL on this server, or an absolute URL. Not a canonical URL; use subjectCanonical for that. Exactly one of subjectCanonical, subjectReference and subjectResource is supplied in each repetition."
* parameter[=].part[+].name = #subjectResource
* parameter[=].part[=].use = #in
* parameter[=].part[=].min = 0
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #CanonicalResource
* parameter[=].part[=].targetProfile[0] = Canonical(ViewDefinition)
* parameter[=].part[=].targetProfile[1] = Canonical(SQLQuery)
* parameter[=].part[=].targetProfile[2] = Canonical(SQLView)
* parameter[=].part[=].documentation = "Inline ViewDefinition, SQLQuery Library or SQLView Library to export. Exactly one of subjectCanonical, subjectReference and subjectResource is supplied in each repetition. The declared type is CanonicalResource because ViewDefinition is a logical model rather than a FHIR resource; see Common Operation Behavior (operations-common.html#declared-type)."
* parameter[=].part[+].name = #parameters
* parameter[=].part[=].use = #in
* parameter[=].part[=].min = 0
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #Parameters
* parameter[=].part[=].documentation = "Input parameter values for this subject, bound by name to the parameters the Library declares (Library.parameter.name). Permitted only where this repetition's subject is a SQLQuery or SQLView; supplying it where the subject is a ViewDefinition is rejected with 400 Bad Request, because a ViewDefinition declares no parameters."

// Input parameters - supporting artefacts, supplied once for the whole job
* parameter[+].name = #context
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].type = #CanonicalResource
* parameter[=].targetProfile[0] = Canonical(ViewDefinition)
* parameter[=].targetProfile[1] = Canonical(SQLView)
* parameter[=].documentation = "Supporting artefacts the server cannot itself resolve, supplied inline and matched by canonical URL against the dependencies in the subjects' transitive relatedArtifact graphs. Applies to the job as a whole rather than to one subject, so an artefact several subjects depend on is supplied once. Accepts inline resources only; there is no context by canonical URL, because a URL is exactly what the server has already failed to resolve. A context entry produces no output entry. See Common Operation Behavior (operations-common.html#context)."

// Input parameters - export control
* parameter[+].name = #clientTrackingId
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #string
* parameter[=].documentation = "Client-provided tracking identifier for the export job, echoed in the manifest."

* parameter[+].name = #_format
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #code
* parameter[=].binding.strength = #extensible
* parameter[=].binding.valueSet = Canonical(ExportOutputFormatCodes)
* parameter[=].documentation = "Output format for the exported files (csv, ndjson, parquet, json). Optional; if omitted, the server uses ndjson irrespective of Accept. Requesting fhir is rejected with 400 Bad Request, because an export produces flat files. See Common Operation Behavior (operations-common.html)."

* parameter[+].name = #header
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #boolean
* parameter[=].documentation = "Include CSV headers (default true). Applies only when csv output is requested."

// Input parameters - filtering (identical on both data operations, stated once for the job)
* parameter[+].name = #patient
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].type = #Reference
* parameter[=].documentation = "Restrict the FHIR resources feeding every subject in the job, before projection, to the supplied patient(s). Where a subject is a SQLQuery or SQLView, that means before the SQL executes. An unresolvable patient is rejected with 400 Bad Request. See Common Operation Behavior (operations-common.html#patient-filter)."

* parameter[+].name = #group
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].type = #Reference
* parameter[=].documentation = "Restrict the FHIR resources feeding every subject in the job, before projection, to members of the supplied group(s). Where a subject is a SQLQuery or SQLView, that means before the SQL executes. An unresolvable group is rejected with 400 Bad Request. See Common Operation Behavior (operations-common.html#group-filter)."

* parameter[+].name = #_since
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #instant
* parameter[=].documentation = "Include only resources whose state changed after this instant. See Common Operation Behavior (operations-common.html#since-filter)."

* parameter[+].name = #source
* parameter[=].use = #in
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #string
* parameter[=].documentation = "External data source to read from instead of the server's own data (for example a URI or bucket name). Where a subject is a SQLQuery or SQLView, this is where the ViewDefinition tables the query selects from are found."

// Output parameters - the manifest, plus the interim polling subset
* parameter[+].name = #exportId
* parameter[=].use = #out
* parameter[=].min = 1
* parameter[=].max = "1"
* parameter[=].type = #string
* parameter[=].documentation = "Server-generated identifier assigned to the export job."

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
* parameter[=].binding.valueSet = Canonical(ExportOutputFormatCodes)
* parameter[=].documentation = "Format of the exported files (echoed from input if supplied)."

* parameter[+].name = #exportStartTime
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #instant
* parameter[=].documentation = "Timestamp when the export job began."

* parameter[+].name = #exportEndTime
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].type = #instant
* parameter[=].documentation = "Timestamp when the export job completed."

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
* parameter[=].documentation = "Estimated seconds remaining until completion. Interim polling responses only."

* parameter[+].name = #output
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "*"
* parameter[=].documentation = "Output information for each exported subject. Exactly one entry per subject repetition, and none for a context entry. Neither manifest order nor computation order is guaranteed; clients correlate entries by name."
* parameter[=].part[+].name = #name
* parameter[=].part[=].use = #out
* parameter[=].part[=].min = 1
* parameter[=].part[=].max = "1"
* parameter[=].part[=].type = #string
* parameter[=].part[=].documentation = "Name assigned to this subject's output, derived from subject.name, else the subject's own name element, else a server-generated identifier."
* parameter[=].part[+].name = #location
* parameter[=].part[=].use = #out
* parameter[=].part[=].min = 1
* parameter[=].part[=].max = "*"
* parameter[=].part[=].type = #uri
* parameter[=].part[=].documentation = "Download URL(s) for the exported file(s)."
