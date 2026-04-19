# GitHub Issue Fixer — Wave-Based Redesign

## Overview

Redesign of the `github-issue-fixer` skill from a linear 5-phase workflow to an 8-wave architecture with TDD core, multi-reviewer loop, and GitHub issue lifecycle management.

## Goals

- Validate issues before investing effort (dual-agent confirmation)
- TDD approach: prove the bug with a test, then fix
- Multi-perspective code review with iterative fix loop
- Harden with regression and edge-case tests
- Full GitHub issue lifecycle: comment and close on resolution or invalidation

## Wave Architecture

```
Wave 1: VALIDATE
  ├── Analyzer (Explore) ──┐
  └── Validator (Explore) ──┤── Both independently assess the issue
                            ├── Both "NOT_CONFIRMED" → User-Gate → Comment + Close → STOP
                            ├── At least one "CONFIRMED" → continue
                            └── Consolidated analysis as input for Wave 2

Wave 2: PLAN
  └── Planner (Explore) ── Fix plan + test strategy + risk assessment
      └── User-Gate: show plan, wait for confirmation

Wave 3: TEST-FIRST
  └── Test-Writer (Code-Changing) ── Write reproduction test
      ├── Test FAILS → bug confirmed, continue to Wave 4
      ├── Test PASSES → bug already fixed → User-Gate → Comment + Close → STOP
      └── Test won't compile → Test-Writer retries (max 3)

Wave 4: FIX
  └── Coder (Code-Changing) ── Implement fix per plan
      └── Run reproduction test → must pass now
      └── If still red → Coder iterates (max 3 attempts)

Wave 5: REVIEW-FIX LOOP (max 5 iterations, shared budget with Wave 7)
  ├── Round 1: Logic + Security + Quality + Architecture (4 parallel)
  │   └── Consolidate & deduplicate findings
  │   └── No findings → continue to Wave 6
  │   └── Fix-Agents (parallel, file-partitioned) resolve findings
  ├── Round 2-5: Only reviewers that had findings in previous round
  │   └── New findings → Fix → Loop
  │   └── No findings → continue to Wave 6
  └── After 5 rounds with open findings → Wave 8 (report only, no commit)

Wave 6: HARDEN
  └── Test-Writer (Code-Changing) ── Regression + edge-case tests
      └── Run all tests → must pass
      └── If red → fix + rerun (max 3 attempts)

Wave 7: ACCEPTANCE
  └── Logic + Security + Quality + Architecture (4 parallel)
      └── Full review of entire state (code + tests)
      └── Findings? → Back to Wave 5 (counts as iteration)
      └── Clean? → Continue to Wave 8

Wave 8: COMMIT
  ├── All findings resolved:
  │   └── User-Gate → Commit (Fixes #N) + Issue comment + PR offer
  └── Open findings after 5 iterations:
      └── Report to user, no commit, issue stays open
```

## Validation Logic (Wave 1)

Analyzer and Validator start in parallel. Both receive only the issue (title, body, comments, labels). The Validator does NOT see the Analyzer's results.

| Analyzer | Validator | Result |
|---|---|---|
| CONFIRMED | CONFIRMED | Continue → Wave 2 (consolidated analysis) |
| CONFIRMED | NOT_CONFIRMED | Continue → Wave 2 (Analyzer analysis as basis, Validator doubts documented) |
| NOT_CONFIRMED | CONFIRMED | Continue → Wave 2 (Validator analysis as basis, Analyzer doubts documented) |
| NOT_CONFIRMED | NOT_CONFIRMED | User-Gate → comment on issue + close → STOP |

On disagreement (one yes, one no): proceed anyway — benefit of the doubt goes to the issue. The dissenting opinion is carried forward as risk context in the plan.

## Branch Creation

Before any code changes (between Wave 2 and Wave 3), create the feature branch:

```
git checkout -b fix/issue-<NUMBER>
```

All code-changing agents (Test-Writer, Coder, Fixer) work on this branch.

## TDD Flow (Wave 3-4)

1. Test-Writer writes a minimally focused test that reproduces exactly the described misbehavior
2. Test is executed — three possible outcomes:
   - **Test FAILS** → bug confirmed, continue to Wave 4
   - **Test PASSES** → bug no longer exists. User-Gate: "Reproduction test passes immediately. Bug appears already fixed. Comment and close issue?"
   - **Test WON'T COMPILE** → Test-Writer gets the error and repairs (max 3 attempts). If still broken after 3 attempts → STOP, report to user
3. Coder implements the fix according to the plan
4. Reproduction test is run again — must now pass
5. If still failing → Coder iterates (max 3 attempts). If still red after 3 attempts → STOP, report to user with diagnostics

## Review-Fix Loop (Wave 5)

### Reviewer Perspectives

| Reviewer | Focus |
|---|---|
| **Logic-Reviewer** | Correctness: logic errors, missing edge cases, off-by-one, incorrect conditions, incomplete fixes |
| **Security-Reviewer** | Security: injection, XSS, auth bypasses, insecure defaults, secrets in code |
| **Quality-Reviewer** | Code quality: naming, complexity, DRY, readability, convention compliance |
| **Architecture-Reviewer** | Architecture: coupling, cohesion, API design, separation of concerns, breaking changes |

### Finding Format

All reviewers return findings in a unified format:

```markdown
## Finding
- **Severity:** CRITICAL | HIGH | MEDIUM | LOW
- **File:** path/to/file.ts:42
- **Issue:** Description of the problem
- **Suggestion:** Concrete fix suggestion
```

### Consolidation

1. Findings targeting the same file + line + problem are deduplicated (highest severity wins)
2. Findings are grouped by file → one Fixer agent per file (file-partitioned, no conflicts)
3. Fixers start in parallel, each receives its assigned findings + affected files

### Iteration Logic

- Round 1: all 4 reviewers
- Round 2-5: only reviewers that produced findings in the previous round
- After each fix round: run full test suite to ensure no regressions were introduced by the fixes
- Exit conditions: no findings OR 5 iterations reached
- Iteration counter is shared between Wave 5 and Wave 7 (acceptance review counts toward the budget)

## Test Hardening (Wave 6)

Test-Writer writes additional tests after the review loop:

- Regression tests for related functionality
- Edge-case tests identified during planning and review
- Boundary condition tests
- All tests are run; if any fail, Test-Writer fixes (max 3 attempts)

## Acceptance Review (Wave 7)

All 4 reviewers run one final time over the complete state (code changes + all tests). If any findings are raised, they feed back into Wave 5 and count as an iteration.

## GitHub Issue Lifecycle

### Comment Templates

**Issue invalidated (Wave 1 or Wave 3):**
- What was investigated
- Why the issue could not be confirmed/reproduced
- What was checked (files, tests, environment)
- Polite tone, invitation to reopen with more details

**Issue resolved (Wave 8):**
- Root cause (1-2 sentences)
- Summary of changes made
- Tests added (reproduction + regression/edge-case)
- Link to commit or PR

### Auto-Close Behavior

- Successful fix: `Fixes #<N>` in commit message auto-closes via Git
- Additionally: explicit comment posted before close
- Invalidated: closed via `gh issue close` after commenting
- All close actions gated by user confirmation

## Agent Definitions

### Existing (modified)

| Agent | Type | Changes |
|---|---|---|
| **Analyzer** | Explore | Add `VERDICT: CONFIRMED / NOT_CONFIRMED` field to output |
| **Planner** | Explore | Add test strategy section (reproduction tests, edge cases) |
| **Coder** | Code-Changing | Receives reproduction test as success criterion |

### New

| Agent | Type | Purpose |
|---|---|---|
| **Validator** | Explore | Independent second opinion on issue validity |
| **Test-Writer** | Code-Changing | Writes reproduction tests (Wave 3) and regression/edge-case tests (Wave 6) |
| **Logic-Reviewer** | Explore | Reviews correctness |
| **Security-Reviewer** | Explore | Reviews security |
| **Quality-Reviewer** | Explore | Reviews code quality |
| **Architecture-Reviewer** | Explore | Reviews architectural impact |
| **Fixer** | Code-Changing | Resolves review findings (parallel, file-partitioned) |

**Total: 10 agent definitions** (3 modified + 7 new)

## File Structure

```
skills/github-issue-fixer/
  SKILL.md                        ← complete rewrite (wave-based)
  agents/
    analyzer.md                   ← modify (add VERDICT field)
    planner.md                    ← modify (add test strategy)
    coder.md                      ← modify (reproduction test criterion)
    validator.md                  ← NEW
    test-writer.md                ← NEW
    logic-reviewer.md             ← NEW
    security-reviewer.md          ← NEW
    quality-reviewer.md           ← NEW
    architecture-reviewer.md      ← NEW
    fixer.md                      ← NEW
  references/
    commit-conventions.md         ← keep
    devtools-verification.md      ← keep
    finding-format.md             ← NEW (unified finding format)
    issue-comments.md             ← NEW (comment templates)
```

## User Gates

All destructive or externally visible actions require user confirmation:

| Gate | Trigger |
|---|---|
| Issue not confirmed | Both validators say NOT_CONFIRMED |
| Bug already fixed | Reproduction test passes immediately |
| Plan approval | Before implementation begins |
| Commit + close | After all reviews pass |
| Report (no commit) | After max iterations with open findings |

## Version Bump

Patch version increment in:
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `CHANGELOG.md`
