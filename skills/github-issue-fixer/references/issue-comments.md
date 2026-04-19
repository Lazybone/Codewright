# Issue Comment Templates

Templates for comments posted to GitHub issues during the fix workflow.
The coordinator fills in the placeholders before posting via `gh issue comment`.

## Issue Invalidated

Used when both Analyzer and Validator determine the issue is not a real problem
(Wave 1), or when the reproduction test passes immediately (Wave 3).

```text
## Investigation Result

We investigated this issue and were unable to confirm the reported behavior.

### What was checked
{CHECKED_AREAS}

### Files examined
{FILE_LIST}

### Reproduction attempt
{REPRODUCTION_DETAILS}

### Conclusion
{REASON_NOT_CONFIRMED}

If you can provide additional reproduction steps or context, please feel free
to reopen this issue. We're happy to take another look.
```

## Issue Resolved

Used when the fix is successfully committed and all reviews pass (Wave 8).

```text
## Fix Applied

This issue has been resolved.

### Root Cause
{ROOT_CAUSE}

### Changes Made
{CHANGE_SUMMARY}

### Tests Added
- **Reproduction test**: {REPRO_TEST_DESCRIPTION}
- **Regression/edge-case tests**: {HARDENING_TESTS_DESCRIPTION}

### Commit
{COMMIT_LINK}
```

## Posting Comments

Use the GitHub CLI to post comments and close issues:

### Comment and close (invalidated)
```bash
gh issue comment <NUMBER> --body "<COMMENT_TEXT>"
gh issue close <NUMBER> --reason "not planned" --comment "Closing: issue could not be confirmed."
```

### Comment (resolved — commit auto-closes via Fixes #N)
```bash
gh issue comment <NUMBER> --body "<COMMENT_TEXT>"
```

The `Fixes #<NUMBER>` in the commit message will auto-close the issue
when pushed. No explicit `gh issue close` needed.
