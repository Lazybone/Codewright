---
name: refactor-orchestrator
description: >
  Orchestriert ein vollstaendiges Projekt-Refactoring mit autonomen Subagents und einem koordinierenden Teamleader.
  Verwende diesen Skill immer wenn der User ein ganzes Projekt, eine Codebase oder ein Repository refactoren,
  modernisieren, aufraeumen oder umstrukturieren will. Auch bei Begriffen wie "Code cleanup", "technische Schulden
  abbauen", "Architektur verbessern", "Projekt modernisieren", "Code-Qualitaet verbessern" oder "grosses Refactoring".
  Funktioniert mit jeder Sprache und jedem Framework.
---

# Refactor Orchestrator

Ein multi-agent Skill fuer Claude Code, der ein komplettes Projekt-Refactoring autonom durchfuehrt.
Ein **Teamleader-Agent** (du) analysiert das Projekt, erstellt einen Plan und delegiert Aufgaben an
spezialisierte **Subagents**. Die Kommunikation zwischen Agenten erfolgt ueber Markdown-Antworten.

---

## Architektur

```
┌─────────────────────────────────────┐
│          TEAMLEADER AGENT           │
│  - Projekt analysieren              │
│  - Refactoring-Plan erstellen       │
│  - Subagents spawnen & koordinieren │
│  - Ergebnisse pruefen & mergen      │
│  - Abschlussbericht erstellen       │
└──────────┬──────────────────────────┘
           │ spawnt parallel
    ┌──────┼──────┬──────────┐
    ▼      ▼      ▼          ▼
┌──────┐┌──────┐┌──────┐┌──────┐
│SCOUT ││ARCHI-││CODE  ││TEST  │
│AGENT ││TEKT  ││WORKER││AGENT │
│      ││AGENT ││(1-N) ││      │
│Analyse││Struk-││Umbau ││Tests │
│& Audit││tur   ││& Fix ││& QA  │
└──────┘└──────┘└──────┘└──────┘
```

---

## Workflow

### Phase 0: Vorbereitung

Bevor du startest, stelle sicher:

1. **Git-Status pruefen** – Arbeitsverzeichnis muss sauber sein (keine uncommitted changes)
2. **Neuen Branch erstellen**: `git checkout -b refactor/orchestrated-$(date +%Y%m%d-%H%M%S)`
3. **Projekt-Root identifizieren** – Frage den User wenn unklar

### Phase 1: Scout Agent (Analyse)

Lies `agents/scout.md` und starte den Agenten gemaess `../../references/agent-invocation.md`.

- Starte den Scout als **Read-Only (Explore)** Agent
- Uebergib das PROJECT_ROOT als Kontext
- Der Agent gibt seine Ergebnisse als Markdown-Antwort zurueck. Verwende diese als Grundlage fuer Phase 2.

### Phase 2: Teamleader erstellt den Plan

Basierend auf dem Scout-Report:

1. **Issues gruppieren** nach Modul/Bereich
2. **Abhaengigkeiten zwischen Issues** erkennen (was muss zuerst passieren?)
3. **Arbeitspakete schnueren** – jedes Paket bekommt ein Subagent
4. **Reihenfolge festlegen** – Pakete ohne gegenseitige Abhaengigkeit parallel, Rest sequentiell

Erstelle den Plan im folgenden Format:

```json
{
  "phases": [
    {
      "phase": 1,
      "parallel": true,
      "packages": [
        {
          "id": "PKG-001",
          "name": "Beschreibender Name",
          "agent_type": "code-worker",
          "files": ["path/to/file1", "path/to/file2"],
          "issues": ["ISSUE-001", "ISSUE-003"],
          "instructions": "Detaillierte Anweisungen was zu tun ist",
          "constraints": [
            "Keine oeffentlichen API-Signaturen aendern ohne Absprache",
            "Bestehende Tests muessen weiter bestehen"
          ]
        }
      ]
    }
  ]
}
```

**Zeige dem User den Plan und hole Bestaetigung bevor du weitermachst.**

### Phase 3: Architekt Agent (optional, bei strukturellen Aenderungen)

Wenn der Plan strukturelle Aenderungen enthaelt (Dateien verschieben, Module aufteilen, neue Verzeichnisse), starte zuerst den Architekt-Agent.

Lies `agents/architect.md` und starte den Agenten gemaess `../../references/agent-invocation.md`.

- Starte als **Code-Changing (Auto Mode)** Agent
- Uebergib PROJECT_ROOT und die strukturellen Aenderungen aus dem Plan
- Der Agent gibt seine Ergebnisse als Markdown-Antwort zurueck. Uebergib diese an die naechsten Agenten als Kontext.

### Phase 4: Code Worker Agents (parallel)

Fuer jedes Arbeitspaket starte einen Code Worker.

Lies `agents/code-worker.md` und starte die Agenten gemaess `../../references/agent-invocation.md`.

- Starte als **Code-Changing (Auto Mode)** Agenten
- Uebergib jedem Worker: PROJECT_ROOT, PACKAGE_ID, PACKAGE_NAME, FILE_LIST, INSTRUCTIONS
- **Parallele Ausfuehrung**: Starte alle Agents einer Phase gleichzeitig mit `run_in_background=true`. Warte bis alle fertig sind bevor die naechste Phase beginnt.
- Jeder Agent gibt seine Ergebnisse als Markdown-Antwort zurueck. Sammle alle Antworten fuer Phase 5.

### Phase 5: Test Agent (Qualitaetssicherung)

Nach allen Code-Aenderungen starte den Test-Agent.

Lies `agents/test-agent.md` und starte den Agenten gemaess `../../references/agent-invocation.md`.

- Starte als **Code-Changing (Auto Mode)** Agent (damit er Fixes anwenden kann)
- Uebergib PROJECT_ROOT, die Liste der geaenderten Dateien und ggf. API-Aenderungen aus den Worker-Antworten
- Der Agent gibt seinen Test-Report als Markdown-Antwort zurueck.

### Phase 6: Abschluss (Teamleader)

1. **Alle Agenten-Antworten** zusammenfassen
2. **Test-Report pruefen** – bei Blockern zurueck zu Phase 4
3. **Abschlussbericht erstellen** fuer den User gemaess `references/report-template.md`
4. **User fragen** ob er den Branch mergen, weitere Aenderungen oder einen Squash-Merge moechte.

---

## Konfiguration & Anpassung

Der User kann vor dem Start folgende Praeferenzen angeben. Frage aktiv danach:

| Option | Beschreibung | Default |
|---|---|---|
| `scope` | Ganzes Projekt oder bestimmte Verzeichnisse | Ganzes Projekt |
| `aggression` | Wie aggressiv refactoren (conservative/moderate/aggressive) | moderate |
| `auto_commit` | Automatisch committen oder nur aendern | true |
| `max_parallel` | Max. gleichzeitige Subagents | 4 |
| `skip_tests` | Test-Phase ueberspringen | false |
| `language` | Berichtssprache | de |
| `dry_run` | Nur analysieren, nichts aendern | false |

---

## Fehlerbehandlung

- **Subagent schlaegt fehl**: Antwort pruefen, bei transientem Fehler einmal wiederholen, sonst User informieren
- **Merge-Konflikte zwischen Workers**: Passiert wenn parallele Agents dieselbe Datei aendern – deshalb Dateien strikt aufteilen. Falls doch: manuell resolven und committen
- **Build bricht nach Refactoring**: Test-Agent versucht Fix (max 3 Iterationen). Falls nicht moeglich: letzten funktionierenden Commit identifizieren, User informieren
- **Zu grosses Projekt**: Bei >500 Dateien in Batches aufteilen (z.B. nach Top-Level-Verzeichnis)

---

## Hinweise

- Jeder Agent gibt seine Ergebnisse als Markdown-Antwort zurueck. Der Koordinator reicht diese als Kontext an den naechsten Agenten weiter.
- Agenten werden ueber das Agent-Tool gestartet — siehe `../../references/agent-invocation.md` fuer Details.
- Alle Aenderungen sind auf dem Refactoring-Branch – der Main-Branch bleibt unberuehrt.
- Bei `dry_run: true` wird nur der Scout-Agent ausgefuehrt und der Plan erstellt, aber nichts geaendert.
