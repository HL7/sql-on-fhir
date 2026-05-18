# Change: Unify Async Pattern for FHIR Operations

## Why

The current async pattern for `$viewdefinition-export` allows returning final results directly from the status polling endpoint (`200 OK`). After discussion between Josh Mandel, Nikolai Ryzhikov, and Steve Munini (Jan 15, 2026), agreement was reached to adopt a **redirect-only pattern** (`303 See Other`) for the following reasons:

### Key Arguments (from Josh)

1. **Error Ambiguity**: If a `500` error occurs during polling, is it a polling failure or an operation failure? The redirect pattern cleanly separates these: polling errors are protocol-level, operation errors are communicated via the result endpoint.

2. **Header Scope Ambiguity**: When client sends `Accept: JSON` header during polling, does it apply to the status response or the final operation result? The redirect pattern solves this by allowing different parameters for status requests vs. result requests.

3. **Clean Separation**: Redirect pattern cleanly separates polling semantics from result semantics, making the protocol unambiguous.

### References
- Josh's proposal: https://hackmd.io/@jmandel/async-pattern-simplified
- SQL on FHIR WG meeting: Jan 13, 2026
- Josh/Nikolai/Steve alignment meeting: Jan 15, 2026

## What Changes

### Async Flow Changes
- Completion response uses `303 See Other` with `Location` header pointing to result URL
- Results are retrieved via separate GET request to result URL
- Result response is identical to what a synchronous call would return
- Polling responses (`202 Accepted`) can still contain interim status information

### Error Handling
- If operation fails completely: polling returns `303 See Other`, result endpoint returns error status (e.g., `500`) with OperationOutcome
- Partial success (e.g., 500k items succeed, one fails): communicated within operation semantics at result endpoint, not protocol-level errors
- Polling failures (network issues, server errors) are clearly distinguishable from operation failures

### Response Body During Polling (agreed with Josh and Steve)
- Polling responses MAY contain partial/interim results in the response body
- This allows servers to report progress beyond just `X-Progress` header
- Interim response format is implementation-defined for now
- Headers like `X-Progress` and `Retry-After` remain for progress indication

### Future Considerations (not in this change)
- FHIR Task integration for job discovery (add task ID header/parameter)
- Interim parameters extension: Formalize mechanism for marking output parameters as "interim" vs "final" in OperationDefinition

## Impact
- Affected specs: `$viewdefinition-export` operation definition and documentation
- Alignment benefit: Consistent with emerging FHIR async pattern direction

Note: The current async spec is not yet published, so no migration concerns.
