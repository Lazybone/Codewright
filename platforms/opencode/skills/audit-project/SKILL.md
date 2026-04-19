---
name: audit-project
description: >
  Runs a comprehensive project audit covering security, bugs, code hygiene,
  project structure, and GitHub Issues. Automatically creates a GitHub Issue
  for each finding via `gh`. Use this skill when the user wants to check,
  audit, or analyze their project. Also triggers on: "check my project",
  "code review the whole repo", "security check", "cleanup",
  "what can be improved", "are there any problems", "find technical debt",
  "project health", "audit", "full analysis".
  Also triggers on (German): "Projekt kontrollieren", "Code Review des ganzen Repos",
  "Sicherheitscheck", "Cleanup", "was kann man verbessern", "gibt es Probleme",
  "technische Schulden finden", "Projekt-Gesundheit", "vollständige Analyse".
  Works with parallel subagent teams.
disable-model-invocation: true
---

# Project Audit — Coordinator

This skill performs a complete project audit with 5 specialized
subagents. Each finding is created as a GitHub Issue.

## Prerequisites

- Git repository with configured GitHub remote
- GitHub CLI (`gh`) installed and authenticated
- Check both at the start:

```bash
git remote -v
gh auth status
```

If `gh` is not available or not authenticated: Inform the user
and offer to create the report as a Markdown file instead.

## Phase 1: Detect Project

Before launching the subagents, collect basic project information:

```bash
# Detect language and framework
ls package.json pyproject.toml Cargo.toml go.mod Gemfile pom.xml \
   build.gradle composer.json 2>/dev/null

# Estimate project size
find . -type f \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -not -path '*/vendor/*' \
  -not -path '*/target/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*/dist/*' \
  -not -path '*/build/*' \
  | head -500 | wc -l

# Check existing labels in the repo
gh label list --limit 100
```

Create missing labels for the audit categories (one-time):

```bash
gh label create "audit:security" --color "D73A4A" --description "Security finding from project audit" 2>/dev/null || true
gh label create "audit:bug" --color "FC8403" --description "Bug/quality finding from project audit" 2>/dev/null || true
gh label create "audit:hygiene" --color "0075CA" --description "Code hygiene finding from project audit" 2>/dev/null || true
gh label create "audit:structure" --color "7057FF" --description "Project structure finding from project audit" 2>/dev/null || true
gh label create "audit:stale-issue" --color "BFDADC" --description "Stale or duplicate issue from audit" 2>/dev/null || true
gh label create "severity:critical" --color "B60205" --description "Critical severity" 2>/dev/null || true
gh label create "severity:high" --color "D93F0B" --description "High severity" 2>/dev/null || true
gh label create "severity:medium" --color "FBCA04" --description "Medium severity" 2>/dev/null || true
gh label create "severity:low" --color "0E8A16" --description "Low severity" 2>/dev/null || true
```

Inform the user about the detected setup and then launch the subagents.

## Phase 2: Parallel Analysis

Launch the 5 subagents. Each agent receives:
- The detected language/framework info
- The project size
- The task to return findings in a structured format

Read the respective agent file and launch the agent:

| # | Agent | File | Type | Task |
|---|-------|------|------|------|
| 1 | Security Auditor | `agents/security.md` | Explore | Find security vulnerabilities |
| 2 | Bug Detector | `agents/bugs.md` | Explore | Find bugs & quality issues |
| 3 | Hygiene Inspector | `agents/hygiene.md` | Explore | Find dead code, cleanup needs |
| 4 | Structure Reviewer | `agents/structure.md` | Explore | Project structure & best practices |
| 5 | Issues Auditor | `agents/issues.md` | Explore | Analyze GitHub Issues |

Launch the agents according to `../../references/agent-invocation.md` as Explore subagents.
Launch all 5 in parallel as Explore subagents (read-only codebase access).
Each agent returns findings in the format from `references/finding-format.md`.

## Phase 3: Consolidate Findings

When all agents are finished:

1. **Deduplicate**: Merge identical findings from different agents.
   E.g., the Security agent and the Bug agent might both find a missing
   input validation.

2. **Assign severity** (if not already done):
   - 🔴 **critical**: Active security vulnerability, data loss risk, crashes
   - 🟠 **high**: Security risk, severe bugs, broken functionality
   - 🟡 **medium**: Potential bugs, code quality, outdated dependencies
   - 🟢 **low**: Cleanup, style, nice-to-have improvements

3. **Sort**: Critical → High → Medium → Low

4. **Cross-reference**: Check whether an open issue already exists for a finding.
   The Issues Auditor provides the list of existing issues. Skip findings
   that are already tracked as issues and note this in the report.

## Phase 4: Create GitHub Issues

Create an issue for each finding. Read `references/issue-template.md`
for the exact format.

```bash
gh issue create \
  --title "<Title>" \
  --body "<Body>" \
  --label "<labels,comma-separated>"
```

Rules:
- Create issues sorted by severity (critical first)
- Maximum 30 issues per audit run (if more: take the most important ones,
  mention the rest in the summary report)
- Pause 2 seconds between `gh issue create` calls to avoid
  rate limits
- Collect the created issue numbers for the final report

Ask the user before creating the issues:
"I have identified X findings (Y critical, Z high, ...).
Should I create issues for all of them, or would you like to review the list first?"

## Phase 5: Final Report

Create a Markdown report and display it to the user in the console.
Also save it as `AUDIT-REPORT.md` in the repo root (on a
separate branch `audit/<date>`).

The report follows the format in `references/report-template.md`.

Finally:
```bash
git checkout -b audit/$(date +%Y-%m-%d)
git add AUDIT-REPORT.md
git commit -m "docs: add project audit report $(date +%Y-%m-%d)"
```

Ask the user whether the branch should be pushed.

## Error Handling

- **`gh` not available**: Report only as Markdown, do not create issues.
  Offer to output the findings as a Markdown list that the user
  can manually enter as issues.
- **No GitHub remote**: Same as above, Markdown report only.
- **Rate limit on `gh`**: Pause and inform the user, save remaining issues
  in a file `remaining-issues.md`.
- **Very large project (>1000 files)**: Ask the user which
  directories should be prioritized. Do not analyze the entire repo
  if it is unrealistically large.
- **Agent returns no findings**: That is OK, note in the report
  that the area is clean.
