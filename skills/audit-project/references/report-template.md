# Audit-Report Template

Der Abschluss-Report wird in diesem Format erstellt und als
`AUDIT-REPORT.md` im Repo-Root gespeichert.

## Template

```markdown
# 🔍 Project Audit Report

**Projekt**: <Repository-Name>
**Datum**: <YYYY-MM-DD>
**Analysierte Dateien**: <Anzahl>
**Erkannte Sprache(n)**: <Sprachen/Frameworks>

---

## Executive Summary

<2-3 Sätze Gesamtbewertung: Wie steht das Projekt da?>

| Severity | Findings | Erstelle Issues |
|----------|----------|-----------------|
| 🔴 Critical | <N> | <N> |
| 🟠 High | <N> | <N> |
| 🟡 Medium | <N> | <N> |
| 🟢 Low | <N> | <N> |
| **Gesamt** | **<N>** | **<N>** |

<Wenn Findings mit bestehenden Issues übersprungen wurden:>
<N> Findings waren bereits als offene Issues erfasst und wurden übersprungen.

---

## 🔴 Critical Findings

### <Nr>. <Titel>
- **Kategorie**: <Agent-Tag> / <Kategorie>
- **Datei**: `<pfad>` (Zeile <X>)
- **Issue**: #<erstellte Issue-Nummer>
- **Problem**: <Beschreibung>
- **Empfehlung**: <Fix>

---

## 🟠 High Findings

### <Nr>. <Titel>
...

---

## 🟡 Medium Findings

### <Nr>. <Titel>
...

---

## 🟢 Low Findings

### <Nr>. <Titel>
...

---

## ✅ Positive Beobachtungen

<Was ist gut am Projekt? Beispiele:>
- Gute Test-Abdeckung in `src/core/`
- Saubere Ordnerstruktur nach Framework-Konventionen
- CI/CD Pipeline konfiguriert
- Konsistenter Code-Stil

---

## 📊 Metriken

| Metrik | Wert |
|--------|------|
| Projektgröße | <N> Dateien |
| Test-Dateien | <N> |
| Test-Ratio | <N>% |
| Offene Issues | <N> |
| Stale Issues (>6 Monate) | <N> |
| TODO/FIXME im Code | <N> |
| Dependencies | <N> |
| Veraltete Dependencies | <N> |

---

## 🎯 Quick Wins

Die folgenden Findings lassen sich schnell beheben und haben den
größten Effekt auf die Projekt-Gesundheit:

1. <Finding mit bestem Aufwand/Nutzen-Verhältnis>
2. <...>
3. <...>

---

## Erstellte Issues

| # | Titel | Severity | Kategorie |
|---|-------|----------|-----------|
| <Nr> | <Titel> | <Severity> | <Kategorie> |
| ... | ... | ... | ... |

---

<sub>Erstellt durch audit-project Skill am <DATUM></sub>
```

## Hinweise für den Koordinator

- **Positive Beobachtungen nicht vergessen** — Ein Audit-Report der nur
  Probleme auflistet ist demotivierend. Erwähne auch was gut ist.
- **Quick Wins hervorheben** — Hilft dem Team zu priorisieren.
- **Metriken geben Kontext** — 5 Findings bei 10 Dateien ist viel,
  5 Findings bei 5000 Dateien ist wenig.
- **Erstellte Issues verlinken** — Damit der User direkt loslegen kann.
