# Finding Format — Auto-Dev

All reviewer agents in this skill use the shared finding format
defined in `../../../references/finding-format.md`.

## Skill-Specific Tags

| Agent | Tag | Categories |
|-------|-----|------------|
| Logic Reviewer | `[LOGIC]` | correctness, edge-case, logic-error, missing-impl, error-handling |
| Security Reviewer | `[SECURITY]` | injection, auth, data-exposure, crypto, config, dependency |
| Quality Reviewer | `[QUALITY]` | complexity, duplication, naming, test-coverage, consistency, readability |
| Architecture Reviewer | `[ARCH]` | coupling, cohesion, api-design, separation, breaking-change |

## Consolidation Rules

When consolidating findings from multiple reviewers:

1. **Deduplication**: Findings targeting the same file + line range + problem
   are merged. The highest severity wins. Both recommendations are preserved.
2. **Grouping**: After deduplication, findings are grouped by file path.
   Each Fixer agent receives one group (file-partitioned, no conflicts).
3. **Ordering**: Within each group, findings are ordered by line number
   (top to bottom) to avoid line number drift during fixes.
