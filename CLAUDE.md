# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **Claude Code Plugin** (`codewright`) — a collection of multi-agent skills for Claude Code that automate complex development tasks. Each skill is a self-contained directory under `skills/` with a `SKILL.md` entry point, agent definitions, and reference templates.

## Plugin Structure

```
.claude-plugin/
  plugin.json               # Plugin manifest (name, version, author)
references/                   # Shared references across all skills
  agent-invocation.md         # How to start and communicate with agents
  finding-format.md           # Unified finding format for all analysis agents
skills/
  skill-name/
    SKILL.md                # Main skill definition (frontmatter + workflow)
    agents/                 # Subagent prompt definitions (.md files)
    references/             # Templates, formats, conventions (.md files)
```

**Installation**: `claude plugin add` or test locally with `claude --plugin-dir .`

### Skills

| Skill | Invocation | Agent Pattern |
|---|---|---|
| `audit-project` | `/codewright:audit-project` | 5 parallel Explore agents → GitHub Issue creation |
| `codebase-doctor` | `/codewright:codebase-doctor` | 3-wave: 7 Explore → Fix → Review agents |
| `github-issue-fixer` | `/codewright:github-issue-fixer` | Sequential: Explore → Plan → Fix → Verify → Commit |
| `refactor-orchestrator` | `/codewright:refactor-orchestrator` | Teamleader + Scout/Architect/Worker/Test agents (agents/ + references/) |
| `auto-dev` | `/codewright:auto-dev` | Teamleader + Analyst/Planner/Workers/Reviewers/Fixers (6 phases, review-fix loop) |

## Skill File Format

`SKILL.md` files use YAML frontmatter:

```yaml
---
name: skill-name
description: >
  Multi-line description used for skill matching/triggering.
  Include German and English trigger phrases.
disable-model-invocation: true  # Optional: prevents direct model invocation
---
```

## Key Patterns

- **Agent types**: Skills use `subagent_type: "Explore"` for read-only analysis and general-purpose agents with `mode: "auto"` for code changes.
- **Inter-agent communication**: Agents return structured Markdown responses; no `/tmp/` files are used.
- **File conflict avoidance**: When multiple agents modify code in parallel, files are strictly partitioned so no two agents edit the same file.
- **Finding format**: Both `audit-project` and `codebase-doctor` share a standardized finding format defined in their respective `references/finding-format.md`.
- **User confirmation gates**: All skills pause before destructive actions (creating issues, committing, merging) and ask the user.

## Language

All skill content, agent prompts, reports, and user-facing output are in **English**. SKILL.md description fields include both English (primary) and German (secondary) trigger phrases for backward compatibility.
