<!-- Author: John Grimes -->

A query over FHIR data frequently asks a terminology question. _Return the
patients whose diagnosis code belongs to the cardiovascular disease value set_
is a question about membership of a [value set](glossary.html#value-set).
_Report each diagnosis as its ICD-10 code_ is a question about
[translation](glossary.html#concept-map) through a concept map. FHIR defines
both; SQL has a notion of neither. This page specifies how a
[SQLQuery](StructureDefinition-SQLQuery.html) or
[SQLView](StructureDefinition-SQLView.html) declares that it depends on a
ValueSet or a ConceptMap, and how a runner makes the artifact's content
available to the SQL: as a [relation](glossary.html#relation) with a fixed set
of columns, named by the dependency's label and joined to like any other table.

### Scope {#scope}

This page defines how a value set or concept map dependency is declared, the
columns and invariants of the relation that exposes each, how that content is
fixed for the duration of a job, and how an artifact supplied inline in a
request is used.

It does not define how membership is computed or how a concept map is obtained.
A runner may obtain a value set's [expansion](glossary.html#expansion) from a
terminology server, a local terminology store, a cached expansion or a static
package, and a ConceptMap from any of the same sources. Evaluation of
`ValueSet.compose`, execution of expression languages such as ECL or VCL,
post-coordination and terminology authoring remain responsibilities of the
terminology layer, which prepares the content before any SQL runs. The FHIRPath
subset available to ViewDefinition is unchanged; this page concerns the SQL
layer only.

### Declaring a terminology dependency {#dependency}

A ValueSet or ConceptMap is declared in the same way as a ViewDefinition or
SQLView dependency: one `relatedArtifact` entry with `type = "depends-on"`,
whose `resource` is the artifact's canonical URL and whose `label` is the SQL
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
    "resource": "http://example.org/ValueSet/cardiovascular-disease|2026",
    "label": "cvd_codes"
  },
  {
    "type": "depends-on",
    "resource": "http://example.org/ConceptMap/sct-to-icd10|2026",
    "label": "sct_to_icd10"
  }
]
```

<span class="fhir-conformance" id="term-1">A SQLQuery or SQLView that uses a
value set or a concept map SHALL declare it as a `relatedArtifact` entry with
`type = "depends-on"`, a `resource` carrying the ValueSet's or ConceptMap's
canonical URL and a `label`.</span>
<span class="fhir-conformance" id="term-2">The SQL SHALL refer to the artifact
by its `label` alone.</span> The SQL therefore names no ValueSet or ConceptMap
by canonical URL and no terminology server address; resolving the canonical URL
is the runner's job. The label is subject to the same
[rules as any other dependency label](StructureDefinition-SQLQuery.html#table-aliases),
and the [`@relatedDependency`](StructureDefinition-SQLQuery.html#sql-annotations)
annotation declares a terminology dependency in the same way as a view.

The canonical URL may carry a `|version` suffix, as in the example.
<span class="fhir-conformance" id="term-3">Authors SHOULD pin the version of a
value set or concept map dependency.</span> The membership of an unpinned value
set, or the mappings of an unpinned concept map, change each time the artifact
is republished, so two runs of the same query may return different rows for
reasons that are recorded nowhere in the query. Pinning fixes the artifact's
definition; the code system versions used to compute a value set's membership
from it are recorded by the runner, as described
[below](#membership-snapshot).

### The value set as a relation {#relation}

The runner exposes each value set dependency to the SQL as a relation whose name
is the dependency's `label` and whose columns are:

| Column     | SQL type            | Null | Content                                                                                             |
| ---------- | ------------------- | ---- | --------------------------------------------------------------------------------------------------- |
| `system`   | `CHARACTER VARYING` | No   | Canonical URL of the code system the member code is drawn from                                      |
| `version`  | `CHARACTER VARYING` | Yes  | Version of that code system used to determine membership; null where no version was recorded        |
| `code`     | `CHARACTER VARYING` | No   | The member code                                                                                     |
| `display`  | `CHARACTER VARYING` | Yes  | Display text for the code, informative only                                                         |
| `inactive` | `BOOLEAN`           | Yes  | `true` where the code is inactive in the code system version used; null where the expansion does not say, which is the normal case for an active code |

{:.table-data}

<span class="fhir-conformance" id="term-4">A runner executing a SQLQuery or
SQLView that declares a value set dependency SHALL make the value set available
under the dependency's `label` as a relation having at least the columns
`system`, `version`, `code`, `display` and `inactive`, of which `system` and
`code` are never null.</span>
<span class="fhir-conformance" id="term-5">The columns SHOULD carry the types
above, which are those the
[default type mappings](StructureDefinition-ViewDefinition.html#default-type-mappings)
assign to `uri`, `string`, `code` and `boolean`; a runner without native SQL
types SHOULD map them to the closest equivalent in its output format.</span>
<span class="fhir-conformance" id="term-6">A runner MAY add further columns to
the relation; authors SHOULD NOT rely on any column other than these
five.</span>

<span class="fhir-conformance" id="term-7">Each row of the relation SHALL
represent one member of the value set, identified by (`system`, `version`,
`code`), and the relation SHALL contain no two rows with the same `system`,
`version` and `code`, two null `version` values counting as equal.</span> A
value set with no members yields a relation with no rows; that is not an error.

Membership is what a FHIR expansion records, and the relation is its tabular
form.
<span class="fhir-conformance" id="term-8">Where the runner holds the value set
as a `ValueSet.expansion`, the relation SHALL contain one row for each distinct
(`system`, `version`, `code`) among the `expansion.contains` entries, at any
depth of nesting, whose `abstract` is not `true`, populated from such an entry's
`system`, `version`, `code`, `display` and `inactive`; an entry with
`abstract = true` is present for navigation only and SHALL NOT contribute a
row.</span> Nesting in an expansion is presentational, so a nested entry is as
much a member as a top-level one, and a code that a hierarchical expansion lists
under two parents is one member, not two. An inactive code the expansion
includes is a member. The `inactive` column lets a query exclude it, but
because FHIR populates `contains.inactive` only for inactive codes, the column is
null rather than `false` for an active code, and a filter must admit null:
`inactive IS NULL OR inactive = FALSE`. Whether inactive codes appear in the
expansion at all is decided when the value set is expanded, which is outside
the scope of this page.

### Joining to a value set {#joining}

The examples below select from a `conditions` dependency with columns
`patient_id`, `system`, `version` and `code`, and from two value set
dependencies, `cvd_codes` and `excluded_codes`. Each returns the matching
condition rows themselves, so a condition that matches must appear exactly
once. Where both the source data and the relation carry a code system version,
the membership test is a join on all three identifying columns; a null
`version` on either side makes the comparison unknown and drops the row, so
this form suits only data that is versioned throughout:

```sql
SELECT conditions.patient_id, conditions.code
FROM conditions
JOIN cvd_codes
  ON cvd_codes.system = conditions.system
 AND cvd_codes.version = conditions.version
 AND cvd_codes.code = conditions.code
```

Source data projected by a ViewDefinition rarely carries a version, because
`Coding.version` is rarely populated, and the test is then on `system` and
`code` alone. Because rows are unique on (`system`, `version`, `code`), the
relation may hold the same code under two versions of one code system, and a
`JOIN` on two columns would then return the condition row twice. Applying
`DISTINCT` to the output hides the duplication at the cost of a sort, and does
not help an aggregate such as `COUNT(*)`, which has already counted the row
twice. A semi-join tests membership without multiplying rows:

```sql
SELECT conditions.patient_id, conditions.code
FROM conditions
WHERE EXISTS (
  SELECT 1
  FROM cvd_codes
  WHERE cvd_codes.system = conditions.system
    AND cvd_codes.code = conditions.code
)
```

<span class="fhir-conformance" id="term-9">Where a query needs only a membership
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
join carries the display text into the output. It is a join rather than a
semi-join, so it is subject to the multiplication described above: with
versioned source data the `version` predicate makes each match unique, and with
unversioned source data a code listed under two versions yields two rows unless
the query selects one version or applies `DISTINCT`.

```sql
SELECT conditions.patient_id, conditions.code, cvd_codes.display
FROM conditions
JOIN cvd_codes
  ON cvd_codes.system = conditions.system
 AND cvd_codes.version = conditions.version
 AND cvd_codes.code = conditions.code
```

The membership itself can be inspected and counted:

```sql
SELECT cvd_codes.system, COUNT(*) AS members
FROM cvd_codes
GROUP BY cvd_codes.system
```

Two value sets can be intersected, or one subtracted from another, with the same
joins.

### The concept map as a relation {#concept-map-relation}

A [concept map](glossary.html#concept-map) asserts, for each of its source
codes, which target codes it maps to and how closely. The runner exposes each
concept map dependency to the SQL as a relation whose name is the dependency's
`label` and whose rows are those assertions, one per mapping:

| Column           | SQL type            | Null | Content                                                                                                   |
| ---------------- | ------------------- | ---- | --------------------------------------------------------------------------------------------------------- |
| `source_system`  | `CHARACTER VARYING` | No   | Canonical URL of the code system the source code is drawn from                                            |
| `source_version` | `CHARACTER VARYING` | Yes  | Version of that code system the mapping was authored against; null where the map records none             |
| `source_code`    | `CHARACTER VARYING` | No   | The source code                                                                                           |
| `source_display` | `CHARACTER VARYING` | Yes  | Display text for the source code, informative only                                                        |
| `target_system`  | `CHARACTER VARYING` | Yes  | Canonical URL of the code system the mapping translates into; null where the map records none             |
| `target_version` | `CHARACTER VARYING` | Yes  | Version of that code system; null where the map records none                                              |
| `target_code`    | `CHARACTER VARYING` | Yes  | The target code; null where the map states that the source code has no mapping                            |
| `target_display` | `CHARACTER VARYING` | Yes  | Display text for the target code, informative only                                                        |
| `relationship`   | `CHARACTER VARYING` | Yes  | How the source relates to the target, a code from [ConceptMapRelationship](https://hl7.org/fhir/valueset-concept-map-relationship.html); null where the map states that the source code has no mapping |

{:.table-data}

<span class="fhir-conformance" id="term-10">A runner executing a SQLQuery or
SQLView that declares a concept map dependency SHALL make the concept map
available under the dependency's `label` as a relation having at least the
columns `source_system`, `source_version`, `source_code`, `source_display`,
`target_system`, `target_version`, `target_code`, `target_display` and
`relationship`, of which `source_system` and `source_code` are never
null.</span>
<span class="fhir-conformance" id="term-11">The columns SHOULD carry the types
above, which are those the
[default type mappings](StructureDefinition-ViewDefinition.html#default-type-mappings)
assign to `uri`, `string` and `code`; a runner without native SQL types SHOULD
map them to the closest equivalent in its output format.</span>
<span class="fhir-conformance" id="term-12">A runner MAY add further columns to
the relation; authors SHOULD NOT rely on any column other than these
nine.</span>

The rows are the tabular form of the ConceptMap's `group.element` entries. Each
`target` of an element is one mapping; an element with `noMap = true` states
that its source code has no mapping into the group's target system, which is an
assertion of its own and is kept as a row so that a query can tell _the map
says no_ from _the map is silent_.
<span class="fhir-conformance" id="term-13">The relation SHALL contain one row
for each `group.element.target` of the ConceptMap, populated from the group's
`source` and `target`, the element's `code` and `display` and the target's
`code`, `display` and `relationship`; and one row for each `group.element`
whose `noMap` is `true`, populated from the group's `source` and `target` and
the element's `code` and `display`, with `target_code`, `target_display` and
`relationship` null.</span>
<span class="fhir-conformance" id="term-14">`source_system` and
`source_version` SHALL be the canonical URL in `group.source` and its
`|version` suffix where present, and `target_system` and `target_version` the
same for `group.target`.</span> Splitting the canonical this way gives columns
that compare directly with a `Coding.system` and `Coding.version` projected
from FHIR data. On a `noMap` row `target_system` is populated where the group
names a target, because the assertion is scoped to that system; the test for
such a row is therefore `target_code IS NULL`, not `target_system IS NULL`.

<span class="fhir-conformance" id="term-15">The relation SHALL contain no two
rows with the same `source_system`, `source_version`, `source_code`,
`target_system`, `target_version`, `target_code` and `relationship`, two null
values counting as equal.</span> A source code may still appear in several
rows: a map may give it several targets, or targets in several target systems,
or list it under two versions of its code system. A concept map with no
mappings yields a relation with no rows; that is not an error.

A ConceptMap may carry content that no flat row can represent. A `target` with
`dependsOn` applies only when some other attribute of the source has a given
value, which the relation has no way to evaluate; a `target` with `product`
yields further outputs alongside the target code, so the target code alone is
not the translation; an `element` or `target` carrying `valueSet` in place of a
code asserts a mapping over a set rather than a code; and a `group` without a
`source` gives codes with no system, which can never match FHIR data.
<span class="fhir-conformance" id="term-16">Where a ConceptMap contains a
`group` without `source`, an `element` or `target` carrying `valueSet`, or a
`target` carrying `dependsOn` or `product`, the runner SHALL fail the request
before executing any SQL, as a concept map whose mappings cannot be
determined.</span> Omitting such mappings would leave the relation silently
incomplete, and including them would produce translations that do not apply;
see [One resolution per job](#membership-snapshot) for how the failure is
reported.

`group.unmapped` gives a default for source codes the group does not list: pass
the source code through, substitute a fixed code, or consult another map. None
is a finite set of rows.
<span class="fhir-conformance" id="term-17">A runner SHALL NOT derive rows from
`group.unmapped`.</span> The relation carries the map's explicit mappings only.
This is a deliberate difference from the
[`$translate`](https://hl7.org/fhir/conceptmap-operation-translate.html)
operation, which applies the default; a query that wants pass-through for
unmapped codes writes it itself, as `COALESCE(sct_to_icd10.target_code,
conditions.code)`.

### Translating with a concept map {#translating}

The examples below select from the same `conditions` dependency and from a
concept map dependency `sct_to_icd10` whose single group maps SNOMED CT codes to
ICD-10. Translation needs the target columns, so it is a join rather than a
semi-join, and a `LEFT JOIN` keeps the source rows the map does not translate:

```sql
SELECT conditions.patient_id,
       conditions.code,
       sct_to_icd10.target_code,
       sct_to_icd10.relationship
FROM conditions
LEFT JOIN sct_to_icd10
  ON sct_to_icd10.source_system = conditions.system
 AND sct_to_icd10.source_code = conditions.code
 AND (sct_to_icd10.relationship IS NULL
      OR sct_to_icd10.relationship <> 'not-related-to')
```

A `relationship` of `not-related-to` is an explicit assertion that the target
is _not_ a translation of the source, yet the row carries a target code, and a
join that does not look at `relationship` would report it as one.
<span class="fhir-conformance" id="term-18">Where a query translates a code,
authors SHOULD exclude rows whose `relationship` is `not-related-to`.</span> The
exclusion belongs in the `ON` clause: placed in `WHERE`, it would also drop the
source rows the `LEFT JOIN` was written to keep. It must admit null, because a
`noMap` row has no `relationship`; `relationship <> 'not-related-to'` alone is
unknown for null and would drop the row.

After the join, a source row falls into one of three cases, told apart by which
columns are null. A translated row has a `target_code`. A row the map says has
no mapping has `source_code` populated and `target_code` null. A row the map is
silent about - its code, or its whole code system, is absent from the map - has
every column of the relation null. The worked [example](#example-concept-map)
shows all three.

One source code may match several rows. Where the map has several groups with
different target systems, a `target_system` predicate selects one; where
precision matters, a `relationship` predicate such as
`relationship = 'equivalent'` keeps only exact translations at the cost of
dropping the rest; and where neither predicate leaves a single row, the query
either accepts one output row per mapping or selects among them. Where both the
source data and the relation carry a code system version, `source_version` joins
in the same way as the value set relation's `version`, with the same
consequences for null.

Because the relation has two sides, the same map translates in either direction:
a join on `target_system` and `target_code` that selects `source_code` is the
reverse translation, and needs no second artifact. Several source codes commonly
map to one target, so the reverse direction multiplies rows more readily than
the forward one.

A translated code is a code like any other, and can be tested for membership by
semi-joining the target columns to a value set relation:

```sql
SELECT conditions.patient_id, sct_to_icd10.target_code
FROM conditions
JOIN sct_to_icd10
  ON sct_to_icd10.source_system = conditions.system
 AND sct_to_icd10.source_code = conditions.code
 AND sct_to_icd10.relationship = 'equivalent'
WHERE EXISTS (
  SELECT 1
  FROM cvd_codes
  WHERE cvd_codes.system = sct_to_icd10.target_system
    AND cvd_codes.code = sct_to_icd10.target_code
)
```

### One resolution per job {#membership-snapshot}

A job is one `$sql-run` invocation, or one `$sql-export` job across all of its
subjects. A value set resolves to a membership and a concept map to a set of
mappings; this section calls either the artifact's _content_.
<span class="fhir-conformance" id="term-19">Within one job, every value set
and concept map dependency SHALL be resolved to a single content before any SQL
executes, and every reference to that artifact within the job SHALL see that
same content.</span> This is the terminology counterpart of the data
[snapshot](glossary.html#snapshot). The
[matching algorithm](operations-common.html#context-matching) already resolves
each canonical URL once per job, so two subjects depending on the same artifact
see the same relation.

Resolution proceeds from the canonical URL, with its version where pinned, to a
ValueSet or ConceptMap, and from the artifact to its content: for a value set,
from its definition to its membership; for a concept map, from its `group`
entries to the rows described [above](#concept-map-relation).
<span class="fhir-conformance" id="term-20">Where a value set or concept map
dependency cannot be resolved to a single content - because the canonical URL
cannot be resolved, because the runner cannot determine which version to use,
because the runner cannot determine the value set's membership, or because the
concept map carries content the relation cannot represent - the runner SHALL
fail the request before executing any SQL.</span> Executing with a partial or
empty content would return rows that are wrong rather than a request that is
rejected. In the [operations](operations.html), a canonical URL that cannot be
resolved, or cannot be resolved to a single version, is rejected with
`404 Not Found`, as for any other dependency, and an artifact that resolves but
whose content the server cannot determine is rejected with
`422 Unprocessable Entity`; see
[Rejected requests](operations-common.html#context-errors). On `$sql-export`
both are kick-off rejections, made before the job is accepted, like every other
dependency failure.

A content is reproducible only if what produced it is known.
<span class="fhir-conformance" id="term-21">For each value set dependency of a
job, a runner SHOULD record the canonical URL and version of the ValueSet
resolved, the versions of the code systems and of any nested value sets used to
compute membership, any expansion parameters that affect membership, the
identity of the terminology source, and an identifier for the expansion where
the source provides one.</span> When membership comes from a FHIR expansion, the
expansion carries this itself: `expansion.identifier` and `expansion.timestamp`
identify it, and `expansion.parameter` records the parameters that affected it,
including the version of each code system used.
<span class="fhir-conformance" id="term-22">For each concept map dependency of
a job, a runner SHOULD record the canonical URL and version of the ConceptMap
resolved and the identity of the source it was obtained from.</span> A concept
map's mappings are stated in the resource rather than computed from it, so
there is no counterpart to expansion parameters, and the code system versions
the mappings were authored against are in the relation itself. How a runner
exposes this record is implementation-defined.

### Supplying an artifact inline {#inline}

The `context` parameter of [`$sql-run`](OperationDefinition-SQLRun.html) and
[`$sql-export`](OperationDefinition-SQLExport.html) admits a ValueSet or a
ConceptMap alongside a ViewDefinition or SQLView, for an artifact the server
cannot itself resolve. It is matched to a dependency by `url`, and by `version`
where the dependency pins one, under the rules in
[Supporting artifacts](operations-common.html#context). Both are leaves of the
dependency graph: neither contributes dependencies of its own.

<span class="fhir-conformance" id="term-23">Where a supplied ValueSet carries an
`expansion`, the runner SHALL derive membership from that expansion rather than
expanding the value set itself.</span> A client that supplies an expansion
states the membership it intends, in the same way that a supplied ViewDefinition
states the view it intends.
<span class="fhir-conformance" id="term-24">An expansion that is incomplete - one
carrying an `offset`, or whose `total` exceeds the number of `contains` entries
at all depths - does not determine membership, and the request SHALL be rejected
as a value set whose membership cannot be determined.</span> A supplied ValueSet
carrying only a `compose` is expanded by the runner where it is able to; where
it is not, the request fails in the same way.

A supplied ConceptMap carries its mappings in full, so there is no counterpart
to expansion: the relation is derived from its `group` entries directly, and
[term-16](#term-16) applies to it as to a map the server resolved itself.

### Examples {#example}

The [Cardiovascular Disease Patients](Library-CardiovascularDiseasePatientsQuery.html)
and [Conditions Translated to ICD-10](Library-ConditionsToIcd10Query.html)
queries declare the dependencies shown [above](#dependency). Suppose the
`conditions` view produces:

| patient_id | system                           | version | code        |
| ---------- | -------------------------------- | ------- | ----------- |
| `p1`       | `http://snomed.info/sct`         |         | `22298006`  |
| `p2`       | `http://hl7.org/fhir/sid/icd-10` |         | `I21`       |
| `p3`       | `http://snomed.info/sct`         |         | `73211009`  |
| `p4`       | `http://snomed.info/sct`         |         | `102499006` |

{:.table-data}

#### Value set membership {#example-value-set}

The runner resolves `http://example.org/ValueSet/cardiovascular-disease|2026`
to the following ValueSet. This is also what a `context` entry supplying the
value set inline would carry. The expansion records the code system versions it
used as `parameter` entries, and lists its two members under an abstract
grouping entry:

```json
{
  "resourceType": "ValueSet",
  "url": "http://example.org/ValueSet/cardiovascular-disease",
  "version": "2026",
  "name": "CardiovascularDisease",
  "status": "active",
  "expansion": {
    "identifier": "urn:uuid:635ad7e4-4f98-48ef-a3c2-1e3af6cc03ec",
    "timestamp": "2026-09-16T00:00:00Z",
    "total": 3,
    "parameter": [
      {
        "name": "version",
        "valueUri": "http://snomed.info/sct|http://snomed.info/sct/900000000000207008/version/20260201"
      },
      {
        "name": "version",
        "valueUri": "http://hl7.org/fhir/sid/icd-10|2019"
      }
    ],
    "contains": [
      {
        "abstract": true,
        "display": "Ischaemic heart disease",
        "contains": [
          {
            "system": "http://snomed.info/sct",
            "version": "http://snomed.info/sct/900000000000207008/version/20260201",
            "code": "22298006",
            "display": "Myocardial infarction"
          },
          {
            "system": "http://hl7.org/fhir/sid/icd-10",
            "version": "2019",
            "code": "I21",
            "display": "Acute myocardial infarction"
          }
        ]
      }
    ]
  }
}
```

The abstract entry is navigational and contributes no row; the two nested
entries are members, so the runner exposes the relation `cvd_codes` with two
rows. Neither entry carries `inactive`, as is usual for an active code, so the
column is null:

| system                           | version                                                      | code       | display                       | inactive |
| -------------------------------- | ------------------------------------------------------------ | ---------- | ----------------------------- | -------- |
| `http://snomed.info/sct`         | `http://snomed.info/sct/900000000000207008/version/20260201` | `22298006` | `Myocardial infarction`       |          |
| `http://hl7.org/fhir/sid/icd-10` | `2019`                                                       | `I21`      | `Acute myocardial infarction` |          |

{:.table-data}

The `2026` in the canonical URL is the value set's version; the `2019` in the
second row is the version of the ICD-10 code system its expansion was computed
against. The two are independent, which is why the relation records the latter.

The query is the semi-join shown [above](#joining), and returns the `p1` and
`p2` rows: their codes are members, and `73211009` (diabetes mellitus) and
`102499006` (fit and well) are not. Had the runner been unable to resolve the
value set, the request would have failed before the SQL ran, rather than
returning no patients.

#### Concept map translation {#example-concept-map}

The runner resolves `http://example.org/ConceptMap/sct-to-icd10|2026` to the
following ConceptMap, which is likewise what a `context` entry would carry. Its
one group names the ICD-10 version the mappings were authored against as a
`|version` suffix on `target` and no SNOMED CT edition on `source`, maps two
codes, and states that a third has no mapping:

```json
{
  "resourceType": "ConceptMap",
  "url": "http://example.org/ConceptMap/sct-to-icd10",
  "version": "2026",
  "name": "SnomedCtToIcd10",
  "status": "active",
  "group": [
    {
      "source": "http://snomed.info/sct",
      "target": "http://hl7.org/fhir/sid/icd-10|2019",
      "element": [
        {
          "code": "22298006",
          "display": "Myocardial infarction",
          "target": [
            {
              "code": "I21",
              "display": "Acute myocardial infarction",
              "relationship": "equivalent"
            }
          ]
        },
        {
          "code": "73211009",
          "display": "Diabetes mellitus",
          "target": [
            {
              "code": "E14",
              "display": "Unspecified diabetes mellitus",
              "relationship": "source-is-broader-than-target",
              "comment": "The source covers every type of diabetes; ICD-10 classifies the types to E10-E13 and the unspecified remainder to E14"
            }
          ]
        },
        {
          "code": "102499006",
          "display": "Fit and well",
          "noMap": true,
          "comment": "A finding of health has no counterpart in a classification of disease"
        }
      ]
    }
  ]
}
```

The two `target` entries and the `noMap` element each contribute a row, so the
runner exposes the relation `sct_to_icd10` with three rows. The group's
`target` canonical is split at `|` into system and version; its `source`
carries no version, so `source_version` is null. The third row carries the
group's target system, because the assertion is that `102499006` has no mapping
into ICD-10, but its `target_code` and `relationship` are null:

| source_system            | source_version | source_code | source_display          | target_system                    | target_version | target_code | target_display                  | relationship                    |
| ------------------------ | -------------- | ----------- | ----------------------- | -------------------------------- | -------------- | ----------- | ------------------------------- | ------------------------------- |
| `http://snomed.info/sct` |                | `22298006`  | `Myocardial infarction` | `http://hl7.org/fhir/sid/icd-10` | `2019`         | `I21`       | `Acute myocardial infarction`   | `equivalent`                    |
| `http://snomed.info/sct` |                | `73211009`  | `Diabetes mellitus`     | `http://hl7.org/fhir/sid/icd-10` | `2019`         | `E14`       | `Unspecified diabetes mellitus` | `source-is-broader-than-target` |
| `http://snomed.info/sct` |                | `102499006` | `Fit and well`          | `http://hl7.org/fhir/sid/icd-10` | `2019`         |             |                                 |                                 |

{:.table-data}

The `comment` elements are not columns; a runner may add them, but the query
does not rely on them.

The query is the `LEFT JOIN` shown [above](#translating), and returns one row
per condition:

| patient_id | code        | target_code | relationship                    |
| ---------- | ----------- | ----------- | ------------------------------- |
| `p1`       | `22298006`  | `I21`       | `equivalent`                    |
| `p2`       | `I21`       |             |                                 |
| `p3`       | `73211009`  | `E14`       | `source-is-broader-than-target` |
| `p4`       | `102499006` |             |                                 |

{:.table-data}

`p1` and `p3` are translated, and `relationship` records that the second
translation is less exact than the first. `p2` and `p4` both lack a
`target_code`, for different reasons: `p2` is already an ICD-10 code, so its
system is absent from the map and every column of the relation is null for it;
`p4` is in the map with `noMap`, so `sct_to_icd10.source_code` is populated
for it and `target_code` alone is null. A query that needs to report the two
cases separately tests `sct_to_icd10.source_code IS NULL`. Had the map carried
a `dependsOn`, the request would have failed before the SQL ran, rather than
returning translations that might not apply.
