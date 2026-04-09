# Commit-Konventionen für Issue-Fixes

## Format

```
fix: <kurze Beschreibung im Imperativ> (closes #<NUMMER>)

<Optionaler Body: Was wurde geändert und warum.
Beschreibe den Root Cause und die gewählte Lösung.
Maximal 72 Zeichen pro Zeile.>

Fixes #<NUMMER>
```

## Beispiele

### Einfacher Fix
```
fix: prevent null pointer in user validation (closes #142)

The validateUser function did not check for undefined email field
before accessing its length property. Added null check with
appropriate error message.

Fixes #142
```

### Fix mit mehreren Dateien
```
fix: resolve race condition in data sync (closes #87)

The WebSocket handler and the REST polling were both writing to
the same state without synchronization. Introduced a mutex lock
and debounced the polling to prevent concurrent writes.

Changed files:
- src/sync/websocket.ts: Added lock acquisition before state write
- src/sync/polling.ts: Added debounce and lock check
- src/sync/__tests__/sync.test.ts: Added concurrent write test

Fixes #87
```

## Regeln

1. Erste Zeile: Maximal 50 Zeichen (ohne Issue-Referenz)
2. Imperativ verwenden: "fix" nicht "fixed" oder "fixes"
3. Kein Punkt am Ende der ersten Zeile
4. Leerzeile zwischen Betreff und Body
5. Body erklärt WAS und WARUM, nicht WIE (das steht im Diff)
6. `Fixes #<N>` am Ende sorgt dafür dass GitHub das Issue automatisch schließt
7. Prüfe ob das Projekt eigene Konventionen hat (CONTRIBUTING.md) und
   bevorzuge diese
