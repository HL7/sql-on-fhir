This will result in a "questionnaire_response_items" table that looks like this:

{% sql SELECT id, questionnaire, patient_id, authored, item_link_id, item_text, answer_value_string, answer_value_integer, answer_value_boolean, answer_value_date FROM questionnaire_response_items %}

Note how all items are flattened into a single table regardless of their nesting depth. The "demographics" and "conditions" items are group items (with no answer values), while items like "name", "dob", "diabetes", and "hypertension" are nested within those groups but appear as separate rows in the output.
