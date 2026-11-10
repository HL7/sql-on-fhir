This will result in a "us_core_blood_pressures" table that looks like this:

{% sql SELECT id, patient_id, effective_date_time, sbp_quantity_system, sbp_quantity_code, sbp_quantity_unit, sbp_quantity_value, dbp_quantity_system, dbp_quantity_code, dbp_quantity_unit, dbp_quantity_value FROM us_core_blood_pressures %}
