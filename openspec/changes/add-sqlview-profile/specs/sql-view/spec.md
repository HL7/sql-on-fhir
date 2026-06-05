## ADDED Requirements

### Requirement: SQLView profile

The IG SHALL define an `SQLView` profile on `Library` representing a reusable,
named query that other queries reference as a virtual table source. A `Library`
conforming to `SQLView` SHALL have a `type` of `LibraryTypesCodes#sql-view` and
SHALL carry its SQL in `content` using the same attachment rules as `SQLQuery`
(every `content.contentType` starts with `application/sql`; `content.data` is
present; the `sql-text` extension MAY carry a plain-text copy).

#### Scenario: Valid SQLView validates

- **WHEN** a `Library` with `type` `LibraryTypesCodes#sql-view`, no `parameter`
  entries, at least one `content` attachment with `contentType` starting with
  `application/sql` and a populated `data`, and `relatedArtifact` entries of
  type `depends-on` referencing a ViewDefinition is validated against `SQLView`
- **THEN** validation succeeds with no errors

#### Scenario: Wrong type rejected

- **WHEN** a `Library` claiming conformance to `SQLView` has a `type` other than
  `LibraryTypesCodes#sql-view`
- **THEN** validation fails with an error on `Library.type`

### Requirement: SQLView prohibits parameters

The `SQLView` profile SHALL constrain `Library.parameter` to a maximum
cardinality of 0. Dependent views cannot be parameterised in this iteration.

#### Scenario: Parameter present rejected

- **WHEN** a `Library` conforming to `SQLView` includes one or more
  `Library.parameter` entries
- **THEN** validation fails with a cardinality error on `Library.parameter`

### Requirement: SQLView dependency references

An `SQLView` SHALL declare its dependencies using `relatedArtifact` entries with
`type` `depends-on`, each carrying a `resource` (the canonical URL of the
dependency) and a `label` that is a valid SQL identifier used as the table name
in the SQL. Each referenced `resource` SHALL be either a ViewDefinition or
another SQLView.

#### Scenario: SQLView referencing another SQLView validates

- **WHEN** an `SQLView` declares a `relatedArtifact` of type `depends-on` whose
  `resource` is the canonical URL of another SQLView and whose `label` is a
  valid SQL identifier
- **THEN** validation succeeds with no errors

### Requirement: SQLQuery may reference SQLViews

The `SQLQuery` profile SHALL allow each `relatedArtifact` entry to reference
either a ViewDefinition or an SQLView. SQLQuery instances that reference only
ViewDefinitions SHALL remain valid (no breaking change).

#### Scenario: SQLQuery referencing an SQLView validates

- **WHEN** an `SQLQuery` declares a `relatedArtifact` of type `depends-on` whose
  `resource` is the canonical URL of an SQLView
- **THEN** validation succeeds with no errors

#### Scenario: Existing ViewDefinition-only SQLQuery still valid

- **WHEN** an `SQLQuery` whose `relatedArtifact` entries reference only
  ViewDefinitions is validated against the updated profile
- **THEN** validation succeeds with no errors

### Requirement: sql-view type code

The `LibraryTypesCodes` code system SHALL define a concept with code `sql-view`
identifying a Library as an SQL view definition.

#### Scenario: Code present in code system

- **WHEN** the generated `LibraryTypesCodes` code system is inspected
- **THEN** it contains a concept with code `sql-view`

### Requirement: Query composition forms an acyclic dependency graph

Composition through `relatedArtifact` references SHALL form a directed acyclic
graph of ViewDefinitions, SQLViews, and SQLQueries, in which each referenced
result acts as a virtual table for the referencing query. Detection of circular
dependencies, any limit on dependency depth, and whether intermediate results
are materialised or inlined (for example as CTEs or database views) SHALL be
implementation decisions and SHALL NOT be mandated by this specification.

#### Scenario: Materialisation left to implementations

- **WHEN** an implementation executes an SQLQuery that depends on an SQLView
- **THEN** the implementation MAY materialise the SQLView result or inline it,
  and either approach conforms to this specification
