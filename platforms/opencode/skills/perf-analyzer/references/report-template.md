# Performance Report Template

Use this template to generate `PERFORMANCE-REPORT.md` after consolidation.

---

```markdown
# Performance Report

**Project:** {project name from package.json, pyproject.toml, or directory name}
**Date:** {YYYY-MM-DD}
**Type:** {frontend / backend / fullstack}
**Analyzed by:** {comma-separated list of agents that ran}

## Executive Summary

{2-3 sentences about overall performance health. Mention the most critical finding
and the estimated total savings if all recommendations are implemented.}

| Impact | Count |
|--------|-------|
| High   | {X}   |
| Medium | {Y}   |
| Low    | {Z}   |

## High Impact Findings

{Findings sorted by estimated savings, highest first. Each finding in this format:}

### [TAG] Finding title

- **Impact**: high
- **File**: `path/to/file`
- **Estimated saving**: ~X KB / ~X ms (if applicable)
- **Description**: What is the issue
- **Recommendation**: How to fix with code example

---

## Medium Impact Findings

{Same format as above}

---

## Low Impact Findings

{Same format as above}

---

## Quick Wins

The following fixes offer the highest impact for the least effort:

1. **{Title}** -- {one-line description} ({estimated saving})
2. **{Title}** -- {one-line description} ({estimated saving})
3. **{Title}** -- {one-line description} ({estimated saving})

---

## Skipped Analyses

| Agent | Reason |
|-------|--------|
| {agent name} | {why it was skipped, e.g. "No frontend detected"} |

---

## Next Steps

- [ ] Address high-impact findings first
- [ ] Re-run analysis after fixes to measure improvement
- [ ] Consider adding performance monitoring for ongoing tracking
```

---

## Usage Notes

- Replace all `{placeholders}` with actual values
- Remove sections that have no content (e.g., if no agents were skipped)
- Quick Wins should contain 3-5 items maximum, selected from all impact levels
- Sort findings within each impact level by estimated savings (highest first)
- If no estimated saving is possible, sort by how frequently the code path executes
