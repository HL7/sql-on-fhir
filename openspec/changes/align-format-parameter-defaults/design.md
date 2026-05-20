## Context

The three operations in this IG accept an `_format` input parameter governing the response body. The current declarations diverge:

| Operation                | `_format` cardinality | Documented default | Source                   |
| ------------------------ | --------------------- | ------------------ | ------------------------ |
| `$viewdefinition-export` | `0..1`                | Not specified      | `operations.fsh:59-68`   |
| `$viewdefinition-run`    | `1..1`                | n/a (mandatory)    | `operations.fsh:229-239` |
| `$sqlquery-run`          | `1..1`                | n/a (mandatory)    | `operations.fsh:360-370` |

This affects three artefacts:

1. The FSH `OperationDefinition` instances in `input/fsh/operations.fsh`.
2. The narrative parameter tables in `input/pagecontent/OperationDefinition-*-notes.md` (the `Required` column and the "Format Parameter Clarification" subsection).
3. Implementations (e.g. Pathling, sof-js) which must apply the default when clients omit the parameter.

There is no design document required for the value set or output mechanics - those are unchanged. The change is small but cross-cuts three operations, so a design doc captures the chosen default and `Accept`-header precedence rule once rather than repeating the rationale in each spec delta.

## Goals / Non-Goals

**Goals:**

- Make `_format` optional on all three operations.
- Define a single named default (`ndjson`) that applies when `_format` is omitted from the input `Parameters` and no `Accept` header negotiates an alternative.
- Define the precedence rule between `_format` and the HTTP `Accept` header.
- Keep the change backwards-compatible for clients that already supply `_format`.

**Non-Goals:**

- Change the set of formats a server must support. The existing "RECOMMENDED to support 'json', 'ndjson' and 'csv'" guidance is unchanged.
- Change the `OutputFormatCodes` or `SQLQueryRunOutputFormatCodes` value sets.
- Touch any other parameter (`header`, `_limit`, `patient`, `_since`, `viewReference`, `queryReference`, etc.).
- Define server behaviour when the negotiated format is unsupported (already covered by the existing 400 error narrative).

## Decisions

### Decision 1: Default value is `ndjson`

Use `ndjson` as the default when `_format` is omitted.

**Rationale:**

- `ndjson` is already RECOMMENDED for support across the IG (`OperationDefinition-ViewDefinitionRun-notes.md:139`, `OperationDefinition-ViewDefinitionExport-notes.md:287`).
- It streams naturally for both single-result (`$viewdefinition-run`, `$sqlquery-run`) and bulk-export (`$viewdefinition-export`) endpoints, so the same default works for all three.
- It is the convention shared with FHIR Bulk Data Access (`Patient/$export` defaults to NDJSON), which is the most directly analogous FHIR-ecosystem operation.

**Alternatives considered:**

- `json` - more familiar to general API clients, but less suitable for bulk export, and using two different defaults across the three operations would re-introduce the inconsistency this change exists to remove.
- `csv` - widely supported but not a natural FHIR-ecosystem default; would require the `header` parameter behaviour to be considered for the default case.
- Leave the default implementation-defined - rejected because it preserves the documentation gap that motivated the change.

### Decision 2: `Accept` header MAY override the default; `_format` SHALL take precedence over `Accept`

When `_format` is omitted, the server MAY honour the HTTP `Accept` header to pick a supported format other than `ndjson`. When `_format` is supplied, its value SHALL determine the response format regardless of the `Accept` header.

**Rationale:**

- Aligns with standard HTTP content negotiation while preserving the explicit, machine-readable behaviour clients get from supplying `_format`.
- Matches existing narrative in `OperationDefinition-ViewDefinitionRun-notes.md:46-53` which already documents the `_format` / `Accept` MIME-type pairs without specifying precedence.

**Alternatives considered:**

- `Accept` always wins - rejected because it would let HTTP middleware (proxies, browsers) silently override a parameter the client deliberately set.
- Ignore `Accept` entirely - rejected because clients relying on standard HTTP tooling lose a natural way to request `csv`/`json` without a `Parameters` resource.

### Decision 3: Cardinality is the right surface to relax

The cardinality declared on the `OperationDefinition.parameter` element is the contract that downstream validators check, so relaxing it from `1` to `0` is what actually changes the behaviour. Adding a `defaultValueCode = #ndjson` extension is not used because the FHIR `OperationDefinition.parameter` element does not carry a default-value slot, and an extension would add a layer of indirection that implementations are unlikely to honour. Instead, the default is encoded in the `documentation` text and the narrative pages.

### Decision 4: Scope `$viewdefinition-export` minimally

`$viewdefinition-export` already has `min = 0`, so its FSH does not need to change. Only its documentation/narrative is updated to name the default. This keeps the diff focused.

## Risks / Trade-offs

- **Risk**: Existing clients that rely on receiving `400 Bad Request` to detect an "I forgot `_format`" bug will no longer get that signal; they will get an `ndjson` body. → Mitigation: this is the desired behaviour change, and `$viewdefinition-export` has shipped with `min = 0` already, so the convention is established within the IG.
- **Risk**: A server that does not support `ndjson` could be put in an awkward position. → Mitigation: the IG already RECOMMENDS `ndjson` support; a server that does not support it MAY return `400` per the existing unsupported-format handling. The default is what the server returns "if it can"; the existing format-support narrative is the safety net.
- **Trade-off**: Encoding the default in prose rather than a machine-readable element means automated tooling cannot infer the default from the `OperationDefinition` alone. Accepted because FHIR `OperationDefinition` has no native default-value slot for input parameters.
- **Risk**: Implementations may have hard-coded the `_format`-is-required check. → Mitigation: this is a spec-only IG change; implementation updates are listed under "Impact" and are out of scope for this change.
