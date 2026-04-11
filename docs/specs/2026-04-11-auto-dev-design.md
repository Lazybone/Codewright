# Auto-Dev Skill — Design Specification

## Overview

**Skill name**: `auto-dev`  
**Invocation**: `/codewright:auto-dev`  
**Purpose**: Universal task executor for any development task — new features, bugfixes, removals, refactoring, and more. Accepts a task description, clarifies requirements through adaptive questions, creates an execution plan, implements with parallel agents, and verifies through an iterative review-fix loop.

**Architecture**: Teamleader pattern — SKILL.md acts as coordinator, delegating to specialized agents across clearly defined phases.

---

## Phases

```
User gives task
       |
       v
+-------------------+
| Phase 0: Prep     |  Clean git check, detect project, create branch,
|                   |  remember start commit for rollback
+--------+----------+
         v
+-------------------+
| Phase 1: Analyze  |  Requirement-Analyst (Explore) analyzes task,
| & Questions       |  generates adaptive questions -> User answers
+--------+----------+
         v
+-------------------+
| Phase 2: Plan     |  Planner (Explore) creates execution plan:
|                   |  work packages, dependencies, file assignment
+--------+----------+
         v
+-------------------+
| Phase 3: Execute  |  Code-Workers (Auto) implement --
|                   |  parallel where independent, sequential where dependent
+--------+----------+
         v
+-------------------------------------------+
| Phase 4: Verify (Loop, max 3x)           |
|                                           |
|  4a: Auto-Checks (tests, linter, types)  |
|       |                                   |
|       v                                   |
|  4b: Review-Agents (adaptively selected)  |
|       |                                   |
|       v                                   |
|  4c: Findings? -> Fix-Agents -> back to 4a|
|                                           |
|  No findings? -> continue                 |
+--------+----------------------------------+
         v
+-------------------+
| Phase 5: Finish   |  Final commit, report, offer merge/PR
+-------------------+

After 3 iterations with remaining findings:
  -> Notify user, list open findings
  -> Offer rollback (git reset to start commit)
  -> Or commit as-is with findings documented in report
```

---

## Phase 0: Prep

1. Verify git repo is clean (no uncommitted changes) — abort if dirty
2. Detect project: language, framework, test runner, linter, type checker
3. Create branch: `auto-dev/<short-description>-YYYYMMDD-HHMMSS` (short-description is derived from the user's task — max 3 words, kebab-case, e.g. `auto-dev/add-user-auth-20260411-143022`)
4. Store start commit hash (for potential rollback)
5. Create working directory: `.codewright/auto-dev/<YYYYMMDD-HHMMSS>/`

---

## Phase 1: Analyze & Questions

### Agent: Requirement-Analyst (Explore)

Receives the user's task description and scans relevant areas of the codebase.

**Returns:**

```markdown
## Analysis
- **Task Type**: feature | bugfix | removal | refactor | other
- **Complexity**: low | medium | high
- **Affected Areas**: [list of directories/files]
- **Risks**: [identified risks]

## Questions
1. [Question] (multiple choice: A, B, C)
2. [Question] (open-ended)
...
```

**Adaptive question count based on complexity:**

| Complexity | Questions |
|------------|-----------|
| Low        | 0-2       |
| Medium     | 2-4       |
| High       | 4-6       |

### Coordinator behavior

- Saves analysis to `.codewright/auto-dev/<run-id>/task.md`
- Presents questions **one at a time** to the user
- Appends user answers to `task.md`
- After all questions are answered, everything runs autonomously

---

## Phase 2: Plan

### Agent: Planner (Explore)

Receives the task, requirement analyst's analysis, and user answers.

**Returns a structured plan** saved to `.codewright/auto-dev/<run-id>/plan.md`:

```markdown
## Task Overview
- **Goal**: What should be achieved
- **Approach**: Chosen approach in 2-3 sentences

## Work Packages

### WP-1: <Title>
- **Files**: [`src/auth.ts`, `src/auth.test.ts`]
- **Action**: create | modify | delete
- **Description**: What exactly needs to be done
- **Depends on**: [] (empty = independent)

### WP-2: <Title>
- **Files**: [`src/routes/login.ts`]
- **Action**: modify
- **Description**: ...
- **Depends on**: [WP-1]

## Execution Order
- **Parallel Group 1**: WP-1, WP-3 (independent)
- **Sequential after Group 1**: WP-2 (depends on WP-1)

## Review Strategy
- **Reviewers needed**: logic, security
- **Auto-checks**: test, lint
```

### Reviewer selection logic (determined by planner)

| Task Type          | Reviewers                    |
|--------------------|------------------------------|
| New feature        | Logic + Quality              |
| Security-relevant  | Logic + Security + Quality   |
| Bugfix             | Logic                        |
| Refactoring        | Logic + Quality              |
| API change         | Logic + Security + Quality   |
| Simple change      | Logic                        |

### Coordinator behavior

- Saves plan to `.codewright/auto-dev/<run-id>/plan.md`
- Creates initial todo list in `.codewright/auto-dev/<run-id>/todos.md`
- Parses execution order for Phase 3

---

## Phase 3: Execute

### Agent: Code-Worker (Auto-Mode, 1-N instances)

Each worker receives:
- Its assigned work package (description, goal)
- Its exclusive file list (no other worker may touch these files)
- Overall context (task description, user answers, plan overview)

### Execution strategy

1. Group work packages by execution order from plan
2. Start independent WPs as parallel background agents (file-partitioned)
3. Wait for all parallel agents to complete
4. Commit changes after each parallel group
5. Start next group (sequential dependencies resolved)
6. Update `.codewright/auto-dev/<run-id>/todos.md` after each WP completes

### Error handling

- Worker fails (file not found, unclear requirement): worker reports error, coordinator logs it, continues with remaining WPs
- Errors are caught in Phase 4 (Verify)

---

## Phase 4: Verify (Review-Fix Loop)

Maximum 3 iterations.

### Stufe 4a: Auto-Checks — Test-Runner Agent (Auto-Mode)

Runs project-specific checks:
1. Tests (`npm test`, `pytest`, `go test`, etc.)
2. Linter (`eslint`, `ruff`, `golangci-lint`, etc.)
3. Type checks (`tsc --noEmit`, `mypy`, etc.)

**Returns:**

```markdown
## Auto-Check Results
- **Tests**: PASS (42/42) | FAIL (3/42): [details]
- **Lint**: PASS | FAIL 5 issues: [details]
- **Types**: PASS | FAIL 2 errors: [details]
```

- All green -> proceed to 4b
- Failures -> skip 4b, go directly to 4c (Fix-Agents)

Saved to `.codewright/auto-dev/<run-id>/iterations/iteration-N/auto-checks.md`

### Stufe 4b: Review-Agents (Explore, parallel)

Only reviewers selected by planner are started:

- **Logic-Reviewer**: Correctness, edge cases, missing logic, off-by-one errors
- **Security-Reviewer**: Injection, auth gaps, secrets exposure, OWASP Top 10
- **Quality-Reviewer**: Complexity, duplication, naming, testability

Each reviewer receives the diff (before/after) and returns findings in the standard finding format (shared `references/finding-format.md`).

- No findings -> Phase 5 (Finish)
- Findings present -> proceed to 4c

Saved to `.codewright/auto-dev/<run-id>/iterations/iteration-N/review-findings.md`

### Stufe 4c: Fix-Agents (Auto-Mode)

- Coordinator collects all findings (auto-checks + reviews)
- Groups by file -> distributes to Fix-Agents (file-partitioned)
- Each Fix-Agent receives its findings + affected files
- Fix-Agents resolve issues and return summary
- Commit after fixes

Saved to `.codewright/auto-dev/<run-id>/iterations/iteration-N/fixes.md`

### Loop termination

```
iteration = 0

LOOP:
  iteration += 1

  4a: Auto-Checks
  if failures -> 4c (Fix) -> LOOP (if iteration < 3)

  4b: Reviews
  if findings -> 4c (Fix) -> LOOP (if iteration < 3)

  if no findings -> EXIT LOOP (success)

  if iteration == 3 AND still findings:
    -> Notify user
    -> List open findings
    -> Offer: "Should I revert all changes?"
    -> Yes: git reset --hard <start-commit>
    -> No: commit as-is, document findings in report
```

---

## Phase 5: Finish

### Final commit

```
feat: <short task description>

- <WP-1 summary>
- <WP-2 summary>
- ...

Verified: X review iterations, all checks passing
```

### Report

Saved to `.codewright/auto-dev/<run-id>/report.md`:

```markdown
## Auto-Dev Report

### Task
<Original task description>

### Changes
| File | Action | Description |
|------|--------|-------------|
| src/auth.ts | modified | Added session validation |
| src/auth.test.ts | created | 12 test cases |

### Verification
- **Review Iterations**: 2
- **Auto-Checks**: Tests (42/42), Lint, Types
- **Reviews**: Logic, Security
- **Open Findings**: 0

### Branch
`auto-dev/add-auth-20260411-143022`

### Git Log
- `abc1234` feat: add session validation
- `def5678` fix: address review findings (iteration 1)
- `ghi9012` feat: add auth (final)
```

### User options

After presenting the report:
- "Should I create a PR?"
- "Should I merge into the main branch?"
- "Branch stays open, you can continue working on it"

---

## Working Directory: `.codewright/`

All artifacts are stored in a structured working directory:

```
.codewright/
  auto-dev/
    <run-id>/                          # e.g. 20260411-143022
      task.md                          # Original task + user answers
      plan.md                          # Execution plan (work packages, deps)
      todos.md                         # Progress: WPs done/pending/failed
      iterations/
        iteration-1/
          auto-checks.md               # Test/lint/type results
          review-findings.md           # Review agent findings
          fixes.md                     # What fix agents changed
        iteration-2/
          ...
        iteration-3/
          ...
      report.md                        # Final report
```

The `.codewright/` directory is committed to the branch. The user can decide whether to add it to `.gitignore` or keep it in the repo.

---

## Skill File Structure

```
skills/auto-dev/
  SKILL.md                    # Coordinator logic (all phases)
  agents/
    requirement-analyst.md    # Analyzes task, generates questions
    planner.md               # Creates execution plan
    code-worker.md           # Implements assigned work packages
    test-runner.md           # Runs tests, linter, type checks
    logic-reviewer.md        # Checks correctness & edge cases
    security-reviewer.md     # Checks security vulnerabilities
    quality-reviewer.md      # Checks code quality
    fixer.md                 # Resolves review findings
  references/
    plan-format.md           # Format for execution plan
    report-template.md       # Template for final report
```

---

## Agent Summary

| Agent | Type | Mode | Purpose |
|-------|------|------|---------|
| Requirement-Analyst | Explore | read-only | Analyze task, generate adaptive questions |
| Planner | Explore | read-only | Create execution plan with dependency graph |
| Code-Worker (1-N) | General | auto | Implement work packages (file-partitioned) |
| Test-Runner | General | auto | Run tests, linter, type checks |
| Logic-Reviewer | Explore | read-only | Review correctness, edge cases |
| Security-Reviewer | Explore | read-only | Review security vulnerabilities |
| Quality-Reviewer | Explore | read-only | Review code quality, complexity |
| Fixer (1-N) | General | auto | Resolve findings (file-partitioned) |

---

## Key Design Decisions

1. **Fully autonomous after questions** — no user gates between phases (except failure after 3 iterations)
2. **Adaptive questions** — complexity-based question count (0-6)
3. **Hybrid parallelism** — planner determines dependency graph, independent WPs run in parallel
4. **Two-stage verification** — auto-checks first (cheap), then review agents (thorough)
5. **Adaptive reviewer selection** — only relevant reviewers start based on task type
6. **Max 3 review iterations** — with user notification and rollback option on failure
7. **Automatic git management** — branch creation, commits after each phase, merge/PR offer at end
8. **Persistent working directory** — `.codewright/auto-dev/<run-id>/` for full traceability
9. **No dry-run mode** — branch isolation + rollback is sufficient
10. **Standard finding format** — reuses shared `references/finding-format.md`
