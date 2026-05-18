# Review: Unify Async Pattern for FHIR Operations

**Reviewers**: Consolidated from Claude, Codex, Gemini, Haiku, and Sonnet
**Date**: 2026-01-20
**Status**: Consolidated Review

---

## Summary

This change replaces the inline-result polling pattern for `$viewdefinition-export` with a redirect-only async completion flow using `303 See Other`. The status endpoint now signals completion via `303` and a `Location` header, and clients retrieve results from a separate result URL. The approach improves HTTP semantics, removes ambiguity between polling and result semantics, and aligns with the simplified async pattern discussed with FHIR leadership. The core direction is sound, but there are implementation gaps and several normative inconsistencies that must be resolved before adoption.

---

## Strengths

- Clear separation between polling semantics (status URL) and operation results (result URL).
- Correct use of HTTP status codes (`202 Accepted` for in-progress, `303 See Other` on completion).
- Resolves ambiguity between infrastructure errors vs. operation failures.
- Clarifies header scope (polling `Accept` only applies to status responses).
- No migration burden because the spec is not yet published.
- Notes and examples are thorough and illustrate the complete lifecycle.

---

## Key Gaps and Risks

- Result URL lifetime is not specified (validity duration, repeat retrievals, expiration headers).
- Interim response body format is implementation-defined, risking interoperability.
- Client behavior guidance is thin (redirect following, polling intervals, retry behavior).
- Access control for status/result URLs is not explicitly required.
- Caching guidance is missing (status vs. result responses).
- Edge cases not covered (late cancellation, transient errors at result endpoint).

---

## Inconsistencies and Implementation Gaps

1. Cancellation normativity conflict:
   - Spec requires `SHALL` support for cancellation.
   - Notes say cancellation is optional (`MAY`).
   - These must be aligned.

2. Reference implementation mismatch:
   - `sof-js` still implements the legacy inline-result flow and tests assert old behavior.
   - Tasks for 3.1–3.3 in `openspec/changes/unify-async/tasks.md` remain open.

3. Status parameter usage ambiguity:
   - Kick-off and polling examples still include `status` parameters.
   - Completion is now signaled via `303`; the role of `status` should be clarified or reduced.

4. Output parameter location not formalized in spec:
   - Notes clarify that output parameters appear only at the result endpoint.
   - This needs to be stated in the spec requirements.

5. Kick-off flow still references old status fields:
   - If `status: accepted` is kept, its scope should be limited to kick-off responses only.

---

## Recommendations

### Must Fix (Blocking)

1. Align cancellation normativity (choose `SHALL`, `SHOULD`, or `MAY` and use consistently).
2. Update `sof-js` reference implementation and tests to match the 303 redirect pattern, or document the divergence explicitly.
3. Add a normative statement on where output parameters appear (result response only).
4. Specify result URL lifetime (minimum retention window, whether multiple retrievals are allowed).
5. Add access control requirements for status/result URLs (same auth context or non-guessable URLs).

### Should Fix (Pre-Approval)

6. Provide polling interval guidance (use of `Retry-After`, minimum poll frequency).
7. Define a minimal interim response schema or at least recommend `Parameters` with an interim flag.
8. Clarify client redirect behavior (auto-follow or manual GET of `Location`).
9. Add caching guidance (`Cache-Control` for status and result responses).
10. Clarify the role of the `status` parameter in kick-off and polling responses.
11. Include the sequence diagram from `design.md` in the notes for implementer clarity.

### Future Considerations

12. Guidance on transient result endpoint errors (e.g., `503` retry strategy).
13. Late cancellation behavior (DELETE arriving after completion).
14. Clarify alignment with synchronous `$viewdefinition-export` behavior.
15. Document differences from FHIR Bulk Data (which uses `200` on completion).

---

## Open Items (From Tasks)

- Reference implementation updates and tests remain unchecked in `openspec/changes/unify-async/tasks.md`.
- Working group review still pending in `openspec/changes/unify-async/tasks.md`.

---

## Notes

- `AGENTS.md` changes are process/tooling updates and separate from the async pattern change.

---

## References

- `openspec/changes/unify-async/proposal.md`
- `openspec/changes/unify-async/design.md`
- `openspec/changes/unify-async/specs/viewdefinition-export/spec.md`
- `input/pagecontent/OperationDefinition-ViewDefinitionExport-notes.md`
- Josh Mandel async pattern: https://hackmd.io/@jmandel/async-pattern-simplified
- Design diagram: https://hackmd.io/XjbZwitlQyaA3_0SkQR2pQ

