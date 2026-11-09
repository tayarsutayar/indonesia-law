# 04 — Agents, Pipeline and Versioning

This document defines the contract and adds the decisions needed for implementation.

## 1. Agent Catalog

| Role | Agent | Queue | Input → Output | LLM |
|---|---|---|---|---|
| Worker | Scout (Web & Catalog) | `q.scout.catalog` | any web source / portal / repository across the internet → `work` + metadata (prioritizing `.go.id`) | only for unstructured listings |
| | Search Hunter | `q.scout.search` | open-web search queries across the internet → candidate URLs + metadata (ranking `.go.id` highest) | yes (filtering & metadata parsing) |
| | Heritage Scout | `q.scout.heritage` | missing citation / backlink targets → `work` + candidate queries across internet | yes |
| | Fetcher | `q.fetch` / `q.fetch.js` | `work` → file in MinIO + `manifestation` | no |
| | Extractor | `q.extract` | file → `source_text` (numbered lines, page map, old-spelling tag) | vision only for scans |
| | Splitter | `q.split` | numbered text → pointer tree → sliced `node`s | yes |
| | Relation Agent | `q.relation` | nodes + candidate works → `relation` | yes |
| | Amendment Analyzer | `q.relation` | amending instrument → `amendment_op[]` | yes |
| | Version Builder | `q.version` | ops + nodes → `node_version` | deterministic; LLM only for ambiguity |
| | Compiler | `q.compile` | node versions → `consolidation_snapshot` | no |
| QC | Node / Relation / Version / Display / Chief QC | `q.qc.*` | see §5 | yes + deterministic checks |
| Evolution | Reflection & Optimizer | `q.evolution` | failure logs + `review_decision` → `skill_bank` + candidate prompts | yes |
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

**Scout (Web & Catalog).** Scans and ingests regulatory listings from **across the entire internet** — not confined to official portals alone, but ingesting university legal repositories (`.ac.id`), archival collections, legal research portals, and digital document hubs. Per-source adapters (`scraping/adapters/<source>.py`) or generic HTML/feed extractors harvest listings.
- **Priority & Tiering:** Tasks targeting `.go.id` domains are given highest queue scheduling priority.
- **Corpus Integrity:** Any web source can discover a `work` or register a new `manifestation`. If a regulation is found on a non-`.go.id` site, it is ingested, and a high-priority background probe is simultaneously queued to verify whether an official `.go.id` canonical manifestation exists.

**Search Hunter.** Formulates open-web search queries (via SearXNG, search APIs, or Common Crawl indexes) to discover regulations and archival PDFs anywhere on the web. Search result ranking algorithm explicitly biases toward `.go.id` top-level domains while indexing all valid PDF documents found across institutional and public repositories.

**Heritage Scout.** Triggered when the Relation Agent or Extractor parses a reference to an earlier regulation (e.g. an Ordonnantie, Penpres, or 1950s emergency law) not present in the catalog. Emits targeted queries across all internet sources, prioritizing `.go.id` archives, to discover the historical predecessor.

**Fetcher.** Enforces polite scraping (`02` §6). Stores `sha256`, size, content-type, URL, source domain, timestamp.
- **Canonical Manifestation Priority Rule:**
  1. Official State Gazette scan with authentic seal/signatures on `.go.id` (e.g. Setneg, JDIH BPK, ANRI).
  2. Official issuer portal on `.go.id` (Kemenkumham `peraturan.go.id`, ministry portals, MKRI/MARI).
  3. Trusted institutional archives (`.ac.id`, National Library / Perpusnas).
  4. General internet legal repositories and archives (used as fallback or when no `.go.id` manifestation is available online).
  Configurable via policy table. Every manifestation explicitly flags `is_gov_domain (boolean)`.

**Extractor.** Native PDF: per-page text + `page ↔ line range` map. Scanned PDF (typewritten sheets from 1945–1970s, low density, carbon copies): render pages → vision transcription in **two independent passes** → compare; disagreement → `review_item` (`ocr_mismatch`), never auto-approved. Handles historical Indonesian spelling (Van Ophuijsen, Suwandi/Soewandi) while preserving verbatim authenticity. Output: `source_text` with line IDs `L0001…`, raw version kept untouched.

**Reflection & Optimizer Agent.** Asynchronous learning loop worker. Listens to `review_decision` outcomes, QC rejections, and novel drafting patterns. Performs automated Root Cause Analysis (RCA), curates micro-skills into the `skill_bank`, formulates candidate prompt patches (`@vN+1`), and triggers automated golden-set regression testing before suggesting promotion.

**Splitter (most important).** Hierarchy is decided by the LLM per instrument type, not hard-coded.
1. Pass 1 — skeleton (Bab/Bagian/Pasal/Diktum/Lampiran) with line pointers; long documents use windows with overlap.
2. Pass 2 — deep split per Pasal/Lampiran (parallel; one document = one "head" + many workers).
3. Pass 3 — merge + numbering continuity check (e.g., Pasal 5 → 6 → 6A → 7; "dihapus" allowed).
4. Slice text from `source_text` by pointers → Verbatim Verifier → retry with `split_retry@v1` (max 3) → review queue.

**Relation Agent.** Flexible types (`relation_type` table can grow + `lainnya` + `custom_label`). Instrument- or node-level. Evidence + confidence required. Target resolution via candidate search over `work` (trigram + jenis/nomor/tahun); ambiguous → `unresolved_reference` + review item.

**Amendment Analyzer.** Converts instructions and court rulings into atomic `amendment_op` records:
- **Standard Indonesian Legislative Formula:** Parses formulas mandated by UU 12/2011 (*diubah sehingga berbunyi...*, *di antara Pasal X dan Y disisipkan Pasal XA*, *ketentuan Pasal Z dihapus*, *dicabut dan dinyatakan tidak berlaku*). Links `target_path` to `new_content_node_id` (a verbatim node from the amending instrument).
- **Constitutional Court (MK) & Supreme Court (MA) Judicial Review Engine:** Treats final and binding court rulings (*Putusan MK/MA*) as external judicial commits/hotfixes:
  1. *Pembatalan Penuh:* Provision annulled (`annulled_by_court`).
  2. *Pembatalan Sebagian/Frasa:* Nullifies specific words or sentences while retaining the remaining provision, generating a `phrase_mask` on the node version.
  3. *Inkonstitusional/Konstitusional Bersyarat:* The text remains intact but is annotated with the mandatory interpretation formula from the court's operative holding (*amar putusan*), categorized as `conditionally_unconstitutional`.
- **Omnibus Law Multi-Target Decomposition:** Deconstructs complex omnibus instruments (e.g. UU Cipta Kerja, UU P2SK, UU Kesehatan) which amend dozens of distinct laws simultaneously. Emits independent, atomic `amendment_op` batches grouped by target `work_id` so target documents can be versioned in parallel.
- **Effective Date & Transition Clauses:** Scans closing and transitional provisions (*Ketentuan Penutup* & *Ketentuan Peralihan*) to identify non-immediate effective dates (e.g., "berlaku 2 tahun sejak tanggal diundangkan", retroactive dates, or phased schedules where specific chapters take effect on future dates). Computes accurate `valid_from` for each op.

**Version Builder.** Replays amendment and court operations in strict chronological order (ordered by: effective date → promulgation date → instrument number → court decision date). Invariant: no overlapping temporal validity per `node_key` (enforced by DB `EXCLUDE USING gist` constraint).
- Resolves conflicts, renumbering (`node_version.renumbered_from`), and transitional periods.
- Reconstructs full **"Hukum Blame"** metadata: maps each provision, paragraph, and phrase to the exact enactment or court decision that introduced or modified it.
- Ambiguity (renumbering, unclear target, missing date) → `version_resolve@v1`; still uncertain → review.

**Compiler.** Point-in-time time-travel engine (equivalent to `git checkout <date>`).
- Builds the complete provision tree valid as of date T (`valid_from ≤ T < valid_to`).
- Resolves phrase masks and conditional court annotations for accurate legal display at date T.
- Computes structural and textual diffs between any two dates ($T_1$ vs $T_2$) or between any two amending works.
- Caches compiled snapshots keyed by `built_from_hash`.

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

## 6. Two-Level Versioning & Git-for-Law Architecture

- **Instrument level (FRBR-like):** `work` (identity) → `expression` (content over time / consolidated as of T) → `manifestation` (physical source PDF/HTML + hash).
- **Provision level (Git-like VCS):** `node_key` + `node_version {content_node_id, valid_from, valid_to, change_type, caused_by_op, court_annotation, phrase_mask, renumbered_from, version_seq}`.
- **Commit Equivalency:** Each legal instrument (or court decision) amending an existing work acts as a legal "commit". A single omnibus law functions as a multi-repository "mega-commit" that branches across dozens of target works.
- **Blame Tracking:** By querying the active `node_version` at any given historical date, the system outputs a `git blame`-like line-by-line attribution indicating the exact amending law, promulgation date, and effective date.
- **Dates & Commencement Invariants:** Dates are stored explicitly (`ditetapkan`, `diundangkan`, `mulai_berlaku`, `berlaku_surut`). `valid_from` is computed from statutory commencement rules with evidence, never assumed. Missing or ambiguous commencement → `needs_review`.
- **Judicial Annulments & Annotations:** Court decisions (Putusan MK & MA) produce `annulled_by_court` or `conditionally_unconstitutional` versions, functioning as external regulatory patches without requiring parliamentary re-enactment.
- **Word & Structural Diffs:** Deterministic, display-only word diffs between consecutive versions or arbitrary dates $T_1$ and $T_2$. Diffing never alters stored node text.

## 7. Swarm and Modes

- Each category has `min/max instances` and `target_queue_latency`. Scout and Fetcher stay low; Splitter/Relation/QC scale.
- Very large documents (omnibus laws, long annexes) become visible sub-tasks (windows) in the UI.
- Manual mode: scope wizard → dry-run estimate → budget + worker counts → start; pause/resume/stop; retry failed; re-run a stage.
- Auto mode: cron/time window, daily budget cap, type priorities, retry policy, notifications; auto-pause on budget or error-rate thresholds.

## 8. Continuous Self-Improvement and Dynamic Skill Evolution

Every agent category continuously enhances its capabilities through an automated reflection-evaluation loop:

1. **Failure & Feedback Mining:** When a human reviewer resolves an item in `review_decision` or a QC tier rejects an output, a learning event is queued in `q.evolution`. The event captures: original raw slice, agent prompt version, failed agent output, human/QC ground truth, and categorized reason.
2. **Dynamic Skill Bank:** Instead of overloading one monolithic prompt, agents retrieve era- and format-specific micro-skills (e.g. `Skill_Historic_OCR_Suwandi`, `Skill_Split_EmergencyLaw_1950`, `Skill_Search_Regional_Archive`). When a task starts, the agent queries the `skill_bank` embedding index with the document's year, type, and drafting features, dynamically injecting 2–3 relevant verified few-shot exemplars.
3. **Automated Prompt Optimization (RCA & Candidate Generation):** The Reflection Agent clusters recurring failures (e.g., misidentifying "Pasal 10 bis" or archaic transitional clauses) and synthesizes prompt revisions (`@v(N+1)_candidate`).
4. **Golden-Set Regression Gatekeeper:** Candidate prompts run through the automated regression suite (`eval:prompts`). If the candidate achieves a higher score without regressing on any existing golden document, it is flagged as verified.
5. **Promotion Guardrails:**
   - Minor micro-skill additions (new few-shot exemplar in `skill_bank`): Auto-promoted if verified against the golden set.
   - Core system prompt revisions (`prompt_id@vN`): Displayed in the Control Panel UI with diff analysis and evaluation delta for operator review and one-click promotion or instant rollback.
   - Preamble invariance: `preamble@v1` remains permanently read-only and immutable.
