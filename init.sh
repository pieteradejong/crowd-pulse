#!/usr/bin/env bash
# Set up everything needed to work on crowd-pulse. Idempotent: a second run reuses
# what it finds. Exit 0 = ready.
#   ./init.sh          check Go, download both services' modules, create the simulator venv
#   ./init.sh --clean  delete and recreate the simulator venv first
# Docker (Colima) is only needed for ./run.sh up; this script reports whether it is reachable.
set -euo pipefail
cd "$(dirname "$0")"

GO_MIN=1.20
VENV=src/utils/venv
GO_MODULES="src/common src/message-service src/sign-service"

CLEAN=0
for arg in "$@"; do
    case "$arg" in
        --clean) CLEAN=1 ;;
        -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
        *) echo "unknown option: $arg (see --help)" >&2; exit 2 ;;
    esac
done

# --- Go toolchain -----------------------------------------------------------
if ! command -v go >/dev/null 2>&1; then
    echo "go not found; install Go $GO_MIN or newer" >&2
    exit 1
fi
go_have="$(go env GOVERSION | sed 's/^go//')"
if [ "$(printf '%s\n%s\n' "$GO_MIN" "$go_have" | sort -V | head -n 1)" != "$GO_MIN" ]; then
    echo "Go $go_have is older than $GO_MIN (go.mod)" >&2
    exit 1
fi
echo "go $go_have"

# --- Go modules ---------------------------------------------------------------
for m in $GO_MODULES; do
    echo "go mod download: $m"
    (cd "$m" && go mod download)
done

# --- Simulator venv -----------------------------------------------------------
if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found" >&2
    exit 1
fi
if [ "$CLEAN" -eq 1 ] && [ -d "$VENV" ]; then
    echo "removing $VENV"
    rm -rf "$VENV"
fi
if [ ! -x "$VENV/bin/python" ]; then
    echo "creating $VENV"
    python3 -m venv "$VENV"
fi
"$VENV/bin/python" -m pip install --quiet --disable-pip-version-check -r src/utils/requirements.txt
echo "venv ready: $VENV"

# --- Docker (informational) ---------------------------------------------------
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo "docker: reachable"
else
    echo "docker: not reachable (needed only for ./run.sh up; start it with: colima start)"
fi

echo "init complete"
