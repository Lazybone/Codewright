# Bug-Fixer Final Report Template

## Template

```
# Bug-Fixer Report

## Bug
[Original bug description from the user]

## Status
**normal** | **report-mode** (iterations exhausted with open findings)

## Root Cause
- **File**: `path/to/file.ext` (line X-Y)
- **Problem**: [What the code did wrong]
- **Why**: [Why this caused the observed bug]

## Fix Summary
- **Approach**: [1-2 sentences describing what was changed]
- **Files Changed**: [count]
- **Fix Type**: one-liner | multi-line | multi-file
- **Reproduction Test**: written and passing | not applicable
- **Review Iterations**: [count] / 5
- **Hardening Tests**: [count] added | skipped (report mode)
- **Acceptance Review**: passed | findings (re-entered loop) | skipped (report mode)
- **All Checks Passing**: yes | no

## Changes

| File | Action | Description |
|------|--------|-------------|
| `path/to/file` | modified | What was changed |
| `path/to/test` | created | Reproduction test |

## TDD Verification

### Reproduction Test
- **File**: `path/to/test`
- **Test Name**: `descriptive name`
- **Before fix**: FAIL (bug confirmed)
- **After fix**: PASS (bug resolved)

## Review Pipeline

### Auto-Checks
- **Tests**: PASS [X/Y] | FAIL [X/Y] | SKIPPED
- **Lint**: PASS | FAIL [count issues] | SKIPPED
- **Types**: PASS | FAIL [count errors] | SKIPPED

### Code Reviews
- **Logic**: PASS | [count] findings
- **Security**: PASS | [count] findings
- **Quality**: PASS | [count] findings
- **Architecture**: PASS | [count] findings

### Review Iterations
- **Iteration 1**: [count] findings -> [count] fixed | Active reviewers: [list]
- **Iteration 2**: [count] findings -> [count] fixed | Active reviewers: [list]
- ...up to iteration 5

### Hardening
- **Tests Added**: [count] (regression: X, edge-case: Y, error-path: Z)
- **All Passing**: yes | no

### Acceptance Review
- **Result**: passed (0 findings) | [count] findings -> re-entered loop
- **Final Status**: accepted | open findings remain

## Open Findings
- [Any NEEDS_REVIEW items or unfixed findings with severity]
- Or: "None — all findings resolved"

## Branch
`bug-fix/<branch-name>`

## Git Log
[Condensed commit history of the bug-fix branch]
```

## Notes

- **Root cause first** — the user wants to understand what went wrong
- **TDD verification** — shows the bug was confirmed and resolved
- **Be honest about open findings** — do not hide unresolved issues
- **Include all review iterations** — shows thoroughness
- **Report mode** — clearly mark when iterations were exhausted
