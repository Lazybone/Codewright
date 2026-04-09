---
name: audit-project
description: >
  Führt ein umfassendes Projekt-Audit durch: Security, Bugs, Code-Hygiene,
  Projekt-Struktur und GitHub Issues. Erstellt für jedes Finding automatisch
  ein GitHub Issue via `gh`. Nutze diesen Skill wenn der User sein Projekt
  überprüfen, auditieren oder analysieren lassen möchte. Auch bei
  "check my project", "Projekt kontrollieren", "Code Review des ganzen Repos",
  "Sicherheitscheck", "Cleanup", "was kann man verbessern", "gibt es Probleme",
  "technische Schulden finden", "Projekt-Gesundheit", "audit", "vollständige
  Analyse". Arbeitet mit parallelen Subagenten-Teams.
disable-model-invocation: true
---

# Project Audit — Koordinator

Dieses Skill führt ein vollständiges Projekt-Audit mit 5 spezialisierten
Subagenten durch. Jedes Finding wird als GitHub Issue angelegt.

## Voraussetzungen

- Git-Repository mit konfiguriertem GitHub Remote
- GitHub CLI (`gh`) installiert und authentifiziert
- Prüfe beides zu Beginn:

```bash
git remote -v
gh auth status
```

Wenn `gh` nicht verfügbar oder nicht authentifiziert: Informiere den User
und biete an, den Report stattdessen als Markdown-Datei zu erstellen.

## Phase 1: Projekt erkennen

Bevor die Subagenten starten, sammle grundlegende Projekt-Informationen:

```bash
# Sprache und Framework erkennen
ls package.json pyproject.toml Cargo.toml go.mod Gemfile pom.xml \
   build.gradle composer.json 2>/dev/null

# Projektgröße einschätzen
find . -type f \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -not -path '*/vendor/*' \
  -not -path '*/target/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*/dist/*' \
  -not -path '*/build/*' \
  | head -500 | wc -l

# Existierende Labels im Repo prüfen
gh label list --limit 100
```

Erstelle fehlende Labels für die Audit-Kategorien (einmalig):

```bash
gh label create "audit:security" --color "D73A4A" --description "Security finding from project audit" 2>/dev/null || true
gh label create "audit:bug" --color "FC8403" --description "Bug/quality finding from project audit" 2>/dev/null || true
gh label create "audit:hygiene" --color "0075CA" --description "Code hygiene finding from project audit" 2>/dev/null || true
gh label create "audit:structure" --color "7057FF" --description "Project structure finding from project audit" 2>/dev/null || true
gh label create "audit:stale-issue" --color "BFDADC" --description "Stale or duplicate issue from audit" 2>/dev/null || true
gh label create "severity:critical" --color "B60205" --description "Critical severity" 2>/dev/null || true
gh label create "severity:high" --color "D93F0B" --description "High severity" 2>/dev/null || true
gh label create "severity:medium" --color "FBCA04" --description "Medium severity" 2>/dev/null || true
gh label create "severity:low" --color "0E8A16" --description "Low severity" 2>/dev/null || true
```

Informiere den User über das erkannte Setup und starte dann die Subagenten.

## Phase 2: Parallele Analyse

Starte die 5 Subagenten. Jeder Agent erhält:
- Die erkannte Sprache/Framework-Info
- Die Projektgröße
- Den Auftrag, Findings in einem strukturierten Format zurückzuliefern

Lies die jeweilige Agent-Datei und starte den Agenten:

| # | Agent | Datei | Typ | Aufgabe |
|---|-------|-------|-----|---------|
| 1 | Security Auditor | `agents/security.md` | Explore | Sicherheitslücken finden |
| 2 | Bug Detector | `agents/bugs.md` | Explore | Bugs & Qualitätsprobleme finden |
| 3 | Hygiene Inspector | `agents/hygiene.md` | Explore | Dead Code, Cleanup-Bedarf finden |
| 4 | Structure Reviewer | `agents/structure.md` | Explore | Projektstruktur & Best Practices |
| 5 | Issues Auditor | `agents/issues.md` | Explore | GitHub Issues analysieren |

Starte die Agenten gemäß `../../references/agent-invocation.md` als Explore-Subagenten.
Starte alle 5 parallel als Explore-Subagenten (read-only Codebase-Zugriff).
Jeder Agent liefert Findings im Format aus `references/finding-format.md`.

## Phase 3: Findings konsolidieren

Wenn alle Agenten fertig sind:

1. **Deduplizieren**: Gleiche Findings aus verschiedenen Agenten zusammenführen.
   Z.B. könnte der Security-Agent und der Bug-Agent beide eine fehlende
   Input-Validierung finden.

2. **Severity zuweisen** (falls nicht bereits geschehen):
   - 🔴 **critical**: Aktive Sicherheitslücke, Datenverlust-Risiko, Crashes
   - 🟠 **high**: Sicherheitsrisiko, schwere Bugs, gebrochene Funktionalität
   - 🟡 **medium**: Potenzielle Bugs, Code-Qualität, veraltete Dependencies
   - 🟢 **low**: Cleanup, Style, nice-to-have Verbesserungen

3. **Sortieren**: Critical → High → Medium → Low

4. **Cross-Referenz**: Prüfe ob für ein Finding bereits ein offenes Issue existiert.
   Der Issues-Auditor liefert die Liste bestehender Issues. Überspringe Findings
   die bereits als Issue erfasst sind und vermerke dies im Report.

## Phase 4: GitHub Issues erstellen

Für jedes Finding ein Issue erstellen. Lies `references/issue-template.md`
für das exakte Format.

```bash
gh issue create \
  --title "<Titel>" \
  --body "<Body>" \
  --label "<labels,kommasepariert>"
```

Regeln:
- Erstelle Issues sortiert nach Severity (critical zuerst)
- Maximal 30 Issues pro Audit-Run (bei mehr: die wichtigsten nehmen,
  Rest im Summary-Report erwähnen)
- Zwischen den `gh issue create` Aufrufen 2 Sekunden pausieren um
  Rate Limits zu vermeiden
- Sammle die erstellten Issue-Nummern für den Abschluss-Report

Frage den User vor dem Erstellen der Issues:
"Ich habe X Findings identifiziert (Y critical, Z high, ...).
Soll ich für alle Issues erstellen, oder willst du die Liste erst sehen?"

## Phase 5: Abschluss-Report

Erstelle einen Markdown-Report und zeige ihn dem User in der Konsole.
Speichere ihn außerdem als `AUDIT-REPORT.md` im Repo-Root (auf einem
separaten Branch `audit/<datum>`).

Der Report folgt dem Format in `references/report-template.md`.

Abschließend:
```bash
git checkout -b audit/$(date +%Y-%m-%d)
git add AUDIT-REPORT.md
git commit -m "docs: add project audit report $(date +%Y-%m-%d)"
```

Frage den User ob der Branch gepusht werden soll.

## Fehlerbehandlung

- **`gh` nicht verfügbar**: Report nur als Markdown, keine Issues erstellen.
  Biete an die Findings als Markdown-Liste auszugeben, die der User
  manuell als Issues eintragen kann.
- **Kein GitHub Remote**: Wie oben, nur Markdown-Report.
- **Rate Limit bei `gh`**: Pausieren und User informieren, Rest der Issues
  in einer Datei `remaining-issues.md` speichern.
- **Sehr großes Projekt (>1000 Dateien)**: Frage den User welche
  Verzeichnisse priorisiert werden sollen. Nicht das gesamte Repo
  analysieren wenn es unrealistisch groß ist.
- **Agent liefert keine Findings**: Das ist OK, im Report vermerken
  dass der Bereich sauber ist.
