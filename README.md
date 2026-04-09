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

Systematically fixes a specific GitHub Issue: load issue, locate bug, create fix plan, implement, verify, and commit.

```
/codewright:github-issue-fixer
```

**Usage:** Pass an issue number or URL as argument.

---

### refactor-orchestrator

Orchestrates a full project refactoring with autonomous subagents. A teamleader agent analyzes the project, creates a plan, and delegates to specialized worker agents.

```
/codewright:refactor-orchestrator
```

**Configuration:** Scope, aggressiveness (`conservative`/`moderate`/`aggressive`), dry-run mode.

## Requirements

- [Claude Code](https://claude.ai/code) with plugin support
- Git
- Optional: GitHub CLI (`gh`) for audit-project and github-issue-fixer

## License

MIT
