// Author: John Grimes

Instance: ActivePatientsView
InstanceOf: SQLView
Description: "A reusable SQL view selecting active patients, intended to be referenced as a virtual table by other queries."
Usage: #example
* url = "https://sql-on-fhir.org/ig/Library/ActivePatientsView"
* name = "ActivePatientsView"
* status = #active
* title = "Active Patients"
* description = """
Selects the identifier, name, and birth date of every active patient. Other
queries reference this view by its canonical URL and use the `active_patients`
label as a table name.

```sql
SELECT
  patient_view.id AS patient_id,
  patient_view.name AS patient_name,
  patient_view.birth_date
FROM patient_view
WHERE patient_view.active = true
```
"""
* relatedArtifact[+]
  * type = #depends-on
  * resource = "https://example.org/ViewDefinition/patient_view"
  * label = "patient_view"
* content[+]
  * contentType = #application/sql
  * extension[sql-text].valueString = """SELECT
  patient_view.id AS patient_id,
  patient_view.name AS patient_name,
  patient_view.birth_date
FROM patient_view
WHERE patient_view.active = true"""
  * data = "U0VMRUNUCiAgcGF0aWVudF92aWV3LmlkIEFTIHBhdGllbnRfaWQsCiAgcGF0aWVudF92aWV3Lm5hbWUgQVMgcGF0aWVudF9uYW1lLAogIHBhdGllbnRfdmlldy5iaXJ0aF9kYXRlCkZST00gcGF0aWVudF92aWV3CldIRVJFIHBhdGllbnRfdmlldy5hY3RpdmUgPSB0cnVl"


Instance: ActivePatientAddressesQuery
InstanceOf: SQLQuery
Description: "A SQL query that composes the ActivePatientsView, demonstrating an SQLQuery that references an SQLView as a virtual table."
Usage: #example
* name = "ActivePatientAddressesQuery"
* status = #active
* title = "Active Patient Addresses"
* description = """
Joins the [Active Patients](Library-ActivePatientsView.html) view to patient
addresses. The `active_patients` label resolves to the referenced SQLView, which
the executing engine may materialise or inline.

```sql
SELECT
  active_patients.patient_id,
  active_patients.patient_name,
  patient_address_view.city,
  patient_address_view.state
FROM active_patients
JOIN patient_address_view
  ON active_patients.patient_id = patient_address_view.patient_id
```
"""
* relatedArtifact[+]
  * type = #depends-on
  * resource = "https://sql-on-fhir.org/ig/Library/ActivePatientsView"
  * label = "active_patients"
  * display = "Active Patients view"
* relatedArtifact[+]
  * type = #depends-on
  * resource = "https://example.org/ViewDefinition/patient_address_view"
  * label = "patient_address_view"
  * display = "Patient address view"
* content[+]
  * contentType = #application/sql
  * extension[sql-text].valueString = """SELECT
  active_patients.patient_id,
  active_patients.patient_name,
  patient_address_view.city,
  patient_address_view.state
FROM active_patients
JOIN patient_address_view
  ON active_patients.patient_id = patient_address_view.patient_id"""
  * data = "U0VMRUNUCiAgYWN0aXZlX3BhdGllbnRzLnBhdGllbnRfaWQsCiAgYWN0aXZlX3BhdGllbnRzLnBhdGllbnRfbmFtZSwKICBwYXRpZW50X2FkZHJlc3Nfdmlldy5jaXR5LAogIHBhdGllbnRfYWRkcmVzc192aWV3LnN0YXRlCkZST00gYWN0aXZlX3BhdGllbnRzCkpPSU4gcGF0aWVudF9hZGRyZXNzX3ZpZXcKICBPTiBhY3RpdmVfcGF0aWVudHMucGF0aWVudF9pZCA9IHBhdGllbnRfYWRkcmVzc192aWV3LnBhdGllbnRfaWQ="
