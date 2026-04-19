# Codewright

Multi-agent skills for automated code analysis, bug fixing, refactoring, and project audits.

Works with [Claude Code](https://claude.ai/code) and [OpenCode](https://github.com/anomalyco/opencode).

## Installation

### Claude Code

```
/plugin marketplace add Lazybone/Codewright
/plugin install codewright@Lazybone-Codewright
```

### OpenCode

```bash
# Install agents + skills to .opencode/
bash platforms/opencode/setup.sh

# Add plugin to opencode.json
# { "plugin": ["@codewright/opencode"] }
```

See [platforms/opencode/README.md](platforms/opencode/README.md) for details.

## Skills

| Skill | Agents | Description |
|-------|--------|-------------|
| [auto-dev](#auto-dev) | 9 | Universal autonomous dev agent — features, bugfixes, refactoring |
| [github-issue-fixer](#github-issue-fixer) | 10 | 8-wave bug fix pipeline with TDD and iterative review |
| [codebase-doctor](#codebase-doctor) | 7 | Analyze → Auto-Fix → Verify in 3 waves |
| [audit-project](#audit-project) | 5 | Parallel project audit → GitHub Issues |
| [refactor-orchestrator](#refactor-orchestrator) | 4 | Teamleader-coordinated project refactoring |
| [pr-reviewer](#pr-reviewer) | 3 | Multi-perspective PR review |
| [test-engineer](#test-engineer) | 4 | Coverage analysis + test generation |
| [codebase-onboarding](#codebase-onboarding) | 3 | Architecture docs + getting-started guides |
| [perf-analyzer](#perf-analyzer) | 4 | Performance bottleneck analysis |

### Platform Support

| Skill | Claude Code | OpenCode |
|-------|:-----------:|:--------:|
| pr-reviewer | Yes | PoC |
| All others | Yes | Planned |

---

### auto-dev

Universal autonomous development agent. Accepts any task, asks adaptive clarifying questions, creates an execution plan, implements with parallel agents, and verifies through an iterative review-fix loop with 4 reviewers (max 5 iterations).

```
/codewright:auto-dev
```

**Workflow:** Analyze → Plan (+Mockup) → Execute (parallel workers) → Review-Fix Loop (Logic, Security, Quality, Architecture) → Harden → Acceptance → Finish

---

### github-issue-fixer

Fixes GitHub Issues with an 8-wave architecture: dual-agent validation, TDD (reproduction test first), iterative multi-reviewer code review (max 5 rounds), test hardening, and automatic issue lifecycle management.

```
/codewright:github-issue-fixer
```

**Usage:** Pass an issue number or URL as argument.

**Waves:** Validate (dual-agent) → Plan → Test-First → Fix → Review-Fix Loop → Harden → Acceptance → Commit

---

### codebase-doctor

Analyzes the entire codebase with 7 parallel agents, automatically fixes found issues, and creates a final report. Works in 3 waves: Analysis → Auto-Fix → Review & Verify.

```
/codewright:codebase-doctor
```

**Modes:** `report-only`, `fix-critical`, `fix-all` (default)

---

### audit-project

Runs a comprehensive project audit with 5 parallel subagents (Security, Bugs, Code Hygiene, Structure, GitHub Issues). Each finding is automatically created as a GitHub Issue.

```
/codewright:audit-project
```

**Requirements:** Git repository with GitHub remote, `gh` CLI installed.

---

### refactor-orchestrator

Orchestrates a full project refactoring with autonomous subagents. A teamleader agent analyzes the project, creates a plan, and delegates to specialized worker agents.

```
/codewright:refactor-orchestrator
```

**Configuration:** Scope, aggressiveness (`conservative`/`moderate`/`aggressive`), dry-run mode.

---

### pr-reviewer

Multi-perspective code review of a Pull Request using 3 parallel agents (Logic, Security, Quality). Optionally posts review as GitHub PR comment.

```
/codewright:pr-reviewer
```

**Usage:** Pass a PR number or URL as argument.

---

### test-engineer

Finds missing tests, identifies coverage gaps, and writes tests automatically. 2-wave approach: analyze coverage & risk, then generate and review tests.

```
/codewright:test-engineer
```

**Modes:** `report-only`, `critical-paths`, `full-coverage` (default)

---

### codebase-onboarding

Analyzes a codebase and generates architecture documentation and getting-started guides. 3 agents: Structure Scanner → Architecture Analyzer → Doc Writer.

```
/codewright:codebase-onboarding
```

**Output:** `ARCHITECTURE.md` and/or `GETTING-STARTED.md`

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

- [Claude Code](https://claude.ai/code) or [OpenCode](https://github.com/anomalyco/opencode)
- Git
- Optional: GitHub CLI (`gh`) for audit-project, github-issue-fixer, and pr-reviewer

## License

MIT
