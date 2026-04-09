# Commit Conventions for Issue Fixes

## Format

```
fix: <short description in imperative> (closes #<NUMBER>)

<Optional body: What was changed and why.
Describe the root cause and the chosen solution.
Maximum 72 characters per line.>

Fixes #<NUMBER>
```

## Examples

### Simple Fix
```
fix: prevent null pointer in user validation (closes #142)

The validateUser function did not check for undefined email field
before accessing its length property. Added null check with
appropriate error message.

Fixes #142
```

### Fix with Multiple Files
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

## Rules

1. First line: Maximum 50 characters (excluding issue reference)
2. Use imperative: "fix" not "fixed" or "fixes"
3. No period at the end of the first line
4. Blank line between subject and body
5. Body explains WHAT and WHY, not HOW (that is in the diff)
6. `Fixes #<N>` at the end ensures GitHub automatically closes the issue
7. Check if the project has its own conventions (CONTRIBUTING.md) and
   prefer those
