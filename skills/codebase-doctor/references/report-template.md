# Doctor-Report Template

## Template

```markdown
# Codebase Doctor Report

**Projekt**: <Repository-Name>
**Datum**: <YYYY-MM-DD>
**Analysierte Dateien**: <Anzahl>
**Erkannte Sprache(n)**: <Sprachen/Frameworks>
**Modus**: report-only / fix-critical / fix-all

---

## Executive Summary

<2-3 Saetze Gesamtbewertung>

| Severity | Gefunden | Auto-Fix | Manual | Info |
|----------|----------|----------|--------|------|
| 🔴 CRITICAL | <N> | <N> | <N> | - |
| 🟠 HIGH | <N> | <N> | <N> | - |
| 🟡 MEDIUM | <N> | <N> | <N> | - |
| 🟢 LOW | <N> | <N> | <N> | - |
| **Gesamt** | **<N>** | **<N>** | **<N>** | **<N>** |

---

## 🔴 Critical Findings

### <Nr>. <Titel>
- **Tag**: [SECURITY/BUG/etc.]
- **Datei**: `<pfad>` (Zeile <X>)
- **Status**: FIXED / NEEDS_REVIEW / OPEN
- **Problem**: <Beschreibung>
- **Fix**: <Was wurde geaendert oder empfohlen>

---

## 🟠 High Findings
...

## 🟡 Medium Findings
...

## 🟢 Low Findings
...

---

## Positive Beobachtungen

<Was ist gut am Projekt? Beispiele:>
- Gute Test-Abdeckung in `src/core/`
- Konsistenter Code-Stil
- CI/CD Pipeline konfiguriert
- Saubere Error-Handling-Strategie

---

## Metriken

| Metrik | Wert |
|--------|------|
| Projektgroesse | <N> Dateien |
| Test-Dateien | <N> |
| Test-Ratio | <N>% |
| Dependencies | <N> |
| Veraltete Deps | <N> |
| TODO/FIXME im Code | <N> |

---

## Quick Wins

Die folgenden Findings haben das beste Aufwand/Nutzen-Verhaeltnis:

1. <Finding>
2. <Finding>
3. <Finding>

---

## Durchgefuehrte Fixes

| # | Finding | Datei | Aenderung |
|---|---------|-------|-----------|
| 1 | <Titel> | `<pfad>` | <Was wurde geaendert> |
| ... | ... | ... | ... |

---

## Offene Punkte (NEEDS_REVIEW)

Findings die menschliche Entscheidung brauchen:

1. <Finding + Kontext + Optionen>
2. ...

---

<sub>Erstellt durch codebase-doctor Skill am <DATUM></sub>
```

## Hinweise

- **Positive Beobachtungen nicht vergessen** — reine Problem-Listen sind demotivierend
- **Quick Wins hervorheben** — hilft bei der Priorisierung
- **Metriken geben Kontext** — 5 Findings bei 10 Dateien != 5 Findings bei 5000 Dateien
- **Durchgefuehrte Fixes auflisten** — Transparenz ueber automatische Aenderungen
- **NEEDS_REVIEW klar dokumentieren** — User muss wissen was noch offen ist
