Invariant: sql-name
Description: """
Name is limited to letters, numbers, or underscores and cannot start with an
underscore -- i.e. with a regular expression of: ^[A-Za-z][A-Za-z0-9_]*$ 


This makes it usable as table names in a wide variety of databases.
"""
Severity: #error
Expression: "empty() or matches('^[A-Za-z][A-Za-z0-9_]*$')"


Invariant: sql-expressions
Description: """
Can only have at most one of `forEach`, `forEachOrNull`, or `repeat`.
"""
Severity: #error
Expression: "(forEach.exists().toInteger() + forEachOrNull.exists().toInteger() + repeat.exists().toInteger()) <= 1"

// NOTE: Using RuleSet with LogicalModels where you pass parameters seems to be broken
Logical: ViewDefinition
Title: "View Definition"
Parent: CanonicalResource
Description: """
A ViewDefinition represents a tabular projection of a FHIR resource, where the columns and inclusion 
criteria are defined by FHIRPath expressions. 
"""
* name obeys sql-name
* resource 1..1 code "FHIR resource for the ViewDefinition" """
  The FHIR resource that the view is based upon, e.g. 'Patient' or 'Observation'.
"""
* resource from http://hl7.org/fhir/ValueSet/resource-types
* profile 0..* Canonical(StructureDefinition) "FHIR profiles that this view definition was intended to be executed against" """
  Indicates that this definition was intended to create a view over a set of resources conforming to the specified FHIR profiles. Each of these profiles SHALL be based upon the resource type specified in `resource`.
"""
* fhirVersion 0..* code "FHIR version(s) of the resource for the ViewDefinition" """
  The FHIR version(s) for the FHIR resource. The value of this element is the
  formal version of the specification, without the revision number, e.g.
  [publication].[major].[minor].
"""
* fhirVersion from http://hl7.org/fhir/ValueSet/FHIR-version
* constant 0..* BackboneElement "Constant that can be used in FHIRPath expressions" """
  A constant is a value that is injected into a FHIRPath expression through the use of a FHIRPath
  external constant with the same name.
"""
  * name 1..1 string "Name of constant (referred to in FHIRPath as %[name])"
  * name obeys sql-name
  * value[x] 1..1 base64Binary or boolean or canonical or code or date or dateTime or decimal or id or instant or integer or integer64 or oid or string or positiveInt or time or unsignedInt or uri or url or uuid   "Value of constant" """
    The value that will be substituted in place of the constant reference. This
    is done by including `%your_constant_name` in a FHIRPath expression, which effectively converts
    the FHIR literal defined here to a FHIRPath literal used in the path expression.

    Support for additional types may be added in the future.
  """
* select 1..* BackboneElement "A collection of columns and nested selects to include in the view." """
  The select structure defines the columns to be used in the resulting view. These are expressed
  in the `column` structure below, or in nested `select`s for nested resources.
"""
  * column 0..* BackboneElement "A column to be produced in the resulting table." """
    A column to be produced in the resulting table. The column is relative to the select structure
    that contains it.
    """
    * path 1..1 string "FHIRPath expression that creates a column and defines its content" """
      A FHIRPath expression that evaluates to the value that will be output in the column for each 
      resource. The input context is the collection of resources of the type specified in the resource 
      element. Constants defined in Reference({constant}) can be referenced as %[name].
    """
    * name 1..1 string "Column name produced in the output" """
      Name of the column produced in the output, must be in a database-friendly format. The column 
      names in the output must not have any duplicates.
    """
    * name obeys sql-name
    * description 0..1 markdown "Description of the column" """
      A human-readable description of the column.
    """
    * collection 0..1 boolean "Indicates whether the column may have multiple values." """
    Indicates whether the column may have multiple values. Defaults to `false` if unset.
  
    ViewDefinitions must have this set to `true` if multiple values may be returned. Implementations SHALL
    report an error if multiple values are produced when that is not the case.
    """
    * type 0..1 uri "A FHIR StructureDefinition URI for the column's type." """
    A FHIR StructureDefinition URI for the column's type. Relative URIs are implicitly given
    the 'http://hl7.org/fhir/StructureDefinition/' prefix. The URI may also use FHIR element ID notation to indicate
    a backbone element within a structure. For instance, `Observation.referenceRange` may be specified to indicate
    the returned type is that backbone element.

    This field *must* be provided if a ViewDefinition returns a non-primitive type. Implementations should report an error
    if the returned type does not match the type set here, or if a non-primitive type is returned but this field is unset.
    """
    * tag 0..* BackboneElement "Additional metadata describing the column" """
      Tags can be used to attach additional metadata to columns, such as implementation-specific 
      directives or database-specific type hints.
    """
      * name 1..1 string "Name of tag" """
        A name that identifies the meaning of the tag. A namespace should be used to scope the tag to 
        a particular context. For example, 'ansi/type' could be used to indicate the type that should 
        be used to represent the value within an ANSI SQL database.
      """
      * value 1..1 string "Value of tag"
  * select 0..* contentReference http://hl7.org/fhir/uv/sql-on-fhir/StructureDefinition/ViewDefinition#ViewDefinition.select  "Nested select relative to a parent expression." """
  Nested select relative to a parent expression. If the parent `select` has a `forEach` or `forEachOrNull`, this child select will apply for each item in that expression. 
  """
  * forEach 0..1 string "A FHIRPath expression to retrieve the parent element(s) used in the containing select. The default is effectively `$this`." """
    A FHIRPath expression to retrieve the parent element(s) used in the containing select, relative to the root resource or parent `select`,
    if applicable. `forEach` will produce a row for each element selected in the expression. For example, using forEach on `address` in Patient will
    generate a new row for each address, with columns defined in the corresponding `column` structure.
  """
  * forEachOrNull 0..1 string "Same as forEach, but will produce a row with null values if the collection is empty." """
    Same as forEach, but produces a single row with null values in the nested expression if the collection is empty. For example,
    with a Patient resource, a `forEachOrNull` on address will produce a row for each patient even if there are no addresses; it will
    simply set the address columns to `null`.
  """
  * repeat 0..* string "FHIRPath expressions to recursively select from." """
    A list of FHIRPath expressions that define paths to recursively traverse. The view runner will recursively
    follow each path to any depth, collecting results from all levels. All results are combined using a union
    operation.
  """
  * unionAll 0..* contentReference http://hl7.org/fhir/uv/sql-on-fhir/StructureDefinition/ViewDefinition#ViewDefinition.select  "Creates a union of all rows in the given selection structures." """
    A `unionAll` combines the results of multiple selection structures. Each structure under the `unionAll` must produce the same column names
    and types. The results from each nested selection will then have their own row.
    """
* select obeys sql-expressions
* where 0..* BackboneElement "A series of zero or more FHIRPath constraints to filter resources for the view." """
  A series of zero or more FHIRPath constraints to filter resources for the view. Every constraint
  must evaluate to true for the resource to be included in the view.
  """
  * path 1..1 string "A FHIRPath expression defining a filter condition" """
    A FHIRPath expression that defines a filter that must evaluate to true for a resource to be
    included in the output. The input context is the collection of resources of the type specified in
    the resource element. Constants defined in Reference({constant}) can be referenced as %[name].
    """
  * description 0..1 string "A human-readable description of the above where constraint."
