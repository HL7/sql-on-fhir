## Context

The reference server ships an `OperationDefinition` for `$viewdefinition-run`
at `sof-js/metadata/OperationDefinition/$run.json`. It is loaded as canonical
metadata at server startup alongside the other operation definitions and is
meant to mirror the spec's `ViewDefinitionRun` instance defined in
`input/fsh/operations.fsh`. Currently it does not - the two have drifted
across identification (URL/code/system flag), the format parameter name and
cardinality, view-input cardinalities and scopes, the source/resource
parameter shape, and the paging model.

The drift is documented in
[issue #343](https://github.com/FHIR/sql-on-fhir-v2/issues/343). The FSH is
the source of truth (the spec is what the IG publishes). This change rewrites
the JSON to match.

Unlike `$viewdefinition-export`, the reference server does mount a runtime
handler for `$run` (in `sof-js/src/server/run.js`). That handler reads
`req.query.format` and `req.query.header` directly and is mounted at
`/ViewDefinition/:id/$run`. The metadata-level alignment here will create a
deliberate gap between what the server publishes as metadata and what its
runtime currently accepts. That gap is preferable to leaving the metadata
incorrect: implementers are increasingly likely to read the metadata as
authoritative, and the runtime gap is small and documented. Closing the
runtime gap (renaming the route to `$viewdefinition-run` and reading
`_format`) is tracked as a follow-up; it is not in scope here.

**Prerequisite changes**: this change assumes
`add-sqlquery-run-limit` and `align-format-parameter-defaults` have already
been applied. `add-sqlquery-run-limit` touches `$sqlquery-run` only and has
no effect here. `align-format-parameter-defaults` rewrites the `_format`
`documentation` text on `ViewDefinitionRun` to name `ndjson` as the default
when the parameter is omitted and to state that `_format` takes precedence
over the HTTP `Accept` header, and relaxes its cardinality from `1..1` to
`0..1`; the reference JSON must carry the updated text and cardinality.

## Goals / Non-Goals

**Goals:**

- Make `sof-js/metadata/OperationDefinition/$viewdefinition-run.json`
  field-for-field equivalent to the FHIR JSON that SUSHI generates from the
  `ViewDefinitionRun` FSH instance, modulo the one deliberate divergence
  noted in Decision 2 below.
- Rename the file from `$run.json` to `$viewdefinition-run.json` so the
  filename matches the spec operation code, using `git mv` to preserve
  history.
- Capture the differences explicitly in the requirements (delta spec) so
  future drift is detectable by inspection and (where practical) by
  automated comparison.
- Keep the change limited to metadata - no route handlers, no test fixtures
  for behaviour the server already implements under the old contract.

**Non-Goals:**

- Change the spec FSH. The spec already defines the correct shape.
- Rename the runtime route in `sof-js/src/server/run.js` from `$run` to
  `$viewdefinition-run`, or teach the handler to read `_format` instead of
  `format`. That is a separate, larger change that should also align the
  HTML form rendering, links elsewhere in `sof-js`, and any external tests
  that target the old route. See "Open questions" below.
- Touch other `sof-js` metadata files (`$viewdefinition-export.json`,
  `$evaluate.json`, `$materialize.json`, `$refresh.json`,
  `$sqlquery-run.json`, `$validate.json`).
- Replace the `ViewDefinition` profile's hack workaround on the spec's
  `OperationDefinition.resource` element. That is a spec FSH question,
  tracked separately.

## Decisions

### Decision 1: Hand-write the JSON; do not symlink to the IG build output

The reference server bundles a small, self-contained set of canonical
resources under `sof-js/metadata/`. Pointing the metadata at the IG build
output (`output/OperationDefinition-ViewDefinitionRun.json`) would couple the
runtime to a build artefact that is not checked into the repository, so the
server could not start without first running `npm run build:ig`. The
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

This mirrors Decision 2 in `align-viewdefinition-export-reference`. It is
the one deliberate divergence between the reference JSON and a strict
re-serialisation of the FSH instance.

**Rationale:**

- The FSH "Hack" comment makes clear `ViewDefinition` is the intended value.
- Implementers reading the reference metadata get the correct semantic
  signal that this operation is `ViewDefinition`-typed.
- The previous reference metadata already used `ViewDefinition` here, so
  preserving it avoids a regression.

**Alternatives considered:**

- Mirror the FSH literally with `CanonicalResource`: rejected. It carries
  the same misleading signal the FSH comment apologises for.

### Decision 3: Rename `$run.json` -> `$viewdefinition-run.json` via `git mv`

The spec operation code is `viewdefinition-run` and the canonical URL is
`http://sql-on-fhir.org/OperationDefinition/$viewdefinition-run`. The
reference filename `$run.json` reflects only the drifted code value (`$run`).
Aligning the filename with the spec keeps the directory self-documenting and
matches the naming convention used by the other operation files in the
same directory (`$viewdefinition-export.json`, `$sqlquery-run.json`).

`git mv` preserves history so the diff reads as a rename plus a content
rewrite rather than a delete-plus-add.

**Rationale:**

- File naming should match the spec code, not the drifted reference code.
- Other files in the directory follow this convention.

**Alternatives considered:**

- Leave the filename as `$run.json` and only fix the content: rejected. The
  filename is the most visible signal in a directory listing, and leaving
  it stale guarantees future drift questions.
- Delete `$run.json` and create a new `$viewdefinition-run.json`: rejected.
  Loses history; `git mv` is the better tool.

### Decision 4: Split `source` (string) and `resource` (Resource) into two distinct parameters

The previous reference JSON declared two parameters both named `source` -
one of type `string` (max 1) for an external data source, and one of type
`Resource` (max `*`) for inline resources. Two parameters with the same name
in a single `OperationDefinition` is unusual and ambiguous when consumers
build forms or parameter resolvers off the metadata.

The spec splits these into `source` (string, max 1) for the external data
source and `resource` (Resource, max `*`) for inline resources. The aligned
reference JSON adopts this split.

**Rationale:**

- The spec defines two distinct names; the reference metadata should match.
- A single parameter name with two `type`s in one `OperationDefinition`
  cannot be addressed unambiguously by clients that build query strings or
  `Parameters` resources from the metadata.

**Alternatives considered:**

- Keep the duplicate `source` parameters: rejected. Spec-incompatible and
  hard to consume programmatically.

### Decision 5: Drop `_count` / `_page`; add `_limit`

The reference JSON modelled paging on FHIR search with `_count` (page size)
and `_page` (page number). The spec defines a single `_limit` parameter
(integer, 0..1) capping the result set, with no page index. The aligned
reference JSON drops `_count` and `_page` and adds `_limit`.

**Rationale:**

- The spec is the source of truth; it does not include a paging model for
  `$viewdefinition-run`.
- Result-set capping is preserved via `_limit`, so the practical use case
  (defending the server from runaway queries) remains addressable.

**Alternatives considered:**

- Keep `_count` / `_page` as reference-only extensions: rejected. The
  reference metadata's purpose is to mirror the spec, not to publish
  experimental parameters that consumers may mistake for spec features.

### Decision 6: `viewResource` adopts `CanonicalResource` + `targetProfile` + allowed-type extension

The previous reference JSON declared `viewResource` with `type: "ViewDefinition"`

- the simpler but non-canonical form (it bypasses the extension mechanism
  and relies on the consumer recognising the custom resource name). The spec
  encodes `viewResource` as a `CanonicalResource`-typed parameter with
  `targetProfile = Canonical(ViewDefinition)` and the
  `operationdefinition-allowed-type` extension narrowing the resource to the
  `ViewDefinition` profile.

We adopt the spec form so the reference server publishes a value that a
stock FHIR validator can interpret.

**Rationale:**

- Matches the FSH instance.
- This is the canonical way to declare a profile-constrained
  `CanonicalResource` parameter in `OperationDefinition` (per the core
  spec).

**Alternatives considered:**

- Keep `type = "ViewDefinition"`: rejected. Non-canonical; bypasses standard
  FHIR validators.

## Risks / Trade-offs

- **Risk**: External consumers of the reference server may have built
  clients that depend on the drifted parameter shape (`format` rather than
  `_format`, `_count`/`_page` paging, the two-`source`-parameters trick, or
  the `$run` filename/operation code). -> **Mitigation**: the spec has
  always defined the correct shape, and the reference server's runtime
  route handler is not changing in this work, so existing clients hitting
  `/ViewDefinition/:id/$run?format=csv` continue to work at the HTTP level.
  Only the published metadata changes.
- **Risk**: The metadata now describes parameters the runtime handler does
  not honour (e.g., `_format`, `_limit`, the split `source`/`resource`).
  -> **Mitigation**: document the gap in this design and open a follow-up
  to close it. The reference server is a worked example of the spec, not a
  conformance test bed for itself; metadata correctness has more
  educational value than runtime parity in the short term.
- **Risk**: The reference server may stop loading the file if the renamed
  filename is not the one the loader is looking up. -> **Mitigation**: the
  loader in `sof-js/src/server/db.js` reads files generically by filename
  pattern, but any code that looks up `OperationDefinition/$run` by id
  (e.g., `sof-js/src/server/run.js:37`) needs the metadata to be reachable
  by the new id `ViewDefinitionRun`. Verify by running `bun test` and by
  visiting the run form page after the change.
- **Trade-off**: The reference JSON diverges from the FSH in exactly one
  place (Decision 2). -> **Mitigation**: capture the divergence as an
  explicit scenario in the spec delta so it is intentional and reviewable.

## Migration Plan

1. `git mv sof-js/metadata/OperationDefinition/\$run.json sof-js/metadata/OperationDefinition/\$viewdefinition-run.json`.
2. Rewrite the JSON contents in a single atomic commit.
3. Update any in-repo references to the old filename or the old
   `OperationDefinition` id `$run` so the metadata is still discoverable
   (in particular, `sof-js/src/server/run.js` calls
   `read(req.config, 'OperationDefinition', '$run')`; this lookup must be
   adjusted to use the new id `ViewDefinitionRun` so the form continues to
   render). This is the minimum runtime touch required to keep the server
   booting; it is not the full runtime alignment, which remains out of
   scope.
4. Run `cd sof-js && bun install && bun test` to confirm nothing breaks.
5. Start the server (`cd sof-js && bun run start` or equivalent) and
   request `GET /OperationDefinition/ViewDefinitionRun`. Confirm the file
   loads and the new parameter set is served.
6. No rollback plan needed beyond `git revert` - the change is a single
   file rewrite (plus the metadata-id lookup fix) with no schema or data
   changes.

## Open Questions

- Should this change also rename the runtime route from
  `/ViewDefinition/:id/$run` to `/ViewDefinition/:id/$viewdefinition-run`?
  Recommendation: no, defer to a follow-up. The route rename is a breaking
  change for any client hitting the reference server via HTTP and is best
  handled with a deprecation window. The metadata alignment can proceed
  independently.
- Should the runtime handler accept `_format` as a synonym for `format` in
  the meantime, so that clients consuming the new metadata can issue
  matching requests? Recommendation: yes in a follow-up; not in this
  change.
