# Tasks

## 1. Create example FHIR resources

- [ ] 1.1 Create Patient example resources in FSH matching PatientDemographics
      and PatientAddresses expected output (3 patients with names, genders, and
      addresses).
- [ ] 1.2 Create Patient contact data for PatientAndContactAddressUnion example.
- [ ] 1.3 Create Observation example resources for UsCoreBloodPressures (5 blood
      pressure observations with systolic/diastolic components).
- [ ] 1.4 Create Condition example resources for ConditionFlat example.
- [ ] 1.5 Create Encounter example resources for EncounterFlat example.

## 2. Configure IG Publisher for ViewDefinitions

- [ ] 2.1 Add `path-viewdef` parameters to `sushi-config.yaml` for each
      ViewDefinition example.
- [ ] 2.2 Verify the IG builds successfully with SUSHI and IG Publisher.
- [ ] 2.3 Confirm ViewDefinitions are processed and SQLite database is
      populated.

## 3. Update example notes with SQL queries

- [ ] 3.1 Update `Binary-PatientDemographics-notes.md` to use `{% sql %}` tag.
- [ ] 3.2 Update `Binary-ShareablePatientDemographics-notes.md` to use `{% sql
      %}` tag.
- [ ] 3.3 Update `Binary-PatientAddresses-notes.md` to use `{% sql %}` tag.
- [ ] 3.4 Update `Binary-PatientAndContactAddressUnion-notes.md` to use `{% sql
      %}` tag.
- [ ] 3.5 Update `Binary-UsCoreBloodPressures-notes.md` to use `{% sql %}` tag.
- [ ] 3.6 Create `Binary-ConditionFlat-notes.md` with `{% sql %}` tag.
- [ ] 3.7 Create `Binary-EncounterFlat-notes.md` with `{% sql %}` tag.

## 4. Validation

- [ ] 4.1 Run full IG build (`npm run build:ig`) and verify no errors.
- [ ] 4.2 Verify generated HTML pages contain the expected tables.
- [ ] 4.3 Compare generated tables with previous static tables to ensure data
      matches.
