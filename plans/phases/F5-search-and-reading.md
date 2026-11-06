# F5 — Search and Reading Experience (1.5 weeks)

**Goal:** an internal reader can find any pilot regulation or provision, read it as of any date, and compare versions, in a calm light UI.

## Tasks

**Backend**
- [ ] `GET /api/search`: metadata (jenis, nomor, tahun, judul via trigram) + provision full text (`to_tsvector('simple', …)`), filters, `at=` for as-of search over versions, highlight offsets (never altered text).
- [ ] Ranking: exact citation match ("UU 1 Tahun 2004", "Pasal 5 ayat (2)" resolved via candidate search, not regex on legal text) > title > provision text.
- [ ] Only `published` data in default search; an operator toggle includes unpublished data with its stage shown.

**Frontend** (read skills first)
- [ ] Home `/`: full-bleed white → parchment sections, search hero (`hero-display`, pill search), coverage summary, latest published.
- [ ] `/cari`: results grouped into works and provisions, filters as chips/segmented controls, date T, empty and error states.
- [ ] Viewer polish: reading column (~72ch), "Salin kutipan" (copies exact text + citation), provenance popover, responsive panel behavior (`07` §3).
- [ ] `/peraturan/:id/bandingkan`: two versions or two instruments side by side.
- [ ] Indonesian date formatting with `ditetapkan / diundangkan / mulai berlaku` labels.

## Exit Criteria

- 20 scripted search tasks on the pilot corpus succeed (target found in the top 5).
- Copied quotes are byte-identical to `node.text` (test).
- Pages pass the `08` §6 checklist and axe; responsive check at 1440, 1068, 833, 640, 480 widths.
- Playwright e2e: search → open work → change date → compare.
