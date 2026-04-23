# Finding Format — Bug-Fixer Reference

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

| Agent | Tag | Categories |
|-------|-----|------------|
| Logic Reviewer | `[LOGIC]` | correctness, edge-case, logic-error, missing-impl, error-handling, regression-risk |
| Security Reviewer | `[SECURITY]` | injection, auth, data-exposure, crypto, config, dependency |
| Quality Reviewer | `[QUALITY]` | complexity, duplication, naming, test-coverage, consistency, readability, scope-creep |
| Architecture Reviewer | `[ARCH]` | coupling, cohesion, api-design, separation, breaking-change, wrong-layer |

## Fixable Rating

| Value | Meaning | Examples |
|-------|---------|----------|
| `auto` | Can be safely fixed automatically | Unused imports, bare except, missing await |
| `manual` | Requires human decision | Architecture changes, API redesign |
| `info` | For information only | Recommendation, positive observation |

## Severity Guidelines

### critical
- Active security vulnerability (exposed secret, SQL injection)
- Data loss risk
- Application crashes in production
- The fix introduces a new bug worse than the original

### high
- Security risk (insecure dependencies with known CVE)
- Severe bugs affecting core functionality
- Fix does not fully resolve the original bug
- Regression in existing functionality

### medium
- Potential bugs (unhandled errors, race conditions)
- Code quality issues affecting maintainability
- Missing edge case coverage
- Fix is correct but overly complex

### low
- Code cleanup opportunities
- Style inconsistencies
- Nice-to-have improvements
- Minor naming issues

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
6. **Focus on the fix** — Review the fix and its impact, not pre-existing issues.
