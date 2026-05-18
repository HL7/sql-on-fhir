# Design: %rowIndex environment variable

## Context

The SQL on FHIR specification allows unnesting of FHIR collections via `forEach`,
`forEachOrNull`, and `repeat` directives. However, there is currently no way to
capture the position of each element within the source collection. This
information is valuable for:

1. **Ordering semantics**: SQL result sets are unordered by default; including
   the original index allows users to restore FHIR ordering.
2. **Disambiguation**: When a Patient has multiple names, knowing which is the
   first vs second can be semantically important.
3. **Surrogate keys**: Combining resource ID with element index creates a unique
   identifier for each row.

### FHIRPath precedent

The FHIRPath specification defines `$index` as an iteration variable available
within functions like `where()` and `select()`. However, SQL on FHIR uses a
restricted FHIRPath subset and does not expose `$index` directly.

We propose introducing `%rowIndex` as a new environment variable (using the `%`
prefix consistent with existing constants like `%bp_code`) rather than exposing
`$index` directly. This keeps the mechanism aligned with how SQL on FHIR already
handles external values.

## Goals / Non-goals

### Goals

- Provide a portable, standardised way to access iteration position.
- Support nested iteration with independent index tracking per level.
- Integrate cleanly with existing constant/environment variable mechanisms.
- Maintain backwards compatibility (existing ViewDefinitions unchanged).

### Non-goals

- Expose the full FHIRPath `$index` variable (out of scope for restricted
  subset).
- Provide named/scoped indices for parent iteration levels (e.g., `%rowIndex[1]`).
- Track indices across `unionAll` branches (each branch maintains its own
  iteration).

## Decisions

### Decision 1: Use `%rowIndex` rather than `$index`

**Rationale**: SQL on FHIR already uses the `%name` syntax for constants and
environment variables. Using `%rowIndex` keeps the mechanism consistent and
avoids confusion with the full FHIRPath `$index` which has broader semantics.

**Alternatives considered**:

- `$index`: Would require documenting that SQL on FHIR's `$index` differs from
  FHIRPath's `$index` (which is scoped to `where()`, `select()`, etc.).
- `%index`: Shorter but less descriptive; `rowIndex` clarifies this is about row
  generation.

### Decision 2: 0-based indexing

**Rationale**: Consistent with FHIRPath's `$index` (0-based), JavaScript arrays,
and most programming languages. Also aligns with SQL's `ROW_NUMBER() - 1`
pattern.

**Alternatives considered**:

- 1-based indexing: More natural for end users but inconsistent with FHIRPath
  and would require conversion when joining with external data.

### Decision 3: Each nesting level has independent `%rowIndex`

**Rationale**: Nested `forEach` blocks operate on different collections. Each
level should track its own position independently. Users can capture parent-level
indices in separate columns if needed.

**Example**:

```json
{
  "forEach": "contact",
  "column": [{ "name": "contact_index", "path": "%rowIndex" }],
  "select": [{
    "forEach": "telecom",
    "column": [{ "name": "telecom_index", "path": "%rowIndex" }]
  }]
}
```

This produces `contact_index` from the outer loop and `telecom_index` from the
inner loop.

### Decision 4: Top-level `%rowIndex` is 0

**Rationale**: At the resource level (no `forEach`), each resource produces one
row. Returning 0 is consistent with "this is the 0th (only) iteration" and avoids
null/undefined semantics.

### Decision 5: `%rowIndex` type is `integer`

**Rationale**: Indices are inherently integer values. This maps to SQL `INT` per
the existing type mapping table.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Implementers may find index tracking complex in `repeat` | Provide clear algorithm description and test cases |
| Users may expect named parent indices | Document the pattern of capturing indices in columns at each level |
| Performance overhead of tracking indices | Minimal; implementations already iterate with counters internally |

## Migration Plan

No migration needed. This is a purely additive feature. Existing ViewDefinitions
continue to work unchanged.

## Open Questions

1. **Should `%rowIndex` be `null` when `forEachOrNull` produces a null row?**
   Proposed answer: No, use `0` for consistency. The null row is effectively the
   "0th" item in an empty collection that was coerced to a single-element
   collection.

2. **Should this be a "shareable" feature or "experimental"?**
   Proposed answer: Mark as shareable since it addresses a clear user need and
   has straightforward semantics.
