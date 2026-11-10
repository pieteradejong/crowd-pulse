#!/usr/bin/env bash
# ./run.sh [up|down|logs|simulate|build|test|lint|format]
#   up        build and start ZooKeeper, Kafka, Spark and both Go services (default; needs Colima)
#   down      stop and remove the compose stack
#   logs      follow logs; optional service name, e.g. ./run.sh logs message-service
#   simulate  send simulated emoji reactions to http://localhost:8080 (needs ./init.sh and `up`)
#   build     build the compose images
#   test      exec ./test.sh with the remaining arguments (--docker, --ci)
#   lint      gofmt -l and go vet
#   format    gofmt -w
set -euo pipefail
cd "$(dirname "$0")"

VENV=src/utils/venv
GO_MODULES="src/common src/message-service src/sign-service"

MODE="${1:-up}"
[ $# -gt 0 ] && shift

need_docker() {
    if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
        echo "Docker is not reachable. Start it with: colima start" >&2
        exit 1
    fi
}

case "$MODE" in
    up)
        need_docker
        exec docker compose up --build "$@"
        ;;
    down)
        need_docker
        exec docker compose down "$@"
        ;;
    logs)
        need_docker
        exec docker compose logs -f "$@"
        ;;
    build)
        need_docker
        exec docker compose build "$@"
        ;;
    simulate)
        if [ ! -x "$VENV/bin/python" ]; then
            echo "No simulator venv. Run ./init.sh first" >&2
            exit 1
        fi
        exec "$VENV/bin/python" src/utils/simulate_requests.py "$@"
        ;;
    test)
        exec ./test.sh "$@"
        ;;
    lint)
        out="$(gofmt -l src)"
        if [ -n "$out" ]; then echo "not gofmt-formatted:"; echo "$out"; exit 1; fi
        for m in $GO_MODULES; do (cd "$m" && go vet ./...); done
        echo "lint clean"
        ;;
    format)
        gofmt -w src
        ;;
    -h|--help)
        sed -n '2,10p' "$0"
        ;;
    *)
        echo "unknown command: $MODE" >&2
        sed -n '2,10p' "$0" >&2
        exit 2
        ;;
esac
