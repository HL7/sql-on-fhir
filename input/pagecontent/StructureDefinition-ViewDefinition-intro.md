It is the central piece of the [View Layer](index.html#system-layers) and
represents a tabular projection of FHIR resources with the columns and filtering
criteria defined by [FHIRPath](https://hl7.org/fhirpath/) expressions. The
logical model is described below.

## Key Elements

### Resource

Each ViewDefinition instance is tied to a single
FHIR [resource type](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.resource),
such as Patient or Observation. It will then create zero or more rows for
each resource
instance. [Examples](StructureDefinition-ViewDefinition-examples.html) include
simple tabular views of patients, unrolling patient addresses into an address
table, views of certain types of observations, and so on.

### Select

Each ViewDefinition instance has
a [select](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select)
that specifies the content and names for the columns in the view. The content
for each column is defined with [FHIRPath](https://hl7.org/fhirpath/)
expressions that return specific data elements from the FHIR resources.

### Where

The ViewDefinition may include one or
more [where](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.where)
clauses that may be used to further limit, or filter, the resources included in
the view. For instance, users may have different views for blood pressure
observations or other observation types.

### Constants

The ViewDefinition may include one or
more [constants](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.constant),
which are simply values that can be reused in FHIRPath expressions.

## View Runner

A *View Runner* implementation can execute a ViewDefinition and return the
results as a table that can be used for further processing using the user's
chosen tech stack. See [System Layers](index.html#system-layers) for details.

## Serialized Form

ViewDefinition is an additional resource, so its JSON and XML representations
follow the FHIR rules for additional resources
([JSON](https://hl7.org/fhir/6.0.0-ballot5/json.html#additional),
[XML](https://hl7.org/fhir/6.0.0-ballot5/xml.html#additional)). An instance
carries a `resourceDefinition` property (an attribute in XML) naming the
versioned canonical of its definition, as every example ViewDefinition
published with this guide does:

```js
{
  "resourceType": "ViewDefinition",
  "resourceDefinition": "http://hl7.org/fhir/StructureDefinition/ViewDefinition|3.0.0-ballot",
  "name": "patient_demographics",
  // other elements
}
```

Like `resourceType`, `resourceDefinition` is part of the serialization format
rather than an element of ViewDefinition, so it does not appear in the element
tables. A parser or validator built from the ViewDefinition StructureDefinition
alone will not find it among the elements, and should accept it as format
metadata rather than reject the instance. It has no effect on the rows a view
produces.

## Profiling

ViewDefinitions may be profiled to meet specific needs. For instance,
the [Shareable View Definition](StructureDefinition-ShareableViewDefinition.html)
profile adds constraints for ViewDefinitions intended to be shared between
systems. Implementers may create their own ViewDefinition profiles for further
specialized needs.
