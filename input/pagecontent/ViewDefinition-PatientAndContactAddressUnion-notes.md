This will result in a "patient_and_contact_addresses" table that looks like
this:

| resource_id | street                   | city        | zip   | is_patient |
|-------------|--------------------------|-------------|-------|------------|
| 1           | 123 Main St\nApt 1       | San Diego   | 92101 | true       |
| 1           | 456 Maplewood Dve\nApt 2 | New York    | 10001 | true       |
| 1           | 456 Maplewood Dve\nApt 2 | New York    | 10001 | false      |
| 2           | 789 Brookside Ave\nApt 3 | Los Angeles | 90001 | true       |
| 2           | 987 Pinehurst Rd\nApt 4  | Chicago     | 60601 | false      |

{:.table-data}
