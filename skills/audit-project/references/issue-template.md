# GitHub Issue Template — für automatisch erstellte Issues

Jedes Finding wird als GitHub Issue mit diesem Format erstellt.

## Issue-Titel

Format: `[AUDIT/<KATEGORIE>] <Kurztitel>`

Beispiele:
- `[AUDIT/SECURITY] Hardcoded API key in config.ts`
- `[AUDIT/BUG] Unhandled promise rejection in UserService`
- `[AUDIT/HYGIENE] 23 unused imports across 8 files`
- `[AUDIT/STRUCTURE] Missing README setup instructions`
- `[AUDIT/ISSUES] 5 stale issues without activity since 2024`

## Issue-Body

```markdown
## Beschreibung

<Beschreibung des Problems aus dem Finding>

## Betroffene Dateien

- `pfad/zur/datei.ext` (Zeile X-Y)

## Auswirkung

<Was passiert wenn nichts getan wird>

## Empfohlene Lösung

<Konkrete Empfehlung aus dem Finding>

## Code-Kontext

```<sprache>
<Code-Ausschnitt wenn vorhanden>
```

---

<sub>🤖 Automatisch erstellt durch Project Audit am <DATUM>.
Severity: <SEVERITY> | Kategorie: <KATEGORIE></sub>
```

## Labels

Jedes Issue bekommt zwei Labels:
1. **Audit-Kategorie**: `audit:security`, `audit:bug`, `audit:hygiene`, `audit:structure`, `audit:stale-issue`
2. **Severity**: `severity:critical`, `severity:high`, `severity:medium`, `severity:low`

## gh-Befehl

```bash
gh issue create \
  --title "[AUDIT/<KATEGORIE>] <Titel>" \
  --body "<Body-Inhalt>" \
  --label "audit:<kategorie>,severity:<severity>"
```

## Spezialfälle

### Gruppierte Findings

Wenn ein Finding viele gleichartige Probleme umfasst (z.B. 47 unbenutzte
Imports), erstelle EIN Issue mit der vollständigen Liste im Body:

```markdown
## Beschreibung

23 unbenutzte Imports in 8 Dateien gefunden.

## Betroffene Dateien

| Datei | Unbenutzte Imports |
|-------|-------------------|
| `src/utils/helpers.ts` | `lodash`, `moment` |
| `src/api/client.ts` | `axios` (nur Type importiert) |
| ... | ... |

## Empfohlene Lösung

Entferne die unbenutzten Imports. Bei Type-only Imports:
`import type { ... }` verwenden.
```

### Stale Issues

Für stale Issues: Erstelle kein neues Issue, sondern kommentiere
das bestehende Issue:

```bash
gh issue comment <NUMBER> --body "🤖 **Audit-Hinweis**: Dieses Issue hatte seit >6 Monaten keine Aktivität. Bitte prüfen ob es noch relevant ist."
```

### Möglicherweise bereits gefixte Issues

```bash
gh issue comment <NUMBER> --body "🤖 **Audit-Hinweis**: Der betroffene Code wurde seit Erstellung dieses Issues geändert (Commits: <hash>). Bitte prüfen ob das Problem noch besteht."
```

### Duplicate Issues

Erstelle ein neues Issue das die Duplikate auflistet:

```markdown
## Beschreibung

Folgende Issues scheinen dasselbe Problem zu beschreiben:

- #12: "Login button does not work"
- #47: "Cannot click login on mobile"

## Empfohlene Lösung

Zusammenführen: Schließe das neuere Issue (#47) mit Verweis auf #12,
oder umgekehrt falls #47 besser dokumentiert ist.
```
