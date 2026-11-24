### Required FHIRPath Expressions/Functions

<span class="fhir-conformance" id="shareable-1">All View Runners claiming conformance to the
Shareable View Definition profile SHALL implement these
[FHIRPath](https://hl7.org/fhirpath/STU3/en/) capabilities:</span>

-   [Literals](https://hl7.org/fhirpath/STU3/en/#literals) for String, Integer and Decimal
-   [where](https://hl7.org/fhirpath/STU3/en/#wherecriteria--this-index--boolean--collection) function
-   [exists](https://hl7.org/fhirpath/STU3/en/#existscriteria--this-index--boolean--boolean) function
-   [empty](https://hl7.org/fhirpath/STU3/en/#empty--boolean) function
-   [extension](https://hl7.org/fhir/R4/fhirpath.html#functions) function
-   [ofType](https://hl7.org/fhirpath/STU3/en/#oftypetype--type-specifier--collection)
    function
-   [first](https://hl7.org/fhirpath/STU3/en/#first--any) function
-   Boolean
    operators: [and](https://hl7.org/fhirpath/STU3/en/#and), [or](https://hl7.org/fhirpath/STU3/en/#or), [not](https://hl7.org/fhirpath/STU3/en/#not--boolean)
-   Math
    operators: [addition (+)](https://hl7.org/fhirpath/STU3/en/#-addition), [subtraction (-)](https://hl7.org/fhirpath/STU3/en/#--subtraction), [multiplication (\*)](https://hl7.org/fhirpath/STU3/en/#-multiplication), [division (/)](https://hl7.org/fhirpath/STU3/en/#-division)
-   Comparison
    operators: [equals (=)](https://hl7.org/fhirpath/STU3/en/#-equals), [not equals (!=)](https://hl7.org/fhirpath/STU3/en/#-not-equals), [greater than (>)](https://hl7.org/fhirpath/STU3/en/#-greater-than), [less or equal (<=)](https://hl7.org/fhirpath/STU3/en/#-less-or-equal)
-   [Indexer expressions](https://hl7.org/fhirpath/STU3/en/#-index--integer---any)

### Experimental FHIRPath Functions

The following functions are intended for eventual inclusion in the required subset. They are published in [FHIRPath 3.0.0](https://hl7.org/fhirpath/STU3/en/) as Standard for Trial Use (STU) content rather than normative content, and may still be subject to change:

-   [join](https://hl7.org/fhirpath/STU3/en/#joinseparator-string--string)
    function
-   [lowBoundary](https://hl7.org/fhirpath/STU3/en/#lowboundaryprecision-integer-decimal--date--datetime--time)
    and [highBoundary](https://hl7.org/fhirpath/STU3/en/#highboundaryprecision-integer-decimal--date--datetime--time)
    functions (including on [Period](https://hl7.org/fhir/datatypes.html#Period))
