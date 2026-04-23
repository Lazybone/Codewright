# Changelog

Alle relevanten Änderungen an diesem Projekt werden hier dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.1.0/)
und dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

## [0.4.2] - 2026-04-23

### Added

- **Kimi CLI platform**: Full install, uninstall, and upgrade support for Kimi CLI
  - New `platforms/kimi/setup.sh`: global (`~/.kimi/skills/`) and local (`.kimi/skills/`) install
  - New `platforms/kimi/INSTALL.md`: LLM-optimized installation guide for humans and agents
  - New `platforms/kimi/README.md`: platform overview and quick reference
  - `upgrade` skill extended with Kimi CLI detection (`kimi-global`, `kimi-local`)
  - `upgrade` skill: version check, sparse-clone upgrade path, and verification for Kimi CLI
  - Root `README.md` updated with Kimi CLI installation and update instructions

### Fixed

- **Kimi CLI skills fully self-contained**: All 11 skills ported to `platforms/kimi/skills/`
  - All agent definitions inlined (no external `agents/*.md` dependencies)
  - All references inlined (no `../../references/` paths that break in Kimi CLI)
  - Uses Kimi CLI's built-in subagent types: `coder`, `explore`, `plan`
  - `setup.sh` now copies shared `references/` alongside skills
  - `references/agent-invocation.md` made platform-agnostic (removed OpenCode-only `mode`/`name` params)

## [0.4.1] - 2026-04-23

### Added

- **Kimi CLI platform**: Full install, uninstall, and upgrade support for Kimi CLI
  - New `platforms/kimi/setup.sh`: global (`~/.kimi/skills/`) and local (`.kimi/skills/`) install
  - New `platforms/kimi/INSTALL.md`: LLM-optimized installation guide for humans and agents
  - New `platforms/kimi/README.md`: platform overview and quick reference
  - `upgrade` skill extended with Kimi CLI detection (`kimi-global`, `kimi-local`)
  - `upgrade` skill: version check, sparse-clone upgrade path, and verification for Kimi CLI
  - Root `README.md` updated with Kimi CLI installation and update instructions

## [0.4.0] - 2026-04-22

### Added

- **upgrade skill**: Platform-aware upgrade skill for both Claude Code and OpenCode
  - Auto-detects platform via runtime markers (plugin cache, OpenCode directories) with user fallback
  - Checks current vs latest version via GitHub API (gh CLI → curl → raw plugin.json fallback)
  - Claude Code: Clears plugin cache to trigger fresh download on next skill invocation
  - OpenCode: Fully automated upgrade via sparse git clone + setup.sh re-run
  - Post-upgrade verification confirms installed version matches expected
  - No subagents required — coordinator-only skill with inline shell commands
  - Version marker file `.codewright-version` written by setup.sh for OpenCode version tracking

## [0.3.9] - 2026-04-22

### Added

- **CI Validation Loop**: New pre-commit CI validation phase for `auto-dev`, `bug-fixer`, and `github-issue-fixer` skills
  - Runs build, tests, lint, type checks, and CI-specific scripts before any final commit
  - Fixes failures automatically in a loop (max 3 iterations, separate budget from review loop)
  - If CI still failing after 3 iterations → enters report mode (no commit, user decides)
  - New `ci-validator.md` agent: detects and runs project CI tooling (npm/cargo/go/maven/gradle/make)
  - `auto-dev`: CI Validation added to Phase 7 before commit
  - `bug-fixer`: CI Validation added to Phase 7 before commit
  - `github-issue-fixer`: New Wave 8 (CI Validation) inserted, old Wave 8 becomes Wave 9

## [0.3.8] - 2026-04-21

### Added

- **bug-fixer skill**: Specialized TDD-based bug-fixing agent with 8-phase workflow:
  - Phase 1: Bug Analyst scans codebase, identifies root cause candidates, asks adaptive questions
  - Phase 2: Reproducer writes a failing test (TDD RED) to confirm the bug
  - Phase 3: Fix Planner designs minimal fix, Fixer applies it (TDD GREEN)
  - Phases 4-6: Full review pipeline — 4-reviewer review-fix loop (max 5 iterations), test hardening, acceptance review
  - 3 new specialized agents: bug-analyst, reproducer, fix-planner
  - 7 adapted agents from auto-dev: fixer, test-runner, test-writer, 4 reviewers (logic, security, quality, architecture)
  - Bug-fix specific report template with root cause documentation and TDD verification
- **OpenCode platform**: Added `bug-fixer` skill to OpenCode platform (10 skills total), updated setup.sh and INSTALL.md

## [0.3.7] - 2026-04-19

### Added

- **OpenCode platform support (PoC)**: Bridge plugin `@codewright/opencode` that enables Codewright skills to run in OpenCode CLI
  - `cw_agent` tool registered via plugin `tool` hook (SDK client closure, not standalone file — ToolContext has no client access)
  - `cw-explore` agent — read-only analysis container (equivalent to `subagent_type: "Explore"`)
  - `cw-worker` agent — code modification container (equivalent to `mode: "auto"`)
  - Orchestrator using real SDK types: `session.create()`, `session.prompt()` with `Part[]` input/output, `session.delete()`
  - `Promise.allSettled`-based parallel execution with abort signal propagation, 5-minute timeouts
  - `extractTextFromParts()` — extracts text from SDK `Part[]` (filters `TextPart` from reasoning, tool, and other part types)
  - `pr-reviewer` skill ported to OpenCode (3-agent parallel PR review)
  - `setup.sh` installer for `.opencode/` directory setup (agents, skills)
  - 25 unit + integration tests (types, formatResults, spawnAgent, spawnParallel with mock client)
  - Plugin exports both `default` and `server` for `PluginModule` compatibility

### Changed

- **CLAUDE.md**: Updated repository overview to reflect multi-platform support and new `platforms/` directory structure

## [0.3.6] - 2026-04-19

### Changed

- **auto-dev**: Major upgrade to review pipeline, adopting github-issue-fixer patterns:
  - 4 parallel reviewers always (Logic, Security, Quality, Architecture) instead of 1-3 selected by task type
  - Dynamic reviewer participation — only reviewers with findings re-enter next round
  - 5-iteration budget (shared between review-fix loop and acceptance) instead of 3
  - New Phase 5: Test hardening with regression, edge-case, and error-path tests
  - New Phase 6: Acceptance review — all 4 reviewers verify code + hardening tests together
  - Report mode when iterations exhausted (no commit, findings documented) instead of simple keep/revert
  - Optional UI mockup generation in Phase 2 — served via localhost for user review
  - 3 new agents: architecture-reviewer, test-writer, mockup-designer
  - New finding-format.md with consolidation rules for 4 reviewers
  - Updated report template with hardening, acceptance, and report mode sections

## [0.3.5] - 2026-04-19

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

## [0.3.1] - 2026-04-12

### Changed

- **auto-dev**: Questions now include recommendations with reasoning. Questions are presented one at a time, waiting for user response before proceeding.

## [0.3.0] - 2026-04-11

### Added

- **auto-dev**: New skill — universal autonomous task executor with adaptive questions, parallel implementation agents, and iterative review-fix loop (8 agent types, 6 phases).

## [0.2.0] - 2026-04-09

### Added

- **codebase-onboarding**: New skill — analyzes codebases and generates ARCHITECTURE.md / GETTING-STARTED.md (3 agents).
- **test-engineer**: New skill — finds coverage gaps and writes missing tests in 2 waves (5 agents).
- **pr-reviewer**: New skill — multi-perspective PR review with 3 parallel agents (Logic, Security, Quality).
- **perf-analyzer**: New skill — performance bottleneck analysis with smart agent selection (4 agents: Bundle, Query, Runtime, Infra).

## [1.2.0] - 2026-04-09

### Changed

- All skills, agent prompts, references, and scripts translated from German to English.
- SKILL.md description fields now include both English (primary) and German (secondary) trigger phrases.
- Shell script comments and output strings translated to English.

## [1.1.0] - 2026-04-09

### Hinzugefügt

- Shared `references/agent-invocation.md` — Standard für Agent-Start, Rückgabeformat und Fehlerbehandlung.
- Shared `references/finding-format.md` — Vereinheitlichtes Finding-Format für alle Analyse-Agenten.
- `github-issue-fixer/agents/coder.md` — Fehlender Agent für Phase 3 (Fix-Implementierung).
- Datei-Partitionierungs-Algorithmus für codebase-doctor Wave 2 (Auto-Fix).
- Loop-Limit (max 2 Iterationen) für codebase-doctor Wave 3 (Review).
- Fixbar-Bewertung in alle 7 codebase-doctor Agenten integriert.

### Geändert

- **refactor-orchestrator** komplett in modulare Struktur aufgeteilt (4 Agent-Dateien + Report-Template).
- `/tmp/`-basierte Inter-Agent-Kommunikation durch Markdown-Antworten ersetzt.
- `claude -p` Referenzen durch Agent-Tool-Invokation ersetzt.
- Severity-Emojis (🔴🟠🟡🟢) in codebase-doctor vereinheitlicht mit audit-project.
- Severity-Bereiche in quality.md und api-consistency.md erweitert (bis `high`).
- Terminologie vereinheitlicht: "Risiko" → "Auswirkung" in allen Agenten.
- Rate-Limit in audit-project SKILL.md auf 2s angepasst (konsistent mit Script).

### Behoben

- `disable-model-invocation: true` in github-issue-fixer entfernt (blockierte Skill-Aufruf).
- `eval "$@"` Sicherheitslücke in `detect-and-run-tests.sh` durch direkte Ausführung ersetzt.
- Subshell-Variable-Bug in `create-audit-issues.sh` (Process Substitution statt Pipe).
- Fehlerhafte JSON-Ausgabe in `create-audit-issues.sh` korrigiert.
- Fehlerhafte Issue-Count-Berechnung in `project-info.sh` korrigiert.
- Fehlerhafte Language-Array-Generierung in `project-info.sh` korrigiert.
- Fehlende Exclude-Patterns in github-issue-fixer Analyzer-Agent hinzugefügt.

## [1.0.0] - 2026-04-09

### Hinzugefügt

- **audit-project**: Umfassendes Projekt-Audit mit 5 parallelen Subagenten (Security, Bugs, Code-Hygiene, Struktur, GitHub Issues) und automatischer GitHub Issue-Erstellung.
- **codebase-doctor**: 3-Wellen Codebase-Analyse (7 Analyse-Agenten → Auto-Fix → Review & Verify) mit automatischer Fehlerbehebung.
- **github-issue-fixer**: Systematischer GitHub Issue Fix-Workflow (Analyse → Plan → Fix → Verify → Commit) mit optionaler Browser-Verifikation via MCP DevTools.
- **refactor-orchestrator**: Multi-Agent Refactoring mit Teamleader-Koordination und parallelen Scout/Architekt/Worker/Test-Agenten.
- Plugin-Manifest (`.claude-plugin/plugin.json`) für die Installation als Claude Code Plugin unter dem Namen **codewright**.
- README.md mit Installationsanleitung und Skill-Dokumentation.
- CLAUDE.md für Claude Code Kontext.
