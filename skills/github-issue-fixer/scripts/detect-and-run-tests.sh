#!/usr/bin/env bash
# detect-and-run-tests.sh
# Erkennt automatisch das Test-Framework und führt Tests aus.
# Usage: ./scripts/detect-and-run-tests.sh [--dry-run]
#
# Exit codes:
#   0 = Tests bestanden
#   1 = Tests fehlgeschlagen
#   2 = Kein Test-Framework erkannt

set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

run_cmd() {
    echo "▶ $*"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  (dry-run, nicht ausgeführt)"
        return 0
    fi
    "$@"
}

# --- JavaScript / TypeScript ---
if [[ -f "package.json" ]]; then
    # Prüfe auf Test-Script in package.json
    if grep -q '"test"' package.json 2>/dev/null; then
        PKG_MANAGER="npm"
        [[ -f "yarn.lock" ]] && PKG_MANAGER="yarn"
        [[ -f "pnpm-lock.yaml" ]] && PKG_MANAGER="pnpm"
        [[ -f "bun.lockb" ]] && PKG_MANAGER="bun"

        echo "=== Erkannt: $PKG_MANAGER (package.json) ==="
        run_cmd $PKG_MANAGER test
        exit $?
    fi
fi

# --- Python ---
if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "setup.cfg" ]]; then
    if [[ -f "pyproject.toml" ]] && grep -q "pytest" pyproject.toml 2>/dev/null; then
        echo "=== Erkannt: pytest (pyproject.toml) ==="
        run_cmd pytest -v
        exit $?
    fi
    if command -v pytest &>/dev/null; then
        echo "=== Erkannt: pytest ==="
        run_cmd pytest -v
        exit $?
    fi
    if [[ -f "manage.py" ]]; then
        echo "=== Erkannt: Django ==="
        run_cmd python manage.py test
        exit $?
    fi
fi

# --- Rust ---
if [[ -f "Cargo.toml" ]]; then
    echo "=== Erkannt: cargo test ==="
    run_cmd cargo test
    exit $?
fi

# --- Go ---
if [[ -f "go.mod" ]]; then
    echo "=== Erkannt: go test ==="
    run_cmd go test ./...
    exit $?
fi

# --- Ruby ---
if [[ -f "Gemfile" ]]; then
    if [[ -f "Rakefile" ]] && grep -q "rspec" Gemfile 2>/dev/null; then
        echo "=== Erkannt: rspec ==="
        run_cmd bundle exec rspec
        exit $?
    fi
    if grep -q "minitest" Gemfile 2>/dev/null; then
        echo "=== Erkannt: minitest ==="
        run_cmd bundle exec rake test
        exit $?
    fi
fi

# --- Java / Kotlin ---
if [[ -f "pom.xml" ]]; then
    echo "=== Erkannt: Maven ==="
    run_cmd mvn test
    exit $?
fi
if [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    echo "=== Erkannt: Gradle ==="
    run_cmd ./gradlew test
    exit $?
fi

# --- Makefile ---
if [[ -f "Makefile" ]]; then
    if grep -q "^test:" Makefile 2>/dev/null; then
        echo "=== Erkannt: make test ==="
        run_cmd make test
        exit $?
    fi
fi

echo "⚠ Kein Test-Framework erkannt."
echo "  Bitte gib den Test-Befehl manuell an."
exit 2
