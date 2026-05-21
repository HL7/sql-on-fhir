# Change: Add embedded SQL queries to ViewDefinition examples

## Why

The ViewDefinition examples in the IG currently show static markdown tables
demonstrating expected output. By using the IG Publisher's SQL on FHIR
integration feature, we can generate these tables dynamically from actual
example FHIR resources. This ensures tables stay in sync with the view
definitions and provides a more compelling demonstration of the specification.

## What changes

- Create FHIR example resources (Patient, Observation, Condition, Encounter)
  that match the expected output shown in existing example notes files.
- Register each ViewDefinition in `sushi-config.yaml` using the
  `path-viewdef` parameter so the IG Publisher builds them into its SQLite
  database.
- Replace static markdown tables in the `*-notes.md` files with Liquid `{% sql
  %}` tags that query the generated views.
- Create new notes files for `ConditionFlat` and `EncounterFlat` examples which
  currently lack any documentation.

## Impact

- Affected files:
  - `sushi-config.yaml` (add `path-viewdef` entries)
  - `input/fsh/examples/` (new FSH file for example resources)
  - `input/pagecontent/Binary-PatientDemographics-notes.md`
  - `input/pagecontent/Binary-ShareablePatientDemographics-notes.md`
  - `input/pagecontent/Binary-PatientAddresses-notes.md`
  - `input/pagecontent/Binary-PatientAndContactAddressUnion-notes.md`
  - `input/pagecontent/Binary-UsCoreBloodPressures-notes.md`
  - `input/pagecontent/Binary-ConditionFlat-notes.md` (new)
  - `input/pagecontent/Binary-EncounterFlat-notes.md` (new)
- No breaking changes; purely additive documentation improvement.
- Requires IG Publisher version that supports SQL on FHIR integration.
