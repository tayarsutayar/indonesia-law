# F1 — Core Single-Document Pipeline + Basic Viewer (2 weeks)

**Goal:** any single Indonesian legal PDF becomes a verbatim, verified provision tree that can be inspected next to the original.

## Tasks

**Pipeline**
- [ ] Fetcher (single URL / upload) → MinIO + `manifestation` with sha256 dedup.
- [ ] Extractor: native text per page, line numbering `L0001…`, `page_map`; scan detection; vision OCR two-pass + comparison (`extract_ocr@v1`); mismatch → `review_item`.
- [ ] Splitter pass 1/2/3 (`split_skeleton@v1`, `split_deep@v1`), windowing for long documents, merge, numbering continuity.
- [ ] Pointer slicer → `node` rows; `node_key` normalization (`03` §3).
- [ ] Verbatim Verifier (deterministic) with a detailed report; retry via `split_retry@v1` (max 3) → review queue.
- [ ] LangGraph `document_pipeline` for stages fetch → verified, Postgres checkpoints, idempotent `task_key`.
- [ ] `doc_stage` updates and events for every transition.

**Golden set**
- [ ] 20 documents (mixed UU, PP, PMK, KMK, scans, old spelling, annex tables, "6A"-style numbering) annotated as JSON in `backend/app/tests/golden/`.
- [ ] `eval:prompts` job scoring the Splitter against the golden set.

**API**
- [ ] `POST /api/uploads`, `GET /api/works/{id}`, `/pdf`, `/source-text`, `/tree`, `/status`.

**Frontend — basic viewer** (read skills first)
- [ ] `/peraturan/:id` with PDF panel (pdf.js, lazy pages, line highlight) and Parsing panel (`ProvisionTree`, verbatim text, badges `Verbatim` / `OCR` / `Perlu tinjauan`, raw source tab).
- [ ] Simple upload page under `/kendali` for a single PDF/URL.
- [ ] Text integrity rules (`07` §6) applied and unit-tested (whitespace, no re-casing, no truncation).

## Exit Criteria

- All 20 golden documents pass the Verbatim Verifier 100% (after retries or review); first-pass rate ≥ 90%.
- Fault-injection suite: paraphrase, dropped fragment, added text, translation are all rejected.
- Killing a worker mid-document and restarting resumes from the last checkpoint without repeating completed LLM calls (proved via `llm_call` count).
- Viewer: clicking a node highlights the right PDF lines on 10 sampled documents; keyboard navigation of the tree works; axe clean.
