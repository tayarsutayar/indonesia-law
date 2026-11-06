# 01 — Vision, Principles and Scope

## 1. Corpus Context (applies to the whole project)

Every document Indonesia Law processes is an **Indonesian legal instrument**: UUD 1945, TAP MPR, UU, Perppu, PP, Perpres, Keppres, Permen/PMK, KMK and other *Keputusan*, Instruksi, Surat Edaran, Perda Provinsi/Kabupaten/Kota, and court decisions that affect norms (e.g., Putusan MK). The text is in Bahasa Indonesia and follows Indonesian legislative-drafting conventions (Law No. 12 of 2011 as amended, with its technical annex).

Consequences:
- Legal text is **never translated**, summarized or "cleaned up". This plan is in English; the data is not.
- Structure terms (Pasal, Ayat, Huruf, Angka, Butir, Bab, Bagian, Paragraf, Penjelasan, Lampiran, Menimbang, Mengingat, Memutuskan/Menetapkan, …) are kept as-is in data and UI labels.
- Every agent prompt starts with the **Corpus Context Preamble** (see `05-prompts-and-llm.md`).

## 2. Product Goals

1. **Discover** all Indonesian regulations and legal instruments from official sources.
2. **Fetch** original documents (PDF/HTML) politely (rate-limited).
3. **Extract** text (native or vision OCR) with line numbering.
4. **Split** every instrument into its smallest provisions **verbatim** (pointers, never LLM copies).
5. **Map relations** between instruments and between provisions, with evidence.
6. **Version** at the instrument level and the smallest-provision level.
7. **Compile** consolidated versions as of any date T (time travel).
8. **Read and search**: viewer (original PDF ↔ parsed tree ↔ change history), metadata and full-text search.
9. **Review**: a human review queue for every uncertain case.
10. **Visualize** the process (virtual office with worker sprites), dashboard, logs and token tracker.
11. Run in **manual** or **automatic** (scheduled, incremental) mode.

## 3. Users and Roles

| Role | Primary needs |
|---|---|
| Operator | Start/pause runs, set swarm sizes and budgets, watch the dashboard and office |
| Reviewer | Resolve the review queue (provision boundaries, OCR, relations, versions) with evidence in view |
| Internal reader | Search and read regulations, view consolidation as of a date, compare versions |

v1.0 is single-user with a static token, but every review decision still records its actor (`decided_by`) so multi-user auth can be added without data migration.

## 4. Non-Negotiable Principles

| # | Principle | Design consequence |
|---|---|---|
| P1 | **Verbatim text** | LLMs never rewrite text; a deterministic Verbatim Verifier checks every node |
| P2 | **LLM parsing, no regex** | No regex decides legal structure; the LLM picks boundaries, text is sliced by pointers |
| P3 | **Polite scraping** | Per-domain rate limiter, jitter, low concurrency, robots.txt, raw cache, backoff |
| P4 | **Versioning to the smallest provision** | Stable `node_key` + temporal validity per node |
| P5 | **Everything traceable** | Every agent action, LLM call, token, cost and decision is logged and replayable |
| P6 | **Resumable and idempotent** | Checkpoints everywhere; a crash never restarts from zero |
| P7 | **Evidence for every claim** | Relations and changes store evidence (node + line range) |
| P8 | **Corpus awareness** | Every prompt states that the input is Indonesian legal text |
| P9 | **Light, calm, accessible UI** | Apple Web Design System, light theme only; target WCAG 2.2 AA (see `07`, `08`) |
| P10 | **Display integrity** | The UI shows text exactly as stored and status exactly as in the DB; nothing appears "final" before it is published |

## 5. Scope

**In scope (v1.0):** end-to-end pipeline for one primary source and one fully covered pilot instrument family, then expansion; viewer; internal search (metadata + provision full text); review queue; dashboard; office visualization; manual/automatic mode; Docker Compose.

**Out of scope (initially):** translation, legal opinions/analysis, public semantic search, multi-tenancy, complex auth (static token is enough, upgradeable), dark theme.

**"Without exception"** is operationalized as **coverage tracking**: the dashboard shows % discovered / fetched / extracted / split / verified / related / versioned / published, plus a failure list with reasons. Nothing is dropped silently.

## 6. Glossary

| Term | Meaning |
|---|---|
| Work | Identity of an instrument (e.g., UU 1/2004); never changes |
| Expression | Content of an instrument over a time range (original, as amended by X, consolidated as of T) |
| Manifestation | A physical copy from one source (PDF from JDIH, BPK, …) + hash |
| Node | A provision inside one source document; its text is a verbatim slice of `source_text` |
| `node_key` | Stable provision ID across versions, e.g., `uu-1-2004/pasal-5/ayat-2/huruf-b` |
| Node version | A temporal version of one `node_key` (`valid_from`–`valid_to`) |
| Amendment op | A change operation read from an amending instrument (replace, insert, delete, revoke, …) |
| Consolidation | The provision tree in force as of date T |
| Swarm | A pool of parallel agent instances for one category/queue |
| Golden set | Manually annotated documents used to score agents and prompts |
