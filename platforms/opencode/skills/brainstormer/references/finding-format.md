# Finding Format — Brainstormer

All reviewer agents in this skill use the shared finding format
defined in `../../../references/finding-format.md`.

## Skill-Specific Tags

| Agent | Tag | Categories |
|-------|-----|------------|
| Logic Reviewer | `[LOGIC]` | completeness, contradiction, edge-case, assumption, missing-impl |
| Security Reviewer | `[SECURITY]` | auth, data-exposure, injection, config, threat-model, dependency |
| Quality Reviewer | `[QUALITY]` | clarity, feasibility, testability, consistency, completeness, readability |
| Architecture Reviewer | `[ARCH]` | coupling, cohesion, api-design, separation, scalability, breaking-change |

## Consolidation Rules

When consolidating findings from multiple reviewers:

1. **Deduplication**: Findings targeting the same section + problem
   are merged. The highest severity wins. Both recommendations are preserved.
2. **Grouping**: After deduplication, findings are grouped by concept/plan section.
   Each Fixer agent receives one group (section-partitioned, no conflicts).
3. **Ordering**: Within each group, findings are ordered by appearance in the document
   (top to bottom) to avoid drift during fixes.
