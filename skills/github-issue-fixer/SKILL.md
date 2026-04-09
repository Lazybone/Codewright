---
name: fix-github-issue
description: >
  Analysiert ein GitHub Issue, reproduziert den Bug, erstellt einen Fix-Plan,
  behebt den Fehler, verifiziert die Lösung und committet das Ergebnis.
  Nutze diesen Skill wenn der User ein GitHub Issue beheben möchte, eine Issue-URL
  oder Issue-Nummer nennt, oder sagt "fix issue", "behebe issue", "löse das issue",
  "schau dir issue #X an". Auch bei "bug fixen", "diesen Fehler beheben" mit
  Issue-Referenz. Arbeitet mit Subagenten-Teams für parallele Analyse und Verifikation.
  Kann MCP Google DevTools zur Browser-Verifikation nutzen.
---

# GitHub Issue Fixer — Agentenbasierter Workflow

Dieser Skill behebt GitHub Issues systematisch in einem mehrstufigen Prozess
mit spezialisierten Subagenten. Jeder Agent hat eine klar definierte Rolle.

## Voraussetzungen

- Git-Repository mit konfiguriertem Remote
- GitHub CLI (`gh`) installiert und authentifiziert
- Optional: MCP Google DevTools für Browser-basierte Verifikation

## Workflow-Übersicht

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  1. ANALYZE │────▶│  2. PLAN     │────▶│  3. FIX     │
│  (Explore)  │     │  (Plan)      │     │  (Code)     │
└─────────────┘     └──────────────┘     └─────────────┘
                                               │
                    ┌──────────────┐            │
                    │  5. COMMIT   │◀───────────│
                    │  (main)      │     ┌─────────────┐
                    └──────────────┘     │  4. VERIFY  │
                          ▲              │  (Test)     │
                          │              └─────────────┘
                          │                    │
                          └────────────────────┘
                               (wenn OK)
```

## Schritt-für-Schritt-Ablauf

### Phase 1: Issue laden & analysieren

Lade das Issue über die GitHub CLI:

```bash
gh issue view <ISSUE_NUMBER> --json title,body,labels,comments,assignees
```

Starte dann einen **Explore-Subagenten** für die Codebase-Analyse.
Starte den Agenten gemäß `../../references/agent-invocation.md`.
Lies dazu die Anweisungen in `agents/analyzer.md` und übergib dem Agenten:

- Den vollständigen Issue-Text (Titel, Body, Kommentare)
- Den Auftrag, relevante Dateien zu finden und den Bug zu lokalisieren
- Die Aufforderung, den Bug zu reproduzieren (Tests ausführen, Logs prüfen)

Der Analyzer liefert zurück:
- Betroffene Dateien und Code-Stellen
- Reproduktionsstatus (Bug bestätigt ja/nein)
- Root-Cause-Analyse

**Wenn der Bug nicht mehr reproduzierbar ist**: Melde dies dem User und frage,
ob das Issue geschlossen werden soll. Beende den Workflow.

### Phase 2: Fix-Plan erstellen

Starte einen **Plan-Subagenten** mit den Ergebnissen aus Phase 1.
Starte den Agenten gemäß `../../references/agent-invocation.md`.
Lies dazu `agents/planner.md` und übergib:

- Die Analyse-Ergebnisse (betroffene Dateien, Root Cause)
- Den Original-Issue-Text

Der Planner liefert:
- Geordnete Liste der notwendigen Änderungen
- Risikobewertung pro Änderung
- Vorgeschlagene Teststrategie

Präsentiere den Plan dem User und warte auf Bestätigung bevor du fortfährst.

### Phase 3: Fix implementieren

Implementiere die Änderungen gemäß Plan. Arbeite dabei im Hauptagenten:

1. Erstelle einen Feature-Branch: `git checkout -b fix/issue-<NUMMER>`
2. Führe die geplanten Änderungen Datei für Datei durch
3. Halte dich eng an den Plan — bei Abweichungen informiere den User
4. Achte auf bestehende Code-Konventionen (Linting, Formatierung)
5. Schreibe oder aktualisiere Tests für den Fix

### Phase 4: Verifikation

Starte die Verifikation auf zwei parallelen Wegen:

**4a. Automatische Tests** — Führe die Test-Suite aus:
```bash
# Erkenne das Test-Framework automatisch
# npm test / pytest / cargo test / go test / etc.
```

**4b. Browser-Verifikation (bei UI-Bugs)** — Wenn das Issue ein
visuelles oder Frontend-Problem betrifft, nutze MCP Google DevTools:

Lies dazu `references/devtools-verification.md` für die genaue Vorgehensweise.

Prüfe nach der Verifikation:
- Alle bestehenden Tests bestehen weiterhin (keine Regressionen)
- Der spezifische Bug ist behoben
- Keine neuen Linting-Fehler oder Warnungen

**Wenn die Verifikation fehlschlägt**: Analysiere die Fehler, passe den Fix an
und wiederhole Phase 4. Maximal 3 Iterationen, danach den User einbeziehen.

### Phase 5: Commit & Abschluss

Wenn alle Verifikationen bestanden:

1. Stage die Änderungen: `git add -A`
2. Erstelle einen aussagekräftigen Commit:
   ```
   fix: <kurze Beschreibung> (closes #<NUMMER>)

   <Was wurde geändert und warum>

   Fixes #<NUMMER>
   ```
3. Zeige dem User eine Zusammenfassung:
   - Welche Dateien geändert wurden
   - Was der Fix bewirkt
   - Testergebnisse
4. Frage ob gepusht und ein PR erstellt werden soll

## Fehlerbehandlung

- Wenn `gh` nicht installiert ist: Versuche die Issue-Infos über die GitHub API
  via `curl` zu holen, oder bitte den User die Issue-Beschreibung zu pasten.
- Wenn Tests nicht gefunden werden: Frage den User nach dem Test-Befehl.
- Wenn der Fix nach 3 Iterationen nicht verifiziert werden kann: Stoppe und
  präsentiere dem User den aktuellen Stand mit den offenen Problemen.

## Hinweise

- Erstelle immer einen separaten Branch, arbeite nie direkt auf main/master.
- Committe nie ohne erfolgreiche Verifikation.
- Informiere den User bei jedem Phasenwechsel über den Fortschritt.
- Bei Unsicherheiten: Lieber nachfragen als raten.
