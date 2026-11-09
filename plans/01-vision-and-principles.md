# 01 — Vision, Principles and Scope

## 1. Corpus Context (applies to the whole project)

Every document Indonesia Law processes is an **Indonesian legal instrument** across all historical eras:
- **Pra-Kemerdekaan / Adopsi Transisional:** Foundational colonial codes (*Staatsblad*) that remain positive law under Pasal II Aturan Peralihan UUD 1945 / Pasal I Aturan Peralihan UUD NRI 1945 and PP No. 2/1945: *Burgerlijk Wetboek* (BW / KUHPerdata, S. 1847 No. 23), *Wetboek van Koophandel* (WvK / KUHD, S. 1847 No. 23), *Herziene Inlandsch Reglement* (HIR, S. 1941 No. 44), *Rechtsreglement Buitengewesten* (RBg, S. 1927 No. 227), *Reglement op de Burgerlijke Rechtsvordering* (Rv, S. 1847 No. 52), *Algemene Bepalingen van Wetgeving* (AB, S. 1847 No. 23), and sector-specific *Ordonnantie*.
- **Awal Kemerdekaan & Revolusi Fisik (1945–1949):** UUD 1945 (Periode I), Maklumat Wakil Presiden No. X/1945, Maklumat Pemerintah, UU, Perppu, PP, dan Penetapan Presiden Darurat.
- **Republik Indonesia Serikat / RIS (1949–1950):** Konstitusi RIS 1949, Undang-Undang Federal RIS, dan Lembaran Negara RIS.
- **Demokrasi Liberal & UUDS 1950 (1950–1959):** UUDS 1950, Undang-Undang, Undang-Undang Darurat (UU Drt), dan PP.
- **Demokrasi Terpimpin / Orde Lama (1959–1966):** UUD 1945 pasca-Dekrit 5 Juli 1959, Ketetapan MPRS (Tap MPRS), Penetapan Presiden (Penpres / PNPS), Peraturan Presiden (Perpres Orla), dan UU.
- **Orde Baru (1966–1998):** UUD 1945 di bawah hierarki Tap MPRS No. XX/MPRS/1966 (UUD 1945, Tap MPR, UU/Perppu, PP, Keppres [regeling vs beschikking], Permen/Instruksi), serta peninjauan Penpres via UU No. 5 Tahun 1969.
- **Era Reformasi (1998–Sekarang):** UUD NRI 1945 (Amandemen I–IV); hierarki Tap MPR No. III/MPR/2000 $\rightarrow$ UU No. 10/2004 $\rightarrow$ UU No. 12/2011 jo. UU No. 15/2019 jo. UU No. 13/2022 (Omnibus Law); peradilan uji materiil (Putusan MK dan Putusan MA); instrumen otonomi daerah asimetris (Qanun Aceh, Perdasus/Perdasi Papua, Perdais DIY); peraturan lembaga independen (POJK, PBI, Perma, PMK); dan dekolonisasi hukum pidana nasional (KUHP Baru UU No. 1 Tahun 2023 per 2 Januari 2026 menggantikan WvS kolonial).

Consequences:
- Legal text is **never translated by the LLM**, summarized or "cleaned up". This plan is in English; the corpus data stays in its authentic register.
- **Dual-Manifestation for Colonial Codes:** For pre-1945 *Staatsblad* codes (originally enacted in Dutch / *Nederlandsch*), the system ingests the authentic Dutch gazette scan as `official_original` and pairs it with the standard doctrinal Indonesian translation used in Indonesian court jurisprudence (e.g. Prof. Subekti & R. Tjitrosudibio, K.R.M.T. Tirtodiningrat) as `doctrinal_translation`, explicitly recording translator provenance and avoiding unverified LLM translations.
- Structure terms:
  - *Modern:* Judul, Menimbang, Mengingat, Memutuskan/Menetapkan, Bab, Bagian, Paragraf, Pasal, Ayat, Huruf, Angka, Butir, Ketentuan Peralihan, Ketentuan Penutup, Penjelasan, Lampiran.
  - *Classical & Transitional:* Boek/Buku, Titel/Bab, Afdeling/Bagian, Artikel/Pasal, Alinea/Lid (un-numbered paragraphs), Diktum, and UUD 1945 pra-amandemen Penjelasan Resmi. All are kept as-is in data and UI labels.
- Every agent prompt starts with the **Corpus Context Preamble** (see `05-prompts-and-llm.md` and Appendix A).

## 2. Product Goals

1. **Discover** all Indonesian regulations and legal instruments from the inception of the Republic of Indonesia (August 17, 1945) through the present day, **as well as foundational pre-1945 colonial codes still in force or cited under Transitional Provisions (BW, WvK, HIR, RBg, Rv, AB, Staatsblad)**, by crawling across the entire open web (including academic repositories, legal portals, and digital archives), with strict priority routing and canonical preference given to official `.go.id` domains.
2. **Fetch** original documents (PDF/HTML) politely (rate-limited).
3. **Extract** text (native or vision OCR for historic typewriter scans and colonial gazettes) with line numbering and old-spelling awareness (Van Ophuijsen, Suwandi/Soewandi).
4. **Split** every instrument into its smallest provisions **verbatim** (pointers, never LLM copies), supporting both modern UU 12/2011 drafting and classical Boek/Titel/Lid code structures.
5. **Map relations** between instruments and between provisions, with evidence, supporting both explicit textual amendments and **subject-matter scope derogations** (*dekodifikasi parsial materiil*), and chase backward citations to discover missing historic regulations.
6. **Version** at the instrument level and the smallest-provision level using a Git-like legal version control system (VCS).
7. **Compile and time-travel**: generate consolidated versions as of any historical date T (`git checkout <date>`) with full "Git blame" provenance down to the provision/phrase level, dynamically evaluated against the **constitutional legal hierarchy active at date T**.
8. **Read, search and diff**: viewer (original PDF ↔ parsed tree ↔ change history), metadata and full-text search, and visual side-by-side / inline diffing between any two historical dates or amending acts (including KUHP Lama WvS vs KUHP Nasional UU 1/2023).
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
- Foundational pre-1945 colonial codes active via Transitional Provisions (Pasal II Aturan Peralihan UUD 1945 / Pasal I Aturan Peralihan UUD NRI 1945, PP 2/1945): BW/KUHPerdata, WvK/KUHD, HIR, RBg, Rv, AB, and historical Ordonnantie.
- All post-1945 historical constitutional eras: Revolusi Fisik (1945–1949), RIS (1949–1950), Demokrasi Liberal / UUDS 1950 (1950–1959), Demokrasi Terpimpin / Orde Lama (1959–1966), Orde Baru (1966–1998), and Era Reformasi (1998–present).
- Asymmetric regional autonomy instruments with unique normative status: Qanun Aceh, Perdasus/Perdasi Papua, Perdais DIY.
- End-to-end extraction and versioning pipeline with support for historic typewriter scans, old spelling conventions (Van Ophuijsen, Suwandi/Soewandi), Dutch original gazettes, and complex drafting styles.
- Dual-Manifestation handling for colonial codes: Dutch authentic gazette scan paired with standard court doctrinal Indonesian translations.
- Continuous agent self-improvement subsystem: Dynamic Skill Bank, failure reflection, candidate prompt generator, automated regression testing, and promotion control.
- End-user features: viewer (original PDF ↔ parsed tree ↔ change history), internal search (metadata + provision full text), review queue, dashboard, coverage tracker by era/year, office visualization, manual/automatic mode, Docker Compose.

**Out of scope (initially):** unverified LLM translations of legal provisions, subjective legal opinions/advisory, public consumer semantic search, multi-tenancy, complex auth (static token is enough, upgradeable), dark theme.

**"Without exception"** is operationalized as **coverage tracking**: the dashboard shows % discovered / fetched / extracted / split / verified / related / versioned / published, plus a failure list with reasons. Nothing is dropped silently.

## 6. Glossary

| Term | Meaning |
|---|---|
| Work | Identity of an instrument (e.g., UU 1/2004, S. 1847:23); never changes |
| Expression | Content of an instrument over a time range (original, as amended by X, consolidated as of T) |
| Manifestation | A physical copy from one source (PDF from JDIH, BPK, Staatsblad scan, doctrinal text) + hash |
| Dual-Manifestation | Storing both authentic Dutch Staatsblad scans and standard doctrinal Indonesian translations for colonial codes |
| Node | A provision inside one source document; its text is a verbatim slice of `source_text` |
| `node_key` | Stable provision ID across versions, e.g., `uu-1-2004/pasal-5/ayat-2/huruf-b` or `bw-1847-23/buku-3/bab-2/pasal-1320` |
| Node version | A temporal version of one `node_key` (`valid_from`–`valid_to`) |
| Amendment op | A change operation read from an amending instrument or court decision (replace, insert, delete, revoke, court annulment, conditional interpretation, or subject-matter scope derogation) |
| Scope Derogation | Substantive/implicit partial repeal by subject matter (e.g. UUPA 1960 repealing Buku II BW regarding land; UU 1/1974 repealing Buku I BW regarding marriage) without article-by-article enumeration |
| Dynamic Legal Hierarchy | Resolving normative precedence point-in-time based on the constitutional era active at historical date T (Tap MPRS XX/1966, Tap MPR III/2000, UU 10/2004, UU 12/2011) |
| Regeling vs Beschikking | Differentiation for pre-2004 Keppres between regulatory instruments (general/abstract norms) and administrative acts (individual/concrete/final) |
| Consolidation | The provision tree in force as of date T (equivalent to `git checkout <date>`) |
| Hukum Blame | Provenance view showing the authoring legal act, promulgation date, and effective date for any specific line, provision, or phrase |
| Judicial Hotfix | An external modification or annulment resulting from a Constitutional Court (MK) or Supreme Court (MA) decision |
| Swarm | A pool of parallel agent instances for one category/queue |
| Golden set | Manually annotated documents used to score agents and prompts |
