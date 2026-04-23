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
| 1 | Security Auditor | the `security` agent definition below | Explore | Find security vulnerabilities |
| 2 | Bug Detector | the `bugs` agent definition below | Explore | Find bugs & quality issues |
| 3 | Hygiene Inspector | the `hygiene` agent definition below | Explore | Find dead code, cleanup needs |
| 4 | Structure Reviewer | the `structure` agent definition below | Explore | Project structure & best practices |
| 5 | Issues Auditor | the `issues` agent definition below | Explore | Analyze GitHub Issues |

Launch the agents using the Agent tool (see guide below) as Explore subagents.
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

### Agent: bugs

# Bug Detector

See the `bugs` agent definition below

This skill uses this agent as a read-only Explore subagent.
Findings are consolidated and created as GitHub Issues.


---

### Agent: hygiene

# Hygiene Inspector Agent

You are the code hygiene agent. Your task: Find dead code, unnecessary files,
duplicates, and anything that should be cleaned up. You work read-only.

## Areas to Check

### 1. Dead Code — Unused Imports & Variables

```bash
# JS/TS: Unused imports (basic — ESLint is more accurate)
# Search for imports and check whether they appear in the rest of the file
[ -f .eslintrc* ] || [ -f eslint.config.* ] && \
  npx eslint . --rule '{"no-unused-vars":"warn","@typescript-eslint/no-unused-vars":"warn"}' \
  --format json 2>/dev/null

# Python: Unused imports
command -v ruff &>/dev/null && ruff check --select F401 . 2>/dev/null
# Fallback
grep -rniE '^(import |from .* import )' --include="*.py" . 2>/dev/null \
  | grep -v node_modules | grep -v __pycache__

# Rust: Dead code warnings
[ -f Cargo.toml ] && cargo check --message-format json 2>/dev/null | grep "dead_code"

# Go: Unused imports (Go compiler reports these as errors)
[ -f go.mod ] && go vet ./... 2>&1
```

### 2. Dead Code — Unused Functions & Classes

Search for exported functions/classes and check whether they are imported:

```bash
# Find exported functions
grep -rniE '^export\s+(function|const|class|interface|type|enum)\s+(\w+)' \
  --include="*.{ts,tsx,js,jsx}" . 2>/dev/null | grep -v node_modules

# For each found: Check whether it is imported elsewhere
# (do this for suspicious candidates, not for everything)
```

Also check:
- Files that are not imported anywhere (orphaned modules)
- Functions that are only defined but never called
- Event handlers that are not bound to any event

### 3. Commented-Out Code

```bash
# Large blocks of commented-out code (3+ consecutive lines)
grep -rniE '^\s*(//|#|/\*|\*)\s*(function|class|if|for|while|return|import|const|let|var|def)\b' \
  --include="*.{ts,tsx,js,jsx,py,rb,go,rs,java}" . 2>/dev/null \
  | grep -v node_modules | grep -v '.git/'
```

Read the context: Individual commented-out lines with an explanation are OK.
Large commented-out code blocks without explanation → finding.

### 4. Files That Do Not Belong in the Repo

```bash
# Build artifacts
find . -type d \( \
  -name "node_modules" -o -name "dist" -o -name "build" -o -name ".next" \
  -o -name "__pycache__" -o -name "*.egg-info" -o -name "target" \
  -o -name ".cache" -o -name "coverage" -o -name ".nyc_output" \
  \) -not -path '*/.git/*' 2>/dev/null

# IDE/editor configs that typically do not belong in the repo
find . -name ".idea" -o -name ".vscode/settings.json" -o -name "*.swp" \
  -o -name "*.swo" -o -name ".DS_Store" -o -name "Thumbs.db" \
  2>/dev/null | grep -v '.git/'

# Log files
find . \( -name "*.log" -o -name "npm-debug.log*" -o -name "yarn-debug.log*" \) \
  -not -path '*/.git/*' 2>/dev/null

# Large binary files
find . -type f -size +1M -not -path '*/.git/*' -not -path '*/node_modules/*' \
  2>/dev/null | head -20
```

### 5. .gitignore Gaps

```bash
# Check whether a .gitignore exists
[ -f .gitignore ] && echo "OK: .gitignore present" || echo "MISSING: .gitignore"

# Check typical entries
if [ -f .gitignore ]; then
  for pattern in "node_modules" ".env" "dist" "build" "__pycache__" \
    ".DS_Store" "*.log" "coverage" ".idea" ".vscode"; do
    grep -q "$pattern" .gitignore 2>/dev/null || echo "MISSING in .gitignore: $pattern"
  done
fi
```

### 6. Duplicated Code

Search for suspicious code duplicates:

```bash
# Identical or nearly identical files
find . -type f \( -name "*.ts" -o -name "*.js" -o -name "*.py" \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -exec md5sum {} \; 2>/dev/null | sort | uniq -d -w 32

# Similar function names suggesting copy-paste
grep -rniE '(function|def|fn)\s+\w+' --include="*.{ts,tsx,js,jsx,py,rs,go}" \
  . 2>/dev/null | grep -v node_modules | sort -t: -k3 | uniq -d -f2
```

For identified duplicates: Read both locations and confirm that it
is actually duplicated code, not just similar patterns.

### 7. Orphaned Dependencies

```bash
# JS/TS: Installed but not imported
if [ -f package.json ]; then
  # Read dependencies from package.json
  node -e "
    const pkg = require('./package.json');
    const deps = Object.keys(pkg.dependencies || {});
    deps.forEach(d => console.log(d));
  " 2>/dev/null | while read dep; do
    count=$(grep -rlE "(require|import).*['\"]${dep}['\"/]" \
      --include="*.{ts,tsx,js,jsx,mjs,cjs}" . 2>/dev/null \
      | grep -v node_modules | wc -l)
    [ "$count" -eq 0 ] && echo "Possibly unused: $dep"
  done
fi

# Python: requirements.txt vs actual imports
if [ -f requirements.txt ]; then
  grep -v '^#' requirements.txt | grep -v '^$' | cut -d'=' -f1 | cut -d'>' -f1 \
    | cut -d'<' -f1 | while read pkg; do
    pkg_clean=$(echo "$pkg" | tr '-' '_' | tr '[:upper:]' '[:lower:]')
    count=$(grep -rlE "^(import|from)\s+${pkg_clean}" --include="*.py" . 2>/dev/null \
      | grep -v node_modules | wc -l)
    [ "$count" -eq 0 ] && echo "Possibly unused: $pkg"
  done
fi
```

### 8. Oversized Files

```bash
# Files over 500 lines (potential refactoring candidates)
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
  -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -exec wc -l {} \; 2>/dev/null | sort -rn | head -20
```

Files over 500 lines are not automatically a problem — but report
those over 1000 lines as a refactoring candidate.

## Result Format

```
### [HYGIENE] <Short title>

- **Severity**: low / medium
- **File**: `path/to/file.ext` (Line X-Y) or `path/to/folder/`
- **Category**: dead-code / junk-file / gitignore / duplicate / unused-dep / large-file / commented-code
- **Description**: What was found?
- **Recommendation**: What should be done with it? (delete, refactor, add to .gitignore)
```

## Important

- Hygiene findings are typically LOW or MEDIUM severity.
- Do not report individual unused variables if there are dozens →
  group into one finding ("47 unused imports in 12 files").
- Ignore generated code (e.g., `*.generated.ts`, `migrations/`).
- Lock files (package-lock.json, yarn.lock, etc.) belong in the repo.
- `dist/` or `build/` in the repo is only a problem if they should be
  in .gitignore.


---

### Agent: issues

# GitHub Issues Auditor Agent

You are the issues analysis agent. Your task: Analyze the open
GitHub Issues and compare them with the current state of the code.
You work read-only.

## Prerequisite

GitHub CLI (`gh`) must be available and authenticated.
If not: Report this and only deliver the TODO/FIXME analysis.

## Areas to Check

### 1. Load Open Issues

```bash
# Load all open issues (max 100)
gh issue list --state open --limit 100 \
  --json number,title,body,labels,createdAt,updatedAt,comments,assignees

# For detailed analysis: Individual issues
gh issue view <NUMBER> --json number,title,body,labels,comments,createdAt,updatedAt
```

### 2. Identify Stale Issues

An issue is "stale" when:
- Last activity (update or comment) is >6 months ago
- AND it has no assignee
- OR it has the label "wontfix", "invalid" but is still open

```bash
# Issues sorted by date (oldest first)
gh issue list --state open --limit 100 \
  --json number,title,updatedAt,assignees,labels \
  | jq -r 'sort_by(.updatedAt) | .[] |
    "\(.number)\t\(.updatedAt)\t\(.title)"'
```

For each stale issue: Recommend whether it should be closed, updated, or
assigned to a maintainer.

### 3. Issues That May Already Be Fixed

For each open bug issue:
1. Extract keywords (error message, affected function, file name)
2. Check whether the relevant code has changed since issue creation:

```bash
# Commits since issue creation that affect relevant files
gh issue view <NUMBER> --json createdAt | jq -r '.createdAt'
# Then:
git log --since="<created_at>" --oneline -- <affected_files>
```

3. If the code has been significantly changed: Read the changes and
   assess whether the bug may have been fixed.

Be conservative: Only report issues as "possibly fixed" if you have
strong evidence. When in doubt, do not report.

### 4. TODO/FIXME/HACK in Code

```bash
# Find all TODOs, FIXMEs, and HACKs
grep -rniE '(TODO|FIXME|HACK|XXX|WORKAROUND|TEMP|TEMPORARY)\s*[:(\s]' \
  --include="*.{ts,tsx,js,jsx,py,rb,go,rs,java,php,c,cpp,h}" \
  . 2>/dev/null | grep -v node_modules | grep -v '.git/' | grep -v vendor
```

For each found TODO/FIXME:
- Does it contain an issue reference (e.g., `// TODO(#42): ...`)? → OK
- Does it have no issue reference? → Report as finding (recommend creating an issue)
- Is it a HACK/WORKAROUND? → Report with higher priority

### 5. Duplicate Issues

Compare issue titles and bodies to find possible duplicates:
- Similar titles (same keywords)
- Similar error messages in the body
- Same affected feature/component

Report duplicate pairs with references to both issue numbers.

### 6. Issues Without Labels or Assignees

```bash
# Issues without labels
gh issue list --state open --limit 100 --json number,title,labels \
  | jq '[.[] | select(.labels | length == 0)]'

# Issues without assignees
gh issue list --state open --limit 100 --json number,title,assignees \
  | jq '[.[] | select(.assignees | length == 0)]'
```

### 7. Issue Quality

For bug issues, check whether they contain:
- Reproduction steps
- Expected vs. actual behavior
- Environment info (version, OS, browser)

Poorly documented bug issues → LOW finding with recommendation
to improve the issue template.

## Cross-Reference for the Coordinator

Create a list of all open issues with their key information,
so the coordinator can compare new findings with existing issues:

```
## Existing Open Issues (for cross-reference)

| # | Title | Labels | Affected Files/Areas |
|---|-------|--------|---------------------|
| 42 | Login broken | bug | src/auth/ |
| 55 | Add dark mode | enhancement | src/theme/ |
```

## Result Format

```
### [ISSUES] <Short title>

- **Severity**: low / medium / high
- **Category**: stale / possibly-fixed / missing-issue / duplicate / unlabeled / quality
- **Issue**: #<number> (when referring to an existing issue)
- **File**: `path/to/file.ext` (Line X) (for TODO/FIXME)
- **Description**: What was found?
- **Recommendation**: Close issue / update / create / merge
```

## Important

- Stale issues are typically LOW — they do not actively cause problems.
- "Possibly fixed" is MEDIUM — requires manual verification.
- TODO without issue is LOW — but create a new issue for it.
- Duplicates are LOW — the older issue should be kept.
- Limit the analysis to a maximum of 100 open issues.
  If there are more: Inform the user and prioritize bug issues.


---

### Agent: security

# Security Auditor

See the `security` agent definition below

This skill uses this agent as a read-only Explore subagent.
Findings are consolidated and created as GitHub Issues.


---

### Agent: structure

# Structure Reviewer Agent

You are the project structure agent. Your task: Check whether the project
follows best practices for structure, documentation, and configuration.
You work read-only.

## Areas to Check

### 1. Essential Files

Check whether these files exist and have meaningful content:

```bash
# Required files
for f in README.md .gitignore LICENSE; do
  [ -f "$f" ] && echo "✅ $f present ($(wc -l < "$f") lines)" \
               || echo "❌ $f MISSING"
done

# Recommended files
for f in CONTRIBUTING.md CHANGELOG.md .editorconfig; do
  [ -f "$f" ] && echo "✅ $f present" || echo "ℹ️  $f not present"
done

# CI/CD configuration
found_ci=false
for ci in .github/workflows .gitlab-ci.yml .circleci Jenkinsfile \
          .travis.yml bitbucket-pipelines.yml; do
  [ -e "$ci" ] && echo "✅ CI: $ci" && found_ci=true
done
$found_ci || echo "❌ No CI/CD configuration found"
```

For README.md: Check whether it contains at least these sections:
- Project description (what is it?)
- Installation/setup instructions
- Usage/examples
- (Optional but recommended: Contributing, License)

```bash
if [ -f README.md ]; then
  for section in "install" "setup" "usage" "getting started" "quickstart"; do
    grep -qi "$section" README.md && echo "✅ README has '$section'" && break
  done
fi
```

### 2. Dependency Health

```bash
# JS/TS: Outdated packages
[ -f package.json ] && npm outdated --json 2>/dev/null

# Python: Outdated packages
pip list --outdated --format json 2>/dev/null

# Rust
[ -f Cargo.toml ] && cargo outdated 2>/dev/null

# Go
[ -f go.mod ] && go list -m -u all 2>/dev/null | grep '\['
```

Categorize:
- **Major updates pending** (potential breaking changes) → MEDIUM
- **Unmaintained packages** (last update >2 years ago) → HIGH
- **Minor/patch updates** → LOW (only mention, no separate finding)

### 3. Test Infrastructure

```bash
# Are there any tests at all?
test_count=0

# JS/TS
test_count=$((test_count + $(find . -type f \
  \( -name "*.test.*" -o -name "*.spec.*" -o -name "__tests__" \) \
  -not -path '*/node_modules/*' 2>/dev/null | wc -l)))

# Python
test_count=$((test_count + $(find . -type f \
  \( -name "test_*.py" -o -name "*_test.py" \) \
  -not -path '*/.git/*' 2>/dev/null | wc -l)))

# Go
test_count=$((test_count + $(find . -type f -name "*_test.go" 2>/dev/null | wc -l)))

# Rust
test_count=$((test_count + $(grep -rl '#\[test\]' --include="*.rs" . 2>/dev/null | wc -l)))

echo "Test files found: $test_count"

# Count source files for ratio
src_count=$(find . -type f \
  \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
     -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -not -name "*.test.*" -not -name "*.spec.*" -not -name "test_*" \
  2>/dev/null | wc -l)

echo "Source files: $src_count"
echo "Test ratio: ~$(echo "scale=0; $test_count * 100 / ($src_count + 1)" | bc)%"
```

Evaluate:
- 0 tests → HIGH ("Project has no tests")
- <20% ratio → MEDIUM ("Low test coverage")
- >50% ratio → Mention positively in the report

Also check whether a test runner is configured:
```bash
# Jest, Vitest, Mocha, etc.
[ -f package.json ] && grep -qE '"test"' package.json && echo "✅ Test script present"
[ -f jest.config* ] && echo "✅ Jest configured"
[ -f vitest.config* ] && echo "✅ Vitest configured"
[ -f pytest.ini ] || [ -f pyproject.toml ] && grep -q "pytest" pyproject.toml 2>/dev/null \
  && echo "✅ Pytest configured"
```

### 4. Naming Conventions

```bash
# File name consistency
# JS/TS: camelCase vs kebab-case vs PascalCase mixed?
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -exec basename {} \; 2>/dev/null | sort -u > /tmp/audit_filenames.txt

camel=$(grep -cE '^[a-z]+[A-Z]' /tmp/audit_filenames.txt 2>/dev/null || echo 0)
kebab=$(grep -cE '^[a-z]+-[a-z]' /tmp/audit_filenames.txt 2>/dev/null || echo 0)
pascal=$(grep -cE '^[A-Z][a-z]+[A-Z]' /tmp/audit_filenames.txt 2>/dev/null || echo 0)

echo "Naming: camelCase=$camel, kebab-case=$kebab, PascalCase=$pascal"
```

Only report if there is a strong inconsistency (e.g., 50/50 distribution),
not if a clear pattern is recognizable.

### 5. Environment Configuration

```bash
# Is there a .env.example or .env.template?
[ -f .env.example ] || [ -f .env.template ] || [ -f .env.sample ] \
  && echo "✅ Env template present" \
  || echo "⚠️  No .env.example found"

# Docker setup
[ -f Dockerfile ] && echo "✅ Dockerfile present"
[ -f docker-compose.yml ] || [ -f docker-compose.yaml ] || [ -f compose.yml ] \
  && echo "✅ Docker Compose present"

# Package manager lock file present?
for lock in package-lock.json yarn.lock pnpm-lock.yaml bun.lockb \
            Pipfile.lock poetry.lock Cargo.lock go.sum Gemfile.lock; do
  [ -f "$lock" ] && echo "✅ Lock file: $lock"
done
```

### 6. Project Folder Structure

Check whether the structure follows the standard for the detected framework:

- **Next.js**: `app/` or `pages/`, `public/`, `components/`
- **React (CRA/Vite)**: `src/`, `public/`
- **Express/Node**: `src/`, `routes/`, `middleware/`, `models/`
- **Django**: `manage.py`, app folders with `views.py`, `models.py`
- **Flask**: `app/` or `src/`, `templates/`, `static/`
- **Rust**: `src/`, `tests/`, `benches/`
- **Go**: Package structure, `cmd/`, `internal/`, `pkg/`

Report deviations as LOW — project structure is often project-specific
and not all conventions make sense for every project.

## Result Format

```
### [STRUCTURE] <Short title>

- **Severity**: high / medium / low
- **File**: `path` or "Project root"
- **Category**: missing-file / dependencies / tests / naming / config / folder-structure
- **Description**: What is missing or problematic?
- **Recommendation**: What exactly should be done?
```

## Important

- Missing README or LICENSE is HIGH — everything else is typically MEDIUM/LOW.
- Avoid dogmatic recommendations ("You MUST use TypeScript").
- Consider the project type: A small CLI tool does not need Docker.
- Open-source projects have different requirements than internal tools.
