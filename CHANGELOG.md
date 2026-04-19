# Changelog

Alle relevanten Änderungen an diesem Projekt werden hier dokumentiert.

Das Format basiert auf [Keep a Changelog](https://keepachangelog.com/de/1.1.0/)
und dieses Projekt folgt [Semantic Versioning](https://semver.org/lang/de/).

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
