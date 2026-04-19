---
name: fix-github-issue
description: >
  Analyzes a GitHub issue, validates it with dual-agent verification,
  writes a reproduction test (TDD), implements the fix, runs iterative
  multi-reviewer code review (Logic, Security, Quality, Architecture),
  hardens with regression tests, and commits with issue lifecycle management.
  Use this skill when the user wants to fix a GitHub issue, mentions an issue
  URL or issue number, or says "fix issue", "resolve issue", "look at issue #X",
  "fix this bug", "resolve this error" with an issue reference.
  Also triggers on German: "behebe issue", "löse das issue",
  "schau dir issue #X an", "bug fixen", "diesen Fehler beheben".
---

# GitHub Issue Fixer — Wave-Based Workflow

This skill fixes GitHub issues systematically using an 8-wave architecture
with TDD core, multi-reviewer verification, and GitHub issue lifecycle management.

## Prerequisites

- Git repository with configured remote
- GitHub CLI (`gh`) installed and authenticated
- Optional: MCP Google DevTools for browser-based verification

## Wave Architecture Overview

```
Wave 1: VALIDATE    ── Analyzer + Validator (parallel)
Wave 2: PLAN        ── Planner (fix plan + test strategy)
       BRANCH       ── Create fix/issue-<N> branch
Wave 3: TEST-FIRST  ── Test-Writer: reproduction test (must FAIL)
Wave 4: FIX         ── Coder: implement fix (reproduction test must PASS)
Wave 5: REVIEW-FIX  ── 4 Reviewers parallel → Fixers → Loop (max 5)
Wave 6: HARDEN      ── Test-Writer: regression + edge-case tests
Wave 7: ACCEPTANCE  ── 4 Reviewers (final review of code + tests)
Wave 8: COMMIT      ── Commit + issue comment + close (or report)
```

Iteration budget: Wave 5 and Wave 7 share a maximum of **5 iterations** total.

## Step-by-Step Process

### Wave 1: VALIDATE

Load the issue via the GitHub CLI:

```bash
gh issue view <ISSUE_NUMBER> --json title,body,labels,comments,assignees
```

Start **two Explore sub-agents in parallel** for independent validation.
Start agents according to `../../references/agent-invocation.md`.

**Agent 1: Analyzer**
Read `agents/analyzer.md` and pass:
- The complete issue text (title, body, comments, labels)
- The task of finding relevant files and locating the bug

**Agent 2: Validator**
Read `agents/validator.md` and pass:
- The complete issue text (title, body, comments, labels)
- Do NOT pass the Analyzer's results — the Validator must assess independently

Wait for both agents to complete, then evaluate their verdicts:

| Analyzer | Validator | Action |
|----------|-----------|--------|
| CONFIRMED | CONFIRMED | Continue → Wave 2 (consolidated analysis from both) |
| CONFIRMED | NOT_CONFIRMED | Continue → Wave 2 (Analyzer analysis as basis, Validator doubts documented as risk context) |
| NOT_CONFIRMED | CONFIRMED | Continue → Wave 2 (Validator analysis as basis, Analyzer doubts documented as risk context) |
| NOT_CONFIRMED | NOT_CONFIRMED | **User-Gate** → ask user to confirm. If confirmed: comment on issue + close → STOP |

**If stopping (both NOT_CONFIRMED):**
1. Show the user both agents' assessments
2. Ask: "Both analysis agents could not confirm this issue. Should I comment on the issue and close it?"
3. If user agrees: Post comment using template from `references/issue-comments.md` (Issue Invalidated), then close:
   ```bash
   gh issue comment <NUMBER> --body "<COMMENT>"
   gh issue close <NUMBER> --reason "not planned"
   ```
4. End the workflow

### Wave 2: PLAN

Start a **Plan sub-agent** with the consolidated validation results.
Read `agents/planner.md` and pass:
- The analysis results (affected files, root cause) from the confirming agent(s)
- The original issue text
- Any dissenting assessment as risk context

The Planner returns:
- Ordered list of necessary changes
- Risk assessment per change
- Comprehensive test strategy (reproduction test + regression tests)
- Overall risk assessment

**User-Gate:** Present the plan to the user and wait for confirmation
before proceeding.

### Branch Creation

After the user approves the plan, create the feature branch:

```bash
git checkout -b fix/issue-<NUMBER>
```

All code-changing agents from this point work on this branch.

### Wave 3: TEST-FIRST

Start a **code-changing Test-Writer agent** in reproduction mode.
Read `agents/test-writer.md` and pass:
- **MODE**: `reproduction`
- **TEST_PLAN**: The test strategy from the Planner
- **ISSUE_SUMMARY**: Issue description
- **ROOT_CAUSE**: Root cause from analysis
- **AFFECTED_FILES**: Files involved in the bug
- **EXPECTED_FAILURE**: How the test should fail

The Test-Writer writes a minimal reproduction test and runs it.

**Evaluate the result:**

| Test Result | Action |
|-------------|--------|
| **Test FAILS** | Bug confirmed via test. Continue → Wave 4 |
| **Test PASSES** | Bug may already be fixed. **User-Gate**: "The reproduction test passes immediately. The bug appears to be already fixed. Should I comment on the issue and close it?" If yes: use Issue Invalidated template → close → STOP |
| **Test won't compile** | Test-Writer retries (max 3 attempts). If still broken → STOP, report to user |

### Wave 4: FIX

Start a **code-changing Coder agent** to implement the fix.
Read `agents/coder.md` and pass:
- **Fix Plan**: From the Planner
- **Root Cause**: From the analysis
- **Affected Files**: From the analysis
- **Issue Number**: For reference
- **Reproduction Test**: Path and name of the failing test

The Coder implements the fix and runs the reproduction test.

**Evaluate the result:**

| Result | Action |
|--------|--------|
| Reproduction test PASSES + full suite PASSES | Continue → Wave 5 |
| Reproduction test FAILS | Coder retries (max 3 attempts). If still red → STOP, report to user with diagnostics |
| Full suite has regressions | Coder fixes regressions (within the 3-attempt budget) |

### Wave 5: REVIEW-FIX LOOP

Initialize iteration counter: `iteration = 0`
Initialize active reviewers: `active = [logic, security, quality, architecture]`

**Loop start (while iteration < 5 and active is not empty):**

1. Start all **active reviewer agents in parallel** (Explore mode).
   For each reviewer, read the corresponding agent file from `agents/` and pass:
   - **PROJECT_ROOT**: Path to the project
   - **CHANGED_FILES**: All files changed on the fix branch
   - **ISSUE_SUMMARY**: Original issue description
   - **FIX_DESCRIPTION**: What the fix does
   - **BRANCH**: The fix branch name

   Reviewer agents:
   - `agents/logic-reviewer.md` → Logic Reviewer
   - `agents/security-reviewer.md` → Security Reviewer
   - `agents/quality-reviewer.md` → Quality Reviewer
   - `agents/architecture-reviewer.md` → Architecture Reviewer

2. Wait for all active reviewers to complete.

3. **Consolidate findings:**
   - Collect all findings from all reviewers
   - Deduplicate: findings targeting the same file + line range + problem
     are merged (highest severity wins, both recommendations preserved)
   - See `references/finding-format.md` for consolidation rules

4. **If no findings:** Exit loop → Continue to Wave 6

5. **If findings exist:**
   - Group findings by file path
   - Start **Fixer agents in parallel** (one per file group, code-changing mode)
   - For each Fixer, read `agents/fixer.md` and pass:
     - **FILE_LIST**: Only the files in this group
     - **FINDINGS**: The findings for these files
   - Wait for all Fixers to complete

6. **Run the full test suite** to verify no regressions from fixes:
   ```bash
   # Use the project's test runner
   # All tests must pass
   ```
   If tests fail: the failing tests become additional findings for the next round

7. **Update active reviewers:**
   - `active` = only the reviewers that produced findings in this round
   - Reviewers that reported "No findings" are excluded from the next round

8. `iteration += 1`

**Loop end**

If the loop exits because `iteration >= 5` with remaining findings:
→ Skip to Wave 8 (report mode — no commit)

### Wave 6: HARDEN

Start a **code-changing Test-Writer agent** in hardening mode.
Read `agents/test-writer.md` and pass:
- **MODE**: `hardening`
- **TEST_PLAN**: The test strategy from the Planner
- **ISSUE_SUMMARY**: Issue description
- **AFFECTED_FILES**: Files involved in the fix
- **FIX_SUMMARY**: What the Coder changed
- **REVIEW_CONTEXT**: Key findings from the review loop (if any)

The Test-Writer writes regression and edge-case tests, then runs the
full test suite.

**If tests fail:** Test-Writer fixes the tests (max 3 attempts).
If still failing → STOP, report to user.

### Wave 7: ACCEPTANCE

Start **all 4 reviewer agents in parallel** (same as Wave 5, Round 1)
for a final review of the complete state: all code changes AND all tests.

**Evaluate the result:**

| Result | Action |
|--------|--------|
| No findings from any reviewer | Continue → Wave 8 (commit mode) |
| Findings exist | `iteration += 1`, feed findings back into Wave 5 loop. If iteration budget exhausted (>= 5 total across Wave 5 + 7) → Wave 8 (report mode) |

### Wave 8: COMMIT or REPORT

**If all findings are resolved (commit mode):**

1. Show the user a summary:
   - Which files were changed
   - What the fix does
   - Reproduction test + hardening tests written
   - Review results (all clean)
2. **User-Gate:** "Fix is ready. Should I commit, comment on the issue, and close it?"
3. If user agrees:
   a. Post comment on the issue using the Issue Resolved template from
      `references/issue-comments.md`
   b. Create the commit following `references/commit-conventions.md`:
      ```bash
      git add <changed-files>
      git commit -m "fix: <description>

      <Root cause and fix explanation>

      Fixes #<NUMBER>"
      ```
   c. Ask whether to push and create a PR

**If open findings remain (report mode):**

1. Present a detailed report to the user:
   - All remaining findings with severity, file, and description
   - Which review rounds were completed
   - What was fixed vs what remains open
   - The current state of the code on the branch
2. Do NOT commit. Do NOT comment on the issue. Do NOT close the issue.
3. The user decides how to proceed.

## Error Handling

- If `gh` is not installed: Try `curl` with the GitHub API, or ask the
  user to paste the issue description.
- If tests are not found: Ask the user for the test command.
- If an agent does not respond within 5 minutes: Inform the user which
  agent is unresponsive and which area is affected. Offer to skip.
- If the reproduction test cannot be written (no test framework detected):
  Ask the user for the test framework and conventions.

## Notes

- Always create a separate branch, never work directly on main/master.
- Never commit without successful verification from all reviewers.
- Inform the user about progress at each wave transition.
- When in doubt: better to ask than to guess.
- The iteration budget (max 5) is shared between Wave 5 and Wave 7.
