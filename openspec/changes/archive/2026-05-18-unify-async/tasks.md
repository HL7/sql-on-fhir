# Implementation Tasks

## 1. Update OperationDefinition-ViewDefinitionExport-notes.md

### 1.1 Async Pattern Overview (lines 7-12)
- [x] Replace 5-step flow with 6-step flow including `303 See Other` redirect
- [x] Clarify that result retrieval is a separate step from status polling

### 1.2 HTTP Status Codes Table (lines 230-239)
- [x] Add `303 See Other` row: "Export complete, follow Location header to get results"
- [x] Update `202 Accepted` description to clarify it's for in-progress only

### 1.3 Operation Flow Section (lines 371-407)
- [x] Update Step 4 (Completion): Change from `200 OK` with body to `303 See Other` with `Location` header
- [x] Add Step 5 (Result Retrieval): GET on result URL returns Parameters with output
- [x] Update Step 5→6 (Error Handling): Errors communicated via result endpoint, not status endpoint
- [x] Renumber subsequent steps

### 1.4 Examples Section (lines 645-726)
- [x] Update "Step 5: Final Status Poll" to show `303 See Other` with `Location` header
- [x] Add "Step 6: Result Retrieval" showing GET on result URL with `200 OK` response
- [x] Renumber "Step 6: Download Files" to "Step 7"

### 1.5 Output Parameters Section (lines 142-179)
- [x] Add clarification that output parameters appear in result response (after 303 redirect)
- [x] Not in status polling response

### 1.6 Add Header Scope Section
- [x] Add new section explaining request headers apply to status response only
- [x] Explain this allows different formats for status vs result

## 2. Update operations.md

- [x] Update Use Case 2 async flow description (lines 39-50)
- [x] Ensure overview aligns with new 303 redirect pattern

## 3. Reference Implementation (sof-js)

- [x] Update `sof-js/src/server/export.js` to return `303 See Other` on completion
- [x] Add separate result endpoint (`getExportResultEndpoint`)
- [x] Update tests in `sof-js/tests/server/export.test.js`

## 4. Validation

- [x] Test IG build (`npm run build:ig`) - Build successful
- [x] Review changes with Claude (write to `review-claude.md`)
- [x] Review changes with Sonnet (write to `review-sonnet.md`)
- [x] Review changes with Haiku (write to `review-haiku.md`)
- [ ] Review changes with working group
- [x] Verify alignment with Josh's HackMD proposal: https://hackmd.io/@jmandel/async-pattern-simplified
