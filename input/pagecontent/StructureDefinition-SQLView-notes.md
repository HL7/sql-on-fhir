### Query Composition

SQLView exists so that queries can build on one another, much like SQL views.
A ViewDefinition produces a tabular projection of FHIR resources; an SQLView
wraps a query over those projections (or over other SQLViews) and gives it a
canonical URL; an SQLQuery then references ViewDefinitions and SQLViews alike as
its table sources.

References made through `relatedArtifact` form a directed graph of
ViewDefinitions, SQLViews, and SQLQueries, in which each referenced result acts
as a virtual table for the referencing query. Authors SHOULD keep this graph
acyclic.

Whether circular dependencies are detected or rejected, any limit on dependency
depth, and whether intermediate results are materialised or inlined (for example
as CTEs or database views) are implementation decisions and are not mandated by
this specification. A SQL engine that creates real views will reject a cyclic
definition; a CTE-based implementation detects loops itself.

### Example

The [Active Patients](Library-ActivePatientsView.html) view selects active
patients from a ViewDefinition. The
[Active Patient Addresses](Library-ActivePatientAddressesQuery.html) query then
references that SQLView by its canonical URL, using the `active_patients` label
as a table name and joining it to a further ViewDefinition. The executing engine
may materialise the view's result or inline it; either approach conforms to this
specification.
