# Appendix C — Office, Dashboard, Logs and Control Panel Spec

Detailed behavior from the original plan. Adjustments in `07-web-apps.md` §7 and the light theme in `08-design-system.md` take precedence.

## 3. Office Visualization (Office-Worker Sprites)

**Technology:** PixiJS (2D, good performance with many sprites), chosen over Three.js because the need is 2D/isometric sprites. Assets: worker sprite sheets (4 directions × idle/walk/type/read/think/alert animations), office tilemap; use free assets or custom-made ones — **avoid licensed/copyrighted character assets**.

**Office layout (department = agent category):**

| Room | Agents | Visual |
|------|--------|--------|
| Lobby / Reception | Supervisor/Dispatcher | Queue board, incoming-folder count |
| Research Room | Scout | Worker with map/laptop, "browsing" |
| Archive / Warehouse | Fetcher | Pulling folders off shelves, PDF trolley; hourglass icon during delays |
| Transcription Room | Extractor | Typewriter/scanner |
| Splitting Room | Splitter | Big table cutting documents into small cards |
| Network Room | Relation | Red-string board linking cards |
| Version Room | Version Builder, Compiler | Tiered revision shelves, version stacks |
| QC Room | Node/Relation/Version/Display QC | Desk with magnifier, ✔/✖ stamps |
| Director's Room | Chief QC | Large desk, final stamp |
| Review Room | Human (you) | Door for review items |
| Server Room | Postgres/Redis/MinIO/Azure | Server racks with activity LEDs |

**Behavior (sprite state machine driven by events):**
- `agent.spawned` → sprite appears at the door → walks to its desk.
- `task.started` → picks up a folder (labelled with the instrument) from the shelf/queue → sits → working animation; small bubble: stage + instrument name + duration.
- `llm.call` → "thinking" icon + floating token counter (+1.2k tok).
- `task.finished` → walks the folder to the next department's desk.
- Failed `qc.result` → red folder returned to the originating department (walk-back animation); pass → green stamp.
- `domain.throttled` → Fetcher sprite pauses with an hourglass (visualizing polite delay).
- `agent.blocked/dead` → exclamation / cross icon.
- Swarm scale-up → new worker walks in; scale-down → worker goes home.
- Hover/click a sprite → detail panel (task, document, tokens, errors). Click a room → its task list.
- Camera pan/zoom, mini-map, run/document filters, time **replay** mode (replay events from `event_log`).
- Degradation mode: beyond ~150 agents, show aggregates (group sprite with a count) for performance.

**Result visualization:** a "Gallery" room shows finished documents as cards on a board (click → Viewer); a relation board shows the network forming live.

## 4. Dashboard

Separate pages; all data from `/api/metrics/*` + WS.

1. **Run summary:** status, duration, documents processed/failed/in review, ETA, budget used vs limit.
2. **Coverage:** funnel `discovered → downloaded → extracted → split → verified → related → versioned → published`, per instrument type and year (heatmap), failure list + reasons.
3. **Tokens and cost (detailed):**
   - totals and trends (minute/hour/day), per agent, stage, document, prompt version, model deployment;
   - prompt vs completion vs cached vs reasoning tokens;
   - cost (USD/IDR), cost per document and per node, projected cost for the remaining corpus;
   - top-N costliest documents, token-wasting retries.
4. **Swarm performance:** active instances per category, utilization, queue depth and latency, throughput (docs/hour), error rate, p50/p95 LLM latency, Azure 429s.
5. **Quality:** pass rate per QC tier, Splitter retry counts, Verbatim fail rate, golden-set accuracy, review-queue aging.
6. **Scraping:** requests per domain, actual vs target delay (compliance proof), 4xx/5xx status, throttled/paused domains.
7. **Versioning:** number of node_versions, instruments with the longest amendment chains, latest changes.

## 5. Log Tracker

- **Log Explorer:** `event_log` + `task` tables with filters (run, document, agent, stage, level, time), text search, links to related LLM calls.
- **Per-document trace:** vertical timeline of every stage → agent → LLM call (prompt/response, tokens, cost, latency) → QC result → status change. Prompts can be replayed.
- **LLM Call Inspector:** view the exact request/response, diff between retries, mark as a golden-set example.
- **Export:** CSV/JSON for tokens and logs.
- **Alerts:** budget 80/100%, error rate, dead worker, blocked domain, queue buildup → banner + optional webhook/WhatsApp.

## 6. Control Panel (Manual / Automatic Start)

- **Manual:** wizard — (1) choose scope (source, type, year, specific list, single PDF/URL upload), (2) see **estimates** of documents/tokens/cost (dry run), (3) set budget and worker count per category, (4) Start. Pause/Resume/Stop controls, "retry failed", "re-run a specific stage".
- **Automatic:** on/off toggle, schedule (cron/time window), daily budget cap, instrument-type priorities, retry policy, notifications.
- The panel shows each swarm's status and an instance-count slider (respecting global limits).
