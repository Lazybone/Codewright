#!/usr/bin/env bash
# detect-and-run-tests.sh
# Automatically detects the test framework and runs tests.
# Usage: ./scripts/detect-and-run-tests.sh [--dry-run]
#
# Exit codes:
#   0 = Tests passed
#   1 = Tests failed
#   2 = No test framework detected

set -euo pipefail

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

run_cmd() {
    echo "▶ $*"
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  (dry-run, not executed)"
        return 0
    fi
    "$@"
}

# --- JavaScript / TypeScript ---
if [[ -f "package.json" ]]; then
    # Check for test script in package.json
    if grep -q '"test"' package.json 2>/dev/null; then
        PKG_MANAGER="npm"
        [[ -f "yarn.lock" ]] && PKG_MANAGER="yarn"
        [[ -f "pnpm-lock.yaml" ]] && PKG_MANAGER="pnpm"
        [[ -f "bun.lockb" ]] && PKG_MANAGER="bun"

        echo "=== Detected: $PKG_MANAGER (package.json) ==="
        run_cmd $PKG_MANAGER test
        exit $?
    fi
fi

# --- Python ---
if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "setup.cfg" ]]; then
    if [[ -f "pyproject.toml" ]] && grep -q "pytest" pyproject.toml 2>/dev/null; then
        echo "=== Detected: pytest (pyproject.toml) ==="
        run_cmd pytest -v
        exit $?
    fi
    if command -v pytest &>/dev/null; then
        echo "=== Detected: pytest ==="
        run_cmd pytest -v
        exit $?
    fi
    if [[ -f "manage.py" ]]; then
        echo "=== Detected: Django ==="
        run_cmd python manage.py test
        exit $?
    fi
fi

# --- Rust ---
if [[ -f "Cargo.toml" ]]; then
    echo "=== Detected: cargo test ==="
    run_cmd cargo test
    exit $?
fi

# --- Go ---
if [[ -f "go.mod" ]]; then
    echo "=== Detected: go test ==="
    run_cmd go test ./...
    exit $?
fi

# --- Ruby ---
if [[ -f "Gemfile" ]]; then
    if [[ -f "Rakefile" ]] && grep -q "rspec" Gemfile 2>/dev/null; then
        echo "=== Detected: rspec ==="
        run_cmd bundle exec rspec
        exit $?
    fi
    if grep -q "minitest" Gemfile 2>/dev/null; then
        echo "=== Detected: minitest ==="
        run_cmd bundle exec rake test
        exit $?
    fi
fi

# --- Java / Kotlin ---
if [[ -f "pom.xml" ]]; then
    echo "=== Detected: Maven ==="
    run_cmd mvn test
    exit $?
fi
if [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]]; then
    echo "=== Detected: Gradle ==="
    run_cmd ./gradlew test
    exit $?
fi

# --- Makefile ---
if [[ -f "Makefile" ]]; then
    if grep -q "^test:" Makefile 2>/dev/null; then
        echo "=== Detected: make test ==="
        run_cmd make test
        exit $?
    fi
fi

echo "⚠ No test framework detected."
echo "  Please specify the test command manually."
exit 2
