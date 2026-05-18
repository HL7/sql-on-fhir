Instance:   PatientDemographics
InstanceOf: ViewDefinition
Description: """A minimal example of a patient demographics view.
This view uses the first 'official' patient name for our demographics table."""
Usage:  #example
* name = "patient_demographics"
* status = #draft
* resource = #Patient
* select[+]
  * column[+]
    * path = "getResourceKey()"
    * name = "id"
  * column[+]
    * path = "gender"
    * name = "gender"
* select[+]
  * forEach = "name.where(use = 'official').first()"
  * column[+]
    * path = "given.join(' ')"
    * name = "given_name"
    * description = "A single given name field with all names joined together."
  * column[+]
    * path = "family"
    * name = "family_name"

Instance:   ShareablePatientDemographics
InstanceOf: ViewDefinition
Description: """
Creates the same view as the 'PatientDemographics' example, but applies both the
ShareableViewDefinition and TabularViewDefinition profiles.
"""
Usage:  #example
* name = "patient_demographics"
* url = "https://sql-on-fhir.org/ig/StructureDefinition/ShareablePatientDemographics"
* fhirVersion[+] = #4.0
* fhirVersion[+] = #5.0
* status = #draft
* resource = #Patient
* meta
  * profile[+] = "https://sql-on-fhir.org/ig/StructureDefinition/ShareableViewDefinition"
  * profile[+] = "https://sql-on-fhir.org/ig/StructureDefinition/TabularViewDefinition"
* select[+]
  * column[+]
    * path = "getResourceKey()"
    * name = "id"
    * type = "string"
  * column[+]
    * path = "gender"
    * name = "gender"
    * type = "code"
* select[+]
  * forEach = "name.where(use = 'official').first()"
  * column[+]
    * path = "given.join(' ')"
    * name = "given_name"
    * description = "A single given name field with all names joined together."
    * type = "string"
  * column[+]
    * path = "family"
    * name = "family_name"
    * type = "string"

Instance:   PatientAddresses
InstanceOf: ViewDefinition
Description: """An example of unnesting patient addresses into multiple
rows.

This view uses `forEach` to indicate we are unrolling these into separate rows. 
The `join` function is used to create a single address line.
"""
Usage:  #example
* name = "patient_addresses"
* status = #draft
* resource = #Patient
* select[+]
  * column[+]
    * path = "getResourceKey()"
    * name = "patient_id"
* select[+]
  * forEach = "address"
  * column[+]
    * path = "line.join('\n')"
    * name = "street"
    * description = "The full street address, including newlines if present."
  * column[+]
    * path = "use"
    * name = "use"
  * column[+]
    * path = "city"
    * name = "city"
  * column[+]
    * path = "postalCode"
    * name = "zip"

Instance:   PatientAndContactAddressUnion
InstanceOf: ViewDefinition
Description: """An example of unnesting patient addresses and contact addresss
into multiple rows, which are unioned together into a single table.
"""
Usage:  #example
* name = "patient_and_contact_addresses"
* status = #draft
* resource = #Patient
* select[+]
  * column[+]
    * path = "getResourceKey()"
    * name = "resource_id"
  * unionAll[+]
    * forEach = "address"
    * column[+]
      * path = "line.join('\n')"
      * name = "street"
    * column[+]
      * path = "city"
      * name = "city"
    * column[+]
      * path = "postalCode"
      * name = "zip"
    * column[+]
      * path = "true"
      * name = "is_patient"
  * unionAll[+]
    * forEach = "contact.address"
    * column[+]
      * path = "line.join('\n')"
      * name = "street"
    * column[+]
      * path = "city"
      * name = "city"
    * column[+]
      * path = "postalCode"
      * name = "zip"
    * column[+]
      * path = "false"
      * name = "is_patient"

Instance: UsCoreBloodPressures
InstanceOf: ViewDefinition
Description: """A simple view of blood pressure observations, with separate columns for 
systolic and diastolic values."""
Usage: #example
* name =  "us_core_blood_pressures"
* status = #draft
* resource =  #Observation
* constant[+]
  * name = "systolic_bp"
  * valueCode = #8480-6
* constant[+]
  * name = "diastolic_bp"
  * valueCode = #8462-4
* constant[+]
  * name = "bp_code"
  * valueCode = #85354-9
* select[+]
  * column[+]
    * path = "getResourceKey()"
    * name = "id"
  * column[+]
    * path = "subject.getReferenceKey(Patient)"
    * name = "patient_id"
    * description = "Can be used to join to patient tables created by other views."
  * column[+]
    * path =  "effective.ofType(dateTime)"
    * name = "effective_date_time"
* select[+]
  * forEach = "component.where(code.coding.exists(system='http://loinc.org' and code=%systolic_bp)).first()"
  * column[+]
    * name = "sbp_quantity_system"
    * path = "value.ofType(Quantity).system"
  * column[+]
    * name = "sbp_quantity_code"
    * path = "value.ofType(Quantity).code"
  * column[+]
    * name = "sbp_quantity_unit"
    * path = "value.ofType(Quantity).unit"
  * column[+]
    * name = "sbp_quantity_value"
    * path = "value.ofType(Quantity).value"
* select[+]
  * forEach = "component.where(code.coding.exists(system='http://loinc.org' and code=%diastolic_bp)).first()"
  * column[+]
    * name = "dbp_quantity_system"
    * path = "value.ofType(Quantity).system"
  * column[+]
    * name = "dbp_quantity_code"
    * path = "value.ofType(Quantity).code"
  * column[+]
    * name = "dbp_quantity_unit"
    * path = "value.ofType(Quantity).unit"
  * column[+]
    * name = "dbp_quantity_value"
    * path = "value.ofType(Quantity).value"
* where[+]
  * path = "code.coding.exists(system='http://loinc.org' and code=%bp_code)"

Instance: ConditionFlat
InstanceOf: ViewDefinition
Description: """A simple view for flattening a Condition resource. Some of the
more commonly used fields are included in this flat view. A notable point
is flattening of `category.coding` fields with one `forEach` construct as
FHIRPath will take care of handling of nested arrays."""
Usage: #example
* name = "condition_flat"
* status = #draft
* resource = #Condition
* select[+]
  * column[+]
    * path = "getResourceKey()"
    * name = "id"
  * column[+]
    * path = "subject.getReferenceKey(Patient)"
    * name = "patient_id"
  * column[+]
    * path = "encounter.getReferenceKey(Encounter)"
    * name = "encounter_id"
  * column[+]
    * path = "onset.ofType(dateTime)"
    * name = "onset_datetime"
    * type = "dateTime"
* select[+]
  * forEachOrNull = "code.coding"
  * column[+]
    * name = "system"
    * path = "system"
    * type = "uri"
  * column[+]
    * path = "code"
    * name = "code"
* select[+]
  * forEachOrNull = "category.coding"
  * column[+]
    * path = "code"
    * name = "category"
* select[+]
  * forEachOrNull = "clinicalStatus.coding"
  * column[+]
    * path = "code"
    * name = "clinical_status"
* select[+]
  * forEachOrNull = "verificationStatus.coding"
  * column[+]
    * path = "code"
    * name = "verification_status"

Instance: PatientNamesWithIndex
InstanceOf: ViewDefinition
Description: """An example demonstrating the use of %rowIndex to capture the
position of elements within a collection. This is useful for preserving FHIR
ordering semantics and creating surrogate keys that combine resource ID with
element position."""
Usage: #example
* name = "patient_names_with_index"
* status = #draft
* resource = #Patient
* select[+]
  * column[+]
    * path = "getResourceKey()"
    * name = "patient_id"
* select[+]
  * forEach = "name"
  * column[+]
    * path = "%rowIndex"
    * name = "name_index"
    * type = "integer"
    * description = "The 0-based position of this name in the patient's name array."
  * column[+]
    * path = "use"
    * name = "use"
  * column[+]
    * path = "family"
    * name = "family"
  * column[+]
    * path = "given.join(' ')"
    * name = "given"

Instance: EncounterFlat
InstanceOf: ViewDefinition
Description: """A simple view for flattening an Encounter resource. Some of the
more commonly used fields are included in this flat view. Note this is valid
for an R4 Encounter resource but not R5 (hence the `fhirVersion`)."""
Usage: #example
* name = "encounter_flat"
* status = #draft
* resource = #Encounter
* fhirVersion[+] = #4.0
* select[+]
  * column[+]
    * path = "getResourceKey()"
    * name = "id"
  * column[+]
    * path = "status"
    * name = "status"
  * column[+]
    * path = "subject.getReferenceKey(Patient)"
    * name = "patient_id"
  * column[+]
    * path = "serviceProvider.getReferenceKey(Organization)"
    * name = "service_org_id"
  * column[+]
    * path = "period.start"
    * name = "period_start"
  * column[+]
    * path = "period.end"
    * name = "period_end"
  * column[+]
    * path = "episodeOfCare.getReferenceKey(EpisodeOfCare)"
    * name = "EpisodeOfCareId"
* select[+]
  * forEachOrNull = "type.coding"
  * column[+]
    * path = "system"
    * name = "type_sys"
  * column[+]
    * path = "code"
    * name = "type_code"
* select[+]
  * forEachOrNull = "participant"
  * column[+]
    * path = "individual.getReferenceKey(Practitioner)"
    * name = "practitioner_id"
* select[+]
  * forEachOrNull = "location"
  * column[+]
    * path = "location.getReferenceKey(Location)"
    * name = "location_id"

Instance: QuestionnaireResponseItems
InstanceOf: ViewDefinition
Description: """Demonstrates using the `repeat` directive to recursively flatten
nested QuestionnaireResponse items. Unlike `forEach`, which only unnests a single
level, `repeat` traverses all levels of nesting to produce one row per item
regardless of depth. This is useful for analysing survey responses where questions
may be grouped into nested sections."""
Usage: #example
* name = "questionnaire_response_items"
* status = #draft
* resource = #QuestionnaireResponse
* select[+]
  * column[+]
    * path = "getResourceKey()"
    * name = "id"
    * description = "Unique questionnaire response identifier"
  * column[+]
    * path = "questionnaire"
    * name = "questionnaire"
    * description = "Canonical URL of the questionnaire"
  * column[+]
    * path = "subject.getReferenceKey(Patient)"
    * name = "patient_id"
    * description = "Patient identifier"
  * column[+]
    * path = "authored"
    * name = "authored"
    * description = "Date and time the response was authored"
* select[+]
  * repeat[+] = "item"
  * column[+]
    * path = "linkId"
    * name = "item_link_id"
    * description = "Unique identifier for this item within the questionnaire"
  * column[+]
    * path = "text"
    * name = "item_text"
    * description = "Question text"
  * column[+]
    * path = "answer.value.ofType(string)"
    * name = "answer_value_string"
    * description = "String answer value"
  * column[+]
    * path = "answer.value.ofType(integer)"
    * name = "answer_value_integer"
    * description = "Integer answer value"
  * column[+]
    * path = "answer.value.ofType(boolean)"
    * name = "answer_value_boolean"
    * description = "Boolean answer value"
  * column[+]
    * path = "answer.value.ofType(date)"
    * name = "answer_value_date"
    * description = "Date answer value"

Instance: CodeSystemHierarchy
InstanceOf: ViewDefinition
Description: """Demonstrates using `repeat` with nested `select` to traverse a
CodeSystem concept hierarchy. This produces parent-child code pairs by using
`repeat` to walk down the concept tree and a nested `forEach` to extract each
child concept at every level. Useful for building concept maps or analysing
hierarchical terminologies."""
Usage: #example
* name = "code_system_hierarchy"
* status = #draft
* resource = #CodeSystem
* select[+]
  * column[+]
    * path = "getResourceKey()"
    * name = "id"
    * description = "CodeSystem identifier"
* select[+]
  * repeat[+] = "concept"
  * column[+]
    * path = "code"
    * name = "parent_code"
    * description = "Code of the parent concept in the hierarchy"
  * select[+]
    * forEach = "concept"
    * column[+]
      * path = "code"
      * name = "code"
      * description = "Code of the child concept"
