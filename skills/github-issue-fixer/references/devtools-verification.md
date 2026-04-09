# Browser-Verifikation mit MCP Google DevTools

Wenn ein Issue ein visuelles Problem, ein Frontend-Bug oder ein Browser-spezifisches
Verhalten betrifft, nutze MCP Google DevTools zur Verifikation.

## Wann Browser-Verifikation nutzen

Verwende DevTools wenn das Issue eines dieser Themen betrifft:
- Layout/CSS-Probleme (Elemente falsch positioniert, fehlende Styles)
- JavaScript-Fehler in der Browser-Konsole
- Netzwerk-Anfragen die fehlschlagen (API-Calls, Asset-Loading)
- Interaktions-Bugs (Klick-Handler, Formulare, Navigation)
- Responsive-Design-Probleme
- Performance-Probleme (langsames Rendering, Memory Leaks)

## Vorgehensweise

### 1. Dev-Server starten

Stelle sicher dass die Anwendung lokal läuft:
```bash
# Erkenne den Start-Befehl aus package.json, Makefile, etc.
npm run dev    # oder yarn dev, pnpm dev
python manage.py runserver
cargo run
```

Warte bis der Server bereit ist und notiere die URL (meist http://localhost:3000
oder http://localhost:8080).

### 2. Seite im Browser öffnen

Nutze die MCP Google DevTools um:
- Die relevante Seite zu öffnen
- Zum betroffenen Bereich zu navigieren
- Die Reproduktionsschritte aus dem Issue durchzuführen

### 3. Vor dem Fix: Bug dokumentieren

Prüfe und dokumentiere:
- **Console**: JavaScript-Fehler oder Warnungen
- **Network**: Fehlgeschlagene Requests (4xx, 5xx, CORS)
- **Elements**: DOM-Struktur und berechnete Styles
- **Screenshots**: Visuellen Zustand festhalten

### 4. Nach dem Fix: Verifikation

Lade die Seite neu und wiederhole die Reproduktionsschritte:
- Bug sollte nicht mehr auftreten
- Keine neuen Konsolen-Fehler
- Keine neuen fehlgeschlagenen Netzwerk-Requests
- Visuelles Ergebnis entspricht dem erwarteten Verhalten

### 5. Ergebnis dokumentieren

```
## Browser-Verifikation

### Vorher
- Console-Fehler: <ja/nein, welche>
- Visuelles Problem: <Beschreibung>
- Network-Fehler: <ja/nein, welche>

### Nachher
- Console-Fehler: <behoben/keine neuen>
- Visuelles Ergebnis: <korrekt/Beschreibung>
- Network-Status: <alle Requests erfolgreich>

### Fazit
Bug behoben: ja/nein
Neue Probleme: ja/nein
```

## Fallback ohne MCP DevTools

Wenn MCP Google DevTools nicht verfügbar ist:
1. Informiere den User dass manuelle Browser-Tests empfohlen werden
2. Beschreibe die genauen Schritte die der User im Browser durchführen soll
3. Verlasse dich auf die automatischen Tests als primäre Verifikation
