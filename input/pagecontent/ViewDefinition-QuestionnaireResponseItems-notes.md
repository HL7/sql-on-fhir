This will result in a "questionnaire_response_items" table that looks like this:

| id  | questionnaire                       | patient_id | authored                  | item_link_id | item_text          | answer_value_string | answer_value_integer | answer_value_boolean | answer_value_date |
|-----|-------------------------------------|------------|---------------------------|--------------|--------------------|--------------------|---------------------|---------------------|------------------|
| 1   | http://example.org/q/phq9           | 101        | 2024-03-15T10:30:00+10:00 | q1           | Little interest... | null               | 2                   | null                | null             |
| 1   | http://example.org/q/phq9           | 101        | 2024-03-15T10:30:00+10:00 | q2           | Feeling down...    | null               | 1                   | null                | null             |
| 2   | http://example.org/q/health-history | 102        | 2024-03-16T14:20:00+10:00 | demographics | Demographics       | null               | null                | null                | null             |
| 2   | http://example.org/q/health-history | 102        | 2024-03-16T14:20:00+10:00 | name         | Full name          | John Smith         | null                | null                | null             |
| 2   | http://example.org/q/health-history | 102        | 2024-03-16T14:20:00+10:00 | dob          | Date of birth      | null               | null                | null                | 1980-05-22       |
| 2   | http://example.org/q/health-history | 102        | 2024-03-16T14:20:00+10:00 | conditions   | Medical conditions | null               | null                | null                | null             |
| 2   | http://example.org/q/health-history | 102        | 2024-03-16T14:20:00+10:00 | diabetes     | Diabetes           | null               | null                | true                | null             |
| 2   | http://example.org/q/health-history | 102        | 2024-03-16T14:20:00+10:00 | hypertension | Hypertension       | null               | null                | false               | null             |
{:.table-data}

Note how all items are flattened into a single table regardless of their nesting depth. The "demographics" and "conditions" items are group items (with no answer values), while items like "name", "dob", "diabetes", and "hypertension" are nested within those groups but appear as separate rows in the output. The `repeat` paths `item` and `answer.item` cover both forms of nesting that QuestionnaireResponse allows: items nested directly under a group, and items nested under an answer.

The answer columns are produced by a nested `forEachOrNull` over `answer`, because an item can have more than one answer. An item with two answers produces two rows, and an item with no answers, such as a group, still produces one row with null answer values.
