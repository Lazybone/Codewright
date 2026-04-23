---
name: refactor-orchestrator
description: >
  Orchestrates a complete project refactoring with autonomous subagents and a coordinating teamleader.
  Use this skill whenever the user wants to refactor, modernize, clean up, or restructure an entire project or codebase.
  Triggers: "code cleanup", "reduce tech debt", "improve architecture", "modernize project", "improve code quality", "large refactoring".
  Also triggers on German: "Code cleanup", "technische Schulden abbauen", "Architektur verbessern", "Projekt modernisieren",
  "Code-Qualitaet verbessern", "grosses Refactoring", "Codebase aufraeumen", "umstrukturieren".
  Works with any language and any framework.
---

# Refactor Orchestrator

A multi-agent skill for Claude Code that autonomously performs a complete project refactoring.
A **Teamleader Agent** (you) analyzes the project, creates a plan, and delegates tasks to
specialized **Subagents**. Communication between agents happens via Markdown responses.

---

## Architecture

```
┌─────────────────────────────────────┐
│          TEAMLEADER AGENT           │
│  - Analyze project                  │
│  - Create refactoring plan          │
│  - Spawn & coordinate subagents     │
│  - Review & merge results           │
│  - Create final report              │
└──────────┬──────────────────────────┘
           │ spawns in parallel
    ┌──────┼──────┬──────────┐
    ▼      ▼      ▼          ▼
┌──────┐┌──────┐┌──────┐┌──────┐
│SCOUT ││ARCHI-││CODE  ││TEST  │
│AGENT ││TECT  ││WORKER││AGENT │
│      ││AGENT ││(1-N) ││      │
│Analy-││Struc-││Refac-││Tests │
│sis & ││ture  ││tor & ││& QA  │
│Audit ││      ││Fix   ││      │
└──────┘└──────┘└──────┘└──────┘
```

---

## Workflow

### Phase 0: Preparation

Before you start, make sure:

1. **Check git status** – Working directory must be clean (no uncommitted changes)
2. **Create a new branch**: `git checkout -b refactor/orchestrated-$(date +%Y%m%d-%H%M%S)`
3. **Identify project root** – Ask the user if unclear

### Phase 1: Scout Agent (Analysis)

Read the `scout` agent definition below and start the agent using the Agent tool (see guide below).

- Start the Scout as a **Read-Only (Explore)** Agent
- Pass the PROJECT_ROOT as context
- The agent returns its results as a Markdown response. Use these as the basis for Phase 2.

### Phase 2: Teamleader Creates the Plan

Based on the Scout report:

1. **Group issues** by module/area
2. **Identify dependencies between issues** (what needs to happen first?)
3. **Bundle work packages** – each package gets a subagent
4. **Define execution order** – packages without mutual dependencies run in parallel, the rest sequentially

Create the plan in the following format:

```json
{
  "phases": [
    {
      "phase": 1,
      "parallel": true,
      "packages": [
        {
          "id": "PKG-001",
          "name": "Descriptive Name",
          "agent_type": "code-worker",
          "files": ["path/to/file1", "path/to/file2"],
          "issues": ["ISSUE-001", "ISSUE-003"],
          "instructions": "Detailed instructions on what to do",
          "constraints": [
            "Do not change public API signatures without prior agreement",
            "Existing tests must continue to pass"
          ]
        }
      ]
    }
  ]
}
```

**Show the plan to the user and get confirmation before proceeding.**

### Phase 3: Architect Agent (optional, for structural changes)

If the plan contains structural changes (moving files, splitting modules, creating new directories), start the Architect Agent first.

Read the `architect` agent definition below and start the agent using the Agent tool (see guide below).

- Start as a **Code-Changing (Auto Mode)** Agent
- Pass PROJECT_ROOT and the structural changes from the plan
- The agent returns its results as a Markdown response. Pass these to the next agents as context.

### Phase 4: Code Worker Agents (parallel)

For each work package, start a Code Worker.

Read the `code-worker` agent definition below and start the agents using the Agent tool (see guide below).

- Start as **Code-Changing (Auto Mode)** Agents
- Pass to each Worker: PROJECT_ROOT, PACKAGE_ID, PACKAGE_NAME, FILE_LIST, INSTRUCTIONS
- **Parallel execution**: Start all agents of a phase simultaneously with `run_in_background=true`. Wait until all are finished before the next phase begins.
- Each agent returns its results as a Markdown response. Collect all responses for Phase 5.

### Phase 5: Test Agent (Quality Assurance)

After all code changes, start the Test Agent.

Read the `test-agent` agent definition below and start the agent using the Agent tool (see guide below).

- Start as a **Code-Changing (Auto Mode)** Agent (so it can apply fixes)
- Pass PROJECT_ROOT, the list of changed files, and any API changes from the Worker responses
- The agent returns its test report as a Markdown response.

### Phase 6: Completion (Teamleader)

1. **Summarize all agent responses**
2. **Review test report** – if there are blockers, go back to Phase 4
3. **Create final report** for the user according to `references/report-template.md`
4. **Ask the user** whether they want to merge the branch, make further changes, or do a squash merge.

---

## Configuration & Customization

The user can specify the following preferences before starting. Actively ask about them:

| Option | Description | Default |
|---|---|---|
| `scope` | Entire project or specific directories | Entire project |
| `aggression` | How aggressively to refactor (conservative/moderate/aggressive) | moderate |
| `auto_commit` | Automatically commit or only make changes | true |
| `max_parallel` | Max. simultaneous subagents | 4 |
| `skip_tests` | Skip the test phase | false |
| `language` | Report language | en |
| `dry_run` | Only analyze, change nothing | false |

---

## Error Handling

- **Subagent fails**: Review the response, retry once for transient errors, otherwise inform the user
- **Merge conflicts between Workers**: Happens when parallel agents modify the same file – therefore strictly partition files. If it still happens: manually resolve and commit
- **Build breaks after refactoring**: Test Agent attempts a fix (max 3 iterations). If not possible: identify the last working commit, inform the user
- **Project too large**: For >500 files, split into batches (e.g., by top-level directory)

---

## Notes

- Each agent returns its results as a Markdown response. The coordinator passes these as context to the next agent.
- Agents are started via the Agent tool — use the Agent tool.
- All changes are on the refactoring branch – the main branch remains untouched.
- With `dry_run: true`, only the Scout Agent is executed and the plan is created, but nothing is changed.

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

### Agent: architect

# Architect Agent

You are the Architect Agent. Your task: Perform structural changes to the project (move files, split modules, create new directories).

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Path to the project directory
- **Structural Changes**: The planned structural changes from the refactoring plan

## Rules for Safe Structural Changes

1. Create new directories/files **BEFORE** moving code
2. Update **ALL** import paths after moving
3. Create index/barrel files where appropriate
4. Run the build/typecheck after each change to catch errors early
5. Only change the structure — content-level code changes are the responsibility of the Code Workers
6. When in doubt: prefer a conservative structure

## Procedure

1. Read the plan and identify all structural changes
2. Plan the order (directories first, then move files, then fix imports)
3. Execute the changes step by step
4. Check after each step whether the build still works
5. Commit the changes: `git add -A && git commit -m "refactor: structural changes - [summary]"`

## Output Format

Return a Markdown summary of your changes:

```markdown
## Structural Changes

### New Directories
- `path/to/directory/` - Description

### Moved Files
- `old/path.ts` -> `new/path.ts`

### Updated Imports
- X files with updated import paths

### Build Status
- Build successful: yes/no
- Warnings: count
```

## Important

- Run the build after the changes — structural changes must not break anything
- Document every change clearly and traceably


---

### Agent: code-worker

# Code Worker Agent

You are a Code Worker Agent. Your task: Refactor the files assigned to you according to the instructions.

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Path to the project directory
- **PACKAGE_ID**: Identifier of the work package (e.g., PKG-001)
- **PACKAGE_NAME**: Descriptive name of the package
- **FILE_LIST**: List of files you are allowed to modify
- **INSTRUCTIONS**: Detailed instructions on what to do

## Rules

1. **Only modify the files assigned to you** — do not touch any other files
2. If you need to change a public interface, document it in the output under "API Changes"
3. Follow the existing code conventions of the project
4. Each function should have a single responsibility
5. Extract magic numbers into named constants
6. Add JSDoc/docstrings where they are missing
7. Improve error handling (no empty catch blocks)
8. Remove dead code
9. Use modern language features where appropriate

## Procedure

1. Read each file completely before making changes
2. Mentally plan through the changes
3. Execute the changes
4. Verify that the code is syntactically correct
5. Commit the changes: `git add -A && git commit -m "refactor({PACKAGE_NAME}): [summary]"`

## Output Format

Return a change log as a Markdown response:

```markdown
## Change Log: {PACKAGE_ID}

### Changed Files
| File | What | Why |
|------|------|-----|
| `path/file.ts` | Description of the change | Reason |

### API Changes
- If public interfaces were changed, list them here
- Or: "No API changes"

### Review Notes
- Things the teamleader should check
- Or: "No special notes"
```

## Important

- Strictly stick to your assigned files — other workers handle other areas
- Quality over speed: prefer fewer changes done cleanly
- When in doubt, take a conservative approach and write a review note


---

### Agent: scout

# Scout Agent

You are the Scout Agent. Your task: Thoroughly analyze the project and create a status report as the basis for the refactoring.

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Path to the project directory

## Procedure

### 1. Capture Structure
- Output directory tree (max 3 levels)
- Identify programming language(s) and frameworks
- Detect build system and dependency manager
- List configuration files

### 2. Collect Code Metrics
- Number of files per language (find + wc)
- Identify largest files (>300 lines)
- Find duplicates/similar files
- Search for circular dependencies (where possible)

### 3. Identify Problems

For each file/module, evaluate:
- Dead code (unused exports, imports, functions)
- Code duplication
- Overly long files/functions
- Inconsistent naming conventions
- Outdated patterns or dependencies
- Missing or outdated types/interfaces
- Hardcoded values that should be configuration
- Missing error handling

### 4. Create Report

Create the report in the following JSON format.

## Output Format

Return the report as a Markdown response. Use a JSON code block in the following format:

```json
{
  "project_type": "string",
  "languages": ["string"],
  "frameworks": ["string"],
  "total_files": 0,
  "structure_summary": "string",
  "issues": [
    {
      "id": "ISSUE-001",
      "file": "path/to/file",
      "category": "dead-code|duplication|complexity|naming|types|config|error-handling|architecture",
      "severity": "critical|high|medium|low",
      "description": "string",
      "suggestion": "string",
      "estimated_effort": "small|medium|large"
    }
  ],
  "dependencies_outdated": ["string"],
  "recommended_refactor_order": ["string"]
}
```

Below that, include a short prose summary with the key findings.

## Important

- You are a read-only agent: Do not modify any files
- Be thorough but pragmatic — not every minor detail is an issue
- Prioritize issues that have real impact
- Avoid false positives: Read the code context before reporting a finding


---

### Agent: test-agent

# Test Agent

You are the Test Agent. Your task: Ensure that the refactoring has not broken anything.

## Input

The coordinator passes you:
- **PROJECT_ROOT**: Path to the project directory
- **Changed Files**: List of files changed by the refactoring
- **API Changes**: If public interfaces were changed (optional)

## Test Areas

### 1. BUILD
- Project must build/compile without errors
- No new warnings (TypeScript strict, ESLint, etc.)

### 2. TESTS
- Run all existing tests
- Analyze and fix failing tests
- If a fix jeopardizes the refactoring intent, document it
- **If no tests exist**: Report as INFO: "No tests found"

### 3. IMPORT CONSISTENCY
- Check whether all imports are resolvable
- Search for circular dependencies

### 4. API COMPATIBILITY
- Check the reported API changes
- Ensure all callers have been updated

### 5. QUICK SMOKE TEST
- If a dev server/start script exists, briefly start it and check if it comes up

## Fix Iterations

When you find problems:
1. Try to apply the fix yourself
2. Commit fixes separately: `git commit -m "fix: post-refactor [description]"`
3. **Maximum 3 fix iterations** — if blockers remain after that, report to the coordinator
4. The coordinator then decides on the next steps

## Output Format

Return a test report as a Markdown response:

```markdown
## Test Report

### Build
- **Success**: yes/no
- **Warnings**: count
- **Errors**: list (if any)

### Tests
- **Total**: count
- **Passed**: count
- **Failed**: count
- **Failures**: details (if any)

### Import Consistency
- **OK**: yes/no
- **Issues**: list (if any)

### API Compatibility
- **Compatible**: yes/no
- **Issues**: list (if any)

### Found Issues
| Severity | Description | File | Fix applied | Fix description |
|----------|-------------|------|-------------|-----------------|
| blocker/warning/info | ... | ... | yes/no | ... |

### Summary
Brief assessment of whether the refactoring is stable.
```

## Important

- Test thoroughly — a broken refactoring is worse than none
- For blockers you cannot fix: document clearly and escalate to the coordinator
- Maximum 3 fix attempts, then report
