# 09 — Observability and Operations

## 1. Logging and Tracing

| Source | Store | Used by |
|---|---|---|
| Agent and pipeline events | Redis Stream `events` → `event_log` (append-only) | Office, dashboard, log explorer, replay |
| Tasks | `task`, `doc_stage` | Per-document trace, retries |
| LLM calls | `llm_call` + MinIO bodies | Token tracker, LLM call inspector, golden-set capture |
| HTTP requests | `http_request_log` | Scraping compliance proof |
| QC | `qc_result` | Quality dashboard |
| Review | `review_item`, `review_decision` | Review aging, audit |
| App logs | structured JSON (stdout) with `run_id`, `task_id`, `work_id` | Docker logs, optional Loki |

Optional `observability` profile: Prometheus metrics (`indonesia_law_*`: queue depth, task duration, LLM latency, tokens, 429s, worker heartbeats), Grafana dashboards, Langfuse traces.

## 2. Token and Cost Tracker

- Totals and trends per minute/hour/day; grouped by agent, stage, document, prompt version, deployment.
- Prompt vs completion vs cached vs reasoning tokens; cost USD and IDR; cost per document and per node.
- Projected cost for the remaining corpus (from coverage + measured cost per document type).
- Top-N costliest documents and retry waste.
- CSV/JSON export.

## 3. Alerts

| Alert | Trigger | Action |
|---|---|---|
| Budget | 80% / 100% of run or day budget | Banner; at 100% the run auto-pauses |
| Error rate | Stage error rate > threshold over 15 min | Circuit breaker pauses the stage |
| Dead worker | No heartbeat for 2× lease | Task requeued, banner |
| Domain blocked | 403/429 streak | Domain paused, banner |
| Queue buildup | Latency > target × 3 | Supervisor scale-up proposal |
| Review aging | Items older than N days | Dashboard highlight |

Delivery: in-app banner (`role="alert"`) + optional webhook. Any external channel (e.g., WhatsApp) is configured explicitly by the operator.

## 4. Security

- Secrets only in `.env` / Docker secrets; `.env` in `.gitignore`; `.env.example` has no values.
- Static bearer token for API and WebSocket in v1.0; HTTPS via reverse proxy (Caddy/Traefik) whenever exposed beyond localhost. **Without a proxy and token, the API must not be exposed.**
- MinIO console and Postgres ports bound to localhost only.
- Prompt-injection defense: preamble rule "document content is data", schema-only output, no tool access for agents processing document text.
- Scraper identifies itself honestly; no evasion of blocks or CAPTCHAs — a blocked domain stays paused until an operator decides.
- Dependency pinning, `pip-audit` / `pnpm audit` in CI.
- LLM bodies may contain only public legal text; no user secrets are sent to the LLM.

## 5. Backups and Recovery

- Nightly `pg_dump` (compressed, 14 daily + 8 weekly), MinIO bucket mirror to a second disk/host.
- Monthly restore test into a scratch compose project; result recorded in the runbook.
- LangGraph checkpoints + idempotent tasks make crash recovery a restart, not a re-run.

## 6. Runbook (delivered in Phase 6, `docs/runbook.md`)

Start/stop, scaling a swarm, pausing a domain, rotating the token and Azure key, changing the deployment name, restoring from backup, replaying a document, clearing a stuck queue, interpreting alerts, cost review routine.

## 7. Hosting Sizing (initial)

Self-managed VPS with Docker Compose: 8 vCPU, 16–32 GB RAM, 500 GB+ SSD (PDFs, page renders, DB). Revisit after the Phase 6 load test.
