# F6 — Office Visualization, Dashboard and Log Explorer (2 weeks)

**Goal:** operators see what every agent is doing, what it costs, and how good the output is, live and on replay.

## Tasks

**Office** (`/kantor`, behavior from [Appendix C](../appendix/C-office-dashboard-spec.md))
- [ ] PixiJS scene in the light palette: rooms per department (Lobby, Research, Archive, Transcription, Splitting, Network, Version, QC, Director, Review, Server).
- [ ] Original or properly licensed sprite sheets (4 directions × idle/walk/type/read/think/alert) and tilemap.
- [ ] Event-driven sprite state machine (spawn, task start/finish, LLM thinking + token counter, QC pass/fail, throttled hourglass, blocked/dead).
- [ ] Hover/click detail panels, room task lists, pan/zoom, mini-map, filters, replay from `event_log`, aggregation above ~150 agents.
- [ ] **Tabel** mode with the same information, default under `prefers-reduced-motion`.

**Dashboard** (`/dasbor/*`)
- [ ] Pages: Run, Coverage (funnel + type/year heatmap + failures), Tokens & Cost (`09` §2), Swarm, Quality, Scraping (actual vs target delay), Versioning.
- [ ] `/api/metrics/*` aggregated server-side; charts with grayscale + Action Blue focus series, direct labels, data-table alternative, "data per <timestamp>".

**Logs** (`/log`)
- [ ] Log explorer with filters and text search; per-document trace timeline; LLM call inspector (request/response, retry diff, "tandai sebagai golden"); CSV/JSON export.
- [ ] Alerts banner (`09` §3).

## Exit Criteria

- Live activity during a run is visible in the office and table mode within 1 s of the event.
- Dashboard numbers match direct DB queries for a sample run (attach the comparison).
- Replay of a past run reproduces the event sequence.
- 200 simulated agents render at ≥ 30 fps on the reference machine (aggregation on).
- axe clean; charts and office usable without animation.
