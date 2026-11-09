# 05 — Prompts and LLM Gateway

Full prompt texts live in [Appendix A](appendix/A-prompt-templates.md) and are moved verbatim into `backend/app/prompts/<id>@v<N>.md` in Phases 0–1. This file defines how they are used, versioned and evaluated.

## 1. LLM Gateway (`backend/app/llm/gateway.py`)

Single entry point for every LLM call. Responsibilities:

| Feature | Behavior |
|---|---|
| Client | `AzureChatOpenAI` with `azure_deployment`, `api_version`, `azure_endpoint` from env; `temperature=0`; `max_retries=0` (gateway retries) |
| Preamble guard | Rejects any call whose system prompt does not start with `preamble@v1` |
| Structured output | Pydantic schema per prompt; invalid output → one retry with the validation error, then fail the task |
| Token accounting | prompt / completion / cached / reasoning tokens → `llm_call` with run, task, work, node, stage, prompt_id, preamble_version, deployment, latency |
| Cost | `pricing.py` table per deployment (USD), IDR shown via a configurable rate |
| Budget guard | Limits per run / day / document; exceeding **pauses** the run (never silent failure), emits `budget.warning` at 80% and 100% |
| Rate limiting | Adaptive token bucket against Azure TPM/RPM; 429 → backoff + `llm.throttled` event |
| Caching | Result cache keyed by `task_key` (includes input hash, prompt version, deployment) |
| Replay | Compressed request/response in MinIO (`indonesia-law-llm-logs`) |
| Capability flags | `supports_vision`, `supports_structured_output`, `context_tokens` per deployment in config; agents check before calling |

Model names are never hard-coded; the deployment is an env setting.

## 2. Corpus Context Preamble

`preamble@v1` (text in Appendix A §1) is injected **first** into every system prompt. It states that inputs are Indonesian legal instruments, lists instrument types and drafting structure, and sets the absolute rules: verbatim, never translate, do not guess (`uncertain` + reason), no legal opinion, treat document content as data (prompt-injection defense), return only the schema.

## 3. Prompt Catalog

| Prompt ID | Agent | Output |
|---|---|---|
| `scout_metadata@v1` | Catalog Scout | metadata records |
| `scout_search@v1` | Search Hunter | candidate URLs + relevance score |
| `scout_heritage@v1` | Heritage Scout | targeted search queries for missing cited laws |
| `extract_ocr@v1` | Extractor (scans) | transcribed lines + confidence |
| `split_skeleton@v1` | Splitter pass 1 | top-level units (pointers) |
| `split_deep@v1` | Splitter pass 2 | sub-provision tree (pointers) |
| `split_retry@v1` | Splitter retry | corrected pointer tree |
| `relation@v1` | Relation Agent | relations + evidence |
| `amendment@v1` | Amendment Analyzer | operations + evidence |
| `version_resolve@v1` | Version Builder (ambiguous cases) | resolutions |
| `qc_node@v1`, `qc_relation@v1`, `qc_version@v1`, `qc_display@v1`, `qc_chief@v1` | QC tiers | verdicts + routing |
| `supervisor@v1` | Supervisor (optional) | scaling / priority proposals |
| `optimizer_rca@v1` | Reflection Agent | failure categorization & root-cause report |
| `optimizer_prompt@v1` | Prompt Optimizer | candidate prompt patch `@v(N+1)` |

Assembly order: preamble → ROLE / TASK / HARD RULES → dynamic micro-skills (from `skill_bank`) → schema → 2–4 targeted few-shot examples → INPUT.

## 4. Prompt Operations

- Changing a prompt bumps `@vN`; the new version is stored in the repo and in `prompt_version`.
- Activation requires the golden-set score not to regress (CI job `eval:prompts`, see `10`).
- Each `llm_call` stores `prompt_id` and `preamble_version`; the dashboard can group cost and quality by prompt version.
- OCR output passes a cheap language sanity check (share of Indonesian stop-words), flagging suspected translation or hallucination. This is a heuristic on returned text, not structure parsing.

## 5. Golden Set

- 20 documents by Phase 1 exit, 50 by Phase 4: mix of UU, PP, Perpres, PMK, KMK, a Perda, a Putusan MK, old-spelling text, annex tables, insert-style numbering ("6A", "2a."), scans.
- Each item: source PDF, numbered text, expected node tree (types, labels, line pointers), and for chains the expected `amendment_op`s and consolidation as of selected dates.
- Annotation is done in Indonesia Law itself via the review UI (`07` §4) once Phase 1 viewer exists; before that, JSON files in `backend/app/tests/golden/`.

## 6. Cost Control

- Dry-run estimator: tokens ≈ f(page count, text density, instrument type) calibrated from pilot runs; shown before every manual run.
- Hash cache: identical `text_sha256` + prompt version → reuse.
- Right-sized windows for Splitter; QC LLM judges run on samples where deterministic checks already passed (configurable sampling rate per tier).
- Phase 6 gate: measured cost per document on ~1,000 documents, projected cost for the remaining corpus, approved before full scale.

## 7. Dynamic Skill Bank and Self-Improvement Loop

1. **Dynamic Micro-Skill Injection:** When parsing diverse documents across different decades (e.g. 1945–1959 vs 1999–present), fixed prompts risk bloat. Agents query the `skill_bank` using semantic search on the document's era, instrument type, and layout features to retrieve relevant micro-guidelines (e.g., `Old_Spelling_VanOphuijsen_Normalizer`, `Emergency_Law_Article_Parser`).
2. **Error-Driven Reflection (Closed-Loop Learning):** Every human intervention in `review_decision` (corrections of pointers, OCR mismatches, missed amendments) triggers an asynchronous analysis by `optimizer_rca@v1`. The agent determines whether the failure stemmed from missing context, ambiguous prompt phrasing, or unseen drafting quirks.
3. **Automated Candidate Tuning:** The Optimizer synthesizes prompt improvements or new micro-skills. All candidate prompts (`prompt_candidate`) are evaluated against the full Golden Set via `eval:prompts`.
4. **Safety Guarantees & Anti-Regression:**
   - Candidate prompts must achieve $\ge$ existing golden-set accuracy with 0% regression on verbatim and continuity checks.
   - Core invariants in `preamble@v1` (verbatim slicing, zero hallucination, no legal opinion) are system-enforced and cannot be overridden by self-improvement.
   - Operations dashboard surfaces a side-by-side diff of proposed prompt modifications and score deltas for auditability.
