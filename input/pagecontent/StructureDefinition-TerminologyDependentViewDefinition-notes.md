<!-- Author: John Grimes -->

### Value set membership

A view frequently needs to ask whether a code belongs to a
[value set](glossary.html#value-set): _keep the observations that record a vital
sign_, or _flag the conditions that are cardiovascular diseases_. FHIR defines a
FHIRPath function for this question,
[memberOf](https://hl7.org/fhir/fhirpath.html#functions), as one of the
functions it adds to the base FHIRPath language:

```
memberOf(valueset : string) : Boolean
```

The function is not part of the FHIRPath subset that the
[Shareable View Definition](StructureDefinition-ShareableViewDefinition.html)
profile requires, because evaluating it needs access to terminology as well as to
the resource. This profile identifies the views that need that access, and states
what a View Runner must do to execute them.

<span class="fhir-conformance" id="termview-1">All View Runners claiming
conformance to the Terminology Dependent View Definition profile SHALL implement
the [memberOf](https://hl7.org/fhir/fhirpath.html#functions) function as FHIR
defines it, for input that is a `code`, a `Coding`, a `CodeableConcept` or a
`string`.</span>
<span class="fhir-conformance" id="termview-2">The runner SHALL resolve the
argument of `memberOf` as the canonical URL of a ValueSet, which may carry a
`|version` suffix.</span> How the runner resolves the canonical URL and
determines the value set's membership is not defined here: it may use a
terminology server, a local terminology store, a cached
[expansion](glossary.html#expansion) or a static package.

The argument is an ordinary FHIRPath string, so it can be written as a literal or
supplied through a [constant](StructureDefinition-ViewDefinition.html#constants):

```js
"constant": [{
  "name": "vital_signs",
  "valueCanonical": "http://hl7.org/fhir/ValueSet/observation-vitalsignresult|5.0.0"
}],
"where": [{"path": "code.memberOf(%vital_signs)"}]
```

### Authoring considerations

Two parts of the FHIR definition of
[memberOf](https://hl7.org/fhir/fhirpath.html#functions) affect how a view is
written.

FHIR defines the result as empty where the input has more than one value.
`code.coding.memberOf(...)` is therefore empty for any resource whose `code`
carries more than one coding. To ask whether any coding is a member, pass the
`CodeableConcept` itself, as in `code.memberOf(...)`, or filter the codings, as
in `code.coding.where(memberOf(...)).exists()`. Within a `forEach` over
`code.coding`, each coding is a single item and `memberOf(...)` applies to it
alone.

FHIR also defines the result as empty where the value set cannot be resolved.
In a `where` clause, an empty result excludes the resource, so a view whose
value set cannot be resolved returns no rows rather than reporting an error. In
a column, it produces a null value. A runner may report unresolved value sets
through logging or other means; how it does so is implementation specific.

### One membership per evaluation {#membership-snapshot}

<span class="fhir-conformance" id="termview-3">Within one evaluation of a view,
every call to `memberOf` naming the same value set SHALL see the same
membership.</span> A runner that consults a terminology server for each call
must therefore not allow a change to the value set on the server partway through
an evaluation to be seen by some calls and not by others.
<span class="fhir-conformance" id="termview-4">Where the view is evaluated as
part of a [`$sql-run`](OperationDefinition-SQLRun.html) or
[`$sql-export`](OperationDefinition-SQLExport.html) job, every call to
`memberOf` naming the same value set within the job SHALL see the same
membership as every other reference to that value set within the job, including
a value set dependency of a SQLQuery or SQLView.</span> This extends the rule in
[One resolution per job](terminology-in-sql.html#membership-snapshot) to value
sets that a view names in FHIRPath.

### Evaluation in SQL

This section is informative.

A runner that translates views into SQL can evaluate `memberOf` without a
function call per row. It resolves each value set named in the view before the
query runs, exposes the membership as a relation with the columns described in
[The value set as a relation](terminology-in-sql.html#relation), and translates
each call into a semi-join on `system` and `code`, as described in
[Joining to a value set](terminology-in-sql.html#joining). This requires nothing
beyond standard SQL. Resolving each value set once before the query runs also
satisfies [termview-3](#termview-3).

### Combining with other profiles

A view may conform to this profile together with the
[Shareable View Definition](StructureDefinition-ShareableViewDefinition.html) and
[Tabular View Definition](StructureDefinition-TabularViewDefinition.html)
profiles. A runner that conforms to the Shareable View Definition profile alone
is not required to implement `memberOf`, and so cannot be relied upon to execute
a view that conforms to this profile.

### Example

The [Vital Sign Observations](ViewDefinition-VitalSignObservations.html) view
keeps the Observations whose code has at least one coding in the
[vital sign result](https://hl7.org/fhir/R5/valueset-observation-vitalsignresult.html)
value set, and produces one row per coding. It calls `memberOf` twice: in a
`where` clause on the `CodeableConcept` in `code`, and in a column on each
`Coding` within a `forEach` over `code.coding`.

Given two Observations:

| Observation | `code.coding`                                                                          |
| ----------- | -------------------------------------------------------------------------------------- |
| `o1`        | `http://loinc.org` `8867-4` (Heart rate) and `http://example.org/codes` `HR` (a local code) |
| `o2`        | `http://loinc.org` `2339-0` (Glucose)                                                  |

{:.table-data}

The `where` clause excludes `o2`, because its only coding is not a member of the
value set. It keeps `o1`, because one of its codings is. The `is_vital_sign`
column then tests each coding of `o1` separately:

| id   | system                     | code     | is_vital_sign |
| ---- | -------------------------- | -------- | ------------- |
| `o1` | `http://loinc.org`         | `8867-4` | `true`        |
| `o1` | `http://example.org/codes` | `HR`     | `false`       |

{:.table-data}

The `patient_id` and `effective_date_time` columns are omitted from the table
for brevity.
