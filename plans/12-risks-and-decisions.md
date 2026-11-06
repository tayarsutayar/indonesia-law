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

## 2. Decisions Needing Approval

| # | Decision | Recommendation |
|---|---|---|
| D1 | Pointer-based node text vs LLM-rewritten text | Pointer-based |
| D2 | `critical` red (`#d70015`) as the only exception to the single-accent rule, for destructive/blocking states | Approve; otherwise blocking states use ink + icon only |
| D3 | Frosted parchment global nav instead of the skill's black nav, to keep the app fully light | Approve |
| D4 | 14px `caption` allowed for dense tables/logs (body stays 17px elsewhere) | Approve |
| D5 | Canonical manifestation priority (issuer site > peraturan.go.id > JDIH > BPK) | Approve, configurable |
| D6 | Display QC worker (Playwright) becomes required, not optional | Approve |

## 3. Open Questions

1. **Primary source:** seed from an existing JDIH / `all_peraturan` index, or crawl peraturan.go.id, JDIH Kemenkeu, BPK directly? (Recommended: seed from existing data, then add adapters.)
2. **Pilot family:** state finance / state property (BMN): treasury law, BMN government regulation, related PMKs? Who validates the pilot chains legally?
3. **Model "gpt 6 luna":** confirm it is the Azure deployment name, its structured-output and vision support, context size, TPM/RPM quota and price per token.
4. **Hosting:** self-managed VPS with Docker Compose at the suggested sizing?
5. **Auth:** single user for v1.0, or multi-user login needed earlier?
6. **Perda:** nationwide from the start, or phased in after national instruments?
7. **Public access:** is Indonesia Law internal-only for v1.0? (Affects auth, hosting and legal disclaimers.)
8. **Budget:** monthly LLM budget cap for pilot and for full scale.

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
