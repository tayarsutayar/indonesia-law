# 02 — System Architecture

## 1. Overview

```mermaid
flowchart LR
  subgraph FE[React Frontend — Indonesia Law]
    SRCH[Search & Regulation List]
    VIEW[Viewer: PDF / Parsing / Changes]
    REV[Review Queue]
    OFF[Office PixiJS]
    DASH[Dashboard]
    LOGS[Logs & Tokens]
    CTRL[Control Panel]
  end
  subgraph BE[Python Backend]
    API[FastAPI REST + WS]
    ORCH[Orchestrator LangGraph]
    SCHED[Scheduler auto mode]
    LLMGW[LLM Gateway: preamble, tokens, budget]
  end
  subgraph SW[Agent Swarms — Celery]
    S1[Scout] --- S2[Fetcher] --- S3[Extractor] --- S4[Splitter]
    S5[Relation] --- S6[Amendment/Version] --- S7[Compiler] --- S8[QC]
  end
  PG[(PostgreSQL 16)]
  RD[(Redis)]
  MN[(MinIO)]
  AZ[[Azure OpenAI]]
  WEB[[Regulation source sites]]
  FE <--> API
  API <--> PG & RD
  SCHED --> ORCH --> SW
  SW --> LLMGW --> AZ
  SW --> PG & MN
  S1 & S2 --> WEB
  SW -- events --> RD -- pubsub --> API
```

## 2. Stack

| Layer | Choice |
|---|---|
| Frontend | React + TypeScript + Vite, React Router, TanStack Query, Zustand, Tailwind CSS (Apple token preset, see `08`), PixiJS, ECharts, pdf.js, TanStack Virtual, custom word diff |
| Fonts | `system-ui, -apple-system, BlinkMacSystemFont` → Inter (self-hosted, no CDN) |
| Backend API | Python 3.12, FastAPI, WebSocket |
| Agent orchestration | LangChain + LangGraph (one graph per pipeline, Postgres checkpoints) |
| LLM | Azure OpenAI via `langchain-openai` (`AzureChatOpenAI`); deployment name from env (initially "gpt 6 luna") |
| Workers | Celery + Redis; swarm = many instances per queue |
| Database | PostgreSQL 16 + `pg_trgm`, `btree_gist`, optional `pgvector` |
| Object storage | MinIO |
| Scraping | httpx; Playwright only for JS-heavy sites and Display QC |
| Observability | Own log tables + LangChain callback; optional Prometheus/Grafana/Langfuse (compose profile) |
| Deployment | Docker Compose |

All dependency versions are pinned exactly via lockfiles (`uv.lock`, `pnpm-lock.yaml`), chosen in Phase 0.

## 3. Monorepo Layout

```
indonesia-law/
├─ docker-compose.yml   .env.example   README.md
├─ docs/                       # copy of plans/ + runbook
├─ backend/
│  ├─ pyproject.toml   alembic/
│  └─ app/
│     ├─ main.py               # FastAPI
│     ├─ api/                  # runs, works, nodes, versions, relations, search, review, logs, metrics, control
│     ├─ core/                 # config, db, redis, events, ids, auth
│     ├─ llm/                  # gateway.py, callbacks.py, pricing.py, schemas/
│     ├─ prompts/              # preamble@v1.md + <id>@v<N>.md
│     ├─ agents/               # base.py, scout/ fetcher/ extractor/ splitter/ relation/ amendment/ versioner/ compiler/ qc/
│     ├─ graphs/               # document_pipeline.py, discovery.py, recompile.py
│     ├─ scraping/             # ratelimit.py, robots.py, adapters/<source>.py
│     ├─ verify/               # verbatim.py (deterministic)
│     ├─ workers/  scheduler/  tests/
├─ frontend/
│  └─ src/
│     ├─ app/                  # shell, router, providers
│     ├─ design/               # tokens, base components (Button, Badge, Tree, …)
│     ├─ features/             # search, viewer, review, office, dashboard, logs, control
│     └─ lib/                  # api, ws, store, i18n
└─ ops/                        # prometheus, grafana, backup scripts
```

## 4. Pipelines

**Document pipeline (LangGraph):** Discovered → Fetch → Extract (+ line numbers) → Splitter (pointers) → Slice → Verbatim Verifier (fail → retry with feedback; fail N times → Review) → Node QC → Relation → Amendment Analyzer → Version Builder → Compiler → Version QC + Relation QC → Display QC → Chief QC → Published / returned to the responsible stage.

Document status: `discovered → fetched → extracted → split → verified → related → versioned → compiled → qc_passed → published` (+ `needs_review`, `failed`, `paused`). Every transition = event + checkpoint.

**Discovery pipeline:** Scout per source adapter → metadata → dedup (`jenis|nomor|tahun|instansi`) → fetch queue. Auto mode schedules incremental discovery and status re-checks.

**Recompile pipeline:** when a new amending instrument is parsed, re-run Amendment → Version → Compile **only** for affected nodes.

## 5. Orchestration and Swarms

- The orchestrator decides *what* happens next per document; Celery workers execute *tasks*. Agents never call each other directly.
- Queues: `q.scout`, `q.fetch`, `q.fetch.js`, `q.extract`, `q.split`, `q.relation`, `q.version`, `q.compile`, `q.qc.node|relation|version|display|chief`.
- Limits: global tokens-per-minute bucket (Redis), per-domain concurrency, Azure quota (TPM/RPM) with 429 backoff.
- Priority: instrument hierarchy and dependencies (parents before amendments/implementing rules), manual > automatic.
- Idempotency: `task_key = sha256(work_id, stage, input_hash, prompt_version, model)`; a successful result is a cache hit on re-run.
- Heartbeat + lease; expired-lease tasks return to the queue. Circuit breaker per source/stage.

## 6. Polite Scraping

- Per-domain minimum interval 5–10 s + ±30% jitter, concurrency 1 per domain (configurable per adapter).
- Respect `robots.txt` and `Crawl-delay`; honest User-Agent with contact; crawl windows can be restricted (e.g., night hours WIB).
- Exponential backoff on 429/503; blocked → auto-pause the domain and flag it on the dashboard.
- Cache raw responses (ETag/If-Modified-Since); never re-download a file with an identical hash.
- Every request is logged in `http_request_log` (url, status, applied delay, duration) as compliance proof.

## 7. Docker Compose

Project `indonesia-law`, database `indonesia_law`.

| Service | Role | Notes |
|---|---|---|
| `postgres` | `pgvector/pgvector:pg16` | `pg_trgm`, `btree_gist` created by migration |
| `redis` | queues, pubsub, rate limiter | AOF on |
| `minio` | object storage | console never exposed publicly |
| `api`, `orchestrator`, `scheduler` | backend | |
| `worker-scout`, `worker-fetch` | concurrency 1 | deliberately low (politeness) |
| `worker-extract`, `worker-split`, `worker-relation`, `worker-version`, `worker-qc` | LLM swarms | `--scale` as needed |
| `worker-browser` | Playwright: `q.fetch.js` + Display QC | **required from Phase 4** (optional profile in the original plan) |
| `frontend` | static build on Nginx | |
| `prometheus`, `grafana`, `langfuse` | `observability` profile | optional |

A full YAML example is in [Appendix D](appendix/D-docker-compose.md); apply the renames and the table above.

`.env.example`: `APP_NAME`, `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_API_VERSION`, `AZURE_OPENAI_DEPLOYMENT`, `LLM_BUDGET_USD_PER_DAY`, `LLM_TPM_LIMIT`, `SCRAPE_MIN_DELAY_SEC=5`, `SCRAPE_JITTER_PCT=30`, `SCRAPE_PER_DOMAIN_CONCURRENCY=1`, `SCRAPER_CONTACT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `APP_STATIC_TOKEN`.
