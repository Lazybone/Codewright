# Auto-Dev Final Report Template

## Template

```
# Auto-Dev Report

## Task
[Original task description from the user]

## Status
**normal** | **report-mode** (iterations exhausted with open findings)

## Summary
- **Work Packages**: [count] executed
- **Files Changed**: [count]
- **Review Iterations**: [count] / 5
- **Hardening Tests**: [count] added | skipped (report mode)
- **Acceptance Review**: passed | findings (re-entered loop) | skipped (report mode)
- **All Checks Passing**: yes | no

## Changes

| File | Action | Description |
|------|--------|-------------|
| `path/to/file` | created / modified / deleted | What was done |

## Verification

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
- **Iteration 1**: [count] findings → [count] fixed | Active reviewers: [list]
- **Iteration 2**: [count] findings → [count] fixed | Active reviewers: [list]
- ...up to iteration 5

### Hardening
- **Tests Added**: [count] (regression: X, edge-case: Y, error-path: Z)
- **All Passing**: yes | no

### Acceptance Review
- **Result**: passed (0 findings) | [count] findings → re-entered loop
- **Final Status**: accepted | open findings remain

## Open Findings
- [Any NEEDS_REVIEW items or unfixed findings with severity]
- Or: "None — all findings resolved"

## Branch
`auto-dev/<branch-name>`

## Git Log
[Condensed commit history of the auto-dev branch]
```

## Notes

- **Summary first** — the user wants to quickly know what happened
- **Be honest about open findings** — do not hide unresolved issues
- **Include all review iterations** — shows how many rounds were needed and which reviewers were active
- **Show hardening and acceptance** — these are key quality indicators
- **Git log** — transparency about all commits
- **Report mode** — clearly mark when the skill could not fully resolve all findings
