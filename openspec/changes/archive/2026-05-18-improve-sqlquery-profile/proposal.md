# Change: Improve SQLQuery Profile and Add Execution Operation

## Why

The SQLQuery profile documentation is minimal and missing critical guidance for:
1. **Table aliasing** - How to disambiguate ViewDefinitions with same name using `relatedArtifact.label`
2. **Query parameters** - How to declare and use parameters via `Library.parameter` and `:placeholder` syntax
3. **SQL annotations** - The `@annotation` syntax for tooling interoperability
4. **ViewDefinition dependencies** - Complete `relatedArtifact` structure
5. **Query execution** - No operation for running SQLQuery Libraries

These gaps have been discussed in Working Group meetings (June-November 2025) and Zulip, with consensus on solutions. Brian Kaney's sql-fhir-library-builder provides a reference implementation.

## What Changes

### Documentation Updates

1. **Expand intro page** (`StructureDefinition-SQLQuery-intro.md`)
   - Add "Table Aliasing" section explaining `relatedArtifact.label`
   - Add "Query Parameters" section explaining `Library.parameter` + `:name` syntax
   - Add "ViewDefinition Dependencies" section with complete structure
   - Expand conformance summary

2. **Create notes page** (`StructureDefinition-SQLQuery-notes.md`) - **NEW**
   - Detailed table aliasing examples with OMOP/FHIR disambiguation scenario
   - Parameter syntax comparison (`:name` vs `@name` vs `?`)
   - FHIR-to-SQL type mapping table
   - SQL annotation reference with FHIR mappings
   - Complete multi-source query example

### Profile Constraints

3. **Make `relatedArtifact.label` required** (`library-profiles.fsh`)
   - Changed from 0..1 to 1..1
   - ViewDefinition dependencies must have explicit table alias
   - Ensures unambiguous table name resolution

4. **Make `content.title` required** (`library-profiles.fsh`)
   - Changed from 0..1 to 1..1
   - SQL attachments must have plain text SQL in title
   - `data` contains base64-encoded SQL for machine processing

### Example Updates

5. **Update existing examples** (`sql-query-examples.fsh`)
   - Add `label` to `UniquePatientAddressesQuery` relatedArtifacts
   - Add `label` to `SqlOnFhirExample` relatedArtifacts

6. **Add new example** - **NEW**
   - `OmopFhirPatientJoin` demonstrating table disambiguation
   - Two ViewDefinitions with conceptually similar names
   - Different labels for disambiguation
   - Parameter usage

### New Operation

7. **Create `$sqlquery-run` operation** (`operations.fsh`) - **NEW**
   - Synchronous execution of SQLQuery Libraries
   - Instance-level: `POST [base]/Library/[id]/$sqlquery-run`
   - Type-level: `POST [base]/Library/$sqlquery-run`
   - System-level: `POST [base]/$sqlquery-run`
   - Input: format, query (reference or inline), parameters, source
   - Output: Binary with results (json, ndjson, csv, parquet)

8. **Create operation documentation** - **NEW**
   - `OperationDefinition-SQLQueryRun-intro.md` - Use cases, endpoints, execution flow
   - `OperationDefinition-SQLQueryRun-notes.md` - Examples, parameter types, error handling

## Impact

- Affected specs: `sqlquery`, `operations`
- Affected files:
  - `input/pagecontent/StructureDefinition-SQLQuery-intro.md` - Expand
  - `input/pagecontent/StructureDefinition-SQLQuery-notes.md` - Create
  - `input/fsh/profiles/library-profiles.fsh` - Add constraints
  - `input/fsh/examples/sql-query-examples.fsh` - Update + add example
  - `input/fsh/operations.fsh` - Add SQLQueryRun operation
  - `input/pagecontent/OperationDefinition-SQLQueryRun-intro.md` - Create
  - `input/pagecontent/OperationDefinition-SQLQueryRun-notes.md` - Create
- Breaking changes: `relatedArtifact.label` and `content.title` now required (minor)

## References

- Brian's implementation: https://github.com/reason-healthcare/sql-fhir-library-builder
- Gino's table name options: https://hackmd.io/@GinoCanessa/SoF-QueryTableNames
- Zulip discussion: https://chat.fhir.org/#narrow/stream/179219-analytics-on-FHIR/topic/Table.20name.20and.20query.20parameters.20syntax
