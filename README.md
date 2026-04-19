# Codewright

A [Claude Code](https://claude.ai/code) plugin with multi-agent skills for automated code analysis, bug fixing, refactoring, and project audits.

## Installation

In Claude Code:

```
/plugin marketplace add Lazybone/Codewright
/plugin install codewright@Lazybone-Codewright
```

## Skills

### audit-project

Runs a comprehensive project audit with 5 parallel subagents (Security, Bugs, Code Hygiene, Structure, GitHub Issues). Each finding is automatically created as a GitHub Issue.

```
/codewright:audit-project
```

**Requirements:** Git repository with GitHub remote, `gh` CLI installed and authenticated.

---

### codebase-doctor

Analyzes the entire codebase with 7 parallel agents, automatically fixes found issues, and creates a final report. Works in 3 waves: Analysis → Auto-Fix → Review & Verify.

```
/codewright:codebase-doctor
```

**Modes:** `report-only`, `fix-critical`, `fix-all` (default)

---

### github-issue-fixer

Fixes GitHub Issues with an 8-wave architecture: dual-agent validation, TDD (reproduction test first), iterative multi-reviewer code review (Logic, Security, Quality, Architecture — max 5 rounds), test hardening, and automatic issue lifecycle management (comment + close).

```
/codewright:github-issue-fixer
```

**Usage:** Pass an issue number or URL as argument.

**Waves:** Validate (dual-agent) → Plan → Test-First → Fix → Review-Fix Loop → Harden → Acceptance → Commit

**Agents:** Analyzer, Validator, Planner, Test-Writer, Coder, Logic/Security/Quality/Architecture Reviewers, Fixer

---

### refactor-orchestrator

Orchestrates a full project refactoring with autonomous subagents. A teamleader agent analyzes the project, creates a plan, and delegates to specialized worker agents.

```
/codewright:refactor-orchestrator
```

**Configuration:** Scope, aggressiveness (`conservative`/`moderate`/`aggressive`), dry-run mode.

---

### auto-dev

Universal autonomous development agent. Accepts any task (features, bugfixes, removals, refactoring), asks adaptive clarifying questions, creates an execution plan, implements with parallel agents, and verifies through an iterative review-fix loop (max 3 iterations).

```
/codewright:auto-dev
```

**Workflow:** Analyze & Questions → Plan → Execute (parallel workers) → Auto-Checks → Code Reviews → Fix Loop → Report

**Agents:** Requirement Analyst, Planner, Code Workers, Test Runner, Logic/Security/Quality Reviewers, Fixers

---

### codebase-onboarding

Analyzes a codebase and generates architecture documentation and getting-started guides. 3 agents: Structure Scanner → Architecture Analyzer → Doc Writer.

```
/codewright:codebase-onboarding
```

**Output:** `ARCHITECTURE.md` and/or `GETTING-STARTED.md`

---

### test-engineer

Finds missing tests, identifies coverage gaps, and writes tests automatically. 2-wave approach: analyze coverage & risk, then generate and review tests.

```
/codewright:test-engineer
```

**Modes:** `report-only`, `critical-paths`, `full-coverage` (default)

---

### pr-reviewer

Multi-perspective code review of a Pull Request using 3 parallel agents (Logic, Security, Quality). Optionally posts review as GitHub PR comment.

```
/codewright:pr-reviewer
```

**Usage:** Pass a PR number or URL as argument.

---

### perf-analyzer

Identifies performance bottlenecks using up to 4 parallel agents (Bundle, Query, Runtime, Infra). Smart agent selection based on project type.

```
/codewright:perf-analyzer
```

**Output:** `PERFORMANCE-REPORT.md` with impact-sorted findings.

---

## Updating

Enable auto-updates (recommended):

```
/plugin → Marketplaces → Lazybone-Codewright → Enable auto-update
```

Or update manually:

```
/plugin marketplace update Lazybone-Codewright
```

## Requirements

- [Claude Code](https://claude.ai/code) with plugin support
- Git
- Optional: GitHub CLI (`gh`) for audit-project and github-issue-fixer

## License

MIT
