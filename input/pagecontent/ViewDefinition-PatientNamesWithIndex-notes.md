This will result in a "patient_names_with_index" table that looks like this:

{% sql SELECT patient_id, name_index, use, family, given FROM patient_names_with_index ORDER BY patient_id, name_index %}
