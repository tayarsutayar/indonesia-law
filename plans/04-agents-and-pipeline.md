# 04 — Agents, Pipeline and Versioning

This document defines the contract and adds the decisions needed for implementation.

## 1. Agent Catalog

| Role | Agent | Queue | Input → Output | LLM |
|---|---|---|---|---|
| Worker | Scout | `q.scout` | source → `work` + metadata | only for unstructured listings |
| | Fetcher | `q.fetch` / `q.fetch.js` | `work` → file in MinIO + `manifestation` | no |
| | Extractor | `q.extract` | file → `source_text` (numbered lines, page map) | vision only for scans |
| | Splitter | `q.split` | numbered text → pointer tree → sliced `node`s | yes |
| | Relation Agent | `q.relation` | nodes + candidate works → `relation` | yes |
| | Amendment Analyzer | `q.relation` | amending instrument → `amendment_op[]` | yes |
| | Version Builder | `q.version` | ops + nodes → `node_version` | deterministic; LLM only for ambiguity |
| | Compiler | `q.compile` | node versions → `consolidation_snapshot` | no |
| QC | Node / Relation / Version / Display / Chief QC | `q.qc.*` | see §5 | yes + deterministic checks |
| Support | Supervisor / Dispatcher | — | metrics → scaling & priority | rule-based first; LLM optional |
| | Reviewer (human) | — | review queue → `review_decision` | no |

New agents are added by registering a `BaseAgent` subclass + queue + sprite; no core change.

## 2. `BaseAgent` Contract

```python
class BaseAgent:
    category: str            # "splitter", "qc.node", ...
    queue: str
    prompt_id: str | None    # "split_skeleton@v1"
    max_retries: int
    def run(self, task: Task) -> Result: ...
    # Provided by the base class: heartbeat, agent.state_changed events,
    # idempotent task_key, llm_call logging via the gateway, retry/backoff,
    # checkpointing, preamble injection.
```

`Result(status, output, evidence[], metrics, next_stage_hint)`. Agents only return results; the orchestrator routes.

## 3. Per-Agent Notes

**Scout.** Per-source adapters (`scraping/adapters/<source>.py`: `list_pages()`, `parse_listing()`, `get_detail()`), no legal logic in adapters. Unstructured pages → LLM with Pydantic schema. Dedup by canonical key; source conflicts become extra *manifestations*. Every finding is recorded for coverage.

**Fetcher.** Enforces polite scraping (`02` §6). Stores `sha256`, size, content-type, URL, timestamp. Picks a canonical manifestation by an explicit, logged rule (default priority: official issuer site > peraturan.go.id > JDIH > BPK; configurable).

**Extractor.** Native PDF: per-page text + `page ↔ line range` map. Scanned PDF (no text layer or low text density): render pages → vision transcription in **two independent passes** → compare; disagreement → `review_item` (`ocr_mismatch`), never auto-approved. Output: `source_text` with line IDs `L0001…`, raw version kept untouched.

**Splitter (most important).** Hierarchy is decided by the LLM per instrument type, not hard-coded.
1. Pass 1 — skeleton (Bab/Bagian/Pasal/Diktum/Lampiran) with line pointers; long documents use windows with overlap.
2. Pass 2 — deep split per Pasal/Lampiran (parallel; one document = one "head" + many workers).
3. Pass 3 — merge + numbering continuity check (e.g., Pasal 5 → 6 → 6A → 7; "dihapus" allowed).
4. Slice text from `source_text` by pointers → Verbatim Verifier → retry with `split_retry@v1` (max 3) → review queue.

**Relation Agent.** Flexible types (`relation_type` table can grow + `lainnya` + `custom_label`). Instrument- or node-level. Evidence + confidence required. Target resolution via candidate search over `work` (trigram + jenis/nomor/tahun); ambiguous → `unresolved_reference` + review item.

**Amendment Analyzer.** Converts instructions (*diubah, disisipkan, ditambah, dihapus, dicabut, dicabut sebagian*) into `amendment_op` with `target_path`, `new_content_node_id` (a verbatim node in the amending instrument), effective-date rule, evidence.

**Version Builder.** Applies ops ordered by effective date → promulgation date → instrument number. Invariant: no overlapping validity per `node_key` (enforced by DB constraint). Ambiguity (renumbering, unclear target, missing date) → `version_resolve@v1`; still uncertain → review.

**Compiler.** Builds the tree valid at T (`valid_from ≤ T < valid_to`), caches snapshots keyed by `built_from_hash`, marks nodes `amended | inserted | revoked` with their cause.

## 4. Verbatim and No-Regex Rules

1. The LLM decides all structure and boundaries; no regex recognizes "Pasal", "Ayat", etc.
2. The LLM returns pointers (line IDs + optional char offsets), never text.
3. Node text = pure slice of `source_text` → byte-identical.
4. The Verbatim Verifier (deterministic string comparison) checks that the ordered concatenation of leaf spans reconstructs the source exactly, except explicitly normalized and logged whitespace.
5. When text must be produced (OCR), two passes + diff, `source_kind=ocr`, visibly marked in the UI.
6. Bookkeeping (newline normalization, page detection, ID normalization) is plain code; no regex decides legal structure or content.

**Decision (recommended, needs approval):** pointer-based extraction over LLM-rewritten node text.

## 5. Layered QC

| Tier | Checks | Method | On failure |
|---|---|---|---|
| Node QC | 100% verbatim, numbering continuity, hierarchy sanity, no orphan text, no key collisions | Deterministic + LLM judge | Back to Splitter with report |
| Relation QC | Evidence really states it, direction, type, target resolution | Deterministic evidence check + independent LLM judge | Back to Relation |
| Version QC | No overlaps, correct order, no orphans, consolidation uses the amending node's wording | Deterministic + LLM judge | Back to Amendment/Version/Compiler |
| Display QC | Viewer render vs original PDF page: order, numbering, tables intact | Playwright screenshot + vision judge | Flag node; route to Splitter/Extractor/viewer |
| Chief QC | All stages passed, no QC conflicts, plausibility, spot-check sample | Aggregation + thresholds + LLM auditor | Publish / return to stage / manual review |

QC is independent (different prompt, ideally different temperature/model), evidence-based, and **never fixes anything** — it rejects and routes; producers fix.

## 6. Two-Level Versioning

- Instrument level (FRBR-like): `work` → `expression` → `manifestation`.
- Provision level: `node_key` + `node_version {content_node_id, valid_from, valid_to, change_type, caused_by_op, renumbered_from, version_seq}`.
- Dates stored separately (`ditetapkan`, `diundangkan`, `mulai_berlaku`, `berlaku_surut`); `valid_from` comes from explicit text with evidence, never assumed. Missing → `needs_review`.
- Court annulments (Putusan MK) produce `annulled_by_court` versions via the same op model.
- Word diffs between consecutive versions are display-only and never change data.

## 7. Swarm and Modes

- Each category has `min/max instances` and `target_queue_latency`. Scout and Fetcher stay low; Splitter/Relation/QC scale.
- Very large documents (omnibus laws, long annexes) become visible sub-tasks (windows) in the UI.
- Manual mode: scope wizard → dry-run estimate → budget + worker counts → start; pause/resume/stop; retry failed; re-run a stage.
- Auto mode: cron/time window, daily budget cap, type priorities, retry policy, notifications; auto-pause on budget or error-rate thresholds.
