# Change: Add %rowIndex environment variable

## Why

When unnesting collections with `forEach`/`forEachOrNull`, users often need to know
the position of each element within the original collection. This is useful for:

- Preserving the original ordering semantics when joining flattened data.
- Distinguishing between the first, second, third (etc.) occurrence of a
  repeating element.
- Creating surrogate keys that combine resource ID with element position.

Currently there is no portable way to capture this information in SQL on FHIR
ViewDefinitions. The FHIRPath specification defines `$index` for iteration
contexts, but SQL on FHIR does not expose an equivalent mechanism.

This proposal originates from a [community discussion on Zulip](https://chat.fhir.org/#narrow/channel/179219-analytics-on-FHIR/topic/Counting.20index.20in.20forEach).

## What Changes

- Add a new FHIRPath environment variable `%rowIndex` that returns the 0-based
  index of the current element within the collection being iterated.
- `%rowIndex` is available within `forEach`, `forEachOrNull`, and `repeat`
  contexts.
- At the top level (no iteration context), `%rowIndex` evaluates to `0`.
- Each nesting level has its own independent `%rowIndex` value scoped to that
  level's iteration.
- The type of `%rowIndex` is `integer`.

## Impact

- Affected specs: New capability (no existing specs to modify).
- Affected code:
  - `input/pagecontent/StructureDefinition-ViewDefinition-notes.md` (documentation).
  - `input/fsh/models.fsh` (potentially add to FHIRPath subset documentation).
  - `sof-js/src/index.js` (reference implementation).
  - `tests/` (new test file for %rowIndex).
