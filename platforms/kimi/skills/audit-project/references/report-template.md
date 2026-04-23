# Audit Report Template

The final report is created in this format and saved as
`AUDIT-REPORT.md` in the repo root.

## Template

```markdown
# 🔍 Project Audit Report

**Project**: <Repository name>
**Date**: <YYYY-MM-DD>
**Analyzed files**: <Count>
**Detected language(s)**: <Languages/Frameworks>

---

## Executive Summary

<2-3 sentences overall assessment: How does the project stand?>

| Severity | Findings | Created Issues |
|----------|----------|----------------|
| 🔴 Critical | <N> | <N> |
| 🟠 High | <N> | <N> |
| 🟡 Medium | <N> | <N> |
| 🟢 Low | <N> | <N> |
| **Total** | **<N>** | **<N>** |

<If findings were skipped because they matched existing issues:>
<N> findings were already tracked as open issues and were skipped.

---

## 🔴 Critical Findings

### <No>. <Title>
- **Category**: <Agent tag> / <Category>
- **File**: `<path>` (Line <X>)
- **Issue**: #<created issue number>
- **Problem**: <Description>
- **Recommendation**: <Fix>

---

## 🟠 High Findings

### <No>. <Title>
...

---

## 🟡 Medium Findings

### <No>. <Title>
...

---

## 🟢 Low Findings

### <No>. <Title>
...

---

## ✅ Positive Observations

<What is good about the project? Examples:>
- Good test coverage in `src/core/`
- Clean folder structure following framework conventions
- CI/CD pipeline configured
- Consistent code style

---

## 📊 Metrics

| Metric | Value |
|--------|-------|
| Project size | <N> files |
| Test files | <N> |
| Test ratio | <N>% |
| Open issues | <N> |
| Stale issues (>6 months) | <N> |
| TODO/FIXME in code | <N> |
| Dependencies | <N> |
| Outdated dependencies | <N> |

---

## 🎯 Quick Wins

The following findings can be fixed quickly and have the
greatest effect on project health:

1. <Finding with best effort/impact ratio>
2. <...>
3. <...>

---

## Created Issues

| # | Title | Severity | Category |
|---|-------|----------|----------|
| <No> | <Title> | <Severity> | <Category> |
| ... | ... | ... | ... |

---

<sub>Created by audit-project skill on <DATE></sub>
```

## Notes for the Coordinator

- **Do not forget positive observations** — An audit report that only
  lists problems is demotivating. Also mention what is good.
- **Highlight quick wins** — Helps the team prioritize.
- **Metrics provide context** — 5 findings in 10 files is a lot,
  5 findings in 5000 files is few.
- **Link created issues** — So the user can get started right away.
