# Design: Embedded SQL queries in ViewDefinition examples

## Context

The SQL on FHIR IG contains several ViewDefinition examples that demonstrate how
to flatten FHIR resources into tabular form. Currently, the expected output is
shown as static markdown tables in the `*-notes.md` files. The IG Publisher
supports dynamically generating these tables by:

1. Registering ViewDefinitions via the `path-viewdef` parameter.
2. Processing example FHIR resources through the ViewDefinitions into an
   internal SQLite database.
3. Executing SQL queries embedded in narrative pages via `{% sql %}` Liquid
   tags.

This approach ensures documentation stays in sync with the actual ViewDefinition
behaviour.

## Goals / Non-goals

**Goals:**

- Dynamically generate example output tables from real FHIR resources.
- Provide concrete examples that demonstrate the specification in action.
- Keep documentation automatically synchronised with ViewDefinition changes.

**Non-goals:**

- Comprehensive test coverage (the `tests/` directory already serves this
  purpose).
- Performance optimisation of the IG build process.
- Supporting all edge cases in the example data.

## Architecture overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              IG Build Pipeline                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                   │
│  │  FSH Files   │───▶│    SUSHI     │───▶│ JSON Resources│                  │
│  │  (examples)  │    │  (compiler)  │    │ (generated)   │                  │
│  └──────────────┘    └──────────────┘    └───────┬───────┘                  │
│                                                  │                          │
│  ┌──────────────┐                                ▼                          │
│  │ ViewDefs     │    ┌──────────────────────────────────────┐               │
│  │ (Binary/*.json)│──▶│         IG Publisher                 │              │
│  └──────────────┘    │  ┌────────────────────────────────┐  │               │
│                      │  │   SQL on FHIR Processor        │  │               │
│                      │  │   ┌────────────────────────┐   │  │               │
│                      │  │   │   SQLite Database      │   │  │               │
│                      │  │   │   - patient_demographics│  │  │               │
│                      │  │   │   - patient_addresses   │  │  │               │
│                      │  │   │   - us_core_blood_...   │  │  │               │
│                      │  │   └────────────────────────┘   │  │               │
│                      │  └────────────────────────────────┘  │               │
│                      └──────────────────┬───────────────────┘               │
│                                         │                                   │
│  ┌──────────────┐                       ▼                                   │
│  │ Markdown     │    ┌──────────────────────────────────────┐               │
│  │ (*-notes.md) │───▶│   Liquid Template Engine             │               │
│  │ {% sql %}    │    │   - Executes SQL queries             │               │
│  └──────────────┘    │   - Generates HTML tables            │               │
│                      └──────────────────┬───────────────────┘               │
│                                         │                                   │
│                                         ▼                                   │
│                      ┌──────────────────────────────────────┐               │
│                      │   output/*.html (final pages)        │               │
│                      └──────────────────────────────────────┘               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Decisions

### Decision 1: Create FSH-based example resources

Example FHIR resources will be defined in FSH (FHIR Shorthand) within
`input/fsh/examples/`. This keeps all IG source content in FSH format and
allows the resources to be automatically included in the IG.

**Alternatives considered:**

- Raw JSON files in `input/resources/` — rejected because FSH is more readable
  and consistent with existing examples.
- Embedding resources in test files — rejected because the `tests/` directory
  serves a different purpose (implementation conformance testing).

### Decision 2: One FSH file for all example resources

All example resources (Patient, Observation, Condition, Encounter) will be
defined in a single file `input/fsh/examples/example-resources.fsh`. This keeps
the examples co-located and easy to maintain.

**Alternatives considered:**

- Separate files per resource type — rejected as unnecessarily complex for this
  small number of examples.

### Decision 3: Minimal but realistic example data

Example resources will contain just enough data to demonstrate the
ViewDefinition features without being overly complex. The data should match
what was previously shown in the static tables.

### Decision 4: Use simple SQL queries

The `{% sql %}` queries will be simple `SELECT * FROM view_name` statements.
Advanced SQL features like joins or aggregations are out of scope for this
change.

## Technical specification

### Configuration changes (sushi-config.yaml)

Add the `path-viewdef` parameter to register ViewDefinitions with the IG
Publisher's SQL on FHIR processor:

```yaml
parameters:
  excludettl: true
  path-test: tests
  path-viewdef: fsh-generated/resources/Binary-PatientDemographics.json
  path-viewdef: fsh-generated/resources/Binary-ShareablePatientDemographics.json
  path-viewdef: fsh-generated/resources/Binary-PatientAddresses.json
  path-viewdef: fsh-generated/resources/Binary-PatientAndContactAddressUnion.json
  path-viewdef: fsh-generated/resources/Binary-UsCoreBloodPressures.json
  path-viewdef: fsh-generated/resources/Binary-ConditionFlat.json
  path-viewdef: fsh-generated/resources/Binary-EncounterFlat.json
```

### Example resource design

#### Patient resources (3 patients)

The Patient resources must support all Patient-based ViewDefinitions:

| ID  | Gender | Official Name      | Addresses                                    | Contacts           |
| --- | ------ | ------------------ | -------------------------------------------- | ------------------ |
| pt1 | female | Malvina Gerda Vicario | home: 123 Main St, San Diego 92101; work: 456 Maplewood Dve, New York 10001 | 456 Maplewood Dve, New York 10001 |
| pt2 | male   | Yolotzin Adel Bristow | home: 789 Brookside Ave, Los Angeles 90001   | 987 Pinehurst Rd, Chicago 60601 |
| pt3 | other  | Jin Gomer Aarens   | home: 987 Pinehurst Rd, Chicago 60601; work: 654 Evergreen Tce, Houston 77001 | (none) |

FSH structure:

```fsh
Instance: ExamplePatient1
InstanceOf: Patient
Usage: #example
* id = "pt1"
* gender = #female
* name[+]
  * use = #official
  * given[+] = "Malvina"
  * given[+] = "Gerda"
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
```

#### Observation resources (5 blood pressure readings)

| ID   | Patient | DateTime            | Systolic | Diastolic |
| ---- | ------- | ------------------- | -------- | --------- |
| obs1 | pt1     | 2020-01-01T00:00:00 | 120      | 80        |
| obs2 | pt1     | 2020-01-02T00:00:00 | 130      | 90        |
| obs3 | pt2     | 2020-01-03T00:00:00 | 140      | 100       |
| obs4 | pt3     | 2020-01-04T00:00:00 | 150      | 110       |
| obs5 | pt3     | 2020-01-05T00:00:00 | 160      | 120       |

FSH structure:

```fsh
Instance: ExampleBloodPressure1
InstanceOf: Observation
Usage: #example
* id = "obs1"
* status = #final
* code = http://loinc.org#85354-9 "Blood pressure panel"
* subject = Reference(Patient/pt1)
* effectiveDateTime = "2020-01-01T00:00:00Z"
* component[+]
  * code = http://loinc.org#8480-6 "Systolic blood pressure"
  * valueQuantity
    * value = 120
    * unit = "mm[Hg]"
    * system = "http://unitsofmeasure.org"
    * code = #mmHg
* component[+]
  * code = http://loinc.org#8462-4 "Diastolic blood pressure"
  * valueQuantity
    * value = 80
    * unit = "mm[Hg]"
    * system = "http://unitsofmeasure.org"
    * code = #mmHg
```

#### Condition resources (2-3 conditions)

| ID    | Patient | Encounter | Code (SNOMED)     | Category   | Clinical Status |
| ----- | ------- | --------- | ----------------- | ---------- | --------------- |
| cond1 | pt1     | enc1      | 44054006 (Diabetes) | encounter-diagnosis | active |
| cond2 | pt2     | enc2      | 38341003 (Hypertension) | problem-list-item | resolved |

#### Encounter resources (2-3 encounters, R4 format)

| ID   | Patient | Status   | Type         | Period                    | Practitioner | Location |
| ---- | ------- | -------- | ------------ | ------------------------- | ------------ | -------- |
| enc1 | pt1     | finished | AMB (ambulatory) | 2020-01-01 to 2020-01-01 | prac1        | loc1     |
| enc2 | pt2     | finished | EMER (emergency) | 2020-01-02 to 2020-01-03 | prac1        | loc2     |

### Liquid SQL tag syntax

The IG Publisher supports the `{% sql %}` Liquid tag for embedding SQL queries.
The basic syntax is:

```liquid
{% sql SELECT * FROM view_name %}
```

For the notes pages, the updated content will look like:

**Binary-PatientDemographics-notes.md:**

```markdown
This will result in a "patient_demographics" table that looks like this:

{% sql SELECT * FROM patient_demographics %}
```

**Binary-PatientAddresses-notes.md:**

```markdown
This will result in a "patient_addresses" table that looks like this:

{% sql SELECT * FROM patient_addresses %}
```

### View name mapping

The IG Publisher creates SQLite tables using the `name` field from each
ViewDefinition:

| ViewDefinition Instance        | View Name (`name` field)        |
| ------------------------------ | ------------------------------- |
| PatientDemographics            | patient_demographics            |
| ShareablePatientDemographics   | patient_demographics            |
| PatientAddresses               | patient_addresses               |
| PatientAndContactAddressUnion  | patient_and_contact_addresses   |
| UsCoreBloodPressures           | us_core_blood_pressures         |
| ConditionFlat                  | condition_flat                  |
| EncounterFlat                  | encounter_flat                  |

Note: PatientDemographics and ShareablePatientDemographics share the same view
name, so they will produce identical output (by design, as ShareablePatientDemographics
is a profiled version of the same view).

## Risks / Trade-offs

| Risk                                             | Mitigation                                            |
| ------------------------------------------------ | ----------------------------------------------------- |
| IG Publisher version may not support SQL on FHIR | Document minimum required version; test with latest   |
| SQL query errors break the build                 | Validate queries during development; keep them simple |
| Example data becomes stale if ViewDefinitions change | This is the problem we're solving — dynamic generation ensures sync |
| View name collisions                             | Use unique names; document shared names explicitly    |
| R4 vs R5 compatibility for Encounter             | EncounterFlat already specifies `fhirVersion = #4.0`  |

## Migration plan

1. Add example resources (no impact on existing build).
2. Add `path-viewdef` parameters to sushi-config.yaml.
3. Test IG build to verify SQLite database is populated.
4. Update notes files one at a time, verifying output after each change.
5. Create new notes files for ConditionFlat and EncounterFlat.

Rollback: Revert to static markdown tables if SQL integration causes issues.

## Open questions

1. **IG Publisher version** — What is the minimum IG Publisher version that
   supports the `{% sql %}` Liquid tag? Need to verify and document.

2. **Column metadata** — Should we add column metadata hints to the SQL queries
   for better rendering (e.g., making IDs into clickable links)? The syntax
   would be:
   ```liquid
   {% sql SELECT id, gender FROM patient_demographics %}
   ```
   With metadata in a comment or separate parameter.

3. **CSS styling** — The existing static tables use `{:.table-data}` for styling.
   Need to verify if the generated tables include appropriate CSS classes.

4. **Shared view names** — PatientDemographics and ShareablePatientDemographics
   use the same `name`. Should we differentiate them or accept that they
   demonstrate identical output?
