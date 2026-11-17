This will result in an "encounter_flat" table that looks like this:

{% sql SELECT id, status, patient_id, service_org_id, period_start, period_end, EpisodeOfCareId, type_sys, type_code, practitioner_id, location_id FROM encounter_flat %}
