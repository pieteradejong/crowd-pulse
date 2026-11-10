# TODO

- [ ] Run `./test.sh --docker` once Colima is up; the compose checks are unverified — 2026-11-10, CHANGELOG [Unreleased] (scripts added)
- [ ] Point `.github/workflows/go.yml` at `./test.sh --ci` instead of its own gofmt step (repo-standards § Scripts); its actions are also unpinned `@v2` tags — 2026-11-10, repo-standards.md § Scripts
- [ ] `go.sum` is gitignored, so module checksums aren't committed; decide whether to track them — 2026-11-10, repo-standards.md § Dependencies
- [ ] `src/message-service/message-service` is a compiled arm64 binary in git; remove it and ignore it — 2026-11-10, repo-standards.md § Media and large binaries
- [ ] No Go tests exist; `go test` passes only because there are no test files — 2026-11-10, test.sh run
- [ ] Triage Dependabot: 48 alerts on main (8 high, 23 moderate, 17 low), reported on push of c6a085c — 2026-11-10, GitHub security/dependabot
