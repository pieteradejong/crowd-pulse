#!/usr/bin/env bash
# Run every check, keep going after a failure, print a summary, exit non-zero if
# anything failed.
#   ./test.sh           toolchain, no tracked .env, gofmt, go vet, go build, go test,
#                       Python syntax, shell syntax + shellcheck
#   ./test.sh --docker  also validate docker-compose.yml and build its images (needs Colima)
#   ./test.sh --ci      plain output (no colours)
# Checks behind a flag that is not given are listed as "skip" in the summary.
set -u
cd "$(dirname "$0")" || exit 1

GO_MIN=1.20
GO_MODULES="src/common src/message-service src/sign-service"
SCRIPTS="init.sh test.sh run.sh"
PY_FILES="src/utils/simulate_requests.py src/spark/spark_streaming_job_emojis.py"

CI=0
DOCKER=0
for arg in "$@"; do
    case "$arg" in
        --ci) CI=1 ;;
        --docker) DOCKER=1 ;;
        -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
        *) echo "unknown option: $arg (see --help)" >&2; exit 2 ;;
    esac
done

if [ "$CI" -eq 1 ] || [ ! -t 1 ]; then
    GREEN=''; RED=''; YELLOW=''; BOLD=''; RESET=''
else
    GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; BOLD='\033[1m'; RESET='\033[0m'
fi

STEP_NAMES=()
STEP_RESULTS=()
FAILED=0

run_step() {
    local name="$1"; shift
    printf '\n%b== %s ==%b\n' "$BOLD" "$name" "$RESET"
    printf '$ %s\n' "$*"
    if "$@"; then
        STEP_RESULTS+=("pass")
    else
        STEP_RESULTS+=("FAIL")
        FAILED=1
    fi
    STEP_NAMES+=("$name")
}

skip_step() {
    STEP_NAMES+=("$1")
    STEP_RESULTS+=("skip")
}

check_go_version() {
    command -v go >/dev/null 2>&1 || { echo "go not found"; return 1; }
    local have
    have="$(go env GOVERSION | sed 's/^go//')"
    echo "go $have (need >= $GO_MIN)"
    [ "$(printf '%s\n%s\n' "$GO_MIN" "$have" | sort -V | head -n 1)" = "$GO_MIN" ]
}

check_no_tracked_env() {
    local hits
    hits="$(git ls-files | grep -E '(^|/)\.env($|\.)' | grep -vE '\.env\.(example|template)$' || true)"
    [ -z "$hits" ] || { echo "tracked env files:"; echo "$hits"; return 1; }
}

check_gofmt() {
    local out
    out="$(gofmt -l src)"
    [ -z "$out" ] || { echo "not gofmt-formatted:"; echo "$out"; return 1; }
}

in_each_module() {
    local m rc=0
    for m in $GO_MODULES; do
        echo "-- $m"
        (cd "$m" && "$@") || rc=1
    done
    return "$rc"
}

check_python_syntax() {
    local f rc=0
    for f in $PY_FILES; do
        python3 -c 'import ast, sys; ast.parse(open(sys.argv[1], encoding="utf-8").read(), sys.argv[1])' "$f" || rc=1
    done
    return "$rc"
}

check_shell_syntax() {
    local f rc=0
    for f in $SCRIPTS; do bash -n "$f" || rc=1; done
    return "$rc"
}

check_shellcheck() {
    command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not found (brew install shellcheck)"; return 1; }
    # shellcheck disable=SC2086 # word splitting of the list is intended
    shellcheck -S warning $SCRIPTS
}

run_step "Go toolchain >= $GO_MIN" check_go_version
run_step "no tracked .env" check_no_tracked_env
run_step "format (gofmt -l)" check_gofmt
run_step "vet (go vet)" in_each_module go vet ./...
run_step "build (go build)" in_each_module go build -o /dev/null ./...
run_step "tests (go test)" in_each_module go test ./...
run_step "Python syntax" check_python_syntax
run_step "shell syntax (bash -n)" check_shell_syntax
run_step "shellcheck" check_shellcheck

if [ "$DOCKER" -eq 1 ]; then
    run_step "compose config" docker compose config --quiet
    run_step "compose build" docker compose build
else
    skip_step "compose config (--docker)"
    skip_step "compose build (--docker)"
fi

printf '\n%bSummary%b\n' "$BOLD" "$RESET"
i=0
while [ "$i" -lt "${#STEP_NAMES[@]}" ]; do
    case "${STEP_RESULTS[$i]}" in
        pass) color="$GREEN" ;;
        skip) color="$YELLOW" ;;
        *) color="$RED" ;;
    esac
    printf '  %b%-6s%b %s\n' "$color" "${STEP_RESULTS[$i]}" "$RESET" "${STEP_NAMES[$i]}"
    i=$((i + 1))
done

if [ "$FAILED" -ne 0 ]; then
    printf '\n%bSome checks failed.%b\n' "$RED" "$RESET"
    exit 1
fi
printf '\n%bAll checks passed.%b\n' "$GREEN" "$RESET"
exit 0
