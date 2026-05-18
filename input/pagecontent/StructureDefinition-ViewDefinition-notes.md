## FHIRPath Functionality

Columns within a view are defined using the [FHIRPath](https://hl7.org/fhirpath/) language. FHIRPath contains a large number of functions and syntax constructs - not all of these are required to be implemented within a SQL on FHIR view runner.

View runner implementations MUST support the following required additional FHIRPath functions. In
addition to this, runners SHOULD implement the FHIRPath subset defined in the
[Shareable View Definition](StructureDefinition-ShareableViewDefinition.html) profile if the intent is for the runner to be able to
execute shared view definitions.

### Required Additional Functions

All View Runners must implement these functions that extend the FHIRPath
specification. Despite not being in the [FHIRPath](https://hl7.org/fhirpath/)
specification, they are necessary in the context of defining views:

- [getResourceKey](#getresourcekey--keytype) function
- [getReferenceKey](#getreferencekeyresource-type-specifier--keytype) function

#### getResourceKey() : _KeyType_

This is invoked at the root of a FHIR Resource and returns an opaque value to be
used as the primary key for the row associated with the resource. In many cases
the value may just be the resource `id`, but exceptions are described below.

This function is used in tandem
with [getReferenceKey](#getreferencekeyresource-type-specifier--keytype),
which returns
an equal value from references that point to this resource.

The returned _KeyType_ is implementation dependent, but must be a FHIR primitive
type that can be used for efficient joins in the system's underlying data
storage. Integers, strings, UUIDs, and other primitive types may be appropriate.

See
the [Joins with Resource and Reference Keys](#joins-with-resource-and-reference-keys)
section below for details.

#### getReferenceKey([resource: type specifier]) : _KeyType_

This is invoked on [Reference](https://hl7.org/fhir/references.html#Reference)
elements and returns an opaque value that represents the database key of the row
being referenced. The value returned must be equal to
the [getResourceKey](#getresourcekey--keytype) value returned on the resource
itself.

Users may pass an optional resource type (e.g., Patient or Observation) to
indicate the expected type that the reference should point to. The
getReferenceKey function will return an empty collection (effectively _null_
since FHIRPath always returns collections) if the reference is not of the
expected type. For example, `Observation.subject.getReferenceKey(Patient)` would
return a row key if the subject is a Patient, or the empty collection (
i.e., `{}`) if it is not.

The returned _KeyType_ is implementation dependent, but must be a FHIR primitive
type that can be used for efficient joins in the systems underlying data
storage. Integers, strings, UUIDs, and other primitive types may be appropriate.

The getReferenceKey function has both required and optional functionality:

- Implementations MUST support the relative literal form of reference (
  e.g., `Patient/123`), and MAY support other types of references. If the
  implementation does not support the reference type, or is unable to resolve
  the reference, it MUST return the empty collection (i.e., `{}`).
- Implementations MAY generate a list of unprocessable references through query
  responses, logging or reporting. The details of how this information would be
  provided to the user is implementation specific.

See the [Joins with Resource and Reference Keys](#joins-with-resource-and-reference-keys) section below for details.

## Specifying a Select

A [select](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select)
specifies the content and names for the columns in the view. The content for
each column is defined with a [FHIRPath](https://hl7.org/fhirpath/) expression
that returns a specific data element from the FHIR resources. More complex views
can be specified to create resource or reference keys, unnest a collection of
items returned by a FHIRPath expression, nest or concatenate the results from
multiple selects, and so on.

## Unnesting Semantics

It is often desirable to unroll the collection returned from
a [FHIRPath](https://hl7.org/fhirpath/) expression into a separate row for each
item in the collection. This is done
with [forEach](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.forEach)
or [forEachOrNull](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.forEachOrNull).

For instance, each Patient resource can have multiple addresses, which users can
expand into a separate `patient_addresses` table with one row per address. Each
row would still have a `patient_id` field to know which patient that address row
is associated with. You can see this in
the [PatientAddresses example](Binary-PatientAddresses.html), which unrolls
addresses as described above.

[forEach](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.forEach)
and [forEachOrNull](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.forEachOrNull)
apply both to the columns within a `select` and any nested `select`s it
contains. Therefore, the following `select`s will produce the same results:

```js
"select": [{
  "forEach": "address",
  "column": [{"name": "zip", "path": "postalCode"}]
}]
```

```js
"select": [{
  "forEach": "address",
  "select": [{"column": [{"name": "zip", "path": "postalCode"}]}]
}]
```

While a [forEach](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.forEach)
is similar to an `INNER JOIN` supported by many SQL engines,
a [forEachOrNull](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.forEachOrNull)
is analogous to
a `LEFT OUTER JOIN`. [forEach](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.forEach)
will produce a row only if the [FHIRPath](https://hl7.org/fhirpath/) expression
returns one or more items in the collection. On the other
hand, [forEachOrNull](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.forEachOrNull)
will produce a row even if the [FHIRPath](https://hl7.org/fhirpath/) expression
returns an empty collection.
With [forEachOrNull](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.forEachOrNull),
all columns will be included but, if nothing is returned by
the [forEachOrNull](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.forEachOrNull)
expression, the row produced will have null values.

To illustrate this, the following expression in a Patient view
uses [forEach](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.forEach),
and will therefore return a row for each Patient resource only if the Patient
resource has at least one `Patient.address`, similar to an `INNER JOIN` in SQL:

```js
"select": [
  {
    "column": [{"name": "id", "path": "getResourceKey()"}]
  },
  {
    "forEach": "address",
    "select": [{"column": [{"name": "zip", "path": "postalCode"}]}]
  }
]
```

In contrast, this view
with [forEachOrNull](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.forEachOrNull)
will produce the `id` column for _every_ Patient resource. If the Patient
resource has no `Patient.address`, there will be a single row for the Patient
resource and the `zip` column will contain null. For Patient resources with one
or more `Patient.address`, the result will be identical to the expression above.

```js
"select": [
  {
    "column": [{"name": "id", "path": "getResourceKey()"}]
  },
  {
    "forEachOrNull": "address",
    "select": [{"column": [{"name": "zip", "path": "postalCode"}]}]
  }
]
```

## Multiple Select Expressions

A ViewDefinition may have multiple `select`s, which can be organized as siblings
or in parent/child relationships. This is typically done as different `select`s
may use different `forEach` or `forEachOrNull`expressions to unroll different
parts of the resources.

The multiple rows produced using `forEach` or `forEachOrNull` from a `select`are
joined to others with the following rules:

- Parent/child `select`s will repeat values from the parent `select` for each
  item in the child `select`.
- Sibling `select`s are effectively cross joined, where each row in
  each `select` is duplicated for every row in sibling `select`s.

The [examples](StructureDefinition-ViewDefinition-examples.html) illustrate this
behavior.

## Recursive Traversal with Repeat

The `repeat` directive enables recursive traversal of nested structures, automatically
flattening hierarchical data to any depth. This is particularly useful for resources
with recursive nesting patterns like QuestionnaireResponse items, where the depth of
nesting is not known in advance.

The `repeat` directive takes an array of [FHIRPath](https://hl7.org/fhirpath/)
expressions that define paths to recursively traverse. The view runner will:

1. Start at the current context node
2. Evaluate each path expression
3. For each result, recursively apply the same path patterns
4. Continue until no more matches are found at any depth
5. Union all results from all levels and all paths together

### Example: Flattening QuestionnaireResponse Items

Consider a QuestionnaireResponse with nested groups and questions:

```json
{
    "resourceType": "QuestionnaireResponse",
    "item": [
        {
            "linkId": "1",
            "text": "Demographics",
            "item": [
                {
                    "linkId": "1.1",
                    "text": "Age",
                    "answer": [
                        {
                            "valueInteger": 45
                        }
                    ]
                }
            ]
        },
        {
            "linkId": "2",
            "text": "Medical History",
            "answer": [
                {
                    "item": [
                        {
                            "linkId": "2.1",
                            "text": "Conditions",
                            "answer": [
                                {
                                    "item": [
                                        {
                                            "linkId": "2.1.1",
                                            "text": "Diabetes Type",
                                            "answer": [
                                                {
                                                    "valueString": "Type 2"
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
            ]
        }
    ]
}
```

Using the repeat directive:

```json
{
    "resource": "QuestionnaireResponse",
    "select": [
        {
            "repeat": ["item", "answer.item"],
            "column": [
                {
                    "path": "linkId",
                    "name": "item_id"
                },
                {
                    "path": "text",
                    "name": "question_text"
                }
            ]
        }
    ]
}
```

This would produce a flat table with all items regardless of nesting depth:

| item_id | question_text   |
| ------- | --------------- |
| 1       | Demographics    |
| 1.1     | Age             |
| 2       | Medical History |
| 2.1     | Conditions      |
| 2.1.1   | Diabetes Type   |

{:.table-data}

## Unions

A `select` can have an optional `unionAll`, which contains a list of `select`s
that are used to create a union. `unionAll` effectively concatenates the results
of the nested `select`s that it contains, but without a guarantee that row
ordering will be preserved. Each `select` contained in the `unionAll` must
produce the same columns including their specified names and FHIR types.

```js
"select": {
  "unionAll": [
    {
      "forEach": "address",
      "column": [
        {"path": "postalCode", "name": "zip"},
        {"path": "true", "name": "is_patient"}
      ]
    },
    {
      "forEach": "contact.address",
      "column": [
        {"path": "postalCode", "name": "zip"},
        {"path": "false", "name": "is_patient"}
      ]
    }
  ]
}
```

The above example uses `forEach` to select different data elements from the
resources to be included in the union. For other use cases, it is possible to
define the columns directly in the `select`. See
the [PatientAndContactAddressUnion example](Binary-PatientAndContactAddressUnion.html)
for a complete version of the above.

The columns produced from the `unionAll` list are effectively added to the
parent `select`, following any other columns from its parent for column
ordering. See the [column ordering](#column-ordering) section below for details.

The `select`s in a `unionAll` MUST have matching columns. Specifically, each
nested selection structure MUST produce the same number of columns with the same
names and order, and the values for the columns MUST be of the same types as
determined by the [column types](#column-types) part of this specification.

`unionAll` behaves similarly to the `UNION ALL` in SQL and will not filter out
duplicate rows. Note that each `select` can contain only one `unionAll` list
since these items must be combined in a single, logical `UNION ALL`.
Nested `select`s can be used when multiple `unionAll`s are needed within a
single view.

## Composing Multiple Selects and Unions

`unionAll` produces rows that can be used just like a `select` expression. These
rows can be used by containing `select`s or `unionAll`s without needing any
special knowledge of how they were produced. This means that `unionAll`
and `select` operations can be nested with intuitive behavior, similar to how
functions can be nested in many programming languages.

For instance, the two expressions below will return the same rows despite the
first being a single `unionAll` and the second being composed of a
nested `select` that contains additional `unionAll`s.

```js
"select": {
  "unionAll": [
    {
      "forEach": "a",
      "column": [] // snip
    },
    {
      "forEach": "b",
      "column": [] // snip
    },
    {
      "forEach": "c",
      "column": [] // snip
    }
  ]
}
```

And, the equivalent with a nested structure:

```js
"select": {
  "unionAll": [
    {
      "forEach": "a",
      "column": [] // snip
    },
    {
      "select": {
        "unionAll": [
          {
            "forEach": "b",
            "column": [] // snip
          },
          {
            "forEach": "c",
            "column": [] // snip
          }
        ]
      }
    }
  ]
}
```

Note the former example is preferred due to its simplicity and the latter is
included purely for illustrative purposes.

## Column Ordering

View Runners that support column ordering in their output format MUST order
the columns of the result according to the rules defined in this section.

`select`s that have nested `select`s will place the columns of the
parent `select` before the columns of the nested `select`, and the columns from
a `unionAll` list are placed last.

To change the column ordering, it is possible to place the columns or
the `unionAll` in a nested `select`, which can be ordered relative to other
nested `select`s as desired.

For example, the `column`s in this ViewDefinition will appear in alphabetical
order:

```json
{
    "name": "column_order_example",
    "resource": "...",
    "select": [
        {
            "column": [
                {
                    "path": "'A'",
                    "name": "a"
                },
                {
                    "path": "'B'",
                    "name": "b"
                }
            ],
            "select": [
                {
                    "forEach": "aNestedStructure",
                    "column": [
                        {
                            "path": "'C'",
                            "name": "c"
                        },
                        {
                            "path": "'D'",
                            "name": "d"
                        }
                    ]
                }
            ],
            "unionAll": [
                {
                    "column": [
                        {
                            "path": "'E1'",
                            "name": "e"
                        },
                        {
                            "path": "'F1'",
                            "name": "f"
                        }
                    ]
                },
                {
                    "column": [
                        {
                            "path": "'E2'",
                            "name": "e"
                        },
                        {
                            "path": "'F2'",
                            "name": "f"
                        }
                    ]
                }
            ]
        },
        {
            "column": [
                {
                    "path": "'G'",
                    "name": "g"
                },
                {
                    "path": "'H'",
                    "name": "h"
                }
            ]
        }
    ]
}
```

## Column Types

All values in a given column must be of a single data type. The data type can be
explicitly specified with
the [collection](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.column.collection)
and [type](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.column.type)
for a column. In most cases, the data type for a column can be determined by
the `path` expression, allowing users to interactively build and evaluate a
ViewDefinition without needing to look up and explicitly specify the data type.

If the column is a primitive type (typical of tabular output), its type is
inferred under the following conditions:

1. If
   the [collection](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.column.collection)
   is not set to `true`, the returned data type must be a single value.
2. If the `path` is a series of `parent.child.subPath` navigation steps from a
   known data type, either from the root resource or a child of an `ofType`
   function, then the data type for each column is determined by the structure
   definition it comes from.
3. If the terminal expression is a FHIRPath function with a defined return type,
   then the column will be of that data type. For instance, if the `path` ends
   in `exists()` or `lowBoundary()`, the data type for the column would be
   boolean or an instant type, respectively.
4. A path that ends in `ofType()` will be of the type given to that function.

Note that type inference is an optional feature and some implementations may not
support it. Therefore, a ViewDefinition that is intended to be shared between
different implementations should have
the [type](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.column.type)
for each column set explicitly, even for primitives. It is reasonable for an
implementation to treat any non-specified types as strings. Moreover,
non-primitive data types will not be supported by all implementations.
Therefore, it is important to always explicitly set
the [type](StructureDefinition-ViewDefinition-definitions.html#diff_ViewDefinition.select.column.type)
so each column can have its data type easily determined.

Importantly, the above determines the FHIR type produced for the column. How
that type is physically manifested depends on the implementation.
Implementations may map these to native database types or have each column
simply produce a string, as would be done in a CSV-based implementation. See
the [database type hints](#type-hinting-with-tags) section below if finer
database-specific type control is needed.

## Using Constants

A ViewDefinition may include one or more constants, which are simply values that
can be reused in [FHIRPath](https://hl7.org/fhirpath/) expressions. This can
improve readability and reduce redundancy. Constants can be used in `path`
expressions by simply using `%[name]`. Effectively, these placeholders are
replaced by the value of the constant before
the [FHIRPath](https://hl7.org/fhirpath/) expression is evaluated.

This is an example of a constant used in the `where` constraint of a view:

```js
{
  // <snip>
  "constant": [{
    "name": "bp_code",
    "valueCode": "8480-6"
  }],
  // <snip>
  "where": [{
    "path": "code.coding.exists(system='http://loinc.org' and code=%bp_code)"
  }],
}
```

## Environment Variables

In addition to user-defined constants, SQL on FHIR provides built-in environment
variables that can be referenced in [FHIRPath](https://hl7.org/fhirpath/)
expressions using the `%name` syntax.

### %rowIndex

The `%rowIndex` environment variable returns the 0-based index of the current
element within the collection being iterated. This is useful for:

- **Preserving ordering semantics**: SQL result sets are unordered by default;
  including the original index allows users to restore FHIR ordering.
- **Disambiguation**: When a resource has multiple repeating elements (e.g.,
  multiple names), knowing which is the first, second, etc. can be
  semantically important.
- **Surrogate keys**: Combining the resource ID with the element index creates
  a unique identifier for each row.

#### Behaviour

- Within `forEach`, `forEachOrNull`, and `repeat` contexts, `%rowIndex`
  returns the position of the current element in the collection (starting
  from 0).
- At the top level (no iteration context), `%rowIndex` evaluates to `0`.
- Each nesting level has its own independent `%rowIndex` value. For nested
  iterations, users can capture the parent-level index in a column before
  entering the child iteration.
- `unionAll` does not create a new `%rowIndex` scope. Within a `unionAll`,
  each branch inherits `%rowIndex` from the enclosing context unless the
  branch contains its own iteration expression (`forEach`, `forEachOrNull`,
  or `repeat`).
- Each branch of a `unionAll` that contains an iteration expression
  establishes its own independent `%rowIndex` sequence, starting from 0.
- The type of `%rowIndex` is `integer`.

#### Example: Capturing element position

```json
{
    "resource": "Patient",
    "select": [
        {
            "column": [{ "name": "id", "path": "id", "type": "id" }]
        },
        {
            "forEach": "name",
            "column": [
                {
                    "name": "name_index",
                    "path": "%rowIndex",
                    "type": "integer"
                },
                { "name": "family", "path": "family", "type": "string" }
            ]
        }
    ]
}
```

For a Patient with two names, this would produce:

| id  | name_index | family |
| --- | ---------- | ------ |
| pt1 | 0          | Smith  |
| pt1 | 1          | Jones  |

{:.table-data}

#### Example: Nested iteration with independent indices

```json
{
    "resource": "Patient",
    "select": [
        {
            "column": [{ "name": "id", "path": "id", "type": "id" }]
        },
        {
            "forEach": "contact",
            "column": [
                {
                    "name": "contact_index",
                    "path": "%rowIndex",
                    "type": "integer"
                }
            ],
            "select": [
                {
                    "forEach": "telecom",
                    "column": [
                        {
                            "name": "telecom_index",
                            "path": "%rowIndex",
                            "type": "integer"
                        },
                        { "name": "system", "path": "system", "type": "code" }
                    ]
                }
            ]
        }
    ]
}
```

For a Patient with two contacts, where the first contact has two telecom entries
(phone and email) and the second contact has one telecom entry (phone), this
would produce:

| id  | contact_index | telecom_index | system |
| --- | ------------- | ------------- | ------ |
| pt1 | 0             | 0             | phone  |
| pt1 | 0             | 1             | email  |
| pt1 | 1             | 0             | phone  |

{:.table-data}

In this example, `contact_index` captures the position in the outer `contact`
collection, while `telecom_index` captures the position in the inner `telecom`
collection. Each iteration level maintains its own independent index.

#### Example: Row index with unionAll

When `unionAll` appears inside an iteration, branches with their own `forEach`
get an independent `%rowIndex` sequence, while branches without iteration
inherit `%rowIndex` from the enclosing context.

```json
{
    "resource": "Patient",
    "select": [
        {
            "column": [{ "name": "id", "path": "id", "type": "id" }]
        },
        {
            "forEach": "name",
            "column": [
                { "name": "name_index", "path": "%rowIndex", "type": "integer" }
            ],
            "select": [
                {
                    "unionAll": [
                        {
                            "forEach": "given",
                            "column": [
                                {
                                    "name": "given_index",
                                    "path": "%rowIndex",
                                    "type": "integer"
                                },
                                {
                                    "name": "value",
                                    "path": "$this",
                                    "type": "string"
                                }
                            ]
                        },
                        {
                            "column": [
                                {
                                    "name": "given_index",
                                    "path": "%rowIndex",
                                    "type": "integer"
                                },
                                {
                                    "name": "value",
                                    "path": "family",
                                    "type": "string"
                                }
                            ]
                        }
                    ]
                }
            ]
        }
    ]
}
```

For a Patient with two names &mdash; Smith (given: John, James) and Jones
(given: Jane) &mdash; this produces:

| id  | name_index | given_index | value |
| --- | ---------- | ----------- | ----- |
| pt1 | 0          | 0           | John  |
| pt1 | 0          | 1           | James |
| pt1 | 0          | 0           | Smith |
| pt1 | 1          | 0           | Jane  |
| pt1 | 1          | 1           | Jones |

{:.table-data}

In the first branch, `forEach: "given"` creates its own `%rowIndex` sequence
(0, 1 for John and James under Smith; 0 for Jane under Jones). In the second
branch, there is no iteration expression, so `%rowIndex` inherits from the
enclosing `forEach: "name"` context (0 for Smith, 1 for Jones).

## Joins with Resource and Reference Keys

While ViewDefinitions do not directly implement joins across resources, the
views produced should be easily joined by the database or analytic tools of the
user's choice. This can be done by including primary and foreign keys as part of
the tabular
view output, which can be done with
the [getResourceKey](#getresourcekey--keytype) and
[getReferenceKey](#getreferencekeyresource-type-specifier--keytype) functions.

Users may call [getResourceKey](#getresourcekey--keytype) to obtain a
resources primary key,
and call [getReferenceKey](#getreferencekeyresource-type-specifier--keytype)to
get
the corresponding foreign key from a reference pointing at that resource/row.

For example, a minimal view of Patient resources could look like this:

```js
{
  "name": "active_patients",
  "resource": "Patient",
  "select": [{
    "column": [
      {
        "path": "getResourceKey()",
        "name": "id"
      },
      {
        "path": "active"
      }
    ]
  }]
}
```

A view of Observation resources would then have its own row key and a foreign
key to easily join to the view of Patient resources, like this:

```js
{
  "name": "simple_obs",
  "resource": "Observation",
  "select": [{
    "column": [
      {
        "path": "getResourceKey()",
        "name": "id"
      },
      {
        // The `Patient` parameter is optional, but ensures the returned value
        // will either be a patient row key or null.
        "path": "subject.getReferenceKey(Patient)",
        "name": "patient_id"
      }
    ]
  }]
}
```

Users of the views could then join `simple_obs.patient_id`
to `active_patients.id` using common join semantics.

### Suggested Implementations for getResourceKey() and getReferenceKey()

While [getResourceKey](#getresourcekey--keytype)
and [getReferenceKey](#getreferencekeyresource-type-specifier--keytype) must
return matching values for the same row, _how_ they do so is left to the
implementation. This is by design, allowing ViewDefinitions to be run across a
wide set of systems that have different data invariants or pre-processing
capabilities.

Here are some implementation options to meet different needs:

<table class='table-data'>
    <thead>
        <tr>
            <th>Approach</th>
            <th>Details</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>Return the Resource ID</td>
            <td>If the system can guarantee that each resource has a simple <code>id</code> and the corresponding references have simple, relative <code>id</code>s that point to it (e.g., <em>Patient/123</em>), <a href="#getresourcekey--keytype">getResourceKey</a> and <a href="#getreferencekeyresource-type-specifier--keytype">getReferenceKey</a> implementations may simply return those values. This is the simplest case and will apply to many (but not all) systems.</td>
        </tr>
        <tr>
            <td>Return a "Primary" Identifier</td>
            <td>Since the resource <code>id</code> is by definition a system-specific identifier, it may change as FHIR data is exported and loaded between systems, and therefore not be a reliable target for references. For instance, a bulk export from one source system could be loaded into a target system that applies its own <code>id</code>s to the resources, requiring that joins be done on the resource's <code>identifier</code> rather than its <code>id</code>.<br><br>In this case, implementations will need to determine row keys based on the resource <code>identifier</code> and corresponding <code>identifier</code>s in the references.<br><br>The simplest variation of this is when there is only one <code>identifier</code> for each resource. In other cases, the implementation may be able to select a "primary" <code>identifier</code>, based on the <code>identifier.system</code> namespace, <code>identifier.use</code> code, or other property. For instance, if the primary <code>Identifier.system</code> is <em>example_primary_system</em>, implementations can select the desired <code>identifier</code> to use as a row key by checking for that.<br><br>In either case, the resource <code>identifier</code> and corresponding reference <code>identifier</code> can then be converted to a row key, perhaps by building a string or computing a cryptographic hash of the <code>identifier</code>s themselves. The best approach is left to the implementation.</td>
        </tr>
        <tr>
            <td>Pre-Process to Create or Resolve Keys</td>
            <td>The most difficult case is systems where the resource <code>id</code> is a not a reliable row key, and resources have multiple <code>identifier</code>s with no clear way to select one for the key.<br><br>In this case, implementations will likely have to fall back to some form of preprocessing to determine appropriate keys. This may be accomplished by:<br><br><ul><li>Pre-processing all data to have clear resource <code>id</code>s or "primary" <code>identifier</code>s and using one of the options above.</li><li>Building some form of cross-link table dynamically within the implementation itself based on the underlying data. For instance, if an implementation's <a href="#getresourcekey--keytype">getResourceKey</a> uses a specific identifier system, <a href="#getreferencekeyresource-type-specifier--keytype">getReferenceKey</a> could use a pre-built cross-link table to find the appropriate identifier-based key to return.</li></ul></td>
        </tr>
    </tbody>
</table>

There are many variations and alternatives to the above. This specification
simply asserts that implementations must be able to produce a row key for each
resource and a matching key for references pointing at that resource, and
intentionally leaves the specific mechanism to the implementation.

## Contained Resources

This specification requires implementers to extract contained resources that
need to be included in views into independent resources that can then be
accessed via [getReferenceKey](#getreferencekeyresource-type-specifier--keytype)
like any
other resource. Implementations SHOULD normalize these resources appropriately
whenever possible, such as eliminating duplicate resources contained in many
parent resources. Note that this may change in a later version of this
specification, allowing users to explicitly create separate views for contained
resources that could be distinct from top-level resource views.

Contained resources have different semantics than other resources since they
don't have an independent identity, and the same logical record may be
duplicated across many containing resources. This makes SQL best practices
difficult since the data is denormalized and ambiguous. For
instance, `Patient.generalPractitioner` may be a contained resource that may or
may not be the same practitioner seen in other Patient resources. Therefore, the
approach in this specification requires systems to pre-process the data into
normalized, independent resources if needed.

For the same reason, the output from running a ViewDefinition will not include
contained resources. For instance, a view of Practitioner resources will include
top-level Practitioner resources but not contained Practitioner resources from
inside the Patient resources.

## Generating Schemas

The output format produced by a View Runner will be technology-specific, such as
a SQL database query or a structured file like Parquet. View Runner
implementations SHOULD offer a way to compute the output schema from a
ViewDefinition when applicable.

For example, a runner that produces a table in a database system could return
a "CREATE TABLE" or "CREATE VIEW" statement based on the ViewDefinition,
allowing the system to define tables prior to populating them by evaluating the
views over data.

This would not apply to outputs that do not have a way of specifying their
schema, like CSV files.

## Type Hinting with Tags

Since these analytic views are often used as SQL tables, it can be useful to
provide database type information to ensure the desired tables or views are
created. This is done by tagging fields with database-specific type information.

### Default Type Mappings

To maximize consistency across different view runners, implementations SHOULD
align their output types to the following default type mappings from FHIR and
FHIRPath types to [ISO/IEC 9075](https://www.iso.org/standard/76583.html) SQL
types. If implementations do not natively support SQL types, they SHOULD map
each of these types to the closest equivalent in their output format.

#### FHIR Type to SQL Type Mapping

| FHIR type    | ISO/IEC 9075 SQL type    |
| ------------ | ------------------------ |
| base64Binary | BINARY                   |
| boolean      | BOOLEAN                  |
| canonical    | CHARACTER VARYING        |
| code         | CHARACTER VARYING        |
| date         | CHARACTER VARYING        |
| dateTime     | CHARACTER VARYING        |
| decimal      | CHARACTER VARYING        |
| id           | CHARACTER VARYING        |
| instant      | TIMESTAMP WITH TIME ZONE |
| integer      | INT                      |
| integer64    | BIGINT                   |
| markdown     | CHARACTER VARYING        |
| oid          | CHARACTER VARYING        |
| positiveInt  | INT                      |
| string       | CHARACTER VARYING        |
| time         | CHARACTER VARYING        |
| unsignedInt  | INT                      |
| uri          | CHARACTER VARYING        |
| url          | CHARACTER VARYING        |
| uuid         | CHARACTER VARYING        |

{:.table-data}

#### FHIRPath Type to SQL Type Mapping

| FHIRPath type | ISO/IEC 9075 SQL type |
| ------------- | --------------------- |
| Boolean       | BOOLEAN               |
| String        | CHARACTER VARYING     |
| Integer       | INT                   |
| Decimal       | CHARACTER VARYING     |
| Date          | CHARACTER VARYING     |
| Time          | CHARACTER VARYING     |
| DateTime      | CHARACTER VARYING     |

{:.table-data}

Where the representation is `CHARACTER VARYING`, the format MUST comply with
the string representation of that type within the
[FHIR spec](https://www.hl7.org/fhir/R4/datatypes.html#primitive).

Where a path has both a FHIR type and a FHIRPath type, the FHIR type mapping
will take precedence.

### Overriding Default Type Mappings

The default type hints can be overridden for individual columns within view
definitions using tags. The tag name is `ansi/type`, and the value is the
desired ISO/IEC 9075 SQL type.

For instance, we tag a birth date column using the `DATE` type. This signals to
the view runner that we would like this column represented using the native
date type. This particular view relies on the birth dates being full dates,
which is not guaranteed but is common and can simplify analysis in some systems.

```json
{
    "resourceType": "ViewDefinition",
    "name": "patient_birth_date",
    "resource": "Patient",
    "description": "A view of simple patient birth dates",
    "select": [
        {
            "column": [
                {
                    "path": "id"
                },
                {
                    "name": "birth_date",
                    "path": "birthDate",
                    "tags": [
                        {
                            "name": "ansi/type",
                            "value": "DATE"
                        }
                    ]
                }
            ]
        }
    ]
}
```

Behavior is undefined and left to the runner if the type hint tag contains a
value that is unknown or incompatible with the underlying database type.

Another use case may be for users to select database-specific numeric types.
Implementations can define a tag name and use it to enable users to specify
the desired implementation-specific type for a column.

## Processing Algorithm

The following description provides an algorithm for how to process a FHIR
resource as input for a ViewDefinition. Implementations do not need to follow
this algorithm directly, but their outputs should be consistent with what this
model produces.

### Validate Columns (entry point)

**Purpose**: This step ensures that a ViewDefinition's columns are valid, by setting up a recursive call.

**Inputs**

- `V`: a `ViewDefinition` to validate

1. Call `ValidateColumns(V, C)` according to the recursive step below.

### `ValidateColumns(S, C)` (recursive step)

**Purpose:** This step ensures that column names are unique across `S` and disjoint from `C`

**Inputs**

- `S`: a single Selection Structure
- `C`: a list of Columns that exist prior to this call

**Outputs**

- `Ret`: a list of Columns

**Errors**

- Column Already Defined
- Union Branches Inconsistent

0. Initialize `Ret` to equal `C`

1. For each Column `col` in `S.column[]`
    - If a Column with name `col.name` already exists in `Ret`, throw "Column Already Defined"
    - Otherwise, append `col` to `Ret`

2. For each Selection Structure `sel` in `S.select[]`
    - For each Column `c` in `Validate(sel, Ret)`
        - If a Column with name `c.name` already exists in `Ret`, throw "Column Already Defined"
        - Otherwise, append `c` to the end of `Ret`

3. If `S.unionAll[]` is present
    1. Define `u0` as `Validate(S.unionAll[0], Ret)`
    2. For each Selection Structure `sel` in `S.unionAll[]`
        - Define `u` as `ValidateColumns(sel, Ret)`
            - If the list of names from `u0` is different from the list of names from `u`, throw "Union Branches Inconsistent"
            - Otherwise, continue
    3. For each Column `col` in `u0`
        - Append `col` to `Ret`

4. Return `Ret`

### Process a Resource (entry point)

**Purpose:** This step emits all rows produced by a ViewDefinition on an input
Resource, by setting up a recursive call.

**Inputs**

- `V`: a `ViewDefinition`
- `R`: a FHIR Resource to process with `V`

**Emits:** one output row at a time

1. Ensure resource type is correct
    - If `R.resourceType` is different from `V.resource`, return immediately
      without emitting any rows
    - Otherwise, continue
2. If `V.where` is defined, ensure constraints are met
    - Evaluate `fhirpath(V.where.path, R)` to determine whether `R` is a
      candidate for `V`
        - If `R` is not a candidate for `V`, return immediately without emitting
          any rows
        - Otherwise, continue
3. Initialise `%rowIndex` to `0` (the top-level row index)
4. Emit all rows from `Process(S, V)` with `%rowIndex` available in the
   evaluation context

### `Process(S, N)` (recursive step)

**Purpose:** This step emits all rows for a given Selection Structure and Node.
We first generate sets of "partial rows" (i.e., sets of incomplete column
bindings from the various clauses of `V`) and combine them to emit complete
rows. For example, if there are two sets of partial rows:

- `[{"a": 1},{"a": 2}]` with bindings for the variable `a`
- `[{"b": 3},{"b": 4}]` with bindings for the variable `b`

Then the Cartesian product of these sets consists of four complete rows:

```json
[
    { "a": 1, "b": 3 },
    { "a": 1, "b": 4 },
    { "a": 2, "b": 3 },
    { "a": 2, "b": 4 }
]
```

**Inputs**

- `S`: a Selection Structure
- `N`: a Node (element) from a FHIR resource

**Errors**

- Multiple values found but not expected for column

**Emits:** One output row at a time

1. Define a list of Nodes `foci` as
    - If `S.repeat` is defined:
        1. Initialize an empty list `result`
        2. Define a recursive function `traverse(node, isRoot)`:
            - If not `isRoot`, add `node` to `result`
            - For each path `p` in `S.repeat`:
                - Evaluate `fhirpath(p, node)` to get child nodes
                - For each child node `c` in the result:
                    - Recursively call `traverse(c, false)`
        3. Call `traverse(N, true)` to start the traversal
        4. Use `result` as `foci`
    - Else if `S.forEach` is defined: `fhirpath(S.forEach, N)`
    - Else if `S.forEachOrNull` is defined: `fhirpath(S.forEachOrNull, N)`
    - Otherwise: `[N]` (a list with just the input node)

2. For each element `f` of `foci` (with 0-based index `i`) 0. Set `%rowIndex` to `i` for this iteration level (each nesting level has
   its own independent `%rowIndex` value)
    1. Initialize an empty list `parts` (each element of `parts` will be a list
       of partial rows)
    2. Process Columns:
        - For each Column `col` of `S.column`, define `val`
          as `fhirpath(col.path, f)`
            1. Define `b` as a row whose column named `col.name` takes the value
                - If `val` was the empty set: `null`
                - Else if `val` has a single element `e`: `e`
                - Else if `col.collection` is true: `val`
                - Else: throw "Multiple values found but not expected for
                  column"
            2. Append `[b]` to `parts`
            - (Note: append a list so the final element of `parts` is now a list
              containing the single row `b`).

    3. Process Selects:
        - For each selection structure `sel` of `S.select`
            1. Define `rows` as the collection of all rows emitted
               by `Process(sel, f)`
            2. Append `rows` to `parts`
            - (Note: do not append the elements but the whole list, so the final
              element of `parts` is now the list `rows`)

    4. Process UnionAlls:
        1. Initialize `urows` as an empty list of rows
        2. For each selection structure `u` of `S.unionAll`
            - For each row `r` in `Process(u, f)`
                - Append `r` to `urows`
        3. Append `urows` to `parts`
        - (Note: do not append the elements but the whole list, so the final
          element of `parts` is now the list `urows`)

    5. For every list of partial rows `prows` in the Cartesian product
       of `parts`
        1. Initialize a blank row `r`
        2. For each partial row `p` in `prows`
            - Add `p`'s column bindings to the row `r`
        3. Emit the row `r`
            - (Note: the Cartesian product is always between a Selection
              Structure and its direct children, not deeper descendants. Because
              the process is recursive, rows generated by, for example,
              a `.select[0].select[0].select[0]` will eventually bubble up to
              the top level, but the bubbling happens one level at a time.)

3. If `foci` is an empty list and `S.forEachOrNull` is defined (Note: when this
   condition is met, no rows have been emitted so far)
    1. Set `%rowIndex` to `0` for this empty collection case
    2. Initialize a blank row `r`
    3. For each Column `c` in `ValidateColumns(V, [])`
        - Bind the column `c.name` to `null` in the row `r` (except for columns
          with path `%rowIndex`, which should be bound to `0`)
    4. Emit the row `r`

## Functional Model

ViewDefinitions can be modeled and implemented using the functional paradigm. In
fact, the [JavaScript reference implementation](https://github.com/FHIR/sql-on-fhir-v2/tree/master/sof-js)
takes such an approach. See [Functional Model](functional-model.html) for a
detailed examination of this approach.
