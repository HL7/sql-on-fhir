### Publication metadata

A view that is distributed between systems needs to be identified, versioned
and attributed independently of the system that holds it. In addition to
`status`, which every ViewDefinition carries, this profile requires the
following elements:

| Element       | Purpose                                                                               |
| ------------- | ------------------------------------------------------------------------------------- |
| `url`         | Canonical identifier of the view, which stays the same on every system that holds it. |
| `version`     | Business version of the view, which distinguishes versions that share a `url`.        |
| `name`        | Computer-friendly name, usable as a table name.                                       |
| `title`       | Human-friendly name.                                                                  |
| `publisher`   | Organization or individual responsible for publishing the view.                       |
| `description` | Natural language description of the rows that the view produces.                      |

These requirements follow the
[CRMI Shareable Library](https://hl7.org/fhir/uv/crmi/StructureDefinition-crmi-shareablelibrary.html)
profile, with one addition: `publisher` is required here, where CRMI marks it
as Must Support only. `name` was already required by this profile.

The [Shareable Patient Demographics](ViewDefinition-ShareablePatientDemographics.html)
example conforms to this profile.

### Must Support

The elements `url`, `version`, `versionAlgorithm[x]`, `name`, `title`,
`status`, `experimental`, `publisher` and `description` are marked as Must
Support. For a ViewDefinition claiming conformance to this profile, Must
Support is interpreted as follows, adapted from
[CRMI](https://hl7.org/fhir/uv/crmi/conformance.html):

- <span class="fhir-conformance" id="shareable-2">Systems that author or
  store ViewDefinitions SHALL be capable of populating all Must Support
  elements.</span>
- <span class="fhir-conformance" id="shareable-3">Systems that distribute
  ViewDefinitions SHOULD populate all Must Support elements when
  transmitting a view.</span>
- <span class="fhir-conformance" id="shareable-4">View runners SHALL be
  capable of processing a ViewDefinition containing any Must Support element
  without generating an error or failing to run the view.</span>
- <span class="fhir-conformance" id="shareable-5">Where the value of an
  optional Must Support element is not known, systems SHALL omit the element
  rather than populate it with a placeholder value.</span>
- <span class="fhir-conformance" id="shareable-6">Systems consuming a
  ViewDefinition SHALL interpret a missing Must Support element as
  information that is not present for the view.</span>

### Required FHIRPath Expressions/Functions

<span class="fhir-conformance" id="shareable-1">All View Runners claiming conformance to the
Shareable View Definition profile SHALL implement these
[FHIRPath](https://hl7.org/fhirpath/) capabilities:</span>

-   [Literals](https://hl7.org/fhirpath/#literals) for String, Integer and Decimal
-   [where](https://hl7.org/fhirpath/#wherecriteria-expression-collection)function
-   [exists](https://hl7.org/fhirpath/#existscriteria-expression-boolean) function
-   [empty](https://hl7.org/fhirpath/#empty-boolean) function
-   [extension](https://hl7.org/fhir/R4/fhirpath.html#functions) function
-   [ofType](https://hl7.org/fhirpath/#oftypetype-type-specifier-collection)
    function
-   [first](https://hl7.org/fhirpath/#first-collection) function
-   Boolean
    operators: [and](https://hl7.org/fhirpath/#and), [or](https://hl7.org/fhirpath/#or), [not](https://hl7.org/fhirpath/#not-boolean)
-   Math
    operators: [addition (+)](https://hl7.org/fhirpath/#addition), [subtraction (-)](https://hl7.org/fhirpath/#subtraction), [multiplication (\*)](https://hl7.org/fhirpath/#multiplication), [division (/)](https://hl7.org/fhirpath/#division)
-   Comparison
    operators: [equals (=)](https://hl7.org/fhirpath/#equals), [not equals (!=)](https://hl7.org/fhirpath/#not-equals), [greater than (>)](https://hl7.org/fhirpath/#greater-than), [less or equal (<=)](https://hl7.org/fhirpath/#less-or-equal)
-   [Indexer expressions](https://hl7.org/fhirpath/#index-integer-collection)

### Experimental FHIRPath Functions

The following functions are intended for eventual inclusion in the required subset, however they are not yet a part of the normative [FHIRPath](https://hl7.org/fhirpath/) release and may still be subject to change:

-   [join](https://build.fhir.org/ig/HL7/FHIRPath/#joinseparator-string-string)
    function
-   [lowBoundary](https://build.fhir.org/ig/HL7/FHIRPath/#lowboundaryprecision-integer-decimal--date--datetime--time)
    and [highBoundary](https://build.fhir.org/ig/HL7/FHIRPath/#highboundaryprecision-integer-decimal--date--datetime--time)
    functions (including on [Period](https://hl7.org/fhir/datatypes.html#Period))
