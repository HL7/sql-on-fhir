# Row Index Environment Variable

## ADDED Requirements

### Requirement: %rowIndex environment variable availability

View runners MUST support a `%rowIndex` environment variable that returns the
0-based index of the current element within the collection being iterated by
`forEach`, `forEachOrNull`, or `repeat`.

#### Scenario: %rowIndex in forEach returns element position

- **GIVEN** a Patient resource with multiple names.
- **WHEN** a ViewDefinition uses `forEach: "name"` with a column
  `path: "%rowIndex"`.
- **THEN** the column contains `0` for the first name, `1` for the second name,
  and so on.

#### Scenario: %rowIndex in forEachOrNull with empty collection

- **GIVEN** a Patient resource with no identifiers.
- **WHEN** a ViewDefinition uses `forEachOrNull: "identifier"` with a column
  `path: "%rowIndex"`.
- **THEN** the single null row produced has `%rowIndex` equal to `0`.

#### Scenario: %rowIndex at top level

- **GIVEN** a Patient resource.
- **WHEN** a ViewDefinition has no `forEach`/`forEachOrNull`/`repeat` and includes
  a column `path: "%rowIndex"`.
- **THEN** the column contains `0` for each resource row.

---

### Requirement: %rowIndex scoping in nested iterations

Each `forEach`, `forEachOrNull`, or `repeat` context MUST have its own
independent `%rowIndex` value. The `%rowIndex` in an inner iteration block
reflects the position within the inner collection, not the outer collection.

#### Scenario: Nested forEach with independent indices

- **GIVEN** a Patient resource with 2 contacts, where the first contact has 3
  telecoms and the second contact has 2 telecoms.
- **WHEN** a ViewDefinition uses nested `forEach` blocks:
  - Outer: `forEach: "contact"` with column `contact_idx` from `%rowIndex`.
  - Inner: `forEach: "telecom"` with column `telecom_idx` from `%rowIndex`.
- **THEN** the output rows have:
  - `contact_idx=0, telecom_idx=0` (first contact, first telecom).
  - `contact_idx=0, telecom_idx=1` (first contact, second telecom).
  - `contact_idx=0, telecom_idx=2` (first contact, third telecom).
  - `contact_idx=1, telecom_idx=0` (second contact, first telecom).
  - `contact_idx=1, telecom_idx=1` (second contact, second telecom).

---

### Requirement: %rowIndex type

The `%rowIndex` environment variable MUST evaluate to an `integer` type.

#### Scenario: %rowIndex column type inference

- **GIVEN** a ViewDefinition with a column defined as `path: "%rowIndex"` without
  an explicit `type`.
- **WHEN** the view runner infers the column type.
- **THEN** the inferred type is `integer`.

---

### Requirement: %rowIndex in repeat

When using the `repeat` directive, `%rowIndex` MUST reflect the position of the
current node within the flattened sequence of all nodes visited during recursive
traversal.

#### Scenario: %rowIndex with repeat directive

- **GIVEN** a QuestionnaireResponse with nested items at multiple levels.
- **WHEN** a ViewDefinition uses `repeat: ["item", "answer.item"]` with a column
  `path: "%rowIndex"`.
- **THEN** the column contains sequential indices `0, 1, 2, ...` for each item
  in the order they are visited during traversal.
