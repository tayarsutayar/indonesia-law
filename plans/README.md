# Indonesia Law — Build Plan

**Indonesia Law** is an agentic multi-agent application that discovers, fetches, reads, splits, relates, versions, searches and reviews Indonesian laws and regulations (*peraturan perundang-undangan*) down to the smallest provision (Pasal → Ayat → Huruf → Angka → Butir), with full provenance for every piece of text, every relation and every change.

This folder is the single, authoritative build plan, aligned with the product name, the light-theme design system, and the rules in `AGENTS.md`. Reference material carried over from the original general plan (full prompt templates, SQL schema, office/dashboard spec, Docker Compose YAML) lives in [appendix/](appendix/); where an appendix and a main document disagree, the main document wins.

## Naming Conventions

| Context | Value |
|---|---|
| Product name (UI, docs, page titles) | `Indonesia Law` |
| Repo slug, Docker Compose project name | `indonesia-law` |
| PostgreSQL database | `indonesia_law` |
| Python package / import root | `app` (inside `backend/`), distribution name `indonesia-law-backend` |
| MinIO buckets | `indonesia-law-raw`, `indonesia-law-pages`, `indonesia-law-snapshots`, `indonesia-law-llm-logs` |
| Scraper User-Agent | `IndonesiaLawBot/1.0 (+<contact-url>; <contact-email>)` |
| App name env var | `APP_NAME="Indonesia Law"` |
| Prometheus metric prefix | `indonesia_law_` |
| UI language | Indonesian by default (i18n-ready); legal text is never translated |

The name "LexVersion" must not appear in code, UI or new documents.

## Document Index

| File | Contents |
|---|---|
| [01-vision-and-principles.md](01-vision-and-principles.md) | Corpus context, goals, users, non-negotiable principles, scope, glossary |
| [02-architecture.md](02-architecture.md) | System architecture, stack, monorepo layout, pipelines, swarms, polite scraping, Docker Compose |
| [03-data-model.md](03-data-model.md) | PostgreSQL schema, `node_key`, status enums, corrections to the original schema |
| [04-agents-and-pipeline.md](04-agents-and-pipeline.md) | Agent catalog, `BaseAgent` contract, Splitter, two-level versioning, layered QC |
| [05-prompts-and-llm.md](05-prompts-and-llm.md) | LLM Gateway, Corpus Context Preamble, prompt catalog, golden set, token budget |
| [06-api-and-realtime.md](06-api-and-realtime.md) | REST API, WebSocket events, auth, error format |
| [07-web-apps.md](07-web-apps.md) | Information architecture, pages, review flows, accessibility, text/status integrity |
| [08-design-system.md](08-design-system.md) | Apple Web Design System adapted to the Indonesia Law light theme |
| [09-observability-and-operations.md](09-observability-and-operations.md) | Logs, token tracker, alerts, backups, security, runbook |
| [10-testing-and-quality.md](10-testing-and-quality.md) | Test strategy, golden set, fault injection, CI gates |
| [11-roadmap.md](11-roadmap.md) | Phase overview, timeline, dependencies, v1.0 Definition of Done |
| [12-risks-and-decisions.md](12-risks-and-decisions.md) | Risks, decisions needing approval, open questions, gaps found in the original plan |
| [phases/](phases/) | One file per phase (F0–F7): tasks, deliverables, exit criteria |
| [appendix/](appendix/) | A: prompt templates · B: full SQL schema · C: office/dashboard/logs/control spec · D: Docker Compose YAML |

## How to Use These Documents

- Everyone: read `01`, then the current phase file in `phases/`.
- Backend / agents: `02`, `03`, `04`, `05`, `06`.
- Frontend / UI / design: first read every `SKILL.md` under `.agents/skills/` (currently `apple-design`) and its linked references, then `07` and `08`.
- A phase is closed only when every **exit criterion** in its phase file is met and proven (logs, tests or a demo).
- Keep changes minimal and consistent with existing structure (`AGENTS.md`).
