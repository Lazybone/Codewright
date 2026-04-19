# GitHub Issue Template — for automatically created issues

Each finding is created as a GitHub Issue using this format.

## Issue Title

Format: `[AUDIT/<CATEGORY>] <Short title>`

Examples:
- `[AUDIT/SECURITY] Hardcoded API key in config.ts`
- `[AUDIT/BUG] Unhandled promise rejection in UserService`
- `[AUDIT/HYGIENE] 23 unused imports across 8 files`
- `[AUDIT/STRUCTURE] Missing README setup instructions`
- `[AUDIT/ISSUES] 5 stale issues without activity since 2024`

## Issue Body

```markdown
## Description

<Description of the problem from the finding>

## Affected Files

- `path/to/file.ext` (Line X-Y)

## Impact

<What happens if nothing is done>

## Recommended Solution

<Specific recommendation from the finding>

## Code Context

```<language>
<Code snippet if available>
```

---

<sub>🤖 Automatically created by Project Audit on <DATE>.
Severity: <SEVERITY> | Category: <CATEGORY></sub>
```

## Labels

Each issue gets two labels:
1. **Audit category**: `audit:security`, `audit:bug`, `audit:hygiene`, `audit:structure`, `audit:stale-issue`
2. **Severity**: `severity:critical`, `severity:high`, `severity:medium`, `severity:low`

## gh Command

```bash
gh issue create \
  --title "[AUDIT/<CATEGORY>] <Title>" \
  --body "<Body content>" \
  --label "audit:<category>,severity:<severity>"
```

## Special Cases

### Grouped Findings

When a finding covers many similar problems (e.g., 47 unused
imports), create ONE issue with the complete list in the body:

```markdown
## Description

23 unused imports found in 8 files.

## Affected Files

| File | Unused Imports |
|------|---------------|
| `src/utils/helpers.ts` | `lodash`, `moment` |
| `src/api/client.ts` | `axios` (only type imported) |
| ... | ... |

## Recommended Solution

Remove the unused imports. For type-only imports:
use `import type { ... }`.
```

### Stale Issues

For stale issues: Do not create a new issue, instead comment on
the existing issue:

```bash
gh issue comment <NUMBER> --body "🤖 **Audit note**: This issue has had no activity for >6 months. Please check whether it is still relevant."
```

### Possibly Already Fixed Issues

```bash
gh issue comment <NUMBER> --body "🤖 **Audit note**: The affected code has been changed since this issue was created (commits: <hash>). Please check whether the problem still exists."
```

### Duplicate Issues

Create a new issue that lists the duplicates:

```markdown
## Description

The following issues appear to describe the same problem:

- #12: "Login button does not work"
- #47: "Cannot click login on mobile"

## Recommended Solution

Merge: Close the newer issue (#47) with a reference to #12,
or vice versa if #47 is better documented.
```
