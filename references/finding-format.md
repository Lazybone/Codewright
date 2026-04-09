# Finding-Format — Gemeinsame Referenz für alle Agenten

Jeder Subagent liefert seine Findings in diesem einheitlichen Format.
Das ermöglicht dem Koordinator die Konsolidierung und Deduplizierung.

## Format pro Finding

```
### [<TAG>] <Kurztitel>

- **Severity**: critical / high / medium / low
- **Datei**: `pfad/zur/datei.ext` (Zeile X-Y)
- **Kategorie**: <agent-spezifische Kategorie>
- **Fixbar**: auto / manual / info
- **Beschreibung**: Was ist das Problem? (1-3 Sätze)
- **Auswirkung**: Was passiert wenn nichts getan wird? (1-2 Sätze)
- **Empfehlung**: Konkreter Fix-Vorschlag
- **Code-Kontext** (optional, max 10 Zeilen)
```

## Agent-Tags

| Agent | Tag | Skills | Beispiel-Kategorien |
|-------|-----|--------|---------------------|
| Security Auditor | `[SECURITY]` | audit-project, codebase-doctor | secrets, injection, config, crypto, validation, dependency |
| Bug Detector | `[BUG]` | audit-project, codebase-doctor | logic, error-handling, async, null-safety, resource-leak, type-safety, lint |
| Hygiene Inspector | `[HYGIENE]` | audit-project | dead-code, junk-file, gitignore, duplicate, unused-dep, large-file, commented-code |
| Structure Reviewer | `[STRUCTURE]` | audit-project | missing-file, dependencies, tests, naming, config, folder-structure |
| Issues Auditor | `[ISSUES]` | audit-project | stale, possibly-fixed, missing-issue, duplicate, unlabeled, quality |
| Code Quality | `[QUALITY]` | codebase-doctor | dead-code, commented-code, duplication, complexity, unused-dep, junk-file, naming |
| API Consistency | `[API]` | codebase-doctor | url-pattern, response-format, validation, auth, frontend-sync, docs |
| Dependency Analyzer | `[DEPS]` | codebase-doctor | vulnerability, outdated, conflict, bloat, license, build-config |
| Frontend Reviewer | `[FRONTEND]` | codebase-doctor | xss, dom-safety, sensitive-data, csrf, js-quality, assets, accessibility |
| Architecture Reviewer | `[ARCH]` | codebase-doctor | structure, coupling, separation, config, error-arch, tests, docs |

## Fixbar-Bewertung

| Wert | Bedeutung | Beispiele |
|------|-----------|-----------|
| `auto` | Kann sicher automatisch behoben werden | Unused imports, bare except, fehlende await |
| `manual` | Braucht menschliche Entscheidung | Architektur-Änderungen, API-Redesign |
| `info` | Nur zur Kenntnis | Empfehlung für Audit-Tool, positive Beobachtung |

## Severity-Richtlinien

### 🔴 critical
- Aktive Sicherheitslücke (exponierter Secret, SQL Injection)
- Datenverlust-Risiko
- Anwendung crashed in Produktion

### 🟠 high
- Sicherheitsrisiko (unsichere Dependencies mit bekanntem CVE)
- Schwere Bugs die Kernfunktionalität betreffen
- Fehlende essenzielle Projektdateien (README, LICENSE)
- Unmaintained Dependencies

### 🟡 medium
- Potenzielle Bugs (unbehandelte Errors, Race Conditions)
- Veraltete Dependencies (Major-Updates ausstehend)
- Code-Qualitätsprobleme die Wartbarkeit beeinträchtigen
- Fehlende Tests für kritische Bereiche

### 🟢 low
- Code-Cleanup (Dead Code, auskommentierter Code)
- Style-Inkonsistenzen
- Stale Issues
- Nice-to-have Verbesserungen
- TODO/FIXME ohne Issue-Referenz

## Regeln

1. **Ein Finding pro Problem** — nicht mehrere Probleme in einem Finding bündeln
   (Ausnahme: "47 unbenutzte Imports" darf ein Finding sein).
2. **Kontext ist Pflicht** — Jedes Finding muss nachvollziehbar sein.
   Datei + Zeile + Beschreibung mindestens.
3. **Empfehlung muss umsetzbar sein** — "Code verbessern" ist keine
   Empfehlung. "Ersetze `md5(password)` durch `bcrypt.hash(password)`" schon.
4. **False Positives vermeiden** — Im Zweifel den Code-Kontext lesen.
   Lieber weniger Findings als viele falsche.
5. **Test-Code milder bewerten** — Ein `any` in einer Test-Fixture ist
   weniger kritisch als in Produktionscode.
