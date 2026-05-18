This will result in a "code_system_hierarchy" table that looks like this:

| id  | parent_code | code      |
|-----|-------------|-----------|
| 1   | vehicle     | car       |
| 1   | vehicle     | truck     |
| 1   | vehicle     | motorbike |
| 1   | car         | sedan     |
| 1   | car         | suv       |
| 1   | car         | hatchback |
| 1   | truck       | pickup    |
| 1   | truck       | semi      |
{:.table-data}

Given a CodeSystem with nested concepts like:

- vehicle
  - car
    - sedan
    - suv
    - hatchback
  - truck
    - pickup
    - semi
  - motorbike

The `repeat` directive walks down the concept tree, and at each level the nested `forEach` extracts each child concept. This produces parent-child pairs that can be used to build adjacency lists for hierarchical queries or to analyse the structure of a terminology.
