# Changelog

## [Unreleased]

### Changed
- Renamed from `go-service` to `crowd-pulse` (2026-11-10): the GitHub repo, the local folder and
  the README badges; the README now opens with what the project does (docs/DECISIONS.md #1).

### Added
- `init.sh`, `test.sh` and `run.sh` at the repo root (2026-11-10). `init.sh` checks Go >= 1.20,
  downloads the modules and creates the simulator venv. `test.sh` runs gofmt, go vet, go build,
  go test, a Python syntax check and shellcheck, with the compose checks behind `--docker`.
  `run.sh` starts the compose stack (default), runs the simulator, and wraps
  down/logs/build/lint/format/test.
