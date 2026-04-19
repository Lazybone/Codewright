---
name: codebase-onboarding
description: >
  Analyzes a codebase and generates comprehensive documentation including architecture overview,
  getting-started guide, and glossary. Use when the user wants to understand a new codebase,
  generate documentation, create architecture docs, or onboard onto a project.
  Triggers: "explain this codebase", "generate docs", "architecture overview", "onboard me",
  "what does this project do", "create README", "document this project".
  Also triggers on German: "Codebase erklären", "Dokumentation generieren", "Projekt verstehen",
  "Architektur-Überblick", "Was macht dieses Projekt".
---

# Codebase Onboarding — Agent-Based Workflow

This skill analyzes a codebase and generates developer documentation
using specialized sub-agents. Each agent has a clearly defined role.

## Prerequisites

- Git repository (for branch creation in Phase 5)
- The codebase to analyze must be the current working directory

## Workflow Overview

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  0. PREPARE  │────▶│  1. SCAN     │────▶│  2. ANALYZE  │
│  (main)      │     │  (Explore)   │     │  (Explore)   │
└──────────────┘     └──────────────┘     └──────────────┘
                                                │
┌──────────────┐     ┌──────────────┐           │
│  5. COMMIT   │◀────│  4. WRITE    │◀──────────│
│  (main)      │     │  (Auto)      │     ┌──────────────┐
└──────────────┘     └──────────────┘     │  3. PRESENT  │
                                          │  (main)      │
                                          └──────────────┘
```

## Step-by-Step Process

### Phase 0: Preparation

Run basic checks in the main agent:

```bash
git status
git remote -v
```

Detect the project root and confirm with the user which directory to analyze.

### Phase 1: Structure Scan

Start an **Explore sub-agent** for structure scanning.
Start the agent according to `../../references/agent-invocation.md`.
Read the instructions in `agents/structure-scanner.md` and pass to the agent:

- The project root path
- The task of mapping the codebase structure

The Structure Scanner returns:
- Directory tree overview
- Languages and frameworks detected
- Entry points and build system
- Configuration files and their purpose
- File counts and LOC estimate

### Phase 2: Architecture Analysis

Start an **Explore sub-agent** for architecture analysis.
Start the agent according to `../../references/agent-invocation.md`.
Read the instructions in `agents/architecture-analyzer.md` and pass to the agent:

- The project root path
- The structure scan results from Phase 1

The Architecture Analyzer returns:
- Module map with responsibilities
- Dependency graph between modules
- API boundaries
- Design patterns in use
- Data flow description
- External integrations

### Phase 3: Present Findings

Present a summary of Phase 1 and Phase 2 results to the user.
Include the key highlights: tech stack, architecture style, main modules.

Ask the user what documentation to generate:
1. **ARCHITECTURE.md** — Technical architecture overview
2. **GETTING-STARTED.md** — Developer setup and onboarding guide
3. **Both** (default)

Wait for user confirmation before proceeding.

### Phase 4: Generate Documentation

Start an **Auto-mode sub-agent** for documentation writing.
Start the agent according to `../../references/agent-invocation.md`.
Read the instructions in `agents/doc-writer.md` and pass to the agent:

- The structure scan results (Phase 1)
- The architecture analysis results (Phase 2)
- Which documents to generate (user choice from Phase 3)
- The project root path (so it knows where to write files)

The Doc Writer creates the selected markdown files in the project root.

### Phase 5: Commit & Wrap-up

Present the generated documentation to the user. Then:

1. Ask if any adjustments are needed — apply them if requested
2. Create a documentation branch: `git checkout -b docs/onboarding-<date>`
   (use format `YYYY-MM-DD` for the date)
3. Stage the generated files: `git add ARCHITECTURE.md GETTING-STARTED.md`
4. Commit with message: `docs: add onboarding documentation`
5. Ask whether to push and create a PR

## Error Handling

- If the project has no git repo: Skip branch creation, just generate the files.
- If the codebase is very large (>1000 files): Focus on the most important
  modules and note which areas were skipped.
- If a sub-agent does not respond: Inform the user which phase failed
  and offer to retry or skip that phase.

## Notes

- Never modify existing source code — this skill only reads and generates docs.
- If a README.md already exists, match its style and tone in generated docs.
- Inform the user about progress at each phase transition.
