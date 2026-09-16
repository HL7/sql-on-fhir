<!-- Author: John Grimes -->

# Terminology in SQL

A query over FHIR data frequently asks a terminology question. _Return the
patients whose diagnosis code belongs to the diabetes value set_ is a question
about membership of a [value set](glossary.html#value-set), which FHIR defines
and SQL has no notion of. This page specifies how a
[SQLQuery](StructureDefinition-SQLQuery.html) or
[SQLView](StructureDefinition-SQLView.html) declares that it depends on a
ValueSet, and how a runner makes the value set's membership available to the
SQL: as a [relation](glossary.html#relation) with a fixed set of columns, named
by the dependency's label and joined to like any other table.

## Scope {#scope}

This page defines how a value set dependency is declared, the columns and
invariants of the relation that exposes it, how membership is fixed for the
duration of a job, and how a ValueSet supplied inline in a request is used.

It does not define how membership is computed. A runner may obtain a value
set's [expansion](glossary.html#expansion) from a terminology server, a local
terminology store, a cached expansion or a static package. Evaluation of
`ValueSet.compose`, execution of expression languages such as ECL or VCL,
post-coordination and terminology authoring remain responsibilities of the
terminology layer, which prepares membership before any SQL runs. The FHIRPath
subset available to ViewDefinition is unchanged; this page concerns the SQL
layer only.

## Declaring a value set dependency {#dependency}

A ValueSet is declared in the same way as a ViewDefinition or SQLView
dependency: one `relatedArtifact` entry with `type = "depends-on"`, whose
`resource` is the value set's canonical URL and whose `label` is the SQL
identifier the query refers to it by.

```json
"relatedArtifact": [
  {
    "type": "depends-on",
    "resource": "https://example.org/ViewDefinition/conditions",
    "label": "conditions"
  },
  {
    "type": "depends-on",
    "resource": "http://example.org/ValueSet/diabetes|2026",
    "label": "diabetes_codes"
  }
]
```

<span class="fhir-conformance" id="term-1">A SQLQuery or SQLView that uses a
value set SHALL declare it as a `relatedArtifact` entry with
`type = "depends-on"`, a `resource` carrying the ValueSet's canonical URL and a
`label`.</span>
<span class="fhir-conformance" id="term-2">The SQL SHALL refer to the value set
by its `label` alone.</span> The SQL therefore contains no canonical URLs and no
terminology server addresses; resolving the canonical URL is the runner's job.
The label is subject to the same
[rules as any other dependency label](StructureDefinition-SQLQuery.html#table-aliases),
and the [`@relatedDependency`](StructureDefinition-SQLQuery.html#sql-annotations)
annotation declares a value set dependency in the same way as a view.

The canonical URL may carry a `|version` suffix, as in the example.
<span class="fhir-conformance" id="term-3">Authors SHOULD pin the version of a
value set dependency.</span> The membership of an unpinned value set changes each
time the value set is republished, so two runs of the same query may return
different rows for reasons that are recorded nowhere in the query. Pinning fixes
the value set's definition; the code system versions used to compute membership
from it are recorded by the runner, as described
[below](#membership-snapshot).

## The value set as a relation {#relation}

The runner exposes each value set dependency to the SQL as a relation whose name
is the dependency's `label` and whose columns are:

| Column     | SQL type            | Null | Content                                                                                             |
| ---------- | ------------------- | ---- | --------------------------------------------------------------------------------------------------- |
| `system`   | `CHARACTER VARYING` | No   | Canonical URL of the code system the member code is drawn from                                      |
| `version`  | `CHARACTER VARYING` | Yes  | Version of that code system used to determine membership; null where no version was recorded        |
| `code`     | `CHARACTER VARYING` | No   | The member code                                                                                     |
| `display`  | `CHARACTER VARYING` | Yes  | Display text for the code, informative only                                                         |
| `inactive` | `BOOLEAN`           | Yes  | `true` where the code is inactive in the code system version used; null where inactivity was not recorded |

{:.table-data}

The types are those the
[default type mappings](StructureDefinition-ViewDefinition.html#default-type-mappings)
assign to `uri`, `string`, `code` and `boolean`, and a runner without native SQL
types maps them to the closest equivalent in the same way.

<span class="fhir-conformance" id="term-4">A runner executing a SQLQuery or
SQLView that declares a value set dependency SHALL make the value set available
under the dependency's `label` as a relation having at least the columns
`system`, `version`, `code`, `display` and `inactive`, with the types and
nullability above.</span>
<span class="fhir-conformance" id="term-5">A runner MAY add further columns to
the relation; authors SHOULD NOT rely on any column other than these
five.</span>

<span class="fhir-conformance" id="term-6">Each row of the relation SHALL
represent one member of the value set, identified by (`system`, `version`,
`code`), and the relation SHALL contain no two rows with the same `system`,
`version` and `code`, two null `version` values counting as equal.</span> A
value set with no members yields a relation with no rows; that is not an error.

Membership is what a FHIR expansion records, and the relation is its tabular
form.
<span class="fhir-conformance" id="term-7">Where the runner holds the value set
as a `ValueSet.expansion`, the relation SHALL contain one row for each distinct
(`system`, `version`, `code`) among the `expansion.contains` entries, at any
depth of nesting, whose `abstract` is not `true`, populated from such an entry's
`system`, `version`, `code`, `display` and `inactive`; an entry with
`abstract = true` is present for navigation only and SHALL NOT contribute a
row.</span> Nesting in an expansion is presentational, so a nested entry is as
much a member as a top-level one, and a code that a hierarchical expansion lists
under two parents is one member, not two. An inactive code the expansion
includes is a member; the `inactive` column lets a query exclude it. Whether
inactive codes appear in the expansion at all is decided when the value set is
expanded, which is outside the scope of this page.

## Joining to a value set {#joining}

The examples below select from a `conditions` dependency with columns
`patient_id`, `system`, `version` and `code`, and a `diabetes_codes` value set
dependency. Where the source data carries a code system version, the membership
test is a join on all three identifying columns:

```sql
SELECT DISTINCT conditions.patient_id
FROM conditions
JOIN diabetes_codes
  ON diabetes_codes.system = conditions.system
 AND diabetes_codes.version = conditions.version
 AND diabetes_codes.code = conditions.code
```

Source data projected by a ViewDefinition rarely carries a version, because
`Coding.version` is rarely populated, and the test is then on `system` and
`code` alone. Because rows are unique on (`system`, `version`, `code`), the
relation may hold the same code under two versions of one code system, and a
`JOIN` on two columns would then return the condition row twice. A semi-join
tests membership without multiplying rows:

```sql
SELECT DISTINCT conditions.patient_id
FROM conditions
WHERE EXISTS (
  SELECT 1
  FROM diabetes_codes
  WHERE diabetes_codes.system = conditions.system
    AND diabetes_codes.code = conditions.code
)
```

<span class="fhir-conformance" id="term-8">Where a query needs only a membership
test, authors SHOULD express it as a semi-join (`EXISTS`) rather than a
`JOIN`.</span>

A source row whose `system` or `code` is null is a member of nothing: comparison
with null yields unknown, so the row satisfies neither the join condition nor
the `EXISTS` predicate. No special handling is needed.

Exclusion is the negated form:

```sql
SELECT conditions.patient_id, conditions.code
FROM conditions
WHERE NOT EXISTS (
  SELECT 1
  FROM excluded_codes
  WHERE excluded_codes.system = conditions.system
    AND excluded_codes.code = conditions.code
)
```

Because the value set is a table, everything SQL does with a table applies. A
join carries the display text into the output:

```sql
SELECT conditions.patient_id, conditions.code, diabetes_codes.display
FROM conditions
JOIN diabetes_codes
  ON diabetes_codes.system = conditions.system
 AND diabetes_codes.code = conditions.code
```

The membership itself can be inspected and counted:

```sql
SELECT diabetes_codes.system, COUNT(*) AS members
FROM diabetes_codes
GROUP BY diabetes_codes.system
```

Two value sets can be intersected, or one subtracted from another, with the same
joins.

## One membership per job {#membership-snapshot}

A job is one `$sql-run` invocation, or one `$sql-export` job across all of its
subjects.
<span class="fhir-conformance" id="term-9">Within one job, every value set
dependency SHALL be resolved to a single membership before any SQL executes, and
every reference to that value set within the job SHALL see that same
membership.</span> This is the terminology counterpart of the data
[snapshot](glossary.html#snapshot). The
[matching algorithm](operations-common.html#context-matching) already resolves
each canonical URL once per job, so two subjects depending on the same value set
see the same relation.

Resolution proceeds from the canonical URL, with its version where pinned, to a
ValueSet, and from the ValueSet to its membership.
<span class="fhir-conformance" id="term-10">Where a value set dependency cannot
be resolved to a single membership - because the canonical URL cannot be
resolved, because the runner cannot determine which version to use, or because
the runner cannot determine the value set's membership - the runner SHALL fail
the request before executing any SQL.</span> Executing with a partial or empty
membership would return rows that are wrong rather than a request that is
rejected. In the [operations](operations.html), a canonical URL that cannot be
resolved is rejected with `404 Not Found`, as for any other dependency, and a
value set that resolves but whose membership the server cannot determine is
rejected with `422 Unprocessable Entity`; see
[Rejected requests](operations-common.html#context-errors).

A membership is reproducible only if what produced it is known.
<span class="fhir-conformance" id="term-11">For each value set dependency of a
job, a runner SHOULD record the canonical URL and version of the ValueSet
resolved, the versions of the code systems and of any nested value sets used to
compute membership, any expansion parameters that affect membership, the
identity of the terminology source, and an identifier for the expansion where
the source provides one.</span> When membership comes from a FHIR expansion, the
expansion carries this itself: `expansion.identifier` and `expansion.timestamp`
identify it, and `expansion.parameter` records the parameters that affected it,
including the version of each code system used. How a runner exposes this record
is implementation-defined.

## Supplying a value set inline {#inline}

The `context` parameter of [`$sql-run`](OperationDefinition-SQLRun.html) and
[`$sql-export`](OperationDefinition-SQLExport.html) admits a ValueSet alongside a
ViewDefinition or SQLView, for a value set the server cannot itself resolve. It
is matched to a dependency by `url`, and by `version` where the dependency pins
one, under the rules in
[Supporting artifacts](operations-common.html#context). A ValueSet is a leaf of
the dependency graph: it contributes no dependencies of its own.

<span class="fhir-conformance" id="term-12">Where a supplied ValueSet carries an
`expansion`, the runner SHALL derive membership from that expansion rather than
expanding the value set itself.</span> A client that supplies an expansion
states the membership it intends, in the same way that a supplied ViewDefinition
states the view it intends.
<span class="fhir-conformance" id="term-13">An expansion that is incomplete - one
carrying an `offset`, or whose `total` exceeds the number of `contains` entries
at all depths - does not determine membership, and the request SHALL be rejected
as a value set whose membership cannot be determined.</span> A supplied ValueSet
carrying only a `compose` is expanded by the runner where it is able to; where
it is not, the request fails in the same way.

## Example {#example}

The [Diabetes Patients](Library-DiabetesPatientsQuery.html) query declares the
two dependencies shown [above](#dependency). Suppose the `conditions` view
produces:

| patient_id | system                           | version | code       |
| ---------- | -------------------------------- | ------- | ---------- |
| `p1`       | `http://snomed.info/sct`         |         | `73211009` |
| `p2`       | `http://hl7.org/fhir/sid/icd-10` |         | `E11`      |
| `p3`       | `http://snomed.info/sct`         |         | `22298006` |

{:.table-data}

and the runner resolves `http://example.org/ValueSet/diabetes|2026` to an
expansion of two concepts, which it exposes as the relation `diabetes_codes`:

| system                           | version                                              | code       | display             | inactive |
| -------------------------------- | ---------------------------------------------------- | ---------- | ------------------- | -------- |
| `http://snomed.info/sct`         | `http://snomed.info/sct/900000000000207008/version/20260201` | `73211009` | `Diabetes mellitus` | `false`  |
| `http://hl7.org/fhir/sid/icd-10` | `2026`                                               | `E11`      | `Type 2 diabetes mellitus` | `false`  |

{:.table-data}

The query is the semi-join shown [above](#joining), and returns `p1` and `p2`:
their codes are members, and `22298006` (myocardial infarction) is not. Had the
runner been unable to resolve the value set, the request would have failed before
the SQL ran, rather than returning no patients.
