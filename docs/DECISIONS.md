# Decisions

## 1 · 2026-11-10 · Name: `crowd-pulse`

**Context.** The repo was called `go-service`, which names the language and says nothing about
the project: a live emoji-reaction pipeline (HTTP → Kafka → Spark 2-second windows → SSE).

**Decision.** Rename the GitHub repo and the local folder to `crowd-pulse`: it names the outcome
(the crowd's mood, refreshed every few seconds) rather than the stack. The portfolio page keeps
its slug (`reaction-message-service`) so its URL does not change; only its `githubUrl` moves.
The Go module names (`message-service`, `sign-service`) stay.

**Rejected.** `live-reactions` — matches the portfolio title "Live Emoji Reactions" but is
generic; `emoji-stream` — names the transport, not the result; keeping `go-service` — says
nothing about the project.

**Verified:** `gh repo view pieteradejong/crowd-pulse --json name,description,visibility` →
`{"name":"crowd-pulse","visibility":"PUBLIC",…}` on 2026-11-10; `git push` to the new remote
succeeded (see the commit that added this file).
