# Auto-Dev Final Report Template

## Template

```
# Auto-Dev Report

## Task
[Original task description from the user]

## Summary
- **Work Packages**: [count] executed
- **Files Changed**: [count]
- **Review Iterations**: [count]
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
- **Security**: PASS | [count] findings | not run
- **Quality**: PASS | [count] findings | not run

### Review Iterations
- **Iteration 1**: [count] findings → [count] fixed
- **Iteration 2**: [count] findings → [count] fixed (if applicable)
- **Iteration 3**: [count] findings → [count] fixed (if applicable)

## Open Findings
- [Any NEEDS_REVIEW items or unfixed findings]
- Or: "None — all findings resolved"

## Branch
`auto-dev/<branch-name>`

## Git Log
[Condensed commit history of the auto-dev branch]
```

## Notes

- **Summary first** — the user wants to quickly know what happened
- **Be honest about open findings** — do not hide unresolved issues
- **Include all review iterations** — shows how many rounds were needed
- **Git log** — transparency about all commits
