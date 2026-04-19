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

Read `agents/scout.md` and start the agent according to `../../references/agent-invocation.md`.

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

Read `agents/architect.md` and start the agent according to `../../references/agent-invocation.md`.

- Start as a **Code-Changing (Auto Mode)** Agent
- Pass PROJECT_ROOT and the structural changes from the plan
- The agent returns its results as a Markdown response. Pass these to the next agents as context.

### Phase 4: Code Worker Agents (parallel)

For each work package, start a Code Worker.

Read `agents/code-worker.md` and start the agents according to `../../references/agent-invocation.md`.

- Start as **Code-Changing (Auto Mode)** Agents
- Pass to each Worker: PROJECT_ROOT, PACKAGE_ID, PACKAGE_NAME, FILE_LIST, INSTRUCTIONS
- **Parallel execution**: Start all agents of a phase simultaneously with `run_in_background=true`. Wait until all are finished before the next phase begins.
- Each agent returns its results as a Markdown response. Collect all responses for Phase 5.

### Phase 5: Test Agent (Quality Assurance)

After all code changes, start the Test Agent.

Read `agents/test-agent.md` and start the agent according to `../../references/agent-invocation.md`.

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
- Agents are started via the Agent tool — see `../../references/agent-invocation.md` for details.
- All changes are on the refactoring branch – the main branch remains untouched.
- With `dry_run: true`, only the Scout Agent is executed and the plan is created, but nothing is changed.
