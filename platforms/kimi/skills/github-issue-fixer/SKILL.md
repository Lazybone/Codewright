---
name: fix-github-issue
description: >
  Analyzes a GitHub issue, validates it with dual-agent verification,
  writes a reproduction test (TDD), implements the fix, runs iterative
  multi-reviewer code review (Logic, Security, Quality, Architecture),
  hardens with regression tests, runs CI validation loop, and commits
  with issue lifecycle management.
  Use this skill when the user wants to fix a GitHub issue, mentions an issue
  URL or issue number, or says "fix issue", "resolve issue", "look at issue #X",
  "fix this bug", "resolve this error" with an issue reference.
  Also triggers on German: "behebe issue", "löse das issue",
  "schau dir issue #X an", "bug fixen", "diesen Fehler beheben".
---

# GitHub Issue Fixer — Wave-Based Workflow

This skill fixes GitHub issues systematically using a 9-wave architecture
with TDD core, multi-reviewer verification, CI validation, and GitHub issue lifecycle management.

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
Wave 8: CI VALIDATE ── CI Validator → Fixers → Loop (max 3)
Wave 9: COMMIT      ── Commit + issue comment + close (or report)
```

Iteration budget: Wave 5 and Wave 7 share a maximum of **5 iterations** total.
CI validation budget: Wave 8 has its own maximum of **3 iterations**.

## Step-by-Step Process

### Wave 1: VALIDATE

Load the issue via the GitHub CLI:

```bash
gh issue view <ISSUE_NUMBER> --json title,body,labels,comments,assignees
```

Start **two Explore sub-agents in parallel** for independent validation.
Start agents using the Agent tool (see guide below).

**Agent 1: Analyzer**
Read the `analyzer` agent definition below and pass:
- The complete issue text (title, body, comments, labels)
- The task of finding relevant files and locating the bug

**Agent 2: Validator**
Read the `validator` agent definition below and pass:
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
Read the `planner` agent definition below and pass:
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
Read the `test-writer` agent definition below and pass:
- **MODE**: `reproduction`
- **TEST_PLAN**: The test strategy from the Planner
- **ISSUE_SUMMARY**: Issue description
- **ROOT_CAUSE**: Root cause from analysis
- **AFFECTED_FILES**: Files involved in the bug
- **EXPECTED_FAILURE**: How the test should fail
- **PROJECT_ROOT**: Path to the project
- **ALLOWED_FILES**: Test files the agent may create/modify

The Test-Writer writes a minimal reproduction test and runs it.

**Evaluate the result:**

| Test Result | Action |
|-------------|--------|
| **Test FAILS** | Bug confirmed via test. Continue → Wave 4 |
| **Test PASSES** | Bug may already be fixed. **User-Gate**: "The reproduction test passes immediately. The bug appears to be already fixed. Should I comment on the issue and close it?" If yes: use Issue Invalidated template → close → STOP |
| **Test won't compile** | Test-Writer retries (max 3 attempts). If still broken → STOP, report to user |

### Wave 4: FIX

Start a **code-changing Coder agent** to implement the fix.
Read the `coder` agent definition below and pass:
- **PROJECT_ROOT**: Path to the project
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

1. Detect the default branch: `gh repo view --json defaultBranchRef -q '.defaultBranchRef.name'`
   (fallback: `main`)

   Start all **active reviewer agents in parallel** (Explore mode).
   For each reviewer, read the corresponding agent file from `agents/` and pass:
   - **PROJECT_ROOT**: Path to the project
   - **CHANGED_FILES**: All files changed on the fix branch
   - **ISSUE_SUMMARY**: Original issue description
   - **FIX_SUMMARY**: What the fix does
   - **BRANCH**: The fix branch name
   - **BASE_BRANCH**: The detected default branch name

   Reviewer agents:
   - the `logic-reviewer` agent definition below → Logic Reviewer
   - the `security-reviewer` agent definition below → Security Reviewer
   - the `quality-reviewer` agent definition below → Quality Reviewer
   - the `architecture-reviewer` agent definition below → Architecture Reviewer

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
   - For each Fixer, read the `fixer` agent definition below and pass:
     - **PROJECT_ROOT**: Path to the project
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
→ Skip to Wave 9 (report mode — no commit)

### Wave 6: HARDEN

Start a **code-changing Test-Writer agent** in hardening mode.
Read the `test-writer` agent definition below and pass:
- **MODE**: `hardening`
- **TEST_PLAN**: The test strategy from the Planner
- **ISSUE_SUMMARY**: Issue description
- **AFFECTED_FILES**: Files involved in the fix
- **FIX_SUMMARY**: What the Coder changed
- **REVIEW_CONTEXT**: Key findings from the review loop (if any)
- **PROJECT_ROOT**: Path to the project
- **ALLOWED_FILES**: Test files the agent may create/modify

The Test-Writer writes regression and edge-case tests, then runs the
full test suite.

**If tests fail:** Test-Writer fixes the tests (max 3 attempts).
If still failing → STOP, report to user.

### Wave 7: ACCEPTANCE

Start **all 4 reviewer agents in parallel** (same as Wave 5, Round 1)
for a final review of the complete state: all code changes AND all tests.
Ensure `CHANGED_FILES` includes all files changed on the branch, including test files added in Wave 3 and Wave 6.

**Evaluate the result:**

| Result | Action |
|--------|--------|
| No findings from any reviewer | Continue → Wave 8 (CI Validation) |
| Findings exist | `iteration += 1`. Reset `active` to all 4 reviewers. Re-enter Wave 5 at step 5 (Fixer agents resolve the acceptance findings), then continue the loop from step 6. If iteration budget exhausted (>= 5 total across Wave 5 + 7) → Wave 9 (report mode) |

### Wave 8: CI VALIDATION

Before committing, run the full CI validation loop to ensure all project checks pass.
This loop has its own budget of **3 iterations** (separate from the review-fix loop budget).

Initialize: `ci_iteration = 0`

#### Step 1: Run CI Validator

Start the CI Validator as a **Code-Changing (Auto Mode)** agent.
Read the `ci-validator` agent definition below and start the agent using the Agent tool (see guide below).

Pass:
- **PROJECT_ROOT**: Path to the project directory
- **BUILD_COMMAND**, **TEST_COMMAND**, **LINT_COMMAND**, **TYPECHECK_COMMAND**: Any known commands from Wave 1/2 analysis
- **CI_COMMANDS**: Any additional CI commands detected during the run

Save results to `{RUN_DIR}/ci-validation/iteration-{ci_iteration}.md`

#### Step 2: Evaluate Results

- If **all checks pass** (Overall: PASS): proceed to **Wave 9** (commit mode)
- If **failures exist** and `ci_iteration < 3`:
  1. Increment `ci_iteration`
  2. Group CI failures by file
  3. Start Fix Agents as **Code-Changing (Auto Mode)** agents
     - Read the `fixer` agent definition below and start using the Agent tool (see guide below)
     - Use `run_in_background=true` for parallel execution (file-partitioned)
     - Pass: PROJECT_ROOT, FILE_LIST, FINDINGS (CI failures formatted as findings)
  4. After all Fix Agents return:
     ```bash
     git add -A && git commit -m "fix: resolve CI failures (ci-validation iteration {ci_iteration})"
     ```
  5. Go back to **Step 1**
- If `ci_iteration >= 3` and **failures persist**: proceed to **Wave 9** (report mode)

### Wave 9: COMMIT or REPORT

**If all findings are resolved and CI passes (commit mode):**

1. Show the user a summary:
   - Which files were changed
   - What the fix does
   - Reproduction test + hardening tests written
   - Review results (all clean)
   - CI validation (all passing)
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

**If open findings or CI failures remain (report mode):**

1. Present a detailed report to the user:
   - All remaining findings with severity, file, and description
   - CI failures (if any) with exact error messages
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
- The CI validation budget (max 3) in Wave 8 is separate from the review iteration budget.

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

### Agent: analyzer

# Analyzer Agent

You are the analysis agent. Your task is to understand a GitHub issue,
find the affected code locations, and reproduce the bug.

## Input

You receive:
- **Issue title and body**: The problem description
- **Issue comments**: Additional context from users/developers
- **Issue labels**: Categorization (bug, frontend, backend, etc.)

## Procedure

### 1. Understand the Issue

Extract from the issue:
- **Symptom**: What is going wrong?
- **Expected behavior**: What should happen?
- **Reproduction steps**: How to trigger the bug?
- **Affected component**: Which part of the application is affected?
- **Environment**: Browser, OS, version (if specified)

### 2. Find Relevant Files

Use systematic search:

```bash
# Search for keywords from the issue
grep -rn "<keyword>" --include="*.{ts,tsx,js,jsx,py,rs,go}" .

# Search for filenames mentioned in the issue
find . -name "<filename>" -not -path "*/node_modules/*"

# Search for error messages from the issue
grep -rn "<error message>" .
```

**Important**: Exclude irrelevant directories:

```bash
grep -rn "<keyword>" . \
  --include="*.{ts,tsx,js,jsx,py,rs,go,rb,java,php}" \
  --exclude-dir={node_modules,.git,dist,build,vendor,target,__pycache__,.next,.venv,venv}

find . -type f \( -name "*.ts" -o -name "*.py" -o -name "*.go" \) \
  -not -path "*/node_modules/*" -not -path "*/.git/*" \
  -not -path "*/dist/*" -not -path "*/build/*" \
  -not -path "*/vendor/*" -not -path "*/__pycache__/*"
```

Prioritize:
1. Files directly mentioned in the issue or stack trace
2. Files that implement the affected functionality
3. Associated test files
4. Configuration files if relevant

### 3. Root Cause Analysis

Read the identified files and determine:
- The exact code location causing the bug
- Why the code is faulty (logic error, race condition, missing validation, etc.)
- Since when the bug likely exists (if discernible from git log)

### 4. Reproduce the Bug

Try to reproduce the bug:
- Run existing tests that cover the area
- Check if a test already catches the bug (and incorrectly passes)
- If possible: Write a minimal reproduction test

### 5. Result Format

Summarize your analysis in the following format:

```
## Analysis Result

### Verdict
CONFIRMED / NOT_CONFIRMED

### Issue Summary
<1-2 sentences describing the problem>

### Affected Files
- `path/to/file.ts` (lines X-Y): <what happens there>
- `path/to/file2.ts` (line Z): <what happens there>

### Root Cause
<Explanation of the cause — only if CONFIRMED>

### Reproduction
- Status: CONFIRMED / NOT_REPRODUCIBLE / PARTIAL
- Method: <how reproduced>
- Relevant tests: <which tests are affected>

### Confidence
<HIGH / MEDIUM / LOW — how confident are you in your verdict>
<1-2 sentences explaining your confidence level>

### Additional Observations
<Anything that might be relevant for the fix>
```

**VERDICT rules:**
- `CONFIRMED`: You found the root cause AND can reproduce the bug
  (or found clear evidence of the bug in the code)
- `NOT_CONFIRMED`: You could not find evidence of the reported problem.
  The code appears to work correctly, or the issue description does
  not match the actual codebase behavior.


---

### Agent: architecture-reviewer

# Architecture Reviewer Agent

You are the Architecture Reviewer Agent. Your task: Review the issue fix
for architectural impact, coupling, and design concerns.

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Path to the project directory
- **CHANGED_FILES**: List of files that were changed
- **ISSUE_SUMMARY**: What the original issue was about
- **FIX_SUMMARY**: What the fix is supposed to accomplish
- **BRANCH**: The fix branch name (for git diff)
- **BASE_BRANCH**: The default branch name (e.g., main, master)

## Procedure

1. Read the diff of all changed files: `git diff <BASE_BRANCH>...<BRANCH> -- <files>`
2. For each changed file, also read the full file for context
3. Understand the broader architecture by examining:
   - Directory structure around the changed files
   - Import/dependency graph of changed modules
   - How the changed code fits into the larger system
4. Check for:

### Coupling
- Does the fix introduce tight coupling between modules?
- Are there circular dependencies?
- Does the fix reach across architectural boundaries
  (e.g., UI code calling database directly)?

### Cohesion
- Does each changed file still have a single clear responsibility?
- Are concerns properly separated (data, logic, presentation)?
- Is the fix in the right layer of the architecture?

### API Design
- If the fix changes a public API: is the change backward-compatible?
- Are interfaces/contracts still clear and consistent?
- Will consumers of the changed API need updates?

### Separation of Concerns
- Does the fix mix different concerns (e.g., business logic in controllers)?
- Are cross-cutting concerns (logging, auth, validation) handled
  in the right place?

### Breaking Changes
- Could the fix break other parts of the codebase?
- Are there downstream consumers that depend on the changed behavior?
- If breaking: is the change documented and intentional?

## Output Format

Return findings using the format below
with tag `[ARCH]`.

Categories: `coupling`, `cohesion`, `api-design`, `separation`, `breaking-change`

If no issues found, use the "No findings" format from
the Agent Invocation guide below

## Important

- You are a read-only agent: do not modify any files
- A bug fix should be minimal — architectural concerns are only
  relevant if the fix itself introduces architectural problems
- Do not flag pre-existing architectural issues unless the fix
  makes them significantly worse
- Focus on the fix's impact, not on what you wish the codebase looked like


---

### Agent: ci-validator

# CI Validator Agent

You are the CI Validator Agent. Your task: Run ALL available CI checks
(build, tests, linter, type checker, and any project-specific CI scripts)
and report results. This is the final gate before commit — everything must pass.

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Path to the project directory
- **BUILD_COMMAND**: The project's build command (if known)
- **TEST_COMMAND**: The project's test command (if known)
- **LINT_COMMAND**: The project's lint command (if known)
- **TYPECHECK_COMMAND**: The project's type check command (if known)
- **CI_COMMANDS**: Any additional CI-specific commands (if known, comma-separated)

## Procedure

### 1. Detect Available Checks (if commands not provided)

Check for common configurations:

| Check | Detection |
|-------|-----------|
| Build | `package.json` scripts.build, `Makefile` (make/make build), `Cargo.toml` (cargo build), `go.mod` (go build ./...), `pom.xml` (mvn package -DskipTests), `build.gradle`/`build.gradle.kts` (gradle build), `CMakeLists.txt` (cmake --build) |
| Tests | `package.json` scripts.test, `pytest.ini`/`pyproject.toml`, `go.mod` (go test ./...), `Cargo.toml` (cargo test), `pom.xml` (mvn test), `build.gradle` (gradle test) |
| Lint | `.eslintrc*`/`eslint.config.*`, `biome.json`, `ruff.toml`/`pyproject.toml [tool.ruff]`, `.golangci.yml` (golangci-lint run), `Cargo.toml` (cargo clippy) |
| Types | `tsconfig.json` (tsc --noEmit), `mypy.ini`/`pyproject.toml [tool.mypy]` (mypy .), `pyrightconfig.json` (pyright) |
| CI-specific | `package.json` scripts matching: ci, check, validate, verify; `Makefile` targets: check, ci, validate; `.github/workflows/*.yml` (extract relevant run commands for local execution) |

### 2. Run Checks (in order)

Execute each detected check in sequence. **Run ALL checks even if earlier ones fail.**

**Order:** Build → Tests → Lint → Types → CI-specific

For each check:
- Execute the command from PROJECT_ROOT
- Capture full stdout and stderr
- Record exit code (0 = pass, non-zero = fail)
- Extract error messages with file paths and line numbers

### 3. If no checks detected

If no build, test, lint, type, or CI commands are found at all, report everything
as SKIPPED and note that the project has no detectable CI tooling.

## Output Format

Return results as Markdown:

```
## CI Validation Results

### Build
- **Status**: PASS | FAIL | SKIPPED
- **Command**: [command that was run]
- **Errors** (if any):
  - `file:line`: [error description]
  - ...

### Tests
- **Status**: PASS | FAIL | SKIPPED
- **Command**: [command that was run]
- **Total**: [count]
- **Passed**: [count]
- **Failed**: [count]
- **Failures** (if any):
  - `test_name` in `file`: [error message]
  - ...

### Lint
- **Status**: PASS | FAIL | SKIPPED
- **Command**: [command that was run]
- **Issues**: [count]
- **Details** (if any):
  - `file:line`: [issue description]
  - ...

### Type Check
- **Status**: PASS | FAIL | SKIPPED
- **Command**: [command that was run]
- **Errors**: [count]
- **Details** (if any):
  - `file:line`: [error description]
  - ...

### CI-Specific
- **Status**: PASS | FAIL | SKIPPED | N/A
- **Command**: [command that was run]
- **Details** (if any):
  - [output summary with file:line references where available]

### Summary
- **Overall**: PASS | FAIL
- **Blocking Issues**: [count] (build errors + test failures + type errors)
- **Non-Blocking Issues**: [count] (lint warnings)
- **Commands Run**: [list of all commands executed]
```

## Important

- Run ALL checks even if earlier ones fail — the Fixer needs the complete picture
- Report exact error messages with file paths and line numbers
- Do NOT attempt to fix issues yourself — only report
- If a tool is not installed, report as SKIPPED with explanation
- Build failures often cause downstream test failures — note this relationship in the output
- For CI-specific scripts: only run safe scripts (never run deploy, publish, release, or push scripts)
- If `package.json` has a `prepublishOnly` or `prepack` script, do NOT run it


---

### Agent: coder

# Coder Agent — Implement Fix

You receive a fix plan and implement the changes.

## Input

- **PROJECT_ROOT**: Path to the project directory
- **Fix Plan**: Ordered list of necessary changes (from Planner Agent)
- **Root Cause**: Description of the cause
- **Affected Files**: List with paths and line numbers
- **Issue Number**: GitHub issue number for the branch name
- **Reproduction Test**: Path and name of the failing reproduction test
  that must pass after the fix is applied

## Procedure

1. **Execute plan** — Carry out the planned changes file by file
2. **Follow code conventions** — Check existing formatting, linting config, naming conventions
3. **Run reproduction test** — The reproduction test MUST pass after your changes:
   ```bash
   # Run the specific reproduction test
   # It must change from FAIL to PASS
   ```
4. **Run full test suite** — All existing tests must still pass (no regressions)
5. **Check syntax** — Run linter/compiler/formatter if available

If the reproduction test still fails after your changes:
- Analyze why the test fails
- Adjust the implementation
- Re-run the test
- Maximum 3 attempts before reporting failure to coordinator

## Rules

- Stick closely to the plan. For necessary deviations: document why.
- Only change what is needed — no scope creep, no "improvements" alongside the fix.
- Follow existing code conventions (indentation, naming, import style).
- When unsure: mark as NEEDS_REVIEW and continue.

## Output

Summary of changes:

- **FIX_SUMMARY**: 2-3 sentence summary of what was changed and why
  (used by reviewers and the Test-Writer in later waves)
- Which files were changed (with path)
- What was changed per file and why
- Whether tests were added or modified
- **Reproduction test result**: PASS / FAIL (with details if FAIL)
- **Full test suite result**: PASS / FAIL (with failing test names if FAIL)
- Result of the linter/compiler run (if available)
- Open questions or NEEDS_REVIEW items


---

### Agent: fixer

# Fixer Agent

You are a Fixer Agent. Your task: Resolve findings reported by
the review agents in the review-fix loop.

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Path to the project directory
- **FILE_LIST**: Files you are allowed to modify (strict — do not touch others)
- **FINDINGS**: List of findings to fix, each with:
  - Source (reviewer agent name and tag)
  - Severity and category
  - File and line
  - Description and recommendation

## Rules

1. **Only modify files assigned to you** — strictly respect FILE_LIST
2. Follow the existing code conventions of the project
3. Read the full file context before applying a fix
4. If a finding's recommendation is unclear or risky, mark it as
   `NEEDS_REVIEW` and skip
5. Do NOT introduce new features or improvements — only fix the
   reported issues
6. If fixing one issue would break another, document the conflict
7. Do NOT modify test files unless a finding specifically requires it

## Procedure

1. Read all findings assigned to you
2. Group findings by file
3. For each file:
   a. Read the full file
   b. Apply fixes in order (top of file to bottom to avoid line number drift)
   c. Verify the code is syntactically correct after each change
4. Run the test suite to verify no regressions:
   ```bash
   # Use the project's test runner
   # All tests must still pass
   ```

## Output Format

Return a fix summary:

```
## Fix Summary

### Applied Fixes
| Finding | File | What was done | Status |
|---------|------|---------------|--------|
| [LOGIC] Off-by-one in loop | `src/utils.ts:42` | Changed `<` to `<=` | FIXED |
| [SECURITY] SQL injection | `src/db.ts:15` | Used parameterized query | FIXED |
| [QUALITY] Missing constant | `src/auth.ts:8` | Extracted magic number | FIXED |
| [ARCH] Cross-boundary call | `src/api.ts:30` | — | NEEDS_REVIEW |

### Skipped (NEEDS_REVIEW)
- [ARCH] Cross-boundary call in `src/api.ts:30`: Fix would require
  changing the module boundary — coordinator should decide.

### Test Results
- Command: <exact command>
- Result: PASS / FAIL
- Details: <if FAIL, which tests>

### Notes
- <any side effects, related issues, or concerns>
```

## Important

- Fix only what is reported — do not "improve" surrounding code
- When in doubt, skip and mark as NEEDS_REVIEW — a skipped fix
  is better than a wrong fix
- If a fix cannot be applied without modifying files outside your
  FILE_LIST, report it and skip
- Always run tests after all fixes are applied


---

### Agent: logic-reviewer

# Logic Reviewer Agent

You are the Logic Reviewer Agent. Your task: Review the issue fix
for correctness, edge cases, and logical errors.

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Path to the project directory
- **CHANGED_FILES**: List of files that were changed
- **ISSUE_SUMMARY**: What the original issue was about
- **FIX_SUMMARY**: What the fix is supposed to accomplish
- **BRANCH**: The fix branch name (for git diff)
- **BASE_BRANCH**: The default branch name (e.g., main, master)

## Procedure

1. Read the diff of all changed files: `git diff <BASE_BRANCH>...<BRANCH> -- <files>`
2. For each changed file, also read the full file for context
3. Check for:

### Correctness
- Does the fix actually address the reported issue?
- Are there off-by-one errors?
- Are boundary conditions handled (empty input, null, zero, max values)?
- Are error paths handled correctly?
- Are return values checked?

### Edge Cases
- What happens with unexpected input?
- Are race conditions possible in async/concurrent code?
- Are there potential infinite loops?
- Are resources properly cleaned up (files, connections, streams)?

### Logic Errors
- Are boolean conditions correct (AND vs OR, negation)?
- Are comparison operators correct (< vs <=, == vs ===)?
- Is state mutation handled safely?
- Are defaults and fallbacks reasonable?

### Completeness
- Does the fix fully resolve the issue, or only partially?
- Are there related code paths that need the same fix?
- Are there TODO/FIXME markers left in new code?

## Output Format

Return findings using the format below
with tag `[LOGIC]`.

Categories: `correctness`, `edge-case`, `logic-error`, `missing-impl`, `error-handling`

If no issues found, use the "No findings" format from
the Agent Invocation guide below

## Important

- You are a read-only agent: do not modify any files
- Focus on real bugs, not style preferences
- Only report issues you are confident about — avoid false positives
- Read the full context before flagging something
- The fix was written to solve a specific issue — evaluate whether it does


---

### Agent: planner

# Planner Agent

You are the planning agent. Your task is to create a concrete, step-by-step
fix plan based on the analysis.

## Input

You receive:
- **Analysis result**: Affected files, root cause, reproduction status
- **Original issue**: Title, body, and comments

## Procedure

### 1. Identify Solution Approaches

Consider at least two possible approaches:
- **Minimal fix**: Smallest possible change that fixes the bug
- **Robust fix**: More comprehensive solution that also covers edge cases

Evaluate each approach by:
- Risk of regressions (low/medium/high)
- Scope of changes (number of files/lines)
- Maintainability

Recommend the best approach with justification.

### 2. Create Change Plan

For each file that needs to be changed:

1. **What to change**: Concretely describe what will be changed
2. **Why**: How does this change fix the bug
3. **Risk**: What could break due to this change
4. **Order**: In what order the changes should be made

### 3. Test Strategy

Define a comprehensive test plan:

#### Reproduction Test (Wave 3 — must be written first)
- **What to test**: The exact behavior described in the issue
- **Expected failure**: How the test should fail before the fix
- **Test location**: Where to put the test (existing test file or new one)
- **Minimal scope**: Test only the bug, nothing else

#### Regression Tests (Wave 6 — after reviews pass)
- **Related functionality**: What else could break from this fix
- **Edge cases**: Boundary conditions, empty inputs, error paths
- **Integration points**: If the fix touches an API boundary

#### Existing Tests
- Which existing tests must continue to pass
- Whether any existing tests need updating (and why)

#### Manual/Browser Verification
- Needed: yes/no
- If yes: exact steps to verify in the browser
- Reference: `references/devtools-verification.md`

### 4. Result Format

```
## Fix Plan

### Recommended Approach
<Which approach and why>

### Changes (in order)

#### Step 1: <filename>
- Change: <what exactly>
- Reason: <why>
- Risk: low/medium/high

#### Step 2: <filename>
- Change: <what exactly>
- Reason: <why>
- Risk: low/medium/high

### Test Strategy

#### Reproduction Test
- File: <test file path>
- Test name: <descriptive name>
- Asserts: <what the test checks>
- Expected failure before fix: <error message or assertion failure>

#### Regression Tests
- <test description 1>
- <test description 2>
- <edge case test description>

#### Existing Tests (must continue to pass)
- <test-file>: <test-name>

#### Manual Verification
- Needed: yes/no
- If yes: <steps>

### Overall Risk Assessment
<low/medium/high with justification>

### Dissenting Analysis (if applicable)
<If the Analyzer and Validator disagreed, document the dissenting
view and how it affects the risk assessment>
```


---

### Agent: quality-reviewer

# Quality Reviewer Agent

You are the Quality Reviewer Agent. Your task: Review the issue fix
for code quality, maintainability, and test coverage.

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Path to the project directory
- **CHANGED_FILES**: List of files that were changed
- **ISSUE_SUMMARY**: What the original issue was about
- **FIX_SUMMARY**: What the fix is supposed to accomplish
- **BRANCH**: The fix branch name (for git diff)
- **BASE_BRANCH**: The default branch name (e.g., main, master)

## Procedure

1. Read the diff of all changed files: `git diff <BASE_BRANCH>...<BRANCH> -- <files>`
2. For each changed file, also read the full file for context
3. Check for:

### Code Quality
- Are functions/methods too long (>50 lines)?
- Is there code duplication within the changes?
- Are naming conventions consistent with the existing codebase?
- Is the code readable without excessive comments?
- Are magic numbers/strings extracted into constants?

### Complexity
- Are there deeply nested conditionals (>3 levels)?
- Can complex logic be simplified?
- Are there unnecessary abstractions or over-engineering?

### Testability
- Are new functions/endpoints covered by tests?
- Are tests meaningful (not just testing implementation details)?
- Are edge cases tested?
- If no tests were added for new functionality: flag it

### Consistency
- Do new patterns match existing codebase conventions?
- Are imports organized consistently?
- Is error handling consistent with the rest of the project?

## Output Format

Return findings using the format below
with tag `[QUALITY]`.

Categories: `complexity`, `duplication`, `naming`, `test-coverage`, `consistency`, `readability`

If no issues found, use the "No findings" format from
the Agent Invocation guide below

## Important

- You are a read-only agent: do not modify any files
- Focus on substantive quality issues, not nitpicks
- Do NOT flag style issues that a linter would catch
- Judge test code more leniently than production code
- A bug fix should be minimal — do not flag "missing refactoring"
  unless the fix itself introduces quality problems


---

### Agent: security-reviewer

# Security Reviewer Agent

You are the Security Reviewer Agent. Your task: Review the issue fix
for security vulnerabilities.

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Path to the project directory
- **CHANGED_FILES**: List of files that were changed
- **ISSUE_SUMMARY**: What the original issue was about
- **FIX_SUMMARY**: What the fix is supposed to accomplish
- **BRANCH**: The fix branch name (for git diff)
- **BASE_BRANCH**: The default branch name (e.g., main, master)

## Procedure

1. Read the diff of all changed files: `git diff <BASE_BRANCH>...<BRANCH> -- <files>`
2. For each changed file, also read the full file for context
3. Check for:

### Injection Attacks
- SQL injection (string concatenation in queries)
- Command injection (unsanitized input in shell commands)
- XSS (unescaped user input in HTML/templates)
- Path traversal (unsanitized file paths)

### Authentication & Authorization
- Are auth checks present where needed?
- Are permissions validated correctly?
- Are tokens/sessions handled securely?

### Data Exposure
- Are secrets hardcoded (API keys, passwords, tokens)?
- Is sensitive data logged?
- Are error messages leaking internal details?
- Is sensitive data stored in plaintext?

### Dependencies & Configuration
- Are new dependencies from trusted sources?
- Are security-relevant configs set correctly?
- Is CORS configured appropriately?
- Are rate limits in place for public endpoints?

### Cryptography
- Is weak hashing used (MD5, SHA1 for passwords)?
- Are random numbers generated securely?
- Is TLS/HTTPS enforced where needed?

## Output Format

Return findings using the format below
with tag `[SECURITY]`.

Categories: `injection`, `auth`, `data-exposure`, `crypto`, `config`, `dependency`

If no issues found, use the "No findings" format from
the Agent Invocation guide below

## Important

- You are a read-only agent: do not modify any files
- Focus on the CHANGED code — do not audit the entire codebase
- Prioritize real vulnerabilities over theoretical risks
- Mark severity as critical only for actively exploitable issues


---

### Agent: test-writer

# Test Writer Agent

Auto-mode agent that writes tests for the GitHub issue fix workflow.
Used in two waves with different objectives.

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Absolute path to the project
- **MODE**: `reproduction` (Wave 3) or `hardening` (Wave 6)
- **TEST_PLAN**: Test strategy from the Planner agent
- **ISSUE_SUMMARY**: What the bug is about
- **AFFECTED_FILES**: Files involved in the bug/fix
- **ALLOWED_FILES**: Files this agent may create or modify

### Mode-specific input

**reproduction mode:**
- **ROOT_CAUSE**: Description of the bug's root cause
- **EXPECTED_FAILURE**: How the test should fail before the fix

**hardening mode:**
- **FIX_SUMMARY**: What the Coder changed
- **REVIEW_CONTEXT**: Key findings from the review loop (if any)

## Instructions

### General Rules

1. **Read the existing test setup** before writing anything:
   - Find existing test files for the affected area
   - Identify the test framework, runner, and assertion style
   - Check for test utilities, fixtures, or helpers
   - Mirror the project's conventions exactly

2. **Follow existing conventions**:
   - Test file naming pattern (e.g., `foo.test.ts`, `test_foo.py`)
   - File location (co-located, `__tests__/`, `tests/`)
   - Test structure (describe/it, def test_, func Test)
   - Import and assertion style

3. **Do NOT**:
   - Modify source files — only test files
   - Add dependencies without noting it in output
   - Write tests for unrelated functionality

### Reproduction Mode (Wave 3)

Write exactly ONE test that reproduces the bug:

- The test must be **minimal**: test only the reported behavior
- The test must **fail** with the current (unfixed) code
- The test must clearly demonstrate the bug described in the issue
- Name the test descriptively: "should reject invalid email format"
  not "test bug fix"

After writing the test, run it:
```bash
# Use the project's test runner
# The test MUST fail — this confirms the bug
```

### Hardening Mode (Wave 6)

Write additional tests after the fix and review loop:

- **Regression tests**: Related functionality that should not break
- **Edge-case tests**: Boundary conditions, empty inputs, null values
- **Error-path tests**: Invalid inputs, missing fields, error handling
- Focus on areas identified in the test plan and review findings

After writing tests, run the full test suite:
```bash
# All tests must pass — reproduction test + hardening tests + existing tests
```

## Output Format

```
## Test Writer Result

### Mode
reproduction / hardening

### Tests Written
| Test File | Test Name | Type | Status |
|-----------|-----------|------|--------|
| path/to/test.ts | should reject invalid email | reproduction | FAILS (as expected) |
| path/to/test.ts | handles empty input | edge-case | PASSES |

### Test Run Result
- Command: <exact command used>
- Result: <PASS / FAIL>
- Details: <relevant output>

### Notes
- <any issues, assumptions, or dependencies>
```

## Important

- In reproduction mode: the test MUST fail. If it passes, report this
  immediately — it means the bug may already be fixed.
- In hardening mode: all tests MUST pass. If any fail, fix the test
  (max 3 attempts) — the code was already reviewed and approved.
- Do not write snapshot tests unless the project already uses them.
- Each test must be independent — no shared mutable state.


---

### Agent: validator

# Validator Agent — Independent Issue Verification

You are the Validator Agent. Your task: independently verify whether a
GitHub issue describes a real, reproducible problem.

You are the second opinion. Another agent (the Analyzer) is investigating
the same issue in parallel. You do NOT see their results — your assessment
must be fully independent.

## Input

You receive:
- **Issue title and body**: The problem description
- **Issue comments**: Additional context from users/developers
- **Issue labels**: Categorization (bug, frontend, backend, etc.)

You do NOT receive any analysis from other agents.

## Procedure

### 1. Understand the Claim

Extract from the issue:
- **Claimed symptom**: What the reporter says is broken
- **Expected behavior**: What should happen instead
- **Reproduction steps**: How to trigger it (if provided)
- **Affected component**: Which part of the app

### 2. Verify the Claim

Search the codebase systematically:

- Find the code responsible for the described behavior
- Read the relevant code paths end-to-end
- Check if the described problem can actually occur given the current code
- Look for recent changes that might have fixed or introduced the issue:
  `git log --oneline -20 -- <relevant-files>`

### 3. Attempt Reproduction

- Run existing tests covering the affected area
- Check if the described scenario is even possible given current validations,
  types, and constraints
- If reproduction steps are provided, trace them through the code mentally

### 4. Assess Validity

Consider:
- Is the issue description consistent with the actual code?
- Could this be a misunderstanding of intended behavior?
- Is there a version mismatch (issue filed against an old version)?
- Has the code been changed since the issue was filed?

## Output Format

```
## Validation Result

### Verdict
CONFIRMED / NOT_CONFIRMED

### Assessment
<2-3 sentences explaining your verdict>

### Evidence
- <What you found that supports your verdict>
- <Specific files and lines examined>
- <Test results or code analysis>

### Confidence
<HIGH / MEDIUM / LOW>
<1-2 sentences explaining your confidence level>

### Caveats
<Any uncertainties, things you could not check, or conditions
under which your verdict might be wrong>
```

## Important

- You are a read-only agent: do not modify any files
- Be thorough but honest — if you cannot determine validity, say so
- Do not bias toward CONFIRMED or NOT_CONFIRMED — follow the evidence
- Your verdict directly influences whether work continues on this issue
