This document will help you understand how ViewDefinitions work "under the hood"
using a functional paradigm.

The application of a ViewDefinition is an algorithm that describes the
transformation of FHIR resources and is composed of combinations of a small set
of functions:

- `column({name:column_name,path: fhirpath},...)` - The main workhorse of
  transformation. This function will extract elements by FHIRPath expressions
  and put the result into columns
- `where(fhirpath)` - This function filters resources by FHIRPath expression.
  For example, you may want to transform only specific profiles like blood
  pressure into a simple table
- `forEach(expr, transform)` - This function unnests collection elements into
  separate rows
- `select(rows1, rows2)` - This function cross-joins `rows1` and `rows2`, and is
  mostly used to join results of `forEach` with top-level columns
- `union(rows, rows)` - This function concatenates sets of rows. It's main use
  case is combining rows from different branches of a resource (for example,
  `telecom` and `contact.telecom`)

A ViewDefinition is represented as a FHIR logical model (in this case as a JSON
document) where the keywords of the ViewDefinition correspond to the functions
described above.

### An Example ViewDefinition

```js
{
    "resourceType": "ViewDefinition",
    "resource": "Patient",
    // Step 1
    "where": [{"path": "active = true"}],
    // Step 6
    "select": [
        {
          // Step 5
          "column": [
             {"path": "getResourceKey()", "name": "id"},
             {"path": "identifier.where(system='ssn')", "name": "ssn"},
          ]
        },
        {
          // Step 4
          "unionAll": [
            {
              // Step 2
              "forEach": "telecom.where(system='phone')",
              "column": [{"path": "value", "name": "phone"}]
            },
            {
              // Step 3
              "forEach": "contact.telecom.where(system='phone')",
              "column": [{"path": "value",  "name": "phone"}]
            }
       ]}
    ]
}
```

### Applying the ViewDefinition

The application of this ViewDefinition produces a table of contacts with one row
per telecom from two different locations in a FHIR Patient resource.

Algorithmically the application can be though of in the following steps:

1.  "where": filter data to only the active patients
2.  "forEach": unnest `Patient.telecom` and select "phone"
3.  "forEach": unnest `Patient.contact.telecom` and select "phone"
4.  "unionAll": concatenate the results of 2 and 3
5.  "column": extracts "id" and "ssn"
6.  "select": cross-join "id" and "ssn" with telecom phones from step 4

Here is example input and output for this ViewDefinition:

```json
[
    {
        "resourceType": "Patient",
        "id": "pt1",
        "identifier": [{ "system": "ssn", "value": "s1" }],
        "telecom": [{ "system": "phone", "value": "tt1" }],
        "contact": [
            { "telecom": [{ "system": "phone", "value": "t12" }] },
            { "telecom": [{ "system": "phone", "value": "t13" }] }
        ]
    },
    {
        "resourceType": "Patient",
        "id": "pt2",
        "identifier": [{ "system": "ssn", "value": "s2" }],
        "telecom": [{ "system": "phone", "value": "t21" }],
        "contact": [
            { "telecom": [{ "system": "phone", "value": "t22" }] },
            { "telecom": [{ "system": "phone", "value": "t23" }] }
        ]
    }
]
```

The resulting output:

| id  | ssn | phone |
| --- | --- | ----- |
| pt1 | s1  | t11   |
| pt1 | s1  | t12   |
| pt1 | s1  | t13   |
| pt2 | s2  | t21   |
| pt2 | s2  | t22   |
| pt2 | s2  | t23   |

## The FHIRPath Subset

ViewDefinitions
use [minimal subset of FHIRPath](https://build.fhir.org/ig/FHIR/sql-on-fhir-v2/StructureDefinition-ViewDefinition.html#fhirpath-functionality)
to make implementation as simple as possible.

The specification also introduces two special functions:

- `getResourceKey` - Indirectly get a resource's id. Since it my not be
  straightforward to access a resource's id, this layer of indirection is
  useful
- `getReferenceKey(resourceType)` - A similar function to get an id from a
  reference

## The Functions in Detail

Let’s walk through every function in detail with examples:

### The `column` Function

`column` extracts elements into tabular columns using FHIRPath expressions. The
algorithm for this function begins by receiving a list of {name, path} pairs.
For each record in the given context, it evaluates the path expression to
extract the desired elements. The resulting values are then added as columns to
the output row.

```json
{
    "column": [
        { "name": "id", "path": "getResourceKey()" },
        { "name": "bod", "path": "birthDate" },
        { "name": "first_name", "path": "name.first().given.join(' ')" },
        { "name": "last_name", "path": "name.first().family" },
        {
            "name": "ssn",
            "path": "identifier.where(system='ssn').value.first()"
        },
        {
            "name": "phone",
            "path": "telecom.where(system='phone').value.first()"
        }
    ]
}
```

Here is the naive JavaScript implementation:

```javascript
function column(cols, rows) {
    return rows.map((row) => {
        return cols.reduce((res, col) => {
            res[col.name] = fhirpath(col.path, row);
            return res;
        }, {});
    });
}
```

### The `where` Function

`where` retains only those records for which it FHIRPath expression returns
true.

```json
{
    "resourceType": "ViewDefinition",
    "resource": "Patient",
    "where": [
        { "path": "meta.profile.where($this = 'myprofile').exists()" },
        { "path": "active = 'true'" }
    ]
}
```

Basic JavaScript implementation:

```javascript
function where(exprs, rows) {
    return rows.filter((row) => {
        return exprs.every((expr) => {
            return fhirpath(expr, row) == true;
        });
    });
}
```

### The `forEach` & `forEachOrNull` Functions

`forEach` and `forEachOrNull` are intended for flattening nested collections by
applying a transformation to each element. It consists of FHIRPath expression
for collection to iterate and transformation to apply to each item. This
function is akin to `flatMap` or `mapcat` in other programming languages.

```json
{
    "resourceType": "ViewDefinition",
    "resource": "Patient",
    "select": [
        {
            "forEach": "name",
            "column": [
                { "path": "given.join(' ')", "name": "first_name" },
                { "path": "family", "name": "last_name" }
            ]
        }
    ]
}
```

There are two versions of this function: `forEach` and `forEachOrNull`. The
primary difference is that `forEach` removes records where the FHIRPath
expression returns no results, whereas `forEachOrNull` keeps an empty record in
such cases.

Both functions set the `%rowIndex` environment variable to the 0-based index
of the current element within the collection being iterated. This allows
columns to capture the position of each element for ordering or surrogate key
purposes.

Basic JavaScript implementation:

```javascript
function forEach(path, expr, rows, envVars = {}) {
    return rows.flatMap((row) => {
        return fhirpath(expr, row).map((item, index) => {
            // Set %rowIndex for this iteration level.
            const childEnvVars = { ...envVars, rowIndex: index };
            // evalKeyword will call column, select or other functions.
            return evalKeyword(expr, item, childEnvVars);
        });
    });
}
```

### The `select` Function

`select` is used in combination with `forEach` or `forEachOrNull` to cross-join
parent elements with unnested collection elements. For example, `Patient.id`
with an unnested collection such as `Patient.name`.

Put another way, this function merges columns from each row set, resulting in a
comprehensive combination of data from the input collections.

```json
{
    "resourceType": "ViewDefinition",
    "resource": "Patient",
    "select": [
        {
            "column": [{ "path": "getResourceKey()", "name": "id" }]
        },
        {
            "forEach": "name",
            "column": [
                { "path": "given.join(' ')", "name": "first_name" },
                { "path": "family", "name": "last_name" }
            ]
        }
    ]
}
```

The naive JavaScript implementation:

```javascript
function select(rows1, rows2) {
    return rows1.flatMap((r1) => {
        return rows2.map((r2) => {
            // merge r1 and r2
            return { ...r1, ...r2 };
        });
    });
}

select([{ a: 1 }, { a: 2 }], [{ b: 1 }, { b: 2 }])[
    //=>
    ({ a: 1, b: 1 }, { a: 1, b: 2 }, { a: 2, b: 1 }, { a: 2, b: 2 })
];
```

### The `unionAll` Function

`unionAll` combines rows from different branches of a resource tree by
concatenating multiple record sets. Essentially a concatenation of several
collections of records into a single, unified collection while preserving all
rows from the input sets.

```json
{
    "resourceType": "ViewDefinition",
    "resource": "Patient",
    "select": [
        {
            "column": [{ "path": "getResourceKey()", "name": "id" }]
        },
        {
            "unionAll": [
                {
                    "forEach": "telecom.where(system='phone')",
                    "column": [{ "path": "value", "name": "phone" }]
                },
                {
                    "forEach": "contact.telecom.where(system='phone')",
                    "column": [{ "path": "value", "name": "phone" }]
                }
            ]
        }
    ]
}
```

In JavaScript this is just a simple concatenation:

```javascript
function unionAll(rowSets) {
    return rowSet.flatMap((rows) => {
        return rows;
    });
}

unionAll([1, 2, 3], [3, 4, 5])[
    //=>
    (1, 2, 3, 3, 4, 5)
];
```

Note that `unionAll` does not create a new `%rowIndex` scope. Each branch
inherits `%rowIndex` from the enclosing context. If a branch contains its own
iteration expression (`forEach`, `forEachOrNull`, or `repeat`), that expression
establishes an independent `%rowIndex` sequence starting from 0.

### Function Precedence

To interpret such nodes, you have to re-order keywords (functions) according to
precedence (higher bubble up):

In a ViewDefinition, different keywords/functions can appear at the same level.
To interpret such node in a ViewDefinition, an implementation must reorder the
keywords/functions according to the following precedence rule.

Keyword/function reordering rule (highest to lowest precedence):

- forEach or forEachOrNull
- select
- unionAll
- column

For example given the following ViewDefinition snippet with all
keywords/functions at the top level, the keywords/functions should be reordered
as shown in the output.

```js
{
    "forEach":   FOREACH,
    "column":    [COLUMNS], // reorder to be nested under select
    "unionALL":  [UNIONS],  // reorder to be nested under select
    "select":    [SELECTS]
}
//=>
{
    "forEach": FOREACH
    "select": [
       {"column":   [COLUMNS]},
       {"unionAll": [UNIONS]},
       SELECTS...
    ]
}
```

### Reference Implementation

The [JavaScript reference implementation](https://github.com/FHIR/sql-on-fhir-v2/tree/master/sof-js)
implements the functional model described here. It is very concise at roughly
400 lines of code and reading it is a good way to understand the model in
detail.
