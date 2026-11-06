# F0 — Foundation (1 week)

**Goal:** a running skeleton where one LLM call is recorded with tokens and cost, and the frontend shell renders with the Indonesia Law design tokens.

## Tasks

**Repo and infra**
- [ ] Monorepo `indonesia-law/` per `02` §3; `README.md`, `.gitignore` (incl. `.env`), `.env.example` per `02` §7.
- [ ] Docker Compose: `postgres`, `redis`, `minio`, `api`, `frontend` (workers stubbed); healthchecks; ports for Postgres/MinIO console bound to localhost.
- [ ] MinIO buckets created on startup (`indonesia-law-raw`, `-pages`, `-snapshots`, `-llm-logs`).
- [ ] CI: ruff, mypy, pytest; eslint, tsc, vitest; dependency audit. Pin all versions (lockfiles).

**Backend core**
- [ ] FastAPI app, settings (pydantic-settings), static bearer token auth, `GET /api/health`, error format (`06` §1).
- [ ] Alembic: extensions (`pg_trgm`, `btree_gist`), all tables from `03` incl. corrections; enums.
- [ ] Event bus: Redis Stream `events` + mirror to `event_log`.
- [ ] LLM Gateway (`05` §1): Azure client from env, preamble guard, Pydantic structured output, token accounting → `llm_call`, pricing table, budget guard (per run/day), MinIO request/response storage.
- [ ] Move `preamble@v1` and all prompt templates from `plans/appendix/A-prompt-templates.md` into `backend/app/prompts/`; loader + renderer.
- [ ] `BaseAgent` skeleton (`04` §2) and Celery app with queue definitions.

**Frontend shell**
- [ ] Read all `SKILL.md` files in `.agents/skills/` and their references before starting.
- [ ] Vite + React + TS, Router, TanStack Query, Zustand, Tailwind preset with tokens from `08` §2.
- [ ] Self-hosted Inter; global styles (17px body, `lang="id"`, focus ring, reduced motion).
- [ ] Base components: `Button` (all variants), `SearchInput`, `GlobalNav`, `SubNav`, `Card`, `Badge`, `Dialog`; page shell with empty routes from `07` §2.
- [ ] i18n module (`id.ts`) and `status.ts` generated against backend enums; OpenAPI → TS client generation script.

## Deliverables

Running compose stack, migrations, LLM gateway with tests, prompt files, frontend shell with design components.

## Exit Criteria

- `docker compose up` on a clean machine brings up all services healthy.
- A test script makes one LLM call through the gateway; the `llm_call` row shows tokens, cost, prompt_id, preamble_version.
- A call without the preamble is rejected by the guard (unit test).
- Frontend shell loads at `/` with the light theme; axe shows 0 serious/critical issues; components pass the `08` §6 checklist.
- Open questions 3 (model capabilities) and 8 (budget) in `12` answered or explicitly deferred.
