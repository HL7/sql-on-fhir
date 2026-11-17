# Change: Add embedded SQL queries to ViewDefinition examples

## Why

The ViewDefinition examples in the IG currently show static markdown tables
demonstrating expected output. By using the IG Publisher's SQL on FHIR
integration feature, we can generate these tables dynamically from actual
example FHIR resources. This ensures tables stay in sync with the view
definitions and provides a more compelling demonstration of the specification.

## What changes

- Create FHIR example resources (Patient, Observation, Condition, Encounter,
  CodeSystem, QuestionnaireResponse and supporting resources) that match the
  expected output shown in existing example notes files.
- Register each ViewDefinition in `sushi-config.yaml` using the
  `viewDefinition` parameter so the IG Publisher builds them into its SQLite
  database.
- Replace static markdown tables in the `*-notes.md` files with Liquid `{% sql
  %}` tags that query the generated views.
- Create new notes files for the `ConditionFlat`, `EncounterFlat` and
  `PatientNamesWithIndex` examples which currently lack any documentation.

## Impact

- Affected files:
  - `sushi-config.yaml` (add `viewDefinition` entries)
  - `input/fsh/examples/example-resources.fsh` (new FSH file for example
    resources)
  - `input/resources/viewdefinition/ViewDefinition-*.json` (unique name for
    ShareablePatientDemographics, R5 paths for EncounterFlat)
  - `input/pagecontent/ViewDefinition-*-notes.md` (one per example, three new)
- No breaking changes; purely additive documentation improvement.
- Requires IG Publisher version that supports SQL on FHIR integration.
