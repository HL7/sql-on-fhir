## Context

The reference server ships an `OperationDefinition` for `$viewdefinition-export`
at `sof-js/metadata/OperationDefinition/$viewdefinition-export.json`. It is
loaded as canonical metadata at server startup alongside the other operation
definitions and is meant to mirror the spec's `ViewDefinitionExport` instance
defined in `input/fsh/operations.fsh`. Currently it does not - the two have
drifted across identification, view-input shape, parameter names, cardinalities,
output metadata, and the bulk-export-style inputs.

The drift is documented in
[issue #344](https://github.com/FHIR/sql-on-fhir-v2/issues/344). The FSH is
the source of truth (the spec is what the IG publishes). This change rewrites
the JSON to match.

**Prerequisite changes**: this change assumes
`add-sqlquery-run-limit` and `align-format-parameter-defaults` have already
been applied. `add-sqlquery-run-limit` touches `$sqlquery-run` only and has
no effect here. `align-format-parameter-defaults` rewrites the `_format`
`documentation` text on `ViewDefinitionExport` to name `ndjson` as the
default when the parameter is omitted and to state that `_format` takes
precedence over the HTTP `Accept` header; the reference JSON must carry the
updated text rather than the older "Bulk export output format" string.

There is no runtime handler for `$viewdefinition-export` in the reference
server today (no route is mounted in `sof-js/src/server.js`; the operation is
spec-only, with the metadata file present so the operation is discoverable).
That means the alignment is purely about what the server publishes as
metadata, not about behaviour.

## Goals / Non-Goals

**Goals:**

- Make `sof-js/metadata/OperationDefinition/$viewdefinition-export.json`
  field-for-field equivalent to the FHIR JSON that SUSHI generates from the
  `ViewDefinitionExport` FSH instance, modulo the one deliberate divergence
  noted in Decision 2 below.
- Capture the differences explicitly in the requirements (delta spec) so
  future drift is detectable by inspection and (where practical) by automated
  comparison.
- Keep the change limited to metadata - no route handlers, no test fixtures
  for behaviour the server does not implement.

**Non-Goals:**

- Change the spec FSH. The spec already defines the correct shape.
- Implement the `$viewdefinition-export` operation at runtime in `sof-js`.
  That is a separate, larger change.
- Touch other `sof-js` metadata files (`$run.json`, `$evaluate.json`,
  `$materialize.json`, `$refresh.json`, `$sqlquery-run.json`,
  `$validate.json`).
- Replace the `ViewDefinition` profile's hack workaround for the operation's
  `resource` element. That is a spec FSH question, tracked separately.

## Decisions

### Decision 1: Hand-write the JSON; do not symlink to the IG build output

The reference server bundles a small, self-contained set of canonical
resources under `sof-js/metadata/`. Pointing the metadata at the IG build
output (`output/OperationDefinition-ViewDefinitionExport.json`) would couple
the runtime to a build artefact that is not checked into the repository, so
the server could not start without first running `npm run build:ig`. The
existing metadata files are all hand-checked-in JSON; this change follows
that convention.

**Rationale:**

- `sof-js` is expected to start without running the IG publisher first.
- The other operation metadata files in the same directory are hand-checked,
  so consistency favours hand-writing this one too.

**Alternatives considered:**

- Generate from FSH via a build step: rejected. Adds a SUSHI/Node coupling to
  the reference server's startup path and a new failure mode for a single
  file.
- Symlink into the IG `output/`: rejected. The IG `output/` directory is
  generated and not committed.

### Decision 2: `resource = [ "ViewDefinition" ]`, not `[ "CanonicalResource" ]`

The FSH defines `resource[0] = #CanonicalResource` with a comment ("Hack: it
should be #ViewDefinition, but we don't have that type yet"). The hack is
necessary because the FHIR `OperationDefinition.resource` value set does not
yet include the IG's custom `ViewDefinition` resource type, so SUSHI rejects
the literal value. The reference server is not bound by SUSHI's value-set
validation and the JSON does not need to round-trip through SUSHI, so it can
declare the resource type the spec actually intends.

This is the one deliberate divergence between the reference JSON and a strict
re-serialisation of the FSH instance. It improves the reference server's
usefulness without re-introducing the original drift.

**Rationale:**

- The FSH "Hack" comment makes clear `ViewDefinition` is the intended value.
- Implementers reading the reference metadata get the correct semantic
  signal that this operation is `ViewDefinition`-typed.

**Alternatives considered:**

- Mirror the FSH literally with `CanonicalResource`: rejected. It carries the
  same misleading signal the FSH comment apologises for.

### Decision 3: Output `_format` is single-valued; per-output `format` part is removed

The spec carries `_format` once at the top level of the output `Parameters`
(set 0..1). The reference JSON previously included a per-output `format`
part (max 1). Removing the per-output `format` part aligns with the spec; the
top-level echo is sufficient because a single export run uses a single
output format.

### Decision 4: Use the `operationdefinition-allowed-type` extension on `viewResource`

The spec encodes `viewResource` as a `Resource`-typed parameter with the
`operationdefinition-allowed-type` extension narrowing the resource to the
`ViewDefinition` profile. This is the canonical way to declare a profile-
constrained `Resource` parameter in `OperationDefinition` (per the core spec).
The previous reference JSON used `type: "ViewDefinition"` directly, which is
the simpler but non-canonical form (it bypasses the extension mechanism and
relies on the consumer recognising the custom resource name).

We adopt the extension-based form so the reference server publishes a value
that a stock FHIR validator can interpret.

### Decision 5: View-input wrapper is named `view`, not retained as flat parameters

The spec wraps each view input under a repeating `view` parameter so a single
export request can name multiple views with optional friendly identifiers.
The previous reference JSON exposed `viewReference` and `viewResource` as two
flat top-level parameters with `max = "*"`, which makes the pairing implicit
and prevents per-view naming. Adopting the wrapper structure is non-optional
for alignment.

## Risks / Trade-offs

- **Risk**: External consumers of the reference server may have built clients
  that depend on the drifted parameter shape (flat `viewReference`,
  `format` instead of `_format`, etc.). → **Mitigation**: the reference
  server has never implemented the operation at runtime, so any such consumer
  is reading the metadata only. Aligning with the spec is the correct fix.
- **Trade-off**: The reference JSON now diverges from the FSH in exactly one
  place (Decision 2). → **Mitigation**: capture the divergence as an explicit
  scenario in the spec delta so it is intentional and reviewable.
- **Risk**: The reference server may stop loading the file if the JSON is
  syntactically malformed or violates the loader's expectations. →
  **Mitigation**: validate by running `bun test` and starting the server
  locally; the loader reads JSON files generically, so any valid FHIR
  `OperationDefinition` JSON is fine.

## Migration Plan

1. Update the JSON file in a single atomic commit.
2. Run `cd sof-js && bun install && bun test` to confirm nothing breaks.
3. Start the server (`cd sof-js && bun run start` or equivalent) and confirm
   the file loads and is served at
   `GET /OperationDefinition/$viewdefinition-export`.
4. No rollback plan needed beyond `git revert` - the change is a single
   file rewrite with no schema or data changes.
