# Codewright

Multi-agent skills for automated code analysis, bug fixing, refactoring, and project audits.

Works with [Claude Code](https://claude.ai/code), [OpenCode](https://github.com/anomalyco/opencode), and [Kimi CLI](https://moonshotai.github.io/kimi-cli/).

## Installation

### Claude Code

```
/plugin marketplace add Lazybone/Codewright
/plugin install codewright@Lazybone-Codewright
```

### OpenCode

Paste this into your OpenCode session:

```
Install and configure Codewright for OpenCode by following the instructions here:
https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/opencode/INSTALL.md
```

Or install manually — see the [OpenCode Installation Guide](platforms/opencode/INSTALL.md).

### Kimi CLI

Paste this into your Kimi CLI session:

```
Install and configure Codewright for Kimi CLI by following the instructions here:
https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/kimi/INSTALL.md
```

Or install manually — see the [Kimi CLI Installation Guide](platforms/kimi/INSTALL.md).

## Skills

| Skill | Agents | Description |
|-------|--------|-------------|
| [auto-dev](#auto-dev) | 9 | Universal autonomous dev agent — features, bugfixes, refactoring |
| [bug-fixer](#bug-fixer) | 10 | TDD-based bug fixing with 8-phase workflow |
| [github-issue-fixer](#github-issue-fixer) | 10 | 8-wave bug fix pipeline with TDD and iterative review |
| [codebase-doctor](#codebase-doctor) | 7 | Analyze → Auto-Fix → Verify in 3 waves |
| [audit-project](#audit-project) | 5 | Parallel project audit → GitHub Issues |
| [refactor-orchestrator](#refactor-orchestrator) | 4 | Teamleader-coordinated project refactoring |
| [pr-reviewer](#pr-reviewer) | 3 | Multi-perspective PR review |
| [test-engineer](#test-engineer) | 4 | Coverage analysis + test generation |
| [codebase-onboarding](#codebase-onboarding) | 3 | Architecture docs + getting-started guides |
| [perf-analyzer](#perf-analyzer) | 4 | Performance bottleneck analysis |
| [upgrade](#upgrade) | 0 | Platform-aware self-upgrade for Claude Code, OpenCode, and Kimi CLI |

All 11 skills are available on Claude Code, OpenCode, and Kimi CLI.

---

### auto-dev

Universal autonomous development agent. Accepts any task, asks adaptive clarifying questions, creates an execution plan, implements with parallel agents, and verifies through an iterative review-fix loop with 4 reviewers (max 5 iterations).

```
/codewright:auto-dev
```

**Workflow:** Analyze → Plan (+Mockup) → Execute (parallel workers) → Review-Fix Loop (Logic, Security, Quality, Architecture) → Harden → Acceptance → Finish

---

### bug-fixer

Specialized bug-fixing agent with TDD workflow. Analyzes root cause, writes a reproduction test (TDD RED), implements the minimal fix (TDD GREEN), then verifies through an iterative review-fix loop with 4 reviewers, test hardening, and acceptance review.

```
/codewright:bug-fixer
```

**Workflow:** Analyze → Reproduce (TDD RED) → Plan & Fix (TDD GREEN) → Review-Fix Loop → Harden → Acceptance → Finish

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

### upgrade

Detects the current platform (Claude Code, OpenCode, or Kimi CLI), checks for newer versions via GitHub API, and performs a platform-specific upgrade. No subagents — coordinator-only skill.

```
/codewright:upgrade
```

**Workflow:** Detect Platform → Version Check (GitHub API) → Upgrade → Verify

- **Claude Code:** Clears plugin cache; latest version downloads automatically on next skill invocation
- **OpenCode:** Fully automated via sparse git clone + setup.sh re-run
- **Kimi CLI:** Fully automated via sparse git clone + setup.sh re-run

---

## Updating

The recommended way to update is the built-in upgrade skill:

```
/codewright:upgrade
```

This auto-detects your platform and handles the upgrade. See [upgrade](#upgrade) above.

### Manual Update

#### Claude Code

Enable auto-updates (recommended):

```
/plugin → Marketplaces → Lazybone-Codewright → Enable auto-update
```

Or update manually:

```
/plugin marketplace update Lazybone-Codewright
```

#### OpenCode

Re-run the installation prompt in your OpenCode session:

```
Install and configure Codewright for OpenCode by following the instructions here:
https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/opencode/INSTALL.md
```

Or update manually:

```bash
CW_TMP="$(mktemp -d)"
git clone --depth 1 --filter=blob:none --sparse \
    https://github.com/Lazybone/Codewright.git "$CW_TMP/codewright"
cd "$CW_TMP/codewright" && git sparse-checkout set platforms/opencode
bash "$CW_TMP/codewright/platforms/opencode/setup.sh"
rm -rf "$CW_TMP"
```

The setup script overwrites existing files — no uninstall needed before updating.

#### Kimi CLI

Re-run the installation prompt in your Kimi CLI session:

```
Install and configure Codewright for Kimi CLI by following the instructions here:
https://raw.githubusercontent.com/Lazybone/Codewright/main/platforms/kimi/INSTALL.md
```

Or update manually:

```bash
CW_TMP="$(mktemp -d)"
git clone --depth 1 --filter=blob:none --sparse \
    https://github.com/Lazybone/Codewright.git "$CW_TMP/codewright"
cd "$CW_TMP/codewright" && git sparse-checkout set platforms/kimi
bash "$CW_TMP/codewright/platforms/kimi/setup.sh"
rm -rf "$CW_TMP"
```

The setup script overwrites existing files — no uninstall needed before updating.

## Requirements

- [Claude Code](https://claude.ai/code), [OpenCode](https://github.com/anomalyco/opencode), or [Kimi CLI](https://moonshotai.github.io/kimi-cli/)
- Git
- Optional: GitHub CLI (`gh`) for audit-project, github-issue-fixer, and pr-reviewer

## License

MIT
