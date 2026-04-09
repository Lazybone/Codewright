#!/usr/bin/env bash
# project-info.sh — Sammelt grundlegende Projekt-Informationen
# Wird vom Koordinator in Phase 1 genutzt.
#
# Usage: ./scripts/project-info.sh [project-root]
# Output: JSON mit Projekt-Metadaten

set -euo pipefail

ROOT="${1:-.}"
cd "$ROOT"

echo "{"

# --- Sprache erkennen ---
languages=()
[ -f package.json ] && languages+=("javascript/typescript")
[ -f tsconfig.json ] && languages+=("typescript")
[ -f pyproject.toml ] || [ -f setup.py ] || [ -f requirements.txt ] && languages+=("python")
[ -f Cargo.toml ] && languages+=("rust")
[ -f go.mod ] && languages+=("go")
[ -f Gemfile ] && languages+=("ruby")
[ -f pom.xml ] || [ -f build.gradle ] || [ -f build.gradle.kts ] && languages+=("java/kotlin")
[ -f composer.json ] && languages+=("php")

printf '  "languages": ['
first=true
for lang in "${languages[@]}"; do
  $first && first=false || printf ', '
  printf '"%s"' "$lang"
done
printf '],\n'

# --- Framework erkennen ---
framework="unknown"
if [ -f package.json ]; then
  [ -f next.config.* ] 2>/dev/null && framework="nextjs"
  [ -f nuxt.config.* ] 2>/dev/null && framework="nuxt"
  [ -f vite.config.* ] 2>/dev/null && framework="vite"
  [ -f angular.json ] && framework="angular"
  grep -q '"react"' package.json 2>/dev/null && [ "$framework" = "unknown" ] && framework="react"
  grep -q '"express"' package.json 2>/dev/null && framework="express"
  grep -q '"fastify"' package.json 2>/dev/null && framework="fastify"
  grep -q '"svelte"' package.json 2>/dev/null && framework="svelte"
fi
[ -f manage.py ] && framework="django"
grep -q "flask" pyproject.toml 2>/dev/null && framework="flask"
grep -q "fastapi" pyproject.toml 2>/dev/null && framework="fastapi"
[ -f Cargo.toml ] && grep -q "actix" Cargo.toml 2>/dev/null && framework="actix"
[ -f Cargo.toml ] && grep -q "axum" Cargo.toml 2>/dev/null && framework="axum"

printf '  "framework": "%s",\n' "$framework"

# --- Datei-Statistiken ---
total_files=$(find . -type f \
  -not -path '*/.git/*' -not -path '*/node_modules/*' \
  -not -path '*/vendor/*' -not -path '*/target/*' \
  -not -path '*/__pycache__/*' -not -path '*/dist/*' \
  -not -path '*/build/*' -not -path '*/.next/*' \
  2>/dev/null | wc -l | tr -d ' ')

source_files=$(find . -type f \
  \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
     -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \
     -o -name "*.rb" -o -name "*.php" -o -name "*.c" -o -name "*.cpp" \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -not -path '*/vendor/*' -not -path '*/target/*' \
  2>/dev/null | wc -l | tr -d ' ')

test_files=$(find . -type f \
  \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" \
     -o -name "*_test.py" -o -name "*_test.go" -o -name "*_test.rs" \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' \
  2>/dev/null | wc -l | tr -d ' ')

printf '  "total_files": %s,\n' "$total_files"
printf '  "source_files": %s,\n' "$source_files"
printf '  "test_files": %s,\n' "$test_files"

# --- GitHub ---
has_gh=false
command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1 && has_gh=true

open_issues=0
if $has_gh; then
  open_issues=$(gh issue list --state open --limit 1000 --json number 2>/dev/null \
    | jq 'length' 2>/dev/null || echo 0)
fi

printf '  "github_cli": %s,\n' "$has_gh"
printf '  "open_issues": %s,\n' "$open_issues"

# --- Essenzielle Dateien ---
printf '  "has_readme": %s,\n' "$([ -f README.md ] && echo true || echo false)"
printf '  "has_gitignore": %s,\n' "$([ -f .gitignore ] && echo true || echo false)"
printf '  "has_license": %s,\n' "$([ -f LICENSE ] || [ -f LICENSE.md ] && echo true || echo false)"
printf '  "has_ci": %s,\n' "$([ -d .github/workflows ] || [ -f .gitlab-ci.yml ] && echo true || echo false)"
printf '  "has_tests": %s\n' "$([ "$test_files" -gt 0 ] && echo true || echo false)"

echo "}"
