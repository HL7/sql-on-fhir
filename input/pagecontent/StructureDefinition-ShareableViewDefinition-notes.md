### Required FHIRPath Expressions/Functions

All View Runners claiming conformance to the Shareable View Definition profile SHALL implement these [FHIRPath](https://hl7.org/fhirpath/)
capabilities:

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
