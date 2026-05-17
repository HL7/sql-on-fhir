---
name: sql-portability
description: Analyse whether a SQL query is portable across database implementations using sqlglot transpilation. Use this skill when checking SQL compatibility, cross-database portability, dialect differences, or when reviewing SQL on FHIR ViewDefinition queries for implementation-specific issues. Trigger keywords include "sql portability", "dialect", "cross-database", "transpile", "compatible", "portable SQL", "database compatibility".
---

# SQL portability analysis

Analyse SQL portability by transpiling a query through multiple database dialects using sqlglot.

## Running the analysis

Pipe the SQL to the bundled script via stdin. The optional first argument sets the source dialect (defaults to `postgres`).

```bash
echo 'SELECT id FROM patient WHERE active = TRUE' | uv run .claude/skills/sql-portability/scripts/sql_portability.py [source_dialect]
```

Target dialects: all dialects supported by the installed version of sqlglot.

## Interpreting results

The script outputs JSON with these fields:

- `original_sql` — the input query.
- `source_dialect` — dialect used to parse the input.
- `parse_error` — present if the input fails to parse.
- `results[]` — one entry per target dialect:
  - `dialect`, `success`, `sql`, `error` (on failure), `modified` (true if output differs from input).

## Presenting the report

1. **Original SQL** — show the query as provided.
2. **Source dialect** — the dialect used to parse input.
3. **Compatibility matrix** — table with columns: Dialect, Status, Notes.
   - Identical: output matches input exactly.
   - Modified: transpiled successfully but SQL differs — show the key differences.
   - Failed: transpilation error — explain the cause.
4. **Key findings** — summarise which constructs caused modifications or failures, common patterns across dialects, and overall portability assessment.
5. **Recommendations** — suggest alternative SQL constructs that would improve portability, where applicable. Focus on changes relevant to SQL on FHIR implementers.
