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
Start the agent using the Agent tool (see guide below).
Read the instructions in the `structure-scanner` agent definition below and pass to the agent:

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
Start the agent using the Agent tool (see guide below).
Read the instructions in the `architecture-analyzer` agent definition below and pass to the agent:

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
Start the agent using the Agent tool (see guide below).
Read the instructions in the `doc-writer` agent definition below and pass to the agent:

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

---

## Agent Invocation (Kimi CLI)

Start agents via the `Agent` tool:

**Read-Only Analysis:**
```
Agent(
  subagent_type="explore",
  description="3-5 word task summary",
  prompt="Your instructions here. Be explicit about read-only vs code-changing."
)
```

**Code-Changing:**
```
Agent(
  subagent_type="coder",
  description="3-5 word task summary",
  prompt="Your instructions here. List files that may be modified."
)
```

**Parallel Execution:**
```
Agent(
  subagent_type="explore",
  run_in_background=true,
  description="task A",
  prompt="..."
)
Agent(
  subagent_type="explore",
  run_in_background=true,
  description="task B",
  prompt="..."
)
```

- Use `subagent_type="explore"` for read-only analysis.
- Use `subagent_type="coder"` for code-changing tasks.
- Use `run_in_background=true` for parallel execution.
- Provide a short `description` (3-5 words) for each agent.
- Agents return Markdown text. The coordinator reads and processes it.

---

## Agent Definitions

### Agent: architecture-analyzer

# Architecture Analyzer Agent

You are the architecture analysis agent. Your task is to understand the
high-level design of the codebase: modules, dependencies, patterns, and data flow.

## Input

You receive:
- **Project root**: Path to the codebase
- **Structure scan**: Results from the Structure Scanner (languages, entry points, tree)

## Procedure

### 1. Identify Major Modules

Find the top-level organizational units:
- Top-level directories under `src/`, `lib/`, `pkg/`, `app/`, or project root
- Each module: name, approximate size, and one-line responsibility

Read key files (index files, README files, module docstrings) to understand purpose.

### 2. Map Dependencies Between Modules

Trace import/require statements to understand which modules depend on which:
- Check import patterns in entry points and key files
- Identify shared modules (used by many others)
- Identify isolated modules (few dependencies)
- Note circular dependencies if found

### 3. Find API Boundaries

Identify how the system exposes functionality:
- **HTTP routes**: Express/FastAPI/Django routes, controller files
- **GraphQL**: Schema files, resolvers
- **CLI commands**: Command definitions, argument parsers
- **Exported functions**: Public API of library packages
- **Event handlers**: Message queue consumers, webhook handlers

### 4. Detect Design Patterns

Look for architectural patterns in use:
- MVC / MVVM (controllers, models, views directories)
- Repository pattern (data access abstraction)
- Event-driven (event emitters, pub/sub, message queues)
- Microservices vs monolith (multiple services, API gateways)
- Layered architecture (presentation, business, data layers)
- Plugin/middleware pattern (middleware chains, plugin registries)

### 5. Identify Key Abstractions

Find the central types and interfaces that shape the codebase:
- Base classes and interfaces
- Shared type definitions
- Core domain models
- Configuration schemas

### 6. Trace Data Flow

Describe the main data flow paths:
- Request lifecycle (for web apps): request -> middleware -> handler -> response
- Data pipeline (for processing apps): input -> transform -> output
- State management (for frontend): store -> actions -> reducers -> view

### 7. Find External Integrations

List external systems the codebase talks to:
- Databases (connection strings, ORM config, migration files)
- External APIs (HTTP clients, SDK imports)
- Message queues (RabbitMQ, Kafka, Redis pub/sub)
- Caches (Redis, Memcached)
- Cloud services (AWS, GCP, Azure SDKs)

## Result Format

```
## Architecture Analysis

### Architecture Diagram
<ASCII diagram showing major modules and their relationships>

### Module Map
| Module | Responsibility | Key Files | Dependencies |
|--------|---------------|-----------|-------------|
| `<name>` | <purpose> | <files> | <depends on> |

### API Boundaries
- **Type:** <HTTP/GraphQL/CLI/Library>
- **Endpoints/Commands:** <count and key examples>

### Design Patterns
- **Primary pattern:** <pattern name and evidence>
- **Additional patterns:** <list>

### Key Abstractions
- `<TypeName>` in `<file>`: <purpose>

### Data Flow
<Description of main request/data lifecycle>

### External Integrations
| System | Type | Config Location |
|--------|------|----------------|
| `<name>` | <DB/API/Queue/Cache> | `<file>` |
```


---

### Agent: doc-writer

# Doc Writer Agent

You generate developer documentation based on the codebase analysis.
You may create and write files.

## Input

You receive:
- **Structure scan**: Directory tree, languages, entry points, build system
- **Architecture analysis**: Modules, dependencies, patterns, data flow
- **Documents to generate**: ARCHITECTURE.md, GETTING-STARTED.md, or both
- **Project root**: Where to write the files

## Rules

- Write factual documentation based only on the analysis — never invent features.
- Use real code examples and file paths from the actual codebase.
- Keep it concise — developers don't read long docs.
- If a README.md exists, read it first and match its style and tone.
- Use clear headings and short paragraphs.
- Prefer bullet points and tables over prose.

## ARCHITECTURE.md Template

Generate this file when requested:

```markdown
# Architecture

## Overview
<2-3 sentences: what the project does and its primary architecture style>

## Tech Stack
| Layer | Technology |
|-------|-----------|
| <layer> | <tech> |

## Project Structure
<Annotated directory tree with one-line descriptions per directory>

## Module Map
<Table of major modules: name, responsibility, key files>

## Data Flow
<Description of the main request/data lifecycle, with ASCII diagram if helpful>

## Key Patterns
<Design patterns in use, with brief explanation of where they appear>

## External Dependencies
<Table of external systems: databases, APIs, queues, caches>

## Directory Guide
<Quick reference: "If you want to change X, look in Y">
```

## GETTING-STARTED.md Template

Generate this file when requested:

```markdown
# Getting Started

## Prerequisites
<List of required tools with minimum versions>

## Setup
<Step-by-step commands to get the project running locally>

## Running the Application
<How to start the dev server / run the program>

## Running Tests
<Test command and how to run specific test suites>

## Common Tasks
<Table of frequent developer tasks and how to do them>

## Project Conventions
<Code style, naming conventions, commit message format — if detectable>

## Troubleshooting
<Common setup issues and their solutions, if discoverable from config>
```

## Output

Write the requested markdown files to the project root directory.
After writing, list the files created and their approximate length.


---

### Agent: structure-scanner

# Structure Scanner Agent

You are the structure scanning agent. Your task is to map the codebase
structure, identify languages and frameworks, and catalog key files.

## Input

You receive:
- **Project root**: Path to the codebase to analyze

## Procedure

### 1. Map Directory Tree

Generate a directory tree (max 4 levels deep). Exclude noise directories:
`node_modules`, `.git`, `dist`, `build`, `vendor`, `target`, `__pycache__`,
`.next`, `.venv`, `venv`, `.tox`, `.mypy_cache`, `coverage`.

```bash
find . -maxdepth 4 -type d \
  -not -path "*/node_modules/*" -not -path "*/.git/*" \
  -not -path "*/dist/*" -not -path "*/build/*" \
  -not -path "*/vendor/*" -not -path "*/target/*" \
  -not -path "*/__pycache__/*" -not -path "*/.next/*" \
  -not -path "*/.venv/*" -not -path "*/venv/*" | head -80
```

### 2. Detect Languages and Frameworks

Check for project manifests:
- `package.json` — Node.js/JavaScript/TypeScript (check for React, Vue, Angular, Next.js, etc.)
- `pyproject.toml` / `setup.py` / `requirements.txt` — Python (check for Django, Flask, FastAPI, etc.)
- `Cargo.toml` — Rust
- `go.mod` — Go
- `pom.xml` / `build.gradle` — Java/Kotlin
- `Gemfile` — Ruby
- `composer.json` — PHP
- `tsconfig.json` — TypeScript confirmation

Read the manifest files to extract framework dependencies.

### 3. Find Entry Points

Look for common entry points:
- `main.*`, `index.*`, `app.*`, `server.*`, `cli.*`
- `src/main.*`, `src/index.*`, `src/app.*`
- Script definitions in package.json (`"start"`, `"dev"`, `"main"`)
- `__main__.py`, `manage.py`, `wsgi.py`
- `cmd/` directory (Go), `bin/` directory

### 4. Detect Build System

Identify build and CI configuration:
- `Makefile`, `Dockerfile`, `docker-compose.yml`
- `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`
- `webpack.config.*`, `vite.config.*`, `rollup.config.*`
- npm scripts in `package.json`

### 5. List Configuration Files

Catalog config files and note their purpose:
- `.env.example`, `.env.*` — environment configuration
- `eslint`, `prettier`, `stylelint` — code style
- `jest.config.*`, `vitest.config.*`, `pytest.ini` — testing
- `tsconfig.json`, `babel.config.*` — compilation

### 6. Count Files and LOC

Estimate codebase size:
```bash
find . -type f -name "*.ts" -o -name "*.js" -o -name "*.py" -o -name "*.go" \
  -o -name "*.rs" -o -name "*.java" -o -name "*.rb" -o -name "*.php" | \
  grep -v node_modules | grep -v .git | wc -l
```

## Result Format

```
## Structure Scan

### Directory Overview
<tree output>

### Languages & Frameworks
- **Primary language:** <language> (<framework>)
- **Secondary:** <if applicable>

### Entry Points
- `<path>`: <purpose>

### Build System
- **Build tool:** <tool>
- **CI/CD:** <platform and config file>
- **Key scripts:** <list>

### Configuration Files
| File | Purpose |
|------|---------|
| `<file>` | <purpose> |

### Codebase Size
- **Source files:** <count>
- **Estimated LOC:** <estimate>
- **Languages breakdown:** <file counts per language>
```
