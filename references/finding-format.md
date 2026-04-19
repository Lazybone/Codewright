# Finding Format — Shared Reference for All Agents

Every subagent delivers its findings in this unified format.
This enables the coordinator to consolidate and deduplicate.

## Format per Finding

```
### [<TAG>] <Short title>

- **Severity**: critical / high / medium / low
- **File**: `path/to/file.ext` (line X-Y)
- **Category**: <agent-specific category>
- **Fixable**: auto / manual / info
- **Description**: What is the problem? (1-3 sentences)
- **Impact**: What happens if nothing is done? (1-2 sentences)
- **Recommendation**: Concrete fix suggestion
- **Code context** (optional, max 10 lines)
```

## Agent Tags

| Agent | Tag | Skills | Example categories |
|-------|-----|--------|---------------------|
| Security Auditor / Reviewer | `[SECURITY]` | audit-project, codebase-doctor, github-issue-fixer, auto-dev | secrets, injection, config, crypto, validation, dependency |
| Bug Detector | `[BUG]` | audit-project, codebase-doctor | logic, error-handling, async, null-safety, resource-leak, type-safety, lint |
| Hygiene Inspector | `[HYGIENE]` | audit-project | dead-code, junk-file, gitignore, duplicate, unused-dep, large-file, commented-code |
| Structure Reviewer | `[STRUCTURE]` | audit-project | missing-file, dependencies, tests, naming, config, folder-structure |
| Issues Auditor | `[ISSUES]` | audit-project | stale, possibly-fixed, missing-issue, duplicate, unlabeled, quality |
| Logic Reviewer | `[LOGIC]` | github-issue-fixer, auto-dev | correctness, edge-case, logic-error, missing-impl, error-handling |
| Quality Reviewer | `[QUALITY]` | github-issue-fixer, auto-dev | complexity, duplication, naming, test-coverage, consistency, readability |
| Code Quality | `[QUALITY]` | codebase-doctor | dead-code, commented-code, duplication, complexity, unused-dep, junk-file, naming |
| API Consistency | `[API]` | codebase-doctor | url-pattern, response-format, validation, auth, frontend-sync, docs |
| Dependency Analyzer | `[DEPS]` | codebase-doctor | vulnerability, outdated, conflict, bloat, license, build-config |
| Frontend Reviewer | `[FRONTEND]` | codebase-doctor | xss, dom-safety, sensitive-data, csrf, js-quality, assets, accessibility |
| Architecture Reviewer | `[ARCH]` | codebase-doctor, github-issue-fixer, auto-dev | structure, coupling, separation, config, error-arch, tests, docs |

## Fixable Rating

| Value | Meaning | Examples |
|-------|---------|----------|
| `auto` | Can be safely fixed automatically | Unused imports, bare except, missing await |
| `manual` | Requires human decision | Architecture changes, API redesign |
| `info` | For information only | Recommendation for audit tool, positive observation |

## Severity Guidelines

### 🔴 critical
- Active security vulnerability (exposed secret, SQL injection)
- Data loss risk
- Application crashes in production

### 🟠 high
- Security risk (insecure dependencies with known CVE)
- Severe bugs affecting core functionality
- Missing essential project files (README, LICENSE)
- Unmaintained dependencies

### 🟡 medium
- Potential bugs (unhandled errors, race conditions)
- Outdated dependencies (major updates pending)
- Code quality issues affecting maintainability
- Missing tests for critical areas

### 🟢 low
- Code cleanup (dead code, commented-out code)
- Style inconsistencies
- Stale issues
- Nice-to-have improvements
- TODO/FIXME without issue reference

## Rules

1. **One finding per problem** — do not bundle multiple problems in one finding
   (Exception: "47 unused imports" may be a single finding).
2. **Context is mandatory** — Every finding must be traceable.
   File + line + description at minimum.
3. **Recommendation must be actionable** — "Improve code" is not a
   recommendation. "Replace `md5(password)` with `bcrypt.hash(password)`" is.
4. **Avoid false positives** — When in doubt, read the code context.
   Fewer findings are better than many incorrect ones.
5. **Judge test code more leniently** — An `any` in a test fixture is
   less critical than in production code.
