# 01 — Vision, Principles and Scope

## 1. Corpus Context (applies to the whole project)

Every document Indonesia Law processes is an **Indonesian legal instrument**: UUD 1945, TAP MPR, UU, Perppu, PP, Perpres, Keppres, Permen/PMK, KMK and other *Keputusan*, Instruksi, Surat Edaran, Perda Provinsi/Kabupaten/Kota, and court decisions that affect norms (e.g., Putusan MK). The text is in Bahasa Indonesia and follows Indonesian legislative-drafting conventions (Law No. 12 of 2011 as amended, with its technical annex).

Consequences:
- Legal text is **never translated**, summarized or "cleaned up". This plan is in English; the data is not.
- Structure terms (Pasal, Ayat, Huruf, Angka, Butir, Bab, Bagian, Paragraf, Penjelasan, Lampiran, Menimbang, Mengingat, Memutuskan/Menetapkan, …) are kept as-is in data and UI labels.
- Every agent prompt starts with the **Corpus Context Preamble** (see `05-prompts-and-llm.md`).

## 2. Product Goals

1. **Discover** all Indonesian regulations and legal instruments from the inception of the Republic of Indonesia (August 17, 1945) through the present day by crawling across the entire open web (including academic repositories, legal portals, and digital archives), with strict priority routing and canonical preference given to official `.go.id` domains.
2. **Fetch** original documents (PDF/HTML) politely (rate-limited).
3. **Extract** text (native or vision OCR for historic typewriter scans) with line numbering and old-spelling awareness.
4. **Split** every instrument into its smallest provisions **verbatim** (pointers, never LLM copies).
5. **Map relations** between instruments and between provisions, with evidence, and chase backward citations to discover missing historic regulations.
6. **Version** at the instrument level and the smallest-provision level using a Git-like legal version control system (VCS).
7. **Compile and time-travel**: generate consolidated versions as of any historical date T (`git checkout <date>`) with full "Git blame" provenance down to the provision/phrase level.
8. **Read, search and diff**: viewer (original PDF ↔ parsed tree ↔ change history), metadata and full-text search, and visual side-by-side / inline diffing between any two historical dates or amending acts.
9. **Review**: a human review queue for every uncertain case.
10. **Visualize** the process (virtual office with worker sprites), dashboard, logs and token tracker.
11. Run in **manual** or **automatic** (scheduled, incremental) mode.
12. **Self-Improve**: autonomous feedback loops for every agent category to refine prompts and micro-skills against real-world errors, gated by non-regression benchmarks.
13. **Developer & Legal AI Interoperability**: Git-compatible repository export (Markdown tree + commit history) and temporal snapshot APIs to prevent temporal hallucinations in legal LLM agents.

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
| P11 | **Guarded self-improvement** | Agents autonomously cluster failures, expand micro-skills, and propose prompt patches, but promotion to production strictly requires passing the automated golden-set regression suite; `preamble@v1` remains permanently immutable |

## 5. Scope

**In scope (v1.0):** 
- Comprehensive historical discovery swarm: Open-web harvesting across all online sources (academic repositories, open legal portals, digital libraries), with priority scheduling and canonical preference anchored in `.go.id` government domains (BPK JDIH, JDIHN, Setneg/Setkab, Peraturan.go.id, Courts).
- End-to-end extraction and versioning pipeline with support for historic typewriter scans, old spelling conventions (Van Ophuijsen, Suwandi/Soewandi), and complex drafting styles.
- Continuous agent self-improvement subsystem: Dynamic Skill Bank, failure reflection, candidate prompt generator, automated regression testing, and promotion control.
- End-user features: viewer (original PDF ↔ parsed tree ↔ change history), internal search (metadata + provision full text), review queue, dashboard, coverage tracker by era/year, office visualization, manual/automatic mode, Docker Compose.

**Out of scope (initially):** translation, subjective legal opinions/advisory, public consumer semantic search, multi-tenancy, complex auth (static token is enough, upgradeable), dark theme.

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
| Amendment op | A change operation read from an amending instrument or court decision (replace, insert, delete, revoke, court annulment, conditional interpretation) |
| Consolidation | The provision tree in force as of date T (equivalent to `git checkout <date>`) |
| Hukum Blame | Provenance view showing the authoring legal act, promulgation date, and effective date for any specific line, provision, or phrase |
| Judicial Hotfix | An external modification or annulment resulting from a Constitutional Court (MK) or Supreme Court (MA) decision |
| Swarm | A pool of parallel agent instances for one category/queue |
| Golden set | Manually annotated documents used to score agents and prompts |
