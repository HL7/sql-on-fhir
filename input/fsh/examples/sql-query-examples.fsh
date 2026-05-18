Instance: UniquePatientAddressesQuery
Description: "A SQL query that retrieves the most recent address per patient with a city filter."
InstanceOf: SQLQuery
Usage: #example
* name = "UniquePatientAddressesQuery"
* status = #active
* title = "Unique Patient Addresses"
* description = """
Retrieves each patient's most recent address in a given city. Includes two
dialects for the same logical query.

**Standard SQL:**
```sql
WITH ranked_addresses AS (
  SELECT
    patient_view.id AS patient_id,
    patient_view.name,
    patient_address_view.address_line1,
    patient_address_view.city,
    patient_address_view.state,
    patient_address_view.postal_code,
    patient_address_view.updated_at,
    ROW_NUMBER() OVER (
      PARTITION BY patient_view.id
      ORDER BY patient_address_view.updated_at DESC, patient_address_view.address_id DESC
    ) AS address_rank
  FROM patient_view
  JOIN patient_address_view
    ON patient_view.id = patient_address_view.patient_id
  WHERE patient_view.active = true
    AND patient_address_view.city = :city
)
SELECT
  patient_id,
  name,
  address_line1,
  city,
  state,
  postal_code
FROM ranked_addresses
WHERE address_rank = 1
```

**PostgreSQL dialect:**
```sql
SELECT DISTINCT ON (patient_view.id)
  patient_view.id AS patient_id,
  patient_view.name,
  patient_address_view.address_line1,
  patient_address_view.city,
  patient_address_view.state,
  patient_address_view.postal_code
FROM patient_view
JOIN patient_address_view
  ON patient_view.id = patient_address_view.patient_id
WHERE patient_view.active = true
  AND patient_address_view.city = :city
ORDER BY patient_view.id, patient_address_view.updated_at DESC, patient_address_view.address_id DESC
```
"""
* parameter[+]
  * name = #city
  * type = #string
  * use = #in
  * documentation = "City to filter addresses"
* relatedArtifact[+]
  * type = #depends-on
  * resource = "https://example.org/ViewDefinition/patient_view"
  * label = "patient_view"
* relatedArtifact[+]
  * type = #depends-on
  * resource = "https://example.org/ViewDefinition/patient_address_view"
  * label = "patient_address_view"
* content[+]
  * contentType = #application/sql
  * extension[sql-text].valueString = """WITH ranked_addresses AS (
  SELECT
    patient_view.id AS patient_id,
    patient_view.name,
    patient_address_view.address_line1,
    patient_address_view.city,
    patient_address_view.state,
    patient_address_view.postal_code,
    patient_address_view.updated_at,
    ROW_NUMBER() OVER (
      PARTITION BY patient_view.id
      ORDER BY patient_address_view.updated_at DESC, patient_address_view.address_id DESC
    ) AS address_rank
  FROM patient_view
  JOIN patient_address_view
    ON patient_view.id = patient_address_view.patient_id
  WHERE patient_view.active = true
    AND patient_address_view.city = :city
)
SELECT
  patient_id,
  name,
  address_line1,
  city,
  state,
  postal_code
FROM ranked_addresses
WHERE address_rank = 1"""
  * data = "V0lUSCByYW5rZWRfYWRkcmVzc2VzIEFTICgKICBTRUxFQ1QKICAgIHBhdGllbnRfdmlldy5pZCBBUyBwYXRpZW50X2lkLAogICAgcGF0aWVudF92aWV3Lm5hbWUsCiAgICBwYXRpZW50X2FkZHJlc3Nfdmlldy5hZGRyZXNzX2xpbmUxLAogICAgcGF0aWVudF9hZGRyZXNzX3ZpZXcuY2l0eSwKICAgIHBhdGllbnRfYWRkcmVzc192aWV3LnN0YXRlLAogICAgcGF0aWVudF9hZGRyZXNzX3ZpZXcucG9zdGFsX2NvZGUsCiAgICBwYXRpZW50X2FkZHJlc3Nfdmlldy51cGRhdGVkX2F0LAogICAgUk9XX05VTUJFUigpIE9WRVIgKAogICAgICBQQVJUSVRJT04gQlkgcGF0aWVudF92aWV3LmlkCiAgICAgIE9SREVSIEJZIHBhdGllbnRfYWRkcmVzc192aWV3LnVwZGF0ZWRfYXQgREVTQywgcGF0aWVudF9hZGRyZXNzX3ZpZXcuYWRkcmVzc19pZCBERVNDCiAgICApIEFTIGFkZHJlc3NfcmFuawogIEZST00gcGF0aWVudF92aWV3CiAgSk9JTiBwYXRpZW50X2FkZHJlc3NfdmlldwogICAgT04gcGF0aWVudF92aWV3LmlkID0gcGF0aWVudF9hZGRyZXNzX3ZpZXcucGF0aWVudF9pZAogIFdIRVJFIHBhdGllbnRfdmlldy5hY3RpdmUgPSB0cnVlCiAgICBBTkQgcGF0aWVudF9hZGRyZXNzX3ZpZXcuY2l0eSA9IDpjaXR5CikKU0VMRUNUCiAgcGF0aWVudF9pZCwKICBuYW1lLAogIGFkZHJlc3NfbGluZTEsCiAgY2l0eSwKICBzdGF0ZSwKICBwb3N0YWxfY29kZQpGUk9NIHJhbmtlZF9hZGRyZXNzZXMKV0hFUkUgYWRkcmVzc19yYW5rID0gMQ=="
* content[+]
  * contentType = #"application/sql;dialect=postgresql"
  * extension[sql-text].valueString = """SELECT DISTINCT ON (patient_view.id)
  patient_view.id AS patient_id,
  patient_view.name,
  patient_address_view.address_line1,
  patient_address_view.city,
  patient_address_view.state,
  patient_address_view.postal_code
FROM patient_view
JOIN patient_address_view
  ON patient_view.id = patient_address_view.patient_id
WHERE patient_view.active = true
  AND patient_address_view.city = :city
ORDER BY patient_view.id, patient_address_view.updated_at DESC, patient_address_view.address_id DESC"""
  * data = "U0VMRUNUIERJU1RJTkNUIE9OIChwYXRpZW50X3ZpZXcuaWQpCiAgcGF0aWVudF92aWV3LmlkIEFTIHBhdGllbnRfaWQsCiAgcGF0aWVudF92aWV3Lm5hbWUsCiAgcGF0aWVudF9hZGRyZXNzX3ZpZXcuYWRkcmVzc19saW5lMSwKICBwYXRpZW50X2FkZHJlc3Nfdmlldy5jaXR5LAogIHBhdGllbnRfYWRkcmVzc192aWV3LnN0YXRlLAogIHBhdGllbnRfYWRkcmVzc192aWV3LnBvc3RhbF9jb2RlCkZST00gcGF0aWVudF92aWV3CkpPSU4gcGF0aWVudF9hZGRyZXNzX3ZpZXcKICBPTiBwYXRpZW50X3ZpZXcuaWQgPSBwYXRpZW50X2FkZHJlc3Nfdmlldy5wYXRpZW50X2lkCldIRVJFIHBhdGllbnRfdmlldy5hY3RpdmUgPSB0cnVlCiAgQU5EIHBhdGllbnRfYWRkcmVzc192aWV3LmNpdHkgPSA6Y2l0eQpPUkRFUiBCWSBwYXRpZW50X3ZpZXcuaWQsIHBhdGllbnRfYWRkcmVzc192aWV3LnVwZGF0ZWRfYXQgREVTQywgcGF0aWVudF9hZGRyZXNzX3ZpZXcuYWRkcmVzc19pZCBERVND"


Instance: SqlOnFhirExample
InstanceOf: SQLQuery
Description: "Annotated SQL query example demonstrating how tooling can derive Library metadata."
Usage: #example
* name = "SqlOnFhirExample"
* status = #active
* title = "Blood Pressure Trend Report"
* description = """
Demonstrates SQL annotations that tooling can use to generate Library metadata.

```sql
/*
@name: SqlOnFhirExample
@title: Blood Pressure Trend Report
@description: Return blood pressure observations for a patient in a date range
@version: 1.0.0
@status: active
@author: Clinical Informatics Team
@publisher: Regional Medical Center
*/

-- @relatedDependency: https://example.org/ViewDefinition/patient_view as patient_view
-- @relatedDependency: https://example.org/ViewDefinition/blood_pressure_view as blood_pressure_view
-- @param: patient_id string Patient identifier
-- @param: from_date date Start date (inclusive)
-- @param: to_date date End date (inclusive)
SELECT
  patient_view.id AS patient_id,
  patient_view.name,
  blood_pressure_view.systolic,
  blood_pressure_view.diastolic,
  blood_pressure_view.effective_date
FROM patient_view
JOIN blood_pressure_view
  ON patient_view.id = blood_pressure_view.patient_id
WHERE patient_view.id = :patient_id
  AND blood_pressure_view.effective_date >= :from_date
  AND blood_pressure_view.effective_date <= :to_date
ORDER BY blood_pressure_view.effective_date
```
"""
* version = "1.0.0"
* author.name = "Clinical Informatics Team"
* publisher = "Regional Medical Center"
* parameter[+]
  * name = #patient_id
  * type = #string
  * use = #in
  * documentation = "Patient identifier"
* parameter[+]
  * name = #from_date
  * type = #date
  * use = #in
  * documentation = "Start date for observations"
* parameter[+]
  * name = #to_date
  * type = #date
  * use = #in
  * documentation = "End date for observations"
* relatedArtifact[+]
  * type = #depends-on
  * resource = "https://example.org/ViewDefinition/patient_view"
  * label = "patient_view"
* relatedArtifact[+]
  * type = #depends-on
  * resource = "https://example.org/ViewDefinition/blood_pressure_view"
  * label = "blood_pressure_view"
* content.contentType = #application/sql
* content.extension[sql-text].valueString = """/*
@name: SqlOnFhirExample
@title: Blood Pressure Trend Report
@description: Return blood pressure observations for a patient in a date range
@version: 1.0.0
@status: active
@author: Clinical Informatics Team
@publisher: Regional Medical Center
*/

-- @relatedDependency: https://example.org/ViewDefinition/patient_view as patient_view
-- @relatedDependency: https://example.org/ViewDefinition/blood_pressure_view as blood_pressure_view
-- @param: patient_id string Patient identifier
-- @param: from_date date Start date (inclusive)
-- @param: to_date date End date (inclusive)
SELECT
  patient_view.id AS patient_id,
  patient_view.name,
  blood_pressure_view.systolic,
  blood_pressure_view.diastolic,
  blood_pressure_view.effective_date
FROM patient_view
JOIN blood_pressure_view
  ON patient_view.id = blood_pressure_view.patient_id
WHERE patient_view.id = :patient_id
  AND blood_pressure_view.effective_date >= :from_date
  AND blood_pressure_view.effective_date <= :to_date
ORDER BY blood_pressure_view.effective_date"""
* content.data = "LyoKQG5hbWU6IFNxbE9uRmhpckV4YW1wbGUKQHRpdGxlOiBCbG9vZCBQcmVzc3VyZSBUcmVuZCBSZXBvcnQKQGRlc2NyaXB0aW9uOiBSZXR1cm4gYmxvb2QgcHJlc3N1cmUgb2JzZXJ2YXRpb25zIGZvciBhIHBhdGllbnQgaW4gYSBkYXRlIHJhbmdlCkB2ZXJzaW9uOiAxLjAuMApAc3RhdHVzOiBhY3RpdmUKQGF1dGhvcjogQ2xpbmljYWwgSW5mb3JtYXRpY3MgVGVhbQpAcHVibGlzaGVyOiBSZWdpb25hbCBNZWRpY2FsIENlbnRlcgoqLwoKLS0gQHJlbGF0ZWREZXBlbmRlbmN5OiBodHRwczovL2V4YW1wbGUub3JnL1ZpZXdEZWZpbml0aW9uL3BhdGllbnRfdmlldyBhcyBwYXRpZW50X3ZpZXcKLS0gQHJlbGF0ZWREZXBlbmRlbmN5OiBodHRwczovL2V4YW1wbGUub3JnL1ZpZXdEZWZpbml0aW9uL2Jsb29kX3ByZXNzdXJlX3ZpZXcgYXMgYmxvb2RfcHJlc3N1cmVfdmlldwotLSBAcGFyYW06IHBhdGllbnRfaWQgc3RyaW5nIFBhdGllbnQgaWRlbnRpZmllcgotLSBAcGFyYW06IGZyb21fZGF0ZSBkYXRlIFN0YXJ0IGRhdGUgKGluY2x1c2l2ZSkKLS0gQHBhcmFtOiB0b19kYXRlIGRhdGUgRW5kIGRhdGUgKGluY2x1c2l2ZSkKU0VMRUNUCiAgcGF0aWVudF92aWV3LmlkIEFTIHBhdGllbnRfaWQsCiAgcGF0aWVudF92aWV3Lm5hbWUsCiAgYmxvb2RfcHJlc3N1cmVfdmlldy5zeXN0b2xpYywKICBibG9vZF9wcmVzc3VyZV92aWV3LmRpYXN0b2xpYywKICBibG9vZF9wcmVzc3VyZV92aWV3LmVmZmVjdGl2ZV9kYXRlCkZST00gcGF0aWVudF92aWV3CkpPSU4gYmxvb2RfcHJlc3N1cmVfdmlldwogIE9OIHBhdGllbnRfdmlldy5pZCA9IGJsb29kX3ByZXNzdXJlX3ZpZXcucGF0aWVudF9pZApXSEVSRSBwYXRpZW50X3ZpZXcuaWQgPSA6cGF0aWVudF9pZAogIEFORCBibG9vZF9wcmVzc3VyZV92aWV3LmVmZmVjdGl2ZV9kYXRlID49IDpmcm9tX2RhdGUKICBBTkQgYmxvb2RfcHJlc3N1cmVfdmlldy5lZmZlY3RpdmVfZGF0ZSA8PSA6dG9fZGF0ZQpPUkRFUiBCWSBibG9vZF9wcmVzc3VyZV92aWV3LmVmZmVjdGl2ZV9kYXRl"


Instance: OmopFhirPatientJoin
InstanceOf: SQLQuery
Description: "Disambiguates OMOP and FHIR Patient views and joins diagnoses for context."
Usage: #example
* name = "OmopFhirPatientJoin"
* status = #active
* title = "OMOP/FHIR Patient Match with Diagnoses"
* description = """
Uses labels to disambiguate patient views from different sources and joins
patient diagnoses for downstream analytics.

```sql
SELECT
  omop_person.person_id AS omop_person_id,
  fhir_patient.id AS fhir_patient_id,
  fhir_patient.name,
  diagnoses_view.code AS diagnosis_code,
  diagnoses_view.display AS diagnosis_display
FROM omop_person
JOIN fhir_patient
  ON omop_person.person_id = fhir_patient.mrn
JOIN diagnoses_view
  ON diagnoses_view.patient_id = fhir_patient.id
WHERE omop_person.source_system = :source_system
```
"""
* parameter[+]
  * name = #source_system
  * type = #string
  * use = #in
  * documentation = "Source system identifier for OMOP records"
* relatedArtifact[+]
  * type = #depends-on
  * resource = "https://example.org/omop/ViewDefinition/Patient"
  * label = "omop_person"
  * display = "OMOP Person view"
* relatedArtifact[+]
  * type = #depends-on
  * resource = "https://example.org/fhir/ViewDefinition/Patient"
  * label = "fhir_patient"
  * display = "FHIR Patient view"
* relatedArtifact[+]
  * type = #depends-on
  * resource = "https://example.org/ViewDefinition/diagnoses_view"
  * label = "diagnoses_view"
  * display = "Diagnosis facts view"
* content.contentType = #application/sql
* content.extension[sql-text].valueString = """SELECT
  omop_person.person_id AS omop_person_id,
  fhir_patient.id AS fhir_patient_id,
  fhir_patient.name,
  diagnoses_view.code AS diagnosis_code,
  diagnoses_view.display AS diagnosis_display
FROM omop_person
JOIN fhir_patient
  ON omop_person.person_id = fhir_patient.mrn
JOIN diagnoses_view
  ON diagnoses_view.patient_id = fhir_patient.id
WHERE omop_person.source_system = :source_system"""
* content.data = "U0VMRUNUCiAgb21vcF9wZXJzb24ucGVyc29uX2lkIEFTIG9tb3BfcGVyc29uX2lkLAogIGZoaXJfcGF0aWVudC5pZCBBUyBmaGlyX3BhdGllbnRfaWQsCiAgZmhpcl9wYXRpZW50Lm5hbWUsCiAgZGlhZ25vc2VzX3ZpZXcuY29kZSBBUyBkaWFnbm9zaXNfY29kZSwKICBkaWFnbm9zZXNfdmlldy5kaXNwbGF5IEFTIGRpYWdub3Npc19kaXNwbGF5CkZST00gb21vcF9wZXJzb24KSk9JTiBmaGlyX3BhdGllbnQKICBPTiBvbW9wX3BlcnNvbi5wZXJzb25faWQgPSBmaGlyX3BhdGllbnQubXJuCkpPSU4gZGlhZ25vc2VzX3ZpZXcKICBPTiBkaWFnbm9zZXNfdmlldy5wYXRpZW50X2lkID0gZmhpcl9wYXRpZW50LmlkCldIRVJFIG9tb3BfcGVyc29uLnNvdXJjZV9zeXN0ZW0gPSA6c291cmNlX3N5c3RlbQ=="
