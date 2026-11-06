# F3 — Relations, Amendments, Versioning and Consolidation (3 weeks)

**Goal:** for the pilot family, Indonesia Law shows how each provision read on any date, which instrument changed it, and the evidence.

## Tasks

**Relations**
- [ ] `relation_type` seed (active directions + `inverse_code`, `03` §2.5).
- [ ] Candidate search over `work` (trigram + jenis/nomor/tahun) for target resolution.
- [ ] Relation Agent (`relation@v1`) with evidence + confidence; ambiguous → `unresolved_reference` + review item.
- [ ] Deterministic evidence check: evidence lines exist inside the cited node.

**Amendments and versions**
- [ ] Amendment Analyzer (`amendment@v1`): ops with `target_path`, `new_content_node_id`, effective-date rule, evidence.
- [ ] Version Builder: deterministic ordering (effective → promulgation → number), `node_version` with DB-enforced non-overlap; `version_resolve@v1` for ambiguity; missing dates → review.
- [ ] `work_date` population with evidence; `work.status_aturan` derived from QC-passed data.
- [ ] Compiler: as-of tree, `consolidation_snapshot` cache, `expression` rows.
- [ ] `recompile` graph: affected-node-only rebuild when a new amending instrument arrives.
- [ ] Court annulment ops (`annulled_by_court`) supported by the same model.

**API**
- [ ] `/tree?at=`, `/consolidated?at=`, `/versions`, `/diff`, `/nodes/{id}/history`, `/relations`, `/graph`.

**Frontend** (read skills first)
- [ ] Changes panel: instrument timeline, per-node version list with evidence links, word diff (`DiffText`, non-color cues).
- [ ] Date slider: whole tree as of T with "Dicabut" / "Disisipkan" / "Diubah" labels; selected date shown as text.
- [ ] Relations tab: list view first (accessible), then network graph with type/depth filters; edge → evidence.
- [ ] Golden set extended with 5 annotated amendment chains.

## Exit Criteria

- 5 real pilot chains (parent + several amendments) consolidated; a human checks provisions at ≥ 3 dates per chain and finds no error.
- Version QC invariants hold (no overlaps, correct order) — DB constraint + test.
- Every relation and op shown in the UI links to evidence lines that highlight in the PDF.
- Adding a new amending instrument triggers recompile of only affected nodes (proved by task count).
