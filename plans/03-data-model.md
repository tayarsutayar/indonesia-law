# 03 — Data Model (PostgreSQL)

The base schema follows [Appendix B](appendix/B-sql-schema.md). This document summarizes the tables, fixes conventions, and lists **corrections** that must be applied in the first Alembic migrations.

## 1. Table Groups

| Group | Tables | Purpose |
|---|---|---|
| Corpus | `work`, `work_date`, `expression`*, `manifestation`, `source_text` | Instrument identity, dates, per-source copies, numbered text |
| Structure & versions | `node`, `amendment_op`, `node_version`, `consolidation_snapshot` | Verbatim provision tree, change ops, temporal versions, snapshots |
| Relations | `relation_type`, `relation`, `unresolved_reference` | Flexible relations with evidence, unresolved references |
| Execution | `run`, `doc_stage`, `task`, `agent_instance` | Run status, per-document stage, tasks, agent instances |
| Observability | `llm_call`, `http_request_log`, `event_log`, `qc_result` | Tokens & cost, scraping compliance, append-only events, QC |
| Review | `review_item`, `review_decision`* | Review queue and human decisions (append-only) |
| Prompts | `prompt_version` | Prompt versions and golden-set scores |
| Config | `auto_mode_config`*, `swarm_config`*, `budget_policy`* | Auto schedule, instance limits, budget limits |

`*` = added relative to the original plan.

## 2. Required Corrections and Additions

1. **`expression`** — referenced by the versioning model but missing from the original schema. Columns: `id`, `work_id`, `kind` (`original | amended | consolidated`), `as_of DATE`, `caused_by_work_id`, `snapshot_id`.
2. **`node.source_kind`** — copied from `source_text` (`native | ocr | manual_transcription`) so viewer badges and filters need no join, and reviewer transcriptions are recorded explicitly.
3. **Extensions** — `CREATE EXTENSION btree_gist` is required before the `EXCLUDE USING gist` constraint on `node_version`; `pg_trgm` for search.
4. **`review_decision`** — `id`, `review_item_id`, `decision` (`accept | reject | return_to_stage | select_candidate | manual_transcription | adjust_pointer`), `reason TEXT` (required for reject/return), `payload JSONB`, `decided_by`, `decided_at`. Decisions are never updated; a reversal is a new decision.
5. **Inverse relations** — store only the active direction (`mengubah`, `mencabut`, …). Passive forms (`diubah_oleh`, `dicabut_oleh`) are derived via `relation_type.inverse_code`, never stored twice.
6. **`work.status_aturan`** — derived from QC-passed relations and versions, not from source-site status text. Source status text is stored separately as `manifestation.source_status_text`.
7. **`doc_stage.status`** — a fixed enum (see §4) so the UI never guesses the meaning of a status.
8. **`node.text`** is written only by the slicer (or by an approved `manual_transcription` decision). No code path lets an LLM response populate it.

## 3. `node_key`

- Format: `<jenis>-<nomor>-<tahun>[-<instansi>]/<segment>/<segment>…`, lowercase; segments derive from `type` + `label`, normalized **only for the ID** (the original label stays verbatim in `node.label`).
  Examples: `uu-1-2004/pasal-5/ayat-2/huruf-b`, `pmk-96-2016/pasal-6a`, `kmk-12-2020/diktum-kedua`.
- ID normalization is simple code (lowercase, spaces → `-`, drop brackets/dots) applied to labels **already chosen by the LLM**; this is bookkeeping, not structure parsing.
- Insertions ("Pasal 6A") create a new key; renumbering is linked via `node_version.renumbered_from`.
- Collisions (same key twice in one work) fail the Node QC tier instead of being silently suffixed.

## 4. Status Enums

| Domain | Values |
|---|---|
| `doc_stage.status` | `pending`, `running`, `succeeded`, `failed`, `needs_review`, `skipped`, `paused` |
| Document status (aggregate) | `discovered`, `fetched`, `extracted`, `split`, `verified`, `related`, `versioned`, `compiled`, `qc_passed`, `published`, `needs_review`, `failed`, `paused` |
| `relation.status` | `proposed`, `qc_passed`, `rejected`, `needs_review` |
| `amendment_op.status` | `proposed`, `applied`, `rejected`, `needs_review` |
| `node_version.change_type` | `original`, `amended`, `inserted`, `deleted`, `revoked`, `partially_revoked`, `renumbered`, `annulled_by_court` |
| `review_item.status` | `open`, `in_progress`, `resolved`, `returned` |
| `agent_instance.state` | `idle`, `walking`, `working`, `blocked`, `dead` |
| `run.mode` / `run.status` | `manual`, `auto` / `estimating`, `ready`, `running`, `paused`, `stopped`, `completed`, `failed` |

UI labels for every enum are defined once in `frontend/src/lib/i18n/status.ts` (see `07` §6). Backend and frontend share the enum list via the generated OpenAPI schema.

## 5. Indexes

`node(work_id, node_key)`, `node_version(work_id, node_key, valid_from)`, `llm_call(created_at)`, `llm_call(agent_category, created_at)`, `event_log(ts)`, `event_log(work_id, ts)`, GIN on `relation`/`payload` as needed, `pg_trgm` GIN on `work.judul` and `node.text`, full-text `to_tsvector('simple', node.text)` (the `simple` config, because Postgres ships no Indonesian stemmer).

## 6. Retention and Storage

- Original PDFs, page renders, snapshots: MinIO, keyed by `sha256`.
- LLM request/response bodies: MinIO, compressed, default retention 180 days (configurable); `llm_call` metadata is permanent.
- `event_log`: monthly partitions; dashboard aggregates are computed from tables, not from raw events.
