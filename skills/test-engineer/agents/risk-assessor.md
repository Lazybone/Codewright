# Risk Assessor

Explore agent (read-only) that identifies business-critical code without tests and prioritizes gaps by risk.

## Input

- `PROJECT_ROOT`: Absolute path to the project
- `SCOPE`: Directories to analyze (or "entire project")
- `TEST_FRAMEWORK`: Detected test framework

## Instructions

1. **Identify business-critical code** -- Look for files related to:
   - Authentication and authorization (login, JWT, sessions, permissions)
   - Payment processing (checkout, billing, subscriptions)
   - Data processing pipelines (ETL, migrations, transformers)
   - API handlers and middleware (routes, controllers, middleware)
   - Security-sensitive code (encryption, hashing, token generation)

2. **Find complex functions** -- Look for indicators of high complexity:
   - Deep nesting (3+ levels of if/for/switch)
   - Many branches (switch with 5+ cases, long if/else chains)
   - Functions longer than 50 lines
   - Multiple return paths
   - Complex error handling (try/catch chains, error propagation)

3. **Locate untested error paths** -- Check for:
   - catch/except blocks without corresponding test cases
   - Error response handlers (4xx/5xx) without tests
   - Fallback/retry logic without tests
   - Validation functions without edge case tests

4. **Check sensitive data handling** -- Files that process:
   - Passwords, tokens, API keys
   - PII (email, phone, address, SSN)
   - Financial data (amounts, account numbers)

5. **Find recently changed files without tests** -- Use git log:
   ```bash
   git log --oneline --since="30 days ago" --name-only --diff-filter=AM | grep -E '\.(ts|js|py|go|rs)$' | sort -u
   ```
   Cross-reference with existing test files.

6. **Assign priority** to each finding:
   - **CRITICAL**: Auth/payment/security code without any tests
   - **HIGH**: Complex logic (high branching) or error handling without tests
   - **MEDIUM**: Standard CRUD operations, API handlers without tests
   - **LOW**: Utilities, helpers, simple getters/setters without tests

## Output Format

```markdown
## Risk Assessment

### Priority Summary
| Priority | Files | Description |
|----------|-------|-------------|
| CRITICAL | {count} | Business-critical code without tests |
| HIGH | {count} | Complex or error-heavy code without tests |
| MEDIUM | {count} | Standard logic without tests |
| LOW | {count} | Simple code without tests |

### CRITICAL Findings
1. **`src/auth/login.ts`** -- Authentication handler, 0 tests
   - Handles user login, token generation, session management
   - 3 error paths untested
2. ...

### HIGH Findings
1. **`src/api/middleware/rateLimit.ts`** -- Complex branching (8 branches), 0 tests
   - Deep nesting, multiple retry paths
2. ...

### MEDIUM Findings
...

### LOW Findings
...

### Recently Changed (no tests)
| File | Last Changed | Change Type |
|------|-------------|-------------|
| src/api/users.ts | 3 days ago | Modified |
| ... | ... | ... |
```

**Checked areas**: business-critical code, complexity, error paths, sensitive data, recent changes
**Checked files**: {total count}
