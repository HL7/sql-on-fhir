This will result in a "code_system_hierarchy" table that looks like this:

{% sql SELECT * FROM code_system_hierarchy %}

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
