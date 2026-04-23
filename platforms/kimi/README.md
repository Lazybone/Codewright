# Codewright for Kimi CLI

Codewright skills for [Kimi CLI](https://moonshotai.github.io/kimi-cli/).

## Quick Install

```bash
git clone --depth 1 https://github.com/Lazybone/Codewright.git /tmp/codewright
bash /tmp/codewright/platforms/kimi/setup.sh
rm -rf /tmp/codewright
```

This installs 11 skills to `~/.kimi/skills/`:

- `audit-project` — comprehensive project audit
- `auto-dev` — autonomous development agent
- `bug-fixer` — TDD-based bug fixing
- `codebase-doctor` — analyze and auto-fix issues
- `codebase-onboarding` — architecture docs + getting-started guides
- `github-issue-fixer` — fix GitHub issues with TDD
- `perf-analyzer` — performance bottleneck analysis
- `pr-reviewer` — multi-perspective PR review
- `refactor-orchestrator` — teamleader-coordinated refactoring
- `test-engineer` — coverage analysis + test generation
- `upgrade` — self-upgrade for Codewright

## Usage

After installation, invoke any skill by name in a Kimi CLI session:

```
review my PR
```

```
auto dev: add user authentication
```

```
upgrade
```

## Files

- `setup.sh` — install / uninstall script (`--global`, `--local`, `--uninstall`)
- `INSTALL.md` — detailed installation guide for humans and LLM agents
