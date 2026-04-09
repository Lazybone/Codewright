#!/usr/bin/env bash
# create-audit-issues.sh — Erstellt GitHub Issues aus einer Findings-Datei
#
# Usage: ./scripts/create-audit-issues.sh <findings.json> [max-issues]
#
# Input: JSON-Array mit Findings:
# [
#   {
#     "title": "[AUDIT/SECURITY] Hardcoded API key",
#     "body": "## Beschreibung\n...",
#     "labels": "audit:security,severity:critical"
#   }
# ]
#
# Output: JSON-Array mit erstellten Issue-Nummern

set -euo pipefail

FINDINGS_FILE="${1:?Usage: $0 <findings.json> [max-issues]}"
MAX_ISSUES="${2:-30}"
DELAY_SECONDS=2

if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI nicht installiert" >&2
  exit 1
fi

if ! gh auth status &>/dev/null 2>&1; then
  echo "Error: gh nicht authentifiziert" >&2
  exit 1
fi

total=$(jq 'length' "$FINDINGS_FILE")
limit=$((total > MAX_ISSUES ? MAX_ISSUES : total))

echo "Erstelle $limit von $total Issues..." >&2

results=()
created=0

while IFS= read -r finding; do
  title=$(echo "$finding" | jq -r '.title')
  body=$(echo "$finding" | jq -r '.body')
  labels=$(echo "$finding" | jq -r '.labels')

  issue_url=$(gh issue create \
    --title "$title" \
    --body "$body" \
    --label "$labels" \
    2>/dev/null) || {
    echo "  ⚠ Fehler beim Erstellen: $title" >&2
    continue
  }

  issue_num=$(echo "$issue_url" | grep -oE '[0-9]+$')
  created=$((created + 1))
  echo "  ✅ #$issue_num: $title" >&2

  results+=("{\"number\": $issue_num, \"title\": $(echo "$title" | jq -R .), \"url\": \"$issue_url\"}")

  sleep "$DELAY_SECONDS"
done < <(jq -c '.[]' "$FINDINGS_FILE" | head -n "$MAX_ISSUES")

# JSON-Array ausgeben
printf '[\n'
for i in "${!results[@]}"; do
  [ "$i" -gt 0 ] && printf ',\n'
  printf '  %s' "${results[$i]}"
done
printf '\n]\n'

if [ "$total" -gt "$MAX_ISSUES" ]; then
  skipped=$((total - MAX_ISSUES))
  echo "" >&2
  echo "⚠ $skipped Findings übersprungen (Limit: $MAX_ISSUES)." >&2
fi
