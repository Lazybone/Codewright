---
name: pr-reviewer
description: >
  Performs automated multi-perspective code review of a Pull Request using 3 parallel agents.
  Analyzes logic correctness, security implications, and code quality of the diff.
  Optionally posts the review as a GitHub PR comment.
  Use when the user wants a PR reviewed, mentions a PR URL or number, or says "review this PR".
  Triggers: "review PR", "review this pull request", "check PR #123", "code review",
  "review my changes", "what do you think of this PR".
  Also triggers on German: "PR reviewen", "Pull Request pruefen", "Code Review machen",
  "Aenderungen pruefen".
license: MIT
compatibility: opencode
metadata:
  platform: opencode
  codewright-version: "0.3.7"
  requires-plugin: "@codewright/opencode"
---

# PR Reviewer

Analyzes a Pull Request from 3 perspectives in parallel (logic, security, quality),
consolidates findings, and optionally posts the review as a GitHub comment.

## Prerequisites

This skill requires the `@codewright/opencode` plugin, which registers the `cw_agent`
tool at startup. Add `"@codewright/opencode"` to the `plugin` array in `opencode.json`.

## Workflow

```
Phase 0: Load PR → Phase 1: Parallel Review (3 Agents) → Phase 2: Consolidation → Phase 3: Present
```

## Phase 0: Load PR

1. **Determine PR number** from user input (number, URL, or current branch).
   If no PR is specified, detect via `gh pr view --json number`.
2. **Fetch PR data**:

```bash
gh pr view <NUMBER> --json title,body,files,additions,deletions,baseRefName,headRefName
gh pr diff <NUMBER>
```

3. **Validate**: If the diff is empty or the PR is already merged, inform the user and stop.
4. **Summarize** the PR for the agents: title, description, number of files changed, total lines changed.

## Phase 1: Parallel Review (3 Agents)

Use the `cw_agent` tool to spawn all 3 reviewers simultaneously.

Each agent receives the **same input**:
- The full PR diff
- The PR title and description
- The list of changed files

Call `cw_agent` with:

```
cw_agent({
  agents: [
    {
      name: "logic-reviewer",
      mode: "explore",
      prompt: "<LOGIC_REVIEWER_PROMPT>"
    },
    {
      name: "security-reviewer",
      mode: "explore",
      prompt: "<SECURITY_REVIEWER_PROMPT>"
    },
    {
      name: "quality-reviewer",
      mode: "explore",
      prompt: "<QUALITY_REVIEWER_PROMPT>"
    }
  ]
})
```

### Agent Prompts

Construct each agent's prompt by reading the agent definition file and appending the PR data.

**Logic Reviewer** — read `agents/logic-reviewer.md`, then append:

```
## Your Input

PR Title: <TITLE>
PR Description: <BODY>
Changed Files: <FILE_LIST>

## PR Diff

<FULL_DIFF>
```

**Security Reviewer** — read `agents/security-reviewer.md`, then append the same input block.

**Quality Reviewer** — read `agents/quality-reviewer.md`, then append the same input block.

**Important**: All 3 agents run as `mode: "explore"` — they do not modify anything.

## Phase 2: Consolidation

After the `cw_agent` tool returns results from all 3 agents:

1. **Deduplicate** — Merge findings that describe the same issue from different perspectives
2. **Assign severity**:
   - `blocking`: Must be fixed before merging (bugs, security holes, broken logic)
   - `suggestion`: Should be fixed, improves quality significantly
   - `nitpick`: Optional improvement, stylistic preference
3. **Sort**: blocking → suggestion → nitpick
4. **Count**: Total findings per severity level

## Phase 3: Present Review

Show the consolidated review to the user in this format:

```markdown
# PR Review: <PR Title> (#<number>)

**Summary**: <1-2 sentence overview of the review>
**Verdict**: APPROVE / REQUEST_CHANGES / COMMENT

| Severity | Count |
|----------|-------|
| Blocking | X |
| Suggestion | Y |
| Nitpick | Z |

---

## Blocking Issues

### [TAG] <title>
- **Severity**: blocking
- **File**: `path/to/file.ext` (line X-Y)
- **Description**: What is the issue?
- **Suggestion**: How to fix it

## Suggestions

...

## Nitpicks

...
```

Then ask the user:
- **Option A**: "Keep this review in the terminal only" (default)
- **Option B**: "Post as a GitHub PR review comment"

If Option B:
```bash
gh pr review <NUMBER> --comment --body "<REVIEW_BODY>"
# Or if blocking issues exist:
gh pr review <NUMBER> --request-changes --body "<REVIEW_BODY>"
# Or if no blocking issues:
gh pr review <NUMBER> --approve --body "<REVIEW_BODY>"
```

## Verdict Logic

- **REQUEST_CHANGES**: 1 or more blocking findings
- **APPROVE**: 0 blocking findings and 0-2 suggestions
- **COMMENT**: 0 blocking findings but 3+ suggestions

## Important Notes

- Keep reviews constructive — suggest fixes, do not just criticize
- Distinguish blocking issues from nitpicks clearly
- If no findings at all: Approve with a short positive note
- PR diff is the single source of truth — agents review only changed code
- Do not re-review code that was not changed in this PR
