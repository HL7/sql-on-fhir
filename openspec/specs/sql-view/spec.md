# sql-view

## Purpose

Defines the `SQLView` profile on `Library`: a reusable, named query that other
queries reference as a virtual table source. This capability also covers how
`SQLView` and `SQLQuery` declare dependencies, the `sql-view` Library type code,
and how composition through references forms a dependency graph.

## Requirements

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
another SQLView, expressed as a `targetProfile` on `relatedArtifact.resource`
(`only Canonical(ViewDefinition or SQLView)`). Validators enforce this target
whenever the canonical resolves to a known resource in the IG or a loaded
dependency; for canonicals that cannot be resolved the constraint is advisory
and the validator reports an unresolved-reference warning rather than a type
error.

#### Scenario: SQLView referencing another SQLView validates

- **WHEN** an `SQLView` declares a `relatedArtifact` of type `depends-on` whose
  `resource` is the canonical URL of another SQLView and whose `label` is a
  valid SQL identifier
- **THEN** validation succeeds with no errors

#### Scenario: Resolvable reference to a disallowed type rejected

- **WHEN** a `relatedArtifact.resource` on an `SQLView` or `SQLQuery` resolves to
  a resource in the IG that is neither a ViewDefinition nor an SQLView
- **THEN** validation fails with a `targetProfile` error on
  `relatedArtifact.resource`

### Requirement: SQLQuery may reference SQLViews

The `SQLQuery` profile SHALL constrain each `relatedArtifact.resource` to
`only Canonical(ViewDefinition or SQLView)`, allowing references to either a
ViewDefinition or an SQLView. Because ViewDefinition remains a permitted target,
SQLQuery instances that reference only ViewDefinitions SHALL remain valid (no
breaking change).

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

### Requirement: Query composition forms a dependency graph

Composition through `relatedArtifact` references SHALL form a directed graph of
ViewDefinitions, SQLViews, and SQLQueries, in which each referenced result acts
as a virtual table for the referencing query. Authors SHOULD ensure these
dependencies are acyclic. Whether circular dependencies are detected or
rejected, any limit on dependency depth, and whether intermediate results are
materialised or inlined (for example as CTEs or database views) are
implementation decisions and SHALL NOT be mandated by this specification.

#### Scenario: Materialisation left to implementations

- **WHEN** an implementation executes an SQLQuery that depends on an SQLView
- **THEN** the implementation MAY materialise the SQLView result or inline it,
  and either approach conforms to this specification

#### Scenario: Cycle handling left to implementations

- **WHEN** a set of SQLViews reference one another such that a dependency cycle
  exists
- **THEN** whether an implementation detects and rejects the cycle, or fails at
  execution time, is implementation-defined and either behaviour conforms to
  this specification
