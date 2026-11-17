// Example FHIR resources for demonstrating ViewDefinition output.
// These resources are used by the IG Publisher's SQL on FHIR integration
// to dynamically generate example tables in the documentation.
//
// Author: John Grimes

// =============================================================================
// Patient resources
// =============================================================================
// Three patients with official names and addresses to demonstrate:
// - PatientDemographics (id, gender, given_name, family_name)
// - PatientAddresses (patient_id, street, use, city, zip)
// - PatientAndContactAddressUnion (resource_id, street, city, zip, is_patient)

Instance: ExamplePatient1
InstanceOf: Patient
Description: "A patient with official and usual names, home and work addresses, and a contact address."
Usage: #example
* id = "1"
* gender = #female
* name[+]
  * use = #official
  * given[+] = "Malvina"
  * given[+] = "Gerda"
  * family = "Vicario"
* name[+]
  * use = #usual
  * given[+] = "Mal"
  * family = "Vicario"
* address[+]
  * use = #home
  * line[+] = "123 Main St"
  * line[+] = "Apt 1"
  * city = "San Diego"
  * postalCode = "92101"
* address[+]
  * use = #work
  * line[+] = "456 Maplewood Dve"
  * line[+] = "Apt 2"
  * city = "New York"
  * postalCode = "10001"
* contact[+]
  * address
    * line[+] = "456 Maplewood Dve"
    * line[+] = "Apt 2"
    * city = "New York"
    * postalCode = "10001"

Instance: ExamplePatient2
InstanceOf: Patient
Description: "A patient with an official name, a home address and a contact address."
Usage: #example
* id = "2"
* gender = #male
* name[+]
  * use = #official
  * given[+] = "Yolotzin"
  * given[+] = "Adel"
  * family = "Bristow"
* address[+]
  * use = #home
  * line[+] = "789 Brookside Ave"
  * line[+] = "Apt 3"
  * city = "Los Angeles"
  * postalCode = "90001"
* contact[+]
  * address
    * line[+] = "987 Pinehurst Rd"
    * line[+] = "Apt 4"
    * city = "Chicago"
    * postalCode = "60601"

Instance: ExamplePatient3
InstanceOf: Patient
Description: "A patient with an official name, and home and work addresses."
Usage: #example
* id = "3"
* gender = #other
* name[+]
  * use = #official
  * given[+] = "Jin"
  * given[+] = "Gomer"
  * family = "Aarens"
* address[+]
  * use = #home
  * line[+] = "987 Pinehurst Rd"
  * line[+] = "Apt 4"
  * city = "Chicago"
  * postalCode = "60601"
* address[+]
  * use = #work
  * line[+] = "654 Evergreen Tce"
  * line[+] = "Apt 5"
  * city = "Houston"
  * postalCode = "77001"

// =============================================================================
// Observation resources (Blood Pressure)
// =============================================================================
// Five blood pressure observations to demonstrate the UsCoreBloodPressures view.
// Each has systolic and diastolic components with LOINC codes.

Instance: ExampleBloodPressure1
InstanceOf: Observation
Description: "A blood pressure observation of 120/80 mmHg for patient 1."
Usage: #example
* id = "1"
* status = #final
* code = http://loinc.org#85354-9 "Blood pressure panel with all children optional"
* category = http://terminology.hl7.org/CodeSystem/observation-category#vital-signs "Vital Signs"
* subject = Reference(Patient/1)
* performer = Reference(Practitioner/1)
* effectiveDateTime = "2020-01-01T00:00:00Z"
* component[+]
  * code = http://loinc.org#8480-6 "Systolic blood pressure"
  * valueQuantity
    * value = 120
    * unit = "mm[Hg]"
    * system = "http://unitsofmeasure.org"
    * code = #"mm[Hg]"
* component[+]
  * code = http://loinc.org#8462-4 "Diastolic blood pressure"
  * valueQuantity
    * value = 80
    * unit = "mm[Hg]"
    * system = "http://unitsofmeasure.org"
    * code = #"mm[Hg]"

Instance: ExampleBloodPressure2
InstanceOf: Observation
Description: "A blood pressure observation of 130/90 mmHg for patient 1."
Usage: #example
* id = "2"
* status = #final
* code = http://loinc.org#85354-9 "Blood pressure panel with all children optional"
* category = http://terminology.hl7.org/CodeSystem/observation-category#vital-signs "Vital Signs"
* subject = Reference(Patient/1)
* performer = Reference(Practitioner/1)
* effectiveDateTime = "2020-01-02T00:00:00Z"
* component[+]
  * code = http://loinc.org#8480-6 "Systolic blood pressure"
  * valueQuantity
    * value = 130
    * unit = "mm[Hg]"
    * system = "http://unitsofmeasure.org"
    * code = #"mm[Hg]"
* component[+]
  * code = http://loinc.org#8462-4 "Diastolic blood pressure"
  * valueQuantity
    * value = 90
    * unit = "mm[Hg]"
    * system = "http://unitsofmeasure.org"
    * code = #"mm[Hg]"

Instance: ExampleBloodPressure3
InstanceOf: Observation
Description: "A blood pressure observation of 140/100 mmHg for patient 2."
Usage: #example
* id = "3"
* status = #final
* code = http://loinc.org#85354-9 "Blood pressure panel with all children optional"
* category = http://terminology.hl7.org/CodeSystem/observation-category#vital-signs "Vital Signs"
* subject = Reference(Patient/2)
* performer = Reference(Practitioner/1)
* effectiveDateTime = "2020-01-03T00:00:00Z"
* component[+]
  * code = http://loinc.org#8480-6 "Systolic blood pressure"
  * valueQuantity
    * value = 140
    * unit = "mm[Hg]"
    * system = "http://unitsofmeasure.org"
    * code = #"mm[Hg]"
* component[+]
  * code = http://loinc.org#8462-4 "Diastolic blood pressure"
  * valueQuantity
    * value = 100
    * unit = "mm[Hg]"
    * system = "http://unitsofmeasure.org"
    * code = #"mm[Hg]"

Instance: ExampleBloodPressure4
InstanceOf: Observation
Description: "A blood pressure observation of 150/110 mmHg for patient 3."
Usage: #example
* id = "4"
* status = #final
* code = http://loinc.org#85354-9 "Blood pressure panel with all children optional"
* category = http://terminology.hl7.org/CodeSystem/observation-category#vital-signs "Vital Signs"
* subject = Reference(Patient/3)
* performer = Reference(Practitioner/1)
* effectiveDateTime = "2020-01-04T00:00:00Z"
* component[+]
  * code = http://loinc.org#8480-6 "Systolic blood pressure"
  * valueQuantity
    * value = 150
    * unit = "mm[Hg]"
    * system = "http://unitsofmeasure.org"
    * code = #"mm[Hg]"
* component[+]
  * code = http://loinc.org#8462-4 "Diastolic blood pressure"
  * valueQuantity
    * value = 110
    * unit = "mm[Hg]"
    * system = "http://unitsofmeasure.org"
    * code = #"mm[Hg]"

Instance: ExampleBloodPressure5
InstanceOf: Observation
Description: "A blood pressure observation of 160/120 mmHg for patient 3."
Usage: #example
* id = "5"
* status = #final
* code = http://loinc.org#85354-9 "Blood pressure panel with all children optional"
* category = http://terminology.hl7.org/CodeSystem/observation-category#vital-signs "Vital Signs"
* subject = Reference(Patient/3)
* performer = Reference(Practitioner/1)
* effectiveDateTime = "2020-01-05T00:00:00Z"
* component[+]
  * code = http://loinc.org#8480-6 "Systolic blood pressure"
  * valueQuantity
    * value = 160
    * unit = "mm[Hg]"
    * system = "http://unitsofmeasure.org"
    * code = #"mm[Hg]"
* component[+]
  * code = http://loinc.org#8462-4 "Diastolic blood pressure"
  * valueQuantity
    * value = 120
    * unit = "mm[Hg]"
    * system = "http://unitsofmeasure.org"
    * code = #"mm[Hg]"

// =============================================================================
// Condition resources
// =============================================================================
// Two conditions to demonstrate the ConditionFlat view.

Instance: ExampleCondition1
InstanceOf: Condition
Description: "An active type 2 diabetes diagnosis for patient 1, recorded during encounter 1."
Usage: #example
* id = "1"
* subject = Reference(Patient/1)
* encounter = Reference(Encounter/1)
* code = http://snomed.info/sct#44054006 "Type 2 diabetes mellitus"
* category = http://terminology.hl7.org/CodeSystem/condition-category#encounter-diagnosis "Encounter Diagnosis"
* clinicalStatus = http://terminology.hl7.org/CodeSystem/condition-clinical#active "Active"
* verificationStatus = http://terminology.hl7.org/CodeSystem/condition-ver-status#confirmed "Confirmed"
* onsetDateTime = "2020-01-01T00:00:00Z"

Instance: ExampleCondition2
InstanceOf: Condition
Description: "A resolved hypertension problem list item for patient 2, linked to encounter 2."
Usage: #example
* id = "2"
* subject = Reference(Patient/2)
* encounter = Reference(Encounter/2)
* code = http://snomed.info/sct#38341003 "Hypertensive disorder"
* category = http://terminology.hl7.org/CodeSystem/condition-category#problem-list-item "Problem List Item"
* clinicalStatus = http://terminology.hl7.org/CodeSystem/condition-clinical#resolved "Resolved"
* verificationStatus = http://terminology.hl7.org/CodeSystem/condition-ver-status#confirmed "Confirmed"
* onsetDateTime = "2020-01-02T00:00:00Z"

// =============================================================================
// Encounter resources
// =============================================================================
// Two encounters to demonstrate the EncounterFlat view.

Instance: ExampleEncounter1
InstanceOf: Encounter
Description: "An ambulatory encounter for patient 1."
Usage: #example
* id = "1"
* status = #completed
* class[+] = http://terminology.hl7.org/CodeSystem/v3-ActCode#AMB "ambulatory"
* type = http://terminology.hl7.org/CodeSystem/v3-ActCode#AMB "ambulatory"
* subject = Reference(Patient/1)
* actualPeriod
  * start = "2020-01-01T09:00:00Z"
  * end = "2020-01-01T10:00:00Z"
* participant[+]
  * actor = Reference(Practitioner/1)
* location[+]
  * location = Reference(Location/1)
* serviceProvider = Reference(Organization/1)

Instance: ExampleEncounter2
InstanceOf: Encounter
Description: "An emergency encounter for patient 2."
Usage: #example
* id = "2"
* status = #completed
* class[+] = http://terminology.hl7.org/CodeSystem/v3-ActCode#EMER "emergency"
* type = http://terminology.hl7.org/CodeSystem/v3-ActCode#EMER "emergency"
* subject = Reference(Patient/2)
* actualPeriod
  * start = "2020-01-02T14:00:00Z"
  * end = "2020-01-03T08:00:00Z"
* participant[+]
  * actor = Reference(Practitioner/1)
* location[+]
  * location = Reference(Location/2)
* serviceProvider = Reference(Organization/1)

// =============================================================================
// Supporting resources for the Encounter examples
// =============================================================================
// Minimal Practitioner, Organization, and Location instances referenced by
// ExampleEncounter1 and ExampleEncounter2.

Instance: ExamplePractitioner1
InstanceOf: Practitioner
Description: "A practitioner who participated in the example encounters."
Usage: #example
* id = "1"
* name[+]
  * family = "Smith"
  * given[+] = "Alice"

Instance: ExampleOrganization1
InstanceOf: Organization
Description: "The organisation that provided the example encounters."
Usage: #example
* id = "1"
* name = "Example Health Service"

Instance: ExampleLocation1
InstanceOf: Location
Description: "The clinic room where encounter 1 took place."
Usage: #example
* id = "1"
* name = "Clinic Room 1"
* status = #active

Instance: ExampleLocation2
InstanceOf: Location
Description: "The emergency department where encounter 2 took place."
Usage: #example
* id = "2"
* name = "Emergency Department"
* status = #active

// =============================================================================
// CodeSystem resource (vehicle hierarchy)
// =============================================================================
// A small hierarchical CodeSystem to demonstrate the CodeSystemHierarchy view.
// Mirrors the structure described in ViewDefinition-CodeSystemHierarchy-notes.md:
//   vehicle
//     car (sedan, suv, hatchback)
//     truck (pickup, semi)
//     motorbike

Instance: ExampleVehicleCodeSystem
InstanceOf: CodeSystem
Description: "A small hierarchical code system of vehicle types."
Usage: #example
* id = "vehicles"
* url = "http://example.org/CodeSystem/vehicles"
* name = "Vehicles"
* title = "Vehicles"
* description = "A small hierarchical code system of vehicle types, used to demonstrate the CodeSystemHierarchy view."
* identifier[+]
  * system = "urn:ietf:rfc:3986"
  * value = "urn:oid:2.25.158148347308242154236102391146884827570"
* status = #draft
* experimental = true
* caseSensitive = true
* hierarchyMeaning = #is-a
* content = #complete
* concept[+]
  * code = #vehicle
  * display = "Vehicle"
  * concept[+]
    * code = #car
    * display = "Car"
    * concept[+]
      * code = #sedan
      * display = "Sedan"
    * concept[+]
      * code = #suv
      * display = "SUV"
    * concept[+]
      * code = #hatchback
      * display = "Hatchback"
  * concept[+]
    * code = #truck
    * display = "Truck"
    * concept[+]
      * code = #pickup
      * display = "Pickup"
    * concept[+]
      * code = #semi
      * display = "Semi"
  * concept[+]
    * code = #motorbike
    * display = "Motorbike"

// =============================================================================
// QuestionnaireResponse resources
// =============================================================================
// Two responses to demonstrate the QuestionnaireResponseItems view, which uses
// `repeat` to recursively flatten nested items into a single table.

Instance: ExampleQuestionnaireResponse1
InstanceOf: QuestionnaireResponse
Description: "A PHQ-9 questionnaire response for patient 1 with integer answers."
Usage: #example
* id = "1"
* status = #completed
* questionnaire = "http://example.org/q/phq9"
* subject = Reference(Patient/1)
* authored = "2024-03-15T10:30:00+10:00"
* item[+]
  * linkId = "q1"
  * text = "Little interest or pleasure in doing things"
  * answer[+]
    * valueInteger = 2
* item[+]
  * linkId = "q2"
  * text = "Feeling down, depressed, or hopeless"
  * answer[+]
    * valueInteger = 1

Instance: ExampleQuestionnaireResponse2
InstanceOf: QuestionnaireResponse
Description: "A health history questionnaire response for patient 2 with nested groups and string, date and boolean answers."
Usage: #example
* id = "2"
* status = #completed
* questionnaire = "http://example.org/q/health-history"
* subject = Reference(Patient/2)
* authored = "2024-03-16T14:20:00+10:00"
* item[+]
  * linkId = "demographics"
  * text = "Demographics"
  * item[+]
    * linkId = "name"
    * text = "Full name"
    * answer[+]
      * valueString = "John Smith"
  * item[+]
    * linkId = "dob"
    * text = "Date of birth"
    * answer[+]
      * valueDate = "1980-05-22"
* item[+]
  * linkId = "conditions"
  * text = "Medical conditions"
  * item[+]
    * linkId = "diabetes"
    * text = "Diabetes"
    * answer[+]
      * valueBoolean = true
  * item[+]
    * linkId = "hypertension"
    * text = "Hypertension"
    * answer[+]
      * valueBoolean = false
