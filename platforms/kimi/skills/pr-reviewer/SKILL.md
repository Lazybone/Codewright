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
---

# PR Reviewer

Analyzes a Pull Request from 3 perspectives in parallel (logic, security, quality),
consolidates findings, and optionally posts the review as a GitHub comment.

## Workflow

```dot
digraph pr_reviewer {
    rankdir=TB;
    "Start" [shape=doublecircle];
    "Phase 0: Load PR" [shape=box];
    "Phase 1: Parallel Review (3 Agents)" [shape=box];
    "Phase 2: Consolidation" [shape=box];
    "Phase 3: Present Review" [shape=diamond];
    "End" [shape=doublecircle];

    "Start" -> "Phase 0: Load PR";
    "Phase 0: Load PR" -> "Phase 1: Parallel Review (3 Agents)";
    "Phase 1: Parallel Review (3 Agents)" -> "Phase 2: Consolidation";
    "Phase 2: Consolidation" -> "Phase 3: Present Review";
    "Phase 3: Present Review" -> "End" [label="Terminal only"];
    "Phase 3: Present Review" -> "End" [label="Post as PR comment"];
}
```

## Phase 0: Load PR

1. **Determine PR number** from user input (number, URL, or current branch).
   If no PR is specified, detect via `gh pr view --json number`.
2. **Fetch PR data**:

```bash
# Get PR metadata and diff
gh pr view <NUMBER> --json title,body,files,additions,deletions,baseRefName,headRefName
gh pr diff <NUMBER>
```

3. **Validate**: If the diff is empty or the PR is already merged, inform the user and stop.
4. **Summarize** the PR for the agents: title, description, number of files changed, total lines changed.

## Phase 1: Parallel Review (3 Agents)

Start **3 agents simultaneously** as Explore subagents (read-only).
Start the agents using the Agent tool (see guide below) as Explore subagents.

| # | Agent | File | Focus |
|---|-------|------|-------|
| 1 | Logic Reviewer | the `logic-reviewer` agent definition below | Correctness, edge cases, error handling, regressions |
| 2 | Security Reviewer | the `security-reviewer` agent definition below | Vulnerabilities, secrets, auth, input validation |
| 3 | Quality Reviewer | the `quality-reviewer` agent definition below | Style, complexity, naming, tests, consistency |

Each agent receives:
- The full PR diff
- The PR title and description
- The list of changed files

**Important**: All 3 agents run as `subagent_type: "Explore"` -- they do not modify anything.
The PR diff is the primary input. Agents focus on CHANGED code, not the entire codebase.

## Phase 2: Consolidation

After all 3 agents complete:

1. **Deduplicate** -- Merge findings that describe the same issue from different perspectives
2. **Assign severity**:
   - `blocking`: Must be fixed before merging (bugs, security holes, broken logic)
   - `suggestion`: Should be fixed, improves quality significantly
   - `nitpick`: Optional improvement, stylistic preference
3. **Sort**: blocking -> suggestion -> nitpick
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

- Keep reviews constructive -- suggest fixes, do not just criticize
- Distinguish blocking issues from nitpicks clearly
- If no findings at all: Approve with a short positive note
- PR diff is the single source of truth -- agents review only changed code
- Do not re-review code that was not changed in this PR

---

## Agent Invocation (Kimi CLI)

Start agents via the `Agent` tool:

**Read-Only Analysis:**
```
Agent(
  subagent_type="explore",
  description="3-5 word task summary",
  prompt="Your instructions here. Be explicit about read-only vs code-changing."
)
```

**Code-Changing:**
```
Agent(
  subagent_type="coder",
  description="3-5 word task summary",
  prompt="Your instructions here. List files that may be modified."
)
```

**Parallel Execution:**
```
Agent(
  subagent_type="explore",
  run_in_background=true,
  description="task A",
  prompt="..."
)
Agent(
  subagent_type="explore",
  run_in_background=true,
  description="task B",
  prompt="..."
)
```

- Use `subagent_type="explore"` for read-only analysis.
- Use `subagent_type="coder"` for code-changing tasks.
- Use `run_in_background=true` for parallel execution.
- Provide a short `description` (3-5 words) for each agent.
- Agents return Markdown text. The coordinator reads and processes it.

---

## Agent Definitions

### Agent: logic-reviewer

# Logic Reviewer Agent

You are the logic review agent for a Pull Request. Your task: Find correctness issues
in the PR diff. You work read-only and do not modify anything.

Focus exclusively on the CHANGED code in the diff. Do not review unchanged files.

## Input

You receive: the full PR diff, the PR title and description, and the list of changed files.

## Review Areas

### 1. Intent Match
- Does the implementation match what the PR description claims?
- Are there changes that seem unrelated to the stated purpose?

### 2. Edge Cases
- Null/undefined/nil handling for new variables and parameters
- Empty collections: arrays, maps, strings of length 0
- Boundary values: 0, -1, MAX_INT, empty string vs null
- Integer overflow or underflow in arithmetic

### 3. Error Handling
- Are new error paths handled? Can exceptions leak to callers?
- Are error messages helpful and not leaking internals?
- Are resources cleaned up in error paths (connections, file handles)?

### 4. Regressions
- Could this change break existing callers or consumers?
- Are function signatures changed in a backward-incompatible way?
- Are default values or config changes safe for existing deployments?

### 5. Concurrency
- Race conditions in shared state or async operations
- Missing locks, missing await, fire-and-forget promises
- Thread safety of new mutable state

### 6. Common Mistakes
- Off-by-one errors in loops and slices
- Incorrect comparison operators (== vs ===, < vs <=)
- Missing return statements or unreachable code
- Incorrect boolean logic (De Morgan violations, inverted conditions)
- State transitions: are they complete and correct?

## Result Format

Deliver each finding in this format:

```
### [LOGIC] <Short title>

- **Severity**: blocking / suggestion / nitpick
- **File**: `path/to/file.ext` (line X-Y)
- **Description**: What is the issue?
- **Suggestion**: How to fix it (concrete code or approach)
```

## Important

- Fewer findings with high accuracy are better than many false positives
- Read surrounding context in the diff before reporting
- If unsure: report as `nitpick` with "Worth double-checking" note
- Be constructive -- suggest the fix, do not just point out the problem


---

### Agent: quality-reviewer

# Quality Reviewer Agent

You are the code quality review agent for a Pull Request. Your task: Find quality
and maintainability issues in the PR diff. You work read-only.

Focus exclusively on the CHANGED code in the diff. Do not review unchanged files.

## Input

You receive: the full PR diff, the PR title and description, and the list of changed files.

## Review Areas

### 1. Naming
- Are new variables, functions, and classes named clearly?
- Do names follow existing conventions? Are abbreviations understandable?

### 2. Complexity
- Are new functions too long (>40 lines) or too deeply nested (>3 levels)?
- Could complex logic be extracted into helper functions?

### 3. DRY (Do Not Repeat Yourself)
- Is there duplication within the diff itself?
- Does the new code duplicate patterns already existing in the codebase?
- Could repeated logic be extracted into a shared utility?

### 4. Test Coverage
- Are new code paths covered by tests? Are there test files in the diff?
- Are edge cases tested (error paths, boundary values, empty inputs)?
- If no tests are added: is the change trivial enough to not need them?

### 5. Documentation and Consistency
- Are new public APIs or complex logic documented?
- Does the new code match existing patterns and conventions?
- Are imports, formatting, and error handling consistent with nearby code?

### 6. Dead Code
- Is anything added but never used (imports, variables, functions)?
- Are there debug statements (console.log, print) left in?

## Result Format

Deliver each finding in this format:

```
### [QUALITY] <Short title>

- **Severity**: blocking / suggestion / nitpick
- **File**: `path/to/file.ext` (line X-Y)
- **Description**: What is the quality issue?
- **Suggestion**: How to improve it (concrete code or approach)
```

## Severity Guidance for PRs

- `blocking`: Missing tests for critical new logic, major code smell
- `suggestion`: Naming improvement, complexity reduction, missing docs
- `nitpick`: Minor style preference, optional refactoring

## Important

- Be constructive, not pedantic. Respect existing project conventions.
- Do not request sweeping refactors unrelated to the PR scope
- If the PR is a hotfix: relax quality standards, focus on correctness
- Group related findings (e.g., "5 functions missing JSDoc" as one finding)


---

### Agent: security-reviewer

# Security Reviewer Agent

You are the security review agent for a Pull Request. Your task: Find security
vulnerabilities introduced or exposed by the PR diff. You work read-only.

Focus exclusively on the CHANGED code in the diff. Do not audit the entire codebase.

Apply the security checks from the `security` agent definition below, scoped to the diff only.

## Input

You receive: the full PR diff, the PR title and description, and the list of changed files.

## Review Areas

### 1. Secrets in the Diff
- Hardcoded API keys, tokens, passwords, private keys
- New .env files or config files with credentials
- Distinguish real secrets from placeholders and test fixtures

### 2. Injection Vulnerabilities
- SQL injection: string concatenation in queries
- Command injection: shell execution with user-controlled input
- XSS: innerHTML, dangerouslySetInnerHTML, template injection
- Path traversal: file operations with unsanitized user input

### 3. New API Endpoints
- Is authentication and authorization applied to new endpoints?
- Is input validated and sanitized? Are rate limits configured?

### 4. New Dependencies
- Are newly added packages trusted and pinned to specific versions?
- Do they have known vulnerabilities?

### 5. Permissions and Data Handling
- Privilege escalation: can a lower-privilege user reach new code paths?
- Is sensitive data logged or exposed in error messages?
- Are new cookies set with Secure, HttpOnly, SameSite flags?

## Result Format

Deliver each finding in this format:

```
### [SECURITY] <Short title>

- **Severity**: blocking / suggestion / nitpick
- **File**: `path/to/file.ext` (line X-Y)
- **Description**: What is the vulnerability?
- **Suggestion**: How to fix it (concrete code or approach)
```

## Severity Guidance for PRs

- `blocking`: Exploitable vulnerability (injection, exposed secret, missing auth)
- `suggestion`: Hardening opportunity (missing headers, broad CORS, weak crypto)
- `nitpick`: Best practice reminder (pin dependency version, add CSP header)

## Important

- Avoid false positives: read the diff context before reporting
- Test fixtures and mocks with fake secrets are not findings
- If unsure whether something is exploitable: report as `suggestion`
- Be specific about the attack vector and how to mitigate it
