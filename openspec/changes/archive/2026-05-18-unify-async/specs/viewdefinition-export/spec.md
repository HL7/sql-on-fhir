# ViewDefinition Export Async Pattern

## MODIFIED Requirements

### Requirement: Async Completion Response
Upon completion of an asynchronous `$viewdefinition-export` operation, the server SHALL use HTTP redirect to separate status polling from result retrieval.

#### Scenario: Successful export completion
- **WHEN** client polls status URL after export completes successfully
- **THEN** server SHALL return `303 See Other` status code
- **AND** server SHALL include `Location` header with URL to retrieve results
- **AND** server SHALL NOT return the final results in the response body

#### Scenario: Failed export completion
- **WHEN** export operation fails completely
- **THEN** server SHALL return `303 See Other` from status endpoint
- **AND** result URL SHALL return appropriate error status code (e.g., `500`)
- **AND** result response SHALL contain OperationOutcome with error details

#### Scenario: Partial export failure
- **WHEN** export partially succeeds (some items fail, others succeed)
- **THEN** server SHALL return `303 See Other` from status endpoint
- **AND** result URL SHALL return `200 OK` with results
- **AND** partial failure details SHALL be communicated within operation response semantics

### Requirement: Result Retrieval
The result endpoint SHALL return a response identical to what a synchronous invocation of the operation would return.

#### Scenario: Successful result retrieval
- **WHEN** client GETs the result URL from Location header
- **THEN** response SHALL use `200 OK` status code for success
- **AND** response body SHALL contain Parameters resource with export output locations
- **AND** response format SHALL match what synchronous call would return

#### Scenario: Error result retrieval
- **WHEN** client GETs result URL for a failed operation
- **THEN** response SHALL use appropriate error status code (4xx or 5xx)
- **AND** response SHALL contain OperationOutcome with error details

### Requirement: Status Polling Response
During polling, the status endpoint SHALL return `202 Accepted` while the operation is in progress.

#### Scenario: In-progress polling
- **WHEN** export is still in progress
- **THEN** server SHALL return `202 Accepted` status code
- **AND** server SHOULD include `Retry-After` header with suggested poll interval
- **AND** server MAY include `X-Progress` header with completion percentage

#### Scenario: Partial/interim results during polling
- **WHEN** export is still in progress
- **THEN** server MAY include partial or interim results in the response body
- **AND** response body format is implementation-defined
- **AND** clients SHOULD NOT treat interim results as final until `303 See Other` is received

#### Scenario: Request header scope
- **WHEN** client includes request headers (e.g., `Accept`) during polling
- **THEN** headers SHALL apply to the status response only
- **AND** headers SHALL NOT affect the format of the final operation result

### Requirement: Export Cancellation
Servers SHOULD support cancellation of in-progress exports via DELETE request to the status URL.

#### Scenario: Successful cancellation
- **WHEN** client sends DELETE request to status URL
- **THEN** server SHOULD return `202 Accepted` status code
- **AND** subsequent polls to status URL SHOULD return `404 Not Found`
- **AND** server SHOULD clean up any partial results

### Requirement: Result URL Lifetime
Servers SHALL ensure result URLs remain accessible for a reasonable period after export completion.

#### Scenario: Result URL validity
- **WHEN** export completes successfully
- **THEN** result URL SHALL remain valid for at least 24 hours
- **AND** server SHOULD support multiple retrievals of the same result
- **AND** server MAY include `Expires` header to indicate result URL expiration

### Requirement: Output Parameter Location
Output parameters from the operation SHALL only appear in the result response, not in status polling responses.

#### Scenario: Output in result response
- **WHEN** client retrieves result from result URL after 303 redirect
- **THEN** response SHALL contain all output parameters (e.g., `output`, `exportEndTime`)
- **AND** status polling responses (202) SHALL NOT contain final output parameters

### Requirement: Access Control
Servers SHALL protect status and result URLs with appropriate access controls.

#### Scenario: Authorization enforcement
- **WHEN** client accesses status or result URL
- **THEN** server SHALL require the same authorization context as the original request
- **OR** server SHALL use non-guessable URLs (e.g., cryptographically random tokens)
- **AND** unauthorized access attempts SHALL return `401 Unauthorized` or `403 Forbidden`

