# View Definition Examples

## ADDED Requirements

### Requirement: ViewDefinition examples include executable SQL demonstrations

Each ViewDefinition example in the IG SHALL include an embedded SQL query that
demonstrates execution of the view over example FHIR resources, producing a
dynamically generated output table.

#### Scenario: PatientDemographics example displays dynamic output

- **WHEN** the IG is built
- **THEN** the PatientDemographics example page SHALL display a table generated
  from executing the view over example Patient resources
- **AND** the table SHALL contain columns: id, gender, given_name, family_name

#### Scenario: PatientAddresses example displays dynamic output

- **WHEN** the IG is built
- **THEN** the PatientAddresses example page SHALL display a table generated
  from executing the view over example Patient resources with addresses
- **AND** the table SHALL contain columns: patient_id, street, use, city, zip

#### Scenario: PatientAndContactAddressUnion example displays dynamic output

- **WHEN** the IG is built
- **THEN** the PatientAndContactAddressUnion example page SHALL display a table
  generated from executing the view over example Patient resources with both
  patient and contact addresses
- **AND** the table SHALL contain columns: resource_id, street, city, zip,
  is_patient

#### Scenario: UsCoreBloodPressures example displays dynamic output

- **WHEN** the IG is built
- **THEN** the UsCoreBloodPressures example page SHALL display a table generated
  from executing the view over example Observation resources
- **AND** the table SHALL contain blood pressure measurements with systolic and
  diastolic components

#### Scenario: ConditionFlat example displays dynamic output

- **WHEN** the IG is built
- **THEN** the ConditionFlat example page SHALL display a table generated from
  executing the view over example Condition resources
- **AND** the table SHALL contain columns including: id, patient_id, code,
  category, clinical_status

#### Scenario: EncounterFlat example displays dynamic output

- **WHEN** the IG is built
- **THEN** the EncounterFlat example page SHALL display a table generated from
  executing the view over example Encounter resources
- **AND** the table SHALL contain columns including: id, status, patient_id,
  period_start, period_end

### Requirement: Example FHIR resources exist for ViewDefinition demonstrations

The IG SHALL include example FHIR resources that can be processed by the
ViewDefinition examples to produce meaningful output tables.

#### Scenario: Patient example resources exist

- **WHEN** the IG is built
- **THEN** example Patient resources SHALL exist with:
  - Official names (given and family)
  - Gender values
  - Multiple addresses with use, city, and postal code
  - Contact information with addresses

#### Scenario: Observation example resources exist

- **WHEN** the IG is built
- **THEN** example Observation resources SHALL exist representing blood pressure
  measurements with:
  - LOINC code 85354-9 for blood pressure
  - Systolic component (LOINC 8480-6)
  - Diastolic component (LOINC 8462-4)
  - Patient references
  - Effective date/time

#### Scenario: Condition example resources exist

- **WHEN** the IG is built
- **THEN** example Condition resources SHALL exist with:
  - Code with coding
  - Category
  - Clinical status
  - Patient and encounter references

#### Scenario: Encounter example resources exist

- **WHEN** the IG is built
- **THEN** example Encounter resources SHALL exist (R4 compatible) with:
  - Status
  - Type with coding
  - Patient reference
  - Period with start and end
  - Participant and location references
