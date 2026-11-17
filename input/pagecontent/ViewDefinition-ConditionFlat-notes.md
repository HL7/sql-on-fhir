This will result in a "condition_flat" table that looks like this:

{% sql SELECT id, patient_id, encounter_id, onset_datetime, system, code, category, clinical_status, verification_status FROM condition_flat %}
