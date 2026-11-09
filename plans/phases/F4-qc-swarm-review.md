# F4 — Layered QC, Swarm Scaling and Review Queue (2 weeks)

**Goal:** the system can run many workers in parallel and still never publish wrong data: QC rejects and routes, and humans resolve what agents cannot.

## Tasks

**QC tiers** (`04` §5)
- [ ] Node QC (deterministic + `qc_node@v1`), Relation QC (`qc_relation@v1`), Version QC (`qc_version@v1`).
- [ ] Display QC: `worker-browser` renders the viewer for a page, screenshots it, compares with the PDF page via `qc_display@v1`.
- [ ] Chief QC (`qc_chief@v1`): aggregation, thresholds, sampling, publish decision; `published` status only set here.
- [ ] Routing back to the responsible stage with the QC report; `qc_result` rows; sampling rates configurable per tier.

**Swarm**
- [ ] `swarm_config` min/max per category; `PUT /api/swarms/{category}`; rule-based Supervisor (optional `supervisor@v1`).
- [ ] Heartbeat + lease, requeue on expiry, per-`work_id` locks, circuit breaker per stage/source.
- [ ] Azure TPM/RPM bucket shared across workers.

**Review queue & Continuous Self-Improvement**
- [ ] `review_decision` model and endpoints (`06` §2), validation rules (reason required, manual transcription verified).
- [ ] Decision effects: re-run the affected stage, update item status, events, and push learning payload to `q.evolution`.
- [ ] Dynamic Skill Bank & Reflection Loop (`worker-optimizer`): RCA on review decisions / QC rejections, micro-skill vector storage in `skill_bank`, candidate prompt patch generation with automated `eval:prompts` benchmark testing.
- [ ] Frontend `/tinjauan` list + `/tinjauan/:id` workspace per `07` §4 (evidence left, proposal right, decision bar), pointer pickers, OCR pass picker, candidate picker, keyboard flow, decision history.
- [ ] Frontend `/kendali/evolusi`: prompt candidate comparison, evaluation delta, and one-click promotion/rollback controls.
- [ ] Golden set grown to 50 documents, annotated through the review UI where possible.

## Exit Criteria

- 10 parallel workers run for 4 hours stably (no stuck tasks, no duplicate nodes).
- Injected faults (verbatim, wrong relation direction, overlapping dates, wrong consolidation wording, rendering defect) are rejected and routed to the right stage (≥ 95%, 100% for verbatim).
- Nothing reaches `published` without Chief QC (DB check).
- A reviewer can resolve each review reason end-to-end by keyboard only; axe clean; manual screen-reader pass on the review workspace.
