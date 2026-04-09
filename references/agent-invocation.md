# Agent-Invocation Standard

Zentrale Referenz für die Nutzung des **Agent**-Tools in allen Codewright-Skills.

---

## 1. Agenten starten

Agenten werden über das `Agent`-Tool von Claude Code gestartet. Es gibt zwei Modi:

### Read-Only (Explore)

Für reine Analyse ohne Code-Änderungen:

```
Agent(
  subagent_type="Explore",
  prompt="Lies die Datei agents/<name>.md und führe die Anweisungen aus.
    Projekt: <PROJECT_ROOT>
    Kontext: <ZUSÄTZLICHER_KONTEXT>"
)
```

- Der Agent kann Dateien lesen, suchen und analysieren.
- Er darf **keine** Dateien erstellen oder ändern.

### Code-Changing (Auto Mode)

Für Agenten die Dateien ändern oder erstellen dürfen:

```
Agent(
  mode="auto",
  prompt="Lies die Datei agents/<name>.md und führe die Anweisungen aus.
    Projekt: <PROJECT_ROOT>
    Dateien die du ändern darfst: <FILE_LIST>
    Kontext: <ZUSÄTZLICHER_KONTEXT>"
)
```

- Der Agent darf Dateien lesen, erstellen und ändern.
- Die erlaubten Dateien **immer explizit** im Prompt angeben.

---

## 2. Parallele Ausführung

Mehrere Agenten können gleichzeitig in einem Nachrichtenblock gestartet werden:

```
Agent(
  subagent_type="Explore",
  run_in_background=true,
  name="security-agent",
  prompt="..."
)

Agent(
  subagent_type="Explore",
  run_in_background=true,
  name="quality-agent",
  prompt="..."
)
```

- Jeden Agenten mit `run_in_background=true` und einem eindeutigen `name` starten.
- Auf **alle** Agenten warten, bevor die Ergebnisse zusammengeführt werden.
- Die Reihenfolge der Fertigstellung ist nicht garantiert.

---

## 3. Rückgabeformat

Agenten liefern ihre Ergebnisse als **Markdown-Text** in ihrer letzten Nachricht zurück. Der Koordinator liest diese Antwort und verarbeitet sie weiter.

Erwartetes Format für Findings:

```markdown
## Findings

### [SEVERITY] Kurzbeschreibung
- **Datei:** pfad/zur/datei.ts
- **Zeile:** 42
- **Problem:** Beschreibung des Problems
- **Empfehlung:** Vorgeschlagene Lösung
```

---

## 4. Keine Findings

Wenn ein Agent keine Probleme findet, muss er explizit mit diesem Format antworten:

```markdown
## Ergebnis

Keine Findings in diesem Bereich. Die analysierten Dateien sind sauber.

**Geprüfte Bereiche:** <Liste>
**Geprüfte Dateien:** <Anzahl>
```

Niemals eine leere Antwort oder nur "alles ok" zurückgeben — die strukturierte Angabe der geprüften Bereiche und Dateianzahl ist Pflicht.

---

## 5. Fehlerbehandlung

### Agent antwortet nicht
- Maximal **5 Minuten** warten.
- Danach den Nutzer informieren: welcher Agent nicht reagiert hat und welcher Bereich betroffen ist.

### Agent meldet einen Fehler
- Prüfen, ob ein benötigtes Tool nicht verfügbar ist.
- Dem Nutzer anbieten, den betroffenen Bereich zu überspringen.
- Die restlichen Ergebnisse trotzdem auswerten.

### Tool nicht installiert
- Der Agent erstellt ein **INFO**-Finding:

```markdown
### [INFO] Tool nicht verfügbar
- **Tool:** <Tool-Name>
- **Problem:** Tool X nicht verfügbar, Bereich Y konnte nicht geprüft werden.
- **Empfehlung:** Tool installieren oder Bereich manuell prüfen.
```
