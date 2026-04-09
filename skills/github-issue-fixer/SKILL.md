---
name: fix-github-issue
description: >
  Analyzes a GitHub issue, reproduces the bug, creates a fix plan, implements the fix,
  verifies the solution and commits the result. Use this skill when the user wants to
  fix a GitHub issue, mentions an issue URL or issue number, or says "fix issue",
  "resolve issue", "look at issue #X", "fix this bug", "resolve this error" with an
  issue reference. Works with sub-agent teams for parallel analysis and verification.
  Can use MCP Google DevTools for browser-based verification.
  Also triggers on German: "behebe issue", "löse das issue", "schau dir issue #X an",
  "bug fixen", "diesen Fehler beheben".
---

# GitHub Issue Fixer — Agent-Based Workflow

This skill fixes GitHub issues systematically in a multi-step process
using specialized sub-agents. Each agent has a clearly defined role.

## Prerequisites

- Git repository with configured remote
- GitHub CLI (`gh`) installed and authenticated
- Optional: MCP Google DevTools for browser-based verification

## Workflow Overview

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  1. ANALYZE │────▶│  2. PLAN     │────▶│  3. FIX     │
│  (Explore)  │     │  (Plan)      │     │  (Code)     │
└─────────────┘     └──────────────┘     └─────────────┘
                                               │
                    ┌──────────────┐            │
                    │  5. COMMIT   │◀───────────│
                    │  (main)      │     ┌─────────────┐
                    └──────────────┘     │  4. VERIFY  │
                          ▲              │  (Test)     │
                          │              └─────────────┘
                          │                    │
                          └────────────────────┘
                               (if OK)
```

## Step-by-Step Process

### Phase 1: Load & Analyze Issue

Load the issue via the GitHub CLI:

```bash
gh issue view <ISSUE_NUMBER> --json title,body,labels,comments,assignees
```

Then start an **Explore sub-agent** for codebase analysis.
Start the agent according to `../../references/agent-invocation.md`.
Read the instructions in `agents/analyzer.md` and pass to the agent:

- The complete issue text (title, body, comments)
- The task of finding relevant files and locating the bug
- The request to reproduce the bug (run tests, check logs)

The Analyzer returns:
- Affected files and code locations
- Reproduction status (bug confirmed yes/no)
- Root cause analysis

**If the bug is no longer reproducible**: Report this to the user and ask
whether the issue should be closed. End the workflow.

### Phase 2: Create Fix Plan

Start a **Plan sub-agent** with the results from Phase 1.
Start the agent according to `../../references/agent-invocation.md`.
Read `agents/planner.md` and pass:

- The analysis results (affected files, root cause)
- The original issue text

The Planner returns:
- Ordered list of necessary changes
- Risk assessment per change
- Suggested test strategy

Present the plan to the user and wait for confirmation before proceeding.

### Phase 3: Implement Fix

Implement the changes according to the plan. Work in the main agent:

1. Create a feature branch: `git checkout -b fix/issue-<NUMBER>`
2. Execute the planned changes file by file
3. Stick closely to the plan — inform the user of any deviations
4. Follow existing code conventions (linting, formatting)
5. Write or update tests for the fix

### Phase 4: Verification

Start verification via two parallel paths:

**4a. Automated Tests** — Run the test suite:
```bash
# Detect the test framework automatically
# npm test / pytest / cargo test / go test / etc.
```

**4b. Browser Verification (for UI bugs)** — If the issue involves
a visual or frontend problem, use MCP Google DevTools:

Read `references/devtools-verification.md` for the exact procedure.

Check after verification:
- All existing tests still pass (no regressions)
- The specific bug is fixed
- No new linting errors or warnings

**If verification fails**: Analyze the errors, adjust the fix,
and repeat Phase 4. Maximum 3 iterations, then involve the user.

### Phase 5: Commit & Wrap-up

Once all verifications have passed:

1. Stage the changes: `git add -A`
2. Create a meaningful commit:
   ```
   fix: <short description> (closes #<NUMBER>)

   <What was changed and why>

   Fixes #<NUMBER>
   ```
3. Show the user a summary:
   - Which files were changed
   - What the fix does
   - Test results
4. Ask whether to push and create a PR

## Error Handling

- If `gh` is not installed: Try to fetch the issue info via the GitHub API
  using `curl`, or ask the user to paste the issue description.
- If tests are not found: Ask the user for the test command.
- If the fix cannot be verified after 3 iterations: Stop and
  present the current state with the open problems to the user.

## Notes

- Always create a separate branch, never work directly on main/master.
- Never commit without successful verification.
- Inform the user about progress at each phase transition.
- When in doubt: Better to ask than to guess.
