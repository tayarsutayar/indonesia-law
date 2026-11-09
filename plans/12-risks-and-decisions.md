# 12 — Risks, Decisions and Open Questions

## 1. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| LLM paraphrases or drops text | Violates P1 | Pointer-based extraction, deterministic Verbatim Verifier, retry, review queue |
| Token cost explodes across the corpus | Budget | Hash cache, right-sized windows, budget guard, pilot first, cost projection gate in F7 |
| Bad scans / OCR errors | Inaccurate text | Two-pass vision OCR, confidence, never auto-approve on disagreement, visible OCR badge |
| Source sites block or change layout | Discovery stalls | Conservative limits, isolated adapters, health checks, fallback sources |
| Long documents exceed context | Parsing fails | Windowing with overlap + merge, visible sub-tasks |
| Legal ambiguity (partial revocation, dates, retroactivity) | Wrong versions | Mandatory evidence, separate date fields, Version QC, review queue |
| Source duplication with differing text | Version conflicts | Manifestations + explicit canonical rule, recorded source |
| Model dependency / retirement | Rework | Deployment name and capability flags in config, golden-set re-eval on change |
| Concurrency races | Corrupt state | Idempotency keys, per-`work_id` locks, transactions, append-only log |
| Model "helpfully" translates | Corrupted corpus | Preamble, verifier, language sanity check |
| UI misrepresents status or text | Loss of trust | Text/status integrity rules (`07` §6), shared enums, e2e tests |
| Design rules conflict with dense data UI | Inconsistent UI | Documented adaptations (`08` §1), PR checklist |
| Review queue grows faster than humans resolve it | Coverage stalls | Aging alerts, prioritization by blocking impact, batch decisions for identical cases |
| Historic scans / faint typewriter text (1945–1960) degrade OCR accuracy | Text errors | Two-pass vision transcription + old-spelling dictionary + contrast enhancement; unresolved lines flagged for human review |
| Unconstrained search engine crawlers fetch unofficial blogs / fake drafts | Corpus contamination | Strict authenticity verification: mandatory official state gazette seal/signatures, domain whitelisting, verification against master registry |
| Agent self-improvement causes prompt drift or catastrophic forgetting | Quality regression | Immutable `preamble@v1`, automated Golden-Set non-regression benchmark gate, human-in-the-loop signoff for system prompt promotions |

## 2. Decisions Needing Approval

| # | Decision | Recommendation | Status | Notes |
|---|---|---|---|---|
| D1 | Pointer-based node text vs LLM-rewritten text | Pointer-based | **Approved** | Verbatim text extraction via LLM without summarizing or paraphrasing; preserve text integrity. |
| D2 | `critical` red (`#d70015`) as the only exception to the single-accent rule, for destructive/blocking states | Approve; otherwise blocking states use ink + icon only | **Approved** | Allowed for destructive / blocking alert states. |
| D3 | Frosted parchment global nav instead of the skill's black nav, to keep the app fully light | Approve | **Approved** | Light mode consistency. |
| D4 | 14px `caption` allowed for dense tables/logs (body stays 17px elsewhere) | Approve | **Approved** | 14px caption permitted for dense tables and logs. |
| D5 | Canonical manifestation priority (.go.id Official Gazette scan > .go.id issuer portal > JDIH BPK > peraturan.go.id > .ac.id / institutional archives > general web) | Approve, configurable | **Approved** | Discovery ingests from the entire internet, with strict priority and canonical preference given to .go.id sources. |
| D6 | Display QC worker (Playwright) becomes required, not optional | Approve | **Approved** | Headless Playwright worker required starting milestone F4. |
| D7 | Agent Continuous Self-Improvement & Dynamic Skill Evolution | Approve with Golden Set guardrails | **Approved** | Agents refine micro-skills and candidate prompts; promotion blocked on any golden set regression. |
| D8 | Historical Scope & Open-Web Discovery Swarm (1945–present) | Approve | **Approved** | Ingests from the whole internet from 1945–present, prioritizing .go.id for authoritative manifestations. |

## 3. Decisions & Confirmed Parameters (Resolved Open Questions)

1. **Source strategy & Historical Depth:** Open-web discovery swarm crawling the entire internet (official portals, academic repositories, legal archives, public domain libraries) for all national legal instruments from 1945 through the present day. Queue scheduling, manifestation ranking, and canonical selection strictly prioritize official `.go.id` government domains.
2. **Pilot family:** State Finance & State Property / BMN (*Keuangan Negara dan BMN*), tracing historic predecessors back to early independence foundations.
3. **Legal validation:** Automated validation via LLM; human legal expert escalations when human sign-off is required.
4. **Model deployment & credentials:** Deployment name, endpoint, and credentials are configured directly in `.env` (kept strictly confidential, not accessed/read by agent).
5. **LLM Budget:** Configured in `.env` with daily cap enforcement.
6. **Hosting:** Full Docker Compose environment (FastAPI, Celery, PostgreSQL/pgvector, Redis, MinIO).
7. **Auth:** Single-user static token authorization for v1.0.
8. **Perda (Regional Regulations):** Deferred; focus initially on national legislation.
9. **Target audience:** Public access (requires appropriate rate limiting and legal disclaimers).

## 4. Gaps Found in the Original Plan (resolved in `plans/`)

| Gap | Resolution |
|---|---|
| `expression` in the model but not in the schema | Added (`03` §2.1) |
| `btree_gist` needed for the `EXCLUDE` constraint | Added (`03` §2.3) |
| No search feature despite "searching and reading" being a goal | F5 + `/api/search` |
| Review queue had a table but no UI flow or decision model | `review_decision`, `07` §4, F4 |
| Display QC needs Playwright but the browser worker was optional | Required from F4 (`02` §7) |
| No design system or accessibility plan | `07` §5, `08`, PR checklist |
| Inverse relations listed as stored types | Derived via `inverse_code` (`03` §2.5) |
| Status labels undefined for the UI | Shared enum + i18n mapping (`03` §4, `07` §6) |
| `#7a7a7a` muted text fails AA on white | `ink-secondary` `#6e6e73` (`08` §2) |
