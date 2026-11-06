# 10 — Testing and Quality

## 1. Test Levels

| Level | Scope | Tooling |
|---|---|---|
| Unit (backend) | Rate limiter, robots, Verbatim Verifier, pointer slicing, `node_key` normalization, pricing, preamble guard, budget guard, Version Builder ordering, Compiler as-of queries | pytest |
| Contract | Pydantic schemas for every prompt; OpenAPI ↔ generated TS client | pytest, `openapi-typescript` diff check |
| Golden set | Splitter accuracy (structure + pointers), Amendment/Version accuracy on chains, OCR agreement | `eval:prompts` job |
| Fault injection | Paraphrase, dropped fragment, added text, translated text, wrong relation direction, overlapping dates | pytest fixtures that corrupt agent outputs |
| Integration | Full document graph with a mocked LLM; a few live runs per phase | pytest + docker compose |
| Load | 10+ workers, 1,000 documents; tokens/doc, cost, throughput, error rate | Phase 6 script |
| Frontend unit | Components, status mapping, diff rendering, date formatting | Vitest + Testing Library |
| Frontend e2e | Search → viewer, review decision, manual-run wizard, office table mode | Playwright |
| Accessibility | axe in e2e on every page; manual VoiceOver/NVDA pass per phase with UI | axe-core, manual |
| Visual | Screenshot baselines for design components | Playwright |

## 2. Quality Metrics and Targets

| Metric | Target |
|---|---|
| Nodes passing Verbatim Verifier among stored "final" nodes | 100% (by construction) |
| Splitter first-pass verbatim pass rate on golden set | ≥ 90% at Phase 1 exit, ≥ 95% at v1.0 |
| Structure accuracy (types + labels + boundaries) on golden set | ≥ 95% node-level F1 at v1.0 |
| Fault-injection rejection rate | 100% for verbatim faults; ≥ 95% for relation/version faults |
| Relation precision (QC-passed relations on sample) | ≥ 95% |
| Consolidation correctness on annotated chains | 100% on the 5 pilot chains |
| axe violations (serious/critical) | 0 |

## 3. CI Gates

1. Lint + type check (ruff, mypy; eslint, tsc).
2. Unit + contract tests.
3. Fault-injection suite.
4. Frontend unit + e2e smoke + axe.
5. `eval:prompts` runs when anything under `backend/app/prompts/` or an agent changes; a regression blocks merge.
6. Migrations apply cleanly on an empty DB and on the previous release's snapshot.

## 4. Manual Verification per Phase

Each phase file lists its exit criteria. Evidence is attached to the phase close-out: test output, dashboard screenshot, or a log query result. Legal correctness of pilot chains is checked by a human familiar with the instruments (see `12` open questions).
