# Tasks

## 1. Create example FHIR resources

- [x] 1.1 Create Patient example resources in FSH matching PatientDemographics
      and PatientAddresses expected output (3 patients with names, genders, and
      addresses).
- [x] 1.2 Create Patient contact data for PatientAndContactAddressUnion example.
- [x] 1.3 Create Observation example resources for UsCoreBloodPressures (5 blood
      pressure observations with systolic/diastolic components).
- [x] 1.4 Create Condition example resources for ConditionFlat example.
- [x] 1.5 Create Encounter example resources for EncounterFlat example.

## 2. Configure IG Publisher for ViewDefinitions

- [x] 2.1 Add `viewDefinition` parameters to `sushi-config.yaml` for each
      ViewDefinition example.
- [x] 2.2 Verify the IG builds successfully with SUSHI and IG Publisher.
- [x] 2.3 Confirm ViewDefinitions are processed and SQLite database is
      populated.

## 3. Update example notes with SQL queries

- [x] 3.1 Update `ViewDefinition-PatientDemographics-notes.md` to use `{% sql
      %}` tag.
- [x] 3.2 Update `ViewDefinition-ShareablePatientDemographics-notes.md` to use
      `{% sql %}` tag.
- [x] 3.3 Update `ViewDefinition-PatientAddresses-notes.md` to use `{% sql %}`
      tag.
- [x] 3.4 Update `ViewDefinition-PatientAndContactAddressUnion-notes.md` to use
      `{% sql %}` tag.
- [x] 3.5 Update `ViewDefinition-UsCoreBloodPressures-notes.md` to use `{% sql
      %}` tag.
- [x] 3.6 Create `ViewDefinition-ConditionFlat-notes.md` with `{% sql %}` tag.
- [x] 3.7 Create `ViewDefinition-EncounterFlat-notes.md` with `{% sql %}` tag.

## 4. Validation

- [x] 4.1 Run full IG build (`npm run build:ig`) and verify no new errors or
      warnings. The six remaining errors also occur on `main` and come from
      upstream IG Publisher handling of additional resources.
- [x] 4.2 Verify generated HTML pages contain the expected tables.
- [x] 4.3 Compare generated tables with previous static tables to ensure data
      matches.
