# GitHub Issue Fixer Wave-Based Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the github-issue-fixer skill from a linear 5-phase workflow to an 8-wave architecture with TDD core, 4 parallel reviewers, iterative review-fix loop, and GitHub issue lifecycle management.

**Architecture:** Wave-based orchestration: Validate (dual-agent) → Plan → Test-First → Fix → Review-Fix Loop (max 5, 4 reviewers) → Harden → Acceptance → Commit/Report. All agents use the shared finding format and agent invocation standard from `references/`.

**Tech Stack:** Claude Code Agent tool, Markdown agent prompts, GitHub CLI (`gh`), Git

**Spec:** `docs/superpowers/specs/2026-04-19-github-issue-fixer-redesign.md`

---

## File Structure Overview

```
skills/github-issue-fixer/
  SKILL.md                          ← REWRITE (wave-based workflow)
  agents/
    analyzer.md                     ← MODIFY (add VERDICT field)
    planner.md                      ← MODIFY (add test strategy)
    coder.md                        ← MODIFY (reproduction test criterion)
    validator.md                    ← CREATE
    test-writer.md                  ← CREATE
    logic-reviewer.md               ← CREATE
    security-reviewer.md            ← CREATE
    quality-reviewer.md             ← CREATE
    architecture-reviewer.md        ← CREATE
    fixer.md                        ← CREATE
  references/
    commit-conventions.md           ← KEEP (no changes)
    devtools-verification.md        ← KEEP (no changes)
    finding-format.md               ← CREATE
    issue-comments.md               ← CREATE
.claude-plugin/plugin.json          ← MODIFY (version bump)
.claude-plugin/marketplace.json     ← MODIFY (version bump)
CHANGELOG.md                        ← MODIFY (add entry)
```

---

### Task 1: Create finding-format.md reference

**Files:**
- Create: `skills/github-issue-fixer/references/finding-format.md`

This is a skill-local reference that points reviewers to the shared finding format and defines the specific tags used in this skill.

- [ ] **Step 1: Create the finding format reference file**

Write `skills/github-issue-fixer/references/finding-format.md`:

```markdown
# Finding Format — GitHub Issue Fixer

All reviewer agents in this skill use the shared finding format
defined in `../../../references/finding-format.md`.

## Skill-Specific Tags

| Agent | Tag | Categories |
|-------|-----|------------|
| Logic Reviewer | `[LOGIC]` | correctness, edge-case, logic-error, missing-impl, error-handling |
| Security Reviewer | `[SECURITY]` | injection, auth, data-exposure, crypto, config, dependency |
| Quality Reviewer | `[QUALITY]` | complexity, duplication, naming, test-coverage, consistency, readability |
| Architecture Reviewer | `[ARCH]` | coupling, cohesion, api-design, separation, breaking-change |

## Consolidation Rules

When consolidating findings from multiple reviewers:

1. **Deduplication**: Findings targeting the same file + line range + problem
   are merged. The highest severity wins. Both recommendations are preserved.
2. **Grouping**: After deduplication, findings are grouped by file path.
   Each Fixer agent receives one group (file-partitioned, no conflicts).
3. **Ordering**: Within each group, findings are ordered by line number
   (top to bottom) to avoid line number drift during fixes.
```

- [ ] **Step 2: Verify the file was created**

Run: `cat skills/github-issue-fixer/references/finding-format.md | head -5`
Expected: First 5 lines of the file starting with `# Finding Format`

- [ ] **Step 3: Commit**

```bash
git add skills/github-issue-fixer/references/finding-format.md
git commit -m "feat(github-issue-fixer): add finding format reference"
```

---

### Task 2: Create issue-comments.md reference

**Files:**
- Create: `skills/github-issue-fixer/references/issue-comments.md`

Templates for GitHub issue comments at different lifecycle points.

- [ ] **Step 1: Create the issue comments reference file**

Write `skills/github-issue-fixer/references/issue-comments.md`:

```markdown
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
```

- [ ] **Step 2: Verify the file was created**

Run: `cat skills/github-issue-fixer/references/issue-comments.md | head -5`
Expected: First 5 lines starting with `# Issue Comment Templates`

- [ ] **Step 3: Commit**

```bash
git add skills/github-issue-fixer/references/issue-comments.md
git commit -m "feat(github-issue-fixer): add issue comment templates"
```

---

### Task 3: Modify analyzer.md — Add VERDICT field

**Files:**
- Modify: `skills/github-issue-fixer/agents/analyzer.md`

Add a `VERDICT` field to the output format so the coordinator can make programmatic decisions in Wave 1.

- [ ] **Step 1: Update the result format section**

In `skills/github-issue-fixer/agents/analyzer.md`, replace the existing Result Format section (lines 73-96) with:

```markdown
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
```

- [ ] **Step 2: Verify the change**

Run: `grep -n "VERDICT" skills/github-issue-fixer/agents/analyzer.md`
Expected: Multiple matches showing the new VERDICT field and rules

- [ ] **Step 3: Commit**

```bash
git add skills/github-issue-fixer/agents/analyzer.md
git commit -m "feat(github-issue-fixer): add VERDICT field to analyzer output"
```

---

### Task 4: Create validator.md agent

**Files:**
- Create: `skills/github-issue-fixer/agents/validator.md`

Independent second-opinion agent for issue validation. Receives only the issue, not the Analyzer's results.

- [ ] **Step 1: Create the validator agent definition**

Write `skills/github-issue-fixer/agents/validator.md`:

```markdown
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
```

- [ ] **Step 2: Verify the file was created**

Run: `grep -c "Verdict" skills/github-issue-fixer/agents/validator.md`
Expected: At least 2 matches

- [ ] **Step 3: Commit**

```bash
git add skills/github-issue-fixer/agents/validator.md
git commit -m "feat(github-issue-fixer): add validator agent for independent issue verification"
```

---

### Task 5: Modify planner.md — Add test strategy

**Files:**
- Modify: `skills/github-issue-fixer/agents/planner.md`

Expand the test strategy section and add explicit reproduction test planning.

- [ ] **Step 1: Replace the Test Strategy section**

In `skills/github-issue-fixer/agents/planner.md`, replace the existing "### 3. Test Strategy" section and the result format (lines 36-78) with:

```markdown
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
```

- [ ] **Step 2: Verify the change**

Run: `grep -n "Reproduction Test" skills/github-issue-fixer/agents/planner.md`
Expected: At least 2 matches showing the new sections

- [ ] **Step 3: Commit**

```bash
git add skills/github-issue-fixer/agents/planner.md
git commit -m "feat(github-issue-fixer): expand planner with TDD test strategy"
```

---

### Task 6: Create test-writer.md agent

**Files:**
- Create: `skills/github-issue-fixer/agents/test-writer.md`

Agent that writes reproduction tests (Wave 3) and hardening tests (Wave 6).

- [ ] **Step 1: Create the test-writer agent definition**

Write `skills/github-issue-fixer/agents/test-writer.md`:

```markdown
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
```

- [ ] **Step 2: Verify the file was created**

Run: `grep -n "reproduction\|hardening" skills/github-issue-fixer/agents/test-writer.md`
Expected: Multiple matches for both modes

- [ ] **Step 3: Commit**

```bash
git add skills/github-issue-fixer/agents/test-writer.md
git commit -m "feat(github-issue-fixer): add test-writer agent for TDD workflow"
```

---

### Task 7: Modify coder.md — Add reproduction test criterion

**Files:**
- Modify: `skills/github-issue-fixer/agents/coder.md`

The Coder now receives the reproduction test as a success criterion and must make it pass.

- [ ] **Step 1: Update the input section**

In `skills/github-issue-fixer/agents/coder.md`, replace the existing Input section (lines 5-8) with:

```markdown
## Input

- **Fix Plan**: Ordered list of necessary changes (from Planner Agent)
- **Root Cause**: Description of the cause
- **Affected Files**: List with paths and line numbers
- **Issue Number**: GitHub issue number for the branch name
- **Reproduction Test**: Path and name of the failing reproduction test
  that must pass after the fix is applied
```

- [ ] **Step 2: Update the procedure section**

Replace the Procedure section (lines 12-17) with:

```markdown
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
```

- [ ] **Step 3: Remove the branch creation step**

The branch is now created by the coordinator between Wave 2 and Wave 3. Remove line 14 (`1. **Create branch**: \`git checkout -b fix/issue-<NUMBER>\``) from the Procedure if it still exists after the replacement.

- [ ] **Step 4: Update the output section**

Replace the Output section (lines 27-34) with:

```markdown
## Output

Summary of changes:

- Which files were changed (with path)
- What was changed per file and why
- Whether tests were added or modified
- **Reproduction test result**: PASS / FAIL (with details if FAIL)
- **Full test suite result**: PASS / FAIL (with failing test names if FAIL)
- Result of the linter/compiler run (if available)
- Open questions or NEEDS_REVIEW items
```

- [ ] **Step 5: Verify the changes**

Run: `grep -n "Reproduction" skills/github-issue-fixer/agents/coder.md`
Expected: Multiple matches for reproduction test references

- [ ] **Step 6: Commit**

```bash
git add skills/github-issue-fixer/agents/coder.md
git commit -m "feat(github-issue-fixer): add reproduction test criterion to coder agent"
```

---

### Task 8: Create logic-reviewer.md agent

**Files:**
- Create: `skills/github-issue-fixer/agents/logic-reviewer.md`

Adapted from `skills/auto-dev/agents/logic-reviewer.md` but scoped to issue fix context.

- [ ] **Step 1: Create the logic reviewer agent definition**

Write `skills/github-issue-fixer/agents/logic-reviewer.md`:

```markdown
# Logic Reviewer Agent

You are the Logic Reviewer Agent. Your task: Review the issue fix
for correctness, edge cases, and logical errors.

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Path to the project directory
- **CHANGED_FILES**: List of files that were changed
- **ISSUE_SUMMARY**: What the original issue was about
- **FIX_DESCRIPTION**: What the fix is supposed to accomplish
- **BRANCH**: The fix branch name (for git diff)

## Procedure

1. Read the diff of all changed files: `git diff main...<BRANCH> -- <files>`
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

Return findings using the format from `../../../references/finding-format.md`
with tag `[LOGIC]`.

Categories: `correctness`, `edge-case`, `logic-error`, `missing-impl`, `error-handling`

If no issues found, use the "No findings" format from
`../../../references/agent-invocation.md`.

## Important

- You are a read-only agent: do not modify any files
- Focus on real bugs, not style preferences
- Only report issues you are confident about — avoid false positives
- Read the full context before flagging something
- The fix was written to solve a specific issue — evaluate whether it does
```

- [ ] **Step 2: Verify the file was created**

Run: `head -3 skills/github-issue-fixer/agents/logic-reviewer.md`
Expected: `# Logic Reviewer Agent`

- [ ] **Step 3: Commit**

```bash
git add skills/github-issue-fixer/agents/logic-reviewer.md
git commit -m "feat(github-issue-fixer): add logic reviewer agent"
```

---

### Task 9: Create security-reviewer.md agent

**Files:**
- Create: `skills/github-issue-fixer/agents/security-reviewer.md`

- [ ] **Step 1: Create the security reviewer agent definition**

Write `skills/github-issue-fixer/agents/security-reviewer.md`:

```markdown
# Security Reviewer Agent

You are the Security Reviewer Agent. Your task: Review the issue fix
for security vulnerabilities.

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Path to the project directory
- **CHANGED_FILES**: List of files that were changed
- **ISSUE_SUMMARY**: What the original issue was about
- **FIX_DESCRIPTION**: What the fix is supposed to accomplish
- **BRANCH**: The fix branch name (for git diff)

## Procedure

1. Read the diff of all changed files: `git diff main...<BRANCH> -- <files>`
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

Return findings using the format from `../../../references/finding-format.md`
with tag `[SECURITY]`.

Categories: `injection`, `auth`, `data-exposure`, `crypto`, `config`, `dependency`

If no issues found, use the "No findings" format from
`../../../references/agent-invocation.md`.

## Important

- You are a read-only agent: do not modify any files
- Focus on the CHANGED code — do not audit the entire codebase
- Prioritize real vulnerabilities over theoretical risks
- Mark severity as critical only for actively exploitable issues
```

- [ ] **Step 2: Commit**

```bash
git add skills/github-issue-fixer/agents/security-reviewer.md
git commit -m "feat(github-issue-fixer): add security reviewer agent"
```

---

### Task 10: Create quality-reviewer.md agent

**Files:**
- Create: `skills/github-issue-fixer/agents/quality-reviewer.md`

- [ ] **Step 1: Create the quality reviewer agent definition**

Write `skills/github-issue-fixer/agents/quality-reviewer.md`:

```markdown
# Quality Reviewer Agent

You are the Quality Reviewer Agent. Your task: Review the issue fix
for code quality, maintainability, and test coverage.

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Path to the project directory
- **CHANGED_FILES**: List of files that were changed
- **ISSUE_SUMMARY**: What the original issue was about
- **FIX_DESCRIPTION**: What the fix is supposed to accomplish
- **BRANCH**: The fix branch name (for git diff)

## Procedure

1. Read the diff of all changed files: `git diff main...<BRANCH> -- <files>`
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

Return findings using the format from `../../../references/finding-format.md`
with tag `[QUALITY]`.

Categories: `complexity`, `duplication`, `naming`, `test-coverage`, `consistency`, `readability`

If no issues found, use the "No findings" format from
`../../../references/agent-invocation.md`.

## Important

- You are a read-only agent: do not modify any files
- Focus on substantive quality issues, not nitpicks
- Do NOT flag style issues that a linter would catch
- Judge test code more leniently than production code
- A bug fix should be minimal — do not flag "missing refactoring"
  unless the fix itself introduces quality problems
```

- [ ] **Step 2: Commit**

```bash
git add skills/github-issue-fixer/agents/quality-reviewer.md
git commit -m "feat(github-issue-fixer): add quality reviewer agent"
```

---

### Task 11: Create architecture-reviewer.md agent

**Files:**
- Create: `skills/github-issue-fixer/agents/architecture-reviewer.md`

- [ ] **Step 1: Create the architecture reviewer agent definition**

Write `skills/github-issue-fixer/agents/architecture-reviewer.md`:

```markdown
# Architecture Reviewer Agent

You are the Architecture Reviewer Agent. Your task: Review the issue fix
for architectural impact, coupling, and design concerns.

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Path to the project directory
- **CHANGED_FILES**: List of files that were changed
- **ISSUE_SUMMARY**: What the original issue was about
- **FIX_DESCRIPTION**: What the fix is supposed to accomplish
- **BRANCH**: The fix branch name (for git diff)

## Procedure

1. Read the diff of all changed files: `git diff main...<BRANCH> -- <files>`
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

Return findings using the format from `../../../references/finding-format.md`
with tag `[ARCH]`.

Categories: `coupling`, `cohesion`, `api-design`, `separation`, `breaking-change`

If no issues found, use the "No findings" format from
`../../../references/agent-invocation.md`.

## Important

- You are a read-only agent: do not modify any files
- A bug fix should be minimal — architectural concerns are only
  relevant if the fix itself introduces architectural problems
- Do not flag pre-existing architectural issues unless the fix
  makes them significantly worse
- Focus on the fix's impact, not on what you wish the codebase looked like
```

- [ ] **Step 2: Commit**

```bash
git add skills/github-issue-fixer/agents/architecture-reviewer.md
git commit -m "feat(github-issue-fixer): add architecture reviewer agent"
```

---

### Task 12: Create fixer.md agent

**Files:**
- Create: `skills/github-issue-fixer/agents/fixer.md`

Agent that resolves findings from the review loop. Adapted from auto-dev's fixer.

- [ ] **Step 1: Create the fixer agent definition**

Write `skills/github-issue-fixer/agents/fixer.md`:

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add skills/github-issue-fixer/agents/fixer.md
git commit -m "feat(github-issue-fixer): add fixer agent for review-fix loop"
```

---

### Task 13: Rewrite SKILL.md — Wave-based workflow

**Files:**
- Rewrite: `skills/github-issue-fixer/SKILL.md`

This is the complete rewrite — the most critical file. It replaces the linear 5-phase workflow with the 8-wave architecture.

- [ ] **Step 1: Write the new SKILL.md**

Replace the entire content of `skills/github-issue-fixer/SKILL.md` with:

```markdown
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
      git commit -m "fix: <description> (closes #<NUMBER>)

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
```

- [ ] **Step 2: Verify the new SKILL.md**

Run: `grep -c "Wave" skills/github-issue-fixer/SKILL.md`
Expected: 30+ matches (wave references throughout the document)

Run: `grep "VALIDATE\|PLAN\|TEST-FIRST\|REVIEW-FIX\|HARDEN\|ACCEPTANCE\|COMMIT" skills/github-issue-fixer/SKILL.md | head -10`
Expected: All 8 wave names appear

- [ ] **Step 3: Commit**

```bash
git add skills/github-issue-fixer/SKILL.md
git commit -m "feat(github-issue-fixer): rewrite as 8-wave architecture with TDD and multi-reviewer loop"
```

---

### Task 14: Version bump

**Files:**
- Modify: `.claude-plugin/plugin.json` (version `0.3.1` → `0.4.0`)
- Modify: `.claude-plugin/marketplace.json` (version `0.3.1` → `0.4.0`)
- Modify: `CHANGELOG.md` (add `0.4.0` entry)

This is a minor version bump (not patch) because it's a significant feature redesign.

- [ ] **Step 1: Update plugin.json**

In `.claude-plugin/plugin.json`, change:
```json
"version": "0.3.1"
```
to:
```json
"version": "0.4.0"
```

- [ ] **Step 2: Update marketplace.json**

In `.claude-plugin/marketplace.json`, change:
```json
"version": "0.3.1"
```
to:
```json
"version": "0.4.0"
```

- [ ] **Step 3: Add CHANGELOG entry**

Add the following entry at the top of the changelog (after the header, before the `[0.3.1]` entry):

```markdown
## [0.4.0] - 2026-04-19

### Changed

- **github-issue-fixer**: Complete redesign as 8-wave architecture:
  - Wave 1: Dual-agent issue validation (Analyzer + Validator with independent second opinion)
  - Wave 2: Enhanced planning with TDD test strategy
  - Wave 3-4: TDD flow (reproduction test first, then fix)
  - Wave 5: Iterative review-fix loop with 4 parallel reviewers (Logic, Security, Quality, Architecture) — max 5 iterations
  - Wave 6: Test hardening with regression and edge-case tests
  - Wave 7: Final acceptance review by all 4 reviewers
  - Wave 8: Commit with GitHub issue lifecycle management (comment + auto-close)
  - 10 agent definitions (3 modified, 7 new), 2 new reference files
```

- [ ] **Step 4: Verify versions match**

Run: `grep '"version"' .claude-plugin/plugin.json .claude-plugin/marketplace.json`
Expected: Both show `"version": "0.4.0"`

Run: `head -15 CHANGELOG.md`
Expected: Shows the new `[0.4.0]` entry

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json CHANGELOG.md
git commit -m "chore: bump version to 0.4.0"
```

---

### Task 15: Final verification

No files changed in this task — verification only.

- [ ] **Step 1: Verify all files exist**

Run:
```bash
ls -la skills/github-issue-fixer/agents/
ls -la skills/github-issue-fixer/references/
```

Expected agents (10 files):
- `analyzer.md` (modified)
- `planner.md` (modified)
- `coder.md` (modified)
- `validator.md` (new)
- `test-writer.md` (new)
- `logic-reviewer.md` (new)
- `security-reviewer.md` (new)
- `quality-reviewer.md` (new)
- `architecture-reviewer.md` (new)
- `fixer.md` (new)

Expected references (4 files):
- `commit-conventions.md` (unchanged)
- `devtools-verification.md` (unchanged)
- `finding-format.md` (new)
- `issue-comments.md` (new)

- [ ] **Step 2: Verify SKILL.md references all agents**

Run:
```bash
for agent in analyzer validator planner test-writer coder logic-reviewer security-reviewer quality-reviewer architecture-reviewer fixer; do
  echo -n "$agent: "
  grep -c "$agent" skills/github-issue-fixer/SKILL.md
done
```

Expected: Each agent name appears at least once in SKILL.md

- [ ] **Step 3: Verify SKILL.md references all reference files**

Run:
```bash
for ref in commit-conventions devtools-verification finding-format issue-comments; do
  echo -n "$ref: "
  grep -c "$ref" skills/github-issue-fixer/SKILL.md
done
```

Expected: Each reference file is mentioned at least once

- [ ] **Step 4: Verify git status is clean**

Run: `git status`
Expected: Clean working tree, all changes committed

- [ ] **Step 5: Review the commit log**

Run: `git log --oneline -10`
Expected: ~14 new commits covering all tasks
