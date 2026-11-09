# 07 — Web App: Information Architecture, Pages, Review Flows, Accessibility

Before any frontend work, read every `SKILL.md` in `.agents/skills/` (currently `apple-design` + its reference and Tailwind guide) and `08-design-system.md`. This file defines **what** the UI does; `08` defines **how it looks**.

## 1. App Shell

- Single-page app, light theme only. Title pattern: `<Page> — Indonesia Law`.
- **Global nav** (44px, frosted parchment, see `08` §5): wordmark "Indonesia Law", primary sections, search field, run status chip, alerts.
- **Sub-nav** (52px, frosted) per section: section name (tagline style) + local tabs + one primary action.
- Primary sections: **Cari** (Search), **Peraturan** (Regulations), **Tinjauan** (Review), **Kantor** (Office), **Dasbor** (Dashboard), **Log**, **Kendali** (Control).
- UI chrome is Indonesian; all strings live in `frontend/src/lib/i18n/id.ts`. Legal content is rendered exactly as stored.

## 2. Pages

| Route | Page | Key content |
|---|---|---|
| `/` | Home | Search hero, coverage summary by historical era, latest published, open review count |
| `/cari` | Search | Query + filters (era, jenis, tahun, norm_character, status, instansi, date T); results grouped as works and provisions; highlights by offset |
| `/peraturan` | Regulation list | Virtualized table: era, jenis, nomor, tahun, judul, norm_character (regeling/beschikking), status aturan, pipeline stage, coverage badges |
| `/peraturan/:id` | Work detail (viewer) | Three synced panels + timeline slider (§3); tabs: Relasi, Log Dokumen, QC, Hierarki Historis |
| `/peraturan/:id/bandingkan` | Compare | Two versions or two instruments side by side (e.g. WvS 1918 vs KUHP 2023), word diff |
| `/tinjauan` | Review queue | Filters by reason, age, stage; claim; keyboard flow (§4) |
| `/tinjauan/:id` | Review item | Evidence workspace + decision form |
| `/kantor` | Office | PixiJS scene + "Tabel" mode (accessible equivalent) |
| `/dasbor/*` | Dashboard | Run, Coverage (multi-era historical grid: Pra-Kemerdekaan through Reformasi), Tokens & Cost, Swarm, Quality, Scraping, Versioning |
| `/log` | Log explorer | Events, tasks, LLM call inspector, per-document trace |
| `/kendali` | Control panel | Manual-run wizard, auto mode, swarm sizes, budgets |
| `/kendali/evolusi` | Prompt & Skill Evolution | Dynamic Skill Bank, candidate prompt diffs, golden-set benchmarks, one-click promotion/rollback |

## 3. Work Detail Viewer

```
┌──────────────┬──────────────────┬───────────────────────┐
│ PDF Asli     │ Hasil Parsing    │ Perubahan / Riwayat   │
│ (pdf.js)     │ (tree + text)    │ (timeline + diff)     │
└──────────────┴──────────────────┴───────────────────────┘
      Timeline slider: date T → consolidated view as of T
```

- **PDF panel:** lazy page render, highlight of the selected node's lines via `page_map`, manifestation selector (shows source website domain, clickable original source URL, `.go.id` verification badge, and fetch timestamp).
  - **Dual-Manifestation Toggle:** For pre-1945 colonial codes (BW, WvK, HIR, RBg, Rv, AB), provides a clean toggle between *Naskah Otentik Staatsblad (Bahasa Belanda)* and *Naskah Kerja Yurisprudensi (Terjemahan Standar Peradilan oleh Subekti/Tirtodiningrat)* with explicit translator provenance badge.
- **Parsing panel:** virtualized collapsible tree (Bab/Pasal for modern laws; Boek/Titel/Afdeling/Lid for classical codes; Penjelasan Resmi for UUD 1945 pra-amandemen); click → PDF highlight; text shown verbatim in a reading column (max ~72ch); "Teks sumber mentah" tab with line IDs in monospace; "Laporkan kesalahan" creates a review item.
  - **"Hukum Blame" Gutter (Git Blame Mode):** Toggleable provenance gutter beside each provision. Displays the authoring enactment tag (e.g. `[UU 16/2019]`, `[UU 5/1960 UUPA]`, or `[MK 91/2020]`), effective date, and author badge. Clicking any blame pill opens the commit inspection popover detailing the exact amendment op, evidence line range, and diff.
  - **Court Annotation & Scope Derogation Badges:** Displays accessible callouts for:
    1. Judicial hotfixes: e.g. "⚠ Inkonstitusional Bersyarat — Putusan MK No. 91/PUU-XVIII/2020" with the court's verbatim operative holding.
    2. Subject-matter scope derogations: e.g. "⚡ Dicabut Sebagian Secara Materiil — UU No. 5/1960 (UUPA) mengenai tanah, bumi, dan air".
- **Changes panel:** instrument timeline, `node_version` list (valid_from–valid_to, change type, causing instrument + evidence link), visual diff inspector.
  - **Visual Diff Engine:** Side-by-side and unified inline diff comparing any two historical dates ($T_1$ vs $T_2$) or amending instruments. Insertions highlighted with subtle accessible green tint + `+` tag; deletions displayed with strikethrough + `-` tag; word-level changes highlighted cleanly without breaking verbatim spacing.
  - **Omnibus Batch Inspector:** If an op was introduced by an Omnibus instrument (e.g. UU Cipta Kerja), displays a batch tag linking to all other laws amended within the same legislative cluster.
- **Date T:** whole tree shows state as of T; revoked = struck through **and** labelled "Dicabut"; inserted = labelled "Disisipkan"; scope-derogated = labelled "Dicabut Materiil"; the selected T is always shown as text alongside the **active constitutional hierarchy badge** (e.g. "Hierarki: Tap MPRS XX/1966").
- Responsive: ≥1069px three panels; 834–1068px two panels + tab for the third; <834px one panel with segmented control.

## 4. Review Flows

Review reasons: `verbatim_failed`, `ocr_mismatch`, `uncertain_boundary`, `unresolved_reference`, `relation_needs_review`, `amendment_uncertain`, `scope_derogation_uncertain`, `keppres_character_uncertain`, `missing_effective_date`, `qc_conflict`, `user_flag`.

Workspace layout for every reason: **evidence left** (PDF page + source lines), **proposal right** (what the agent produced, its `uncertain_reason`, QC findings), **decision bar bottom**.

| Reason | Decisions available |
|---|---|
| `verbatim_failed`, `uncertain_boundary` | Adjust pointers (line/char pickers on source lines, never free text), accept, return to Splitter |
| `ocr_mismatch` | Pick pass A / pass B per line, or manual transcription (verified against the image by the reviewer, stored as `manual_transcription`) |
| `unresolved_reference` | Pick a candidate work, search for another, or mark "tidak ada di korpus" |
| `relation_needs_review`, `amendment_uncertain` | Accept, reject (reason required), change type/target from lists |
| `missing_effective_date` | Point to the evidence node that states the date, or mark unknown |
| `qc_conflict`, `user_flag` | Return to a named stage with reason |

Rules:
- Every decision creates a `review_decision`; nothing is edited in place. The item shows its full decision history.
- Reject / return require a reason. A destructive or bulk action asks for confirmation and states what will change.
- After a decision the affected stage re-runs; the item shows "Menunggu proses ulang" until the pipeline reports back.
- Keyboard flow: `J/K` next/previous item, `A` accept, `R` reject, `Enter` confirm, `Esc` cancel; all shortcuts listed in a help dialog and never the only way to act.

## 5. Accessibility (target WCAG 2.2 AA)

- Semantic HTML first: landmarks (`header`, `nav`, `main`), one `h1` per page, ordered headings; the provision tree uses the ARIA `tree` pattern with roving tabindex.
- Every interactive element is keyboard reachable, with visible focus (`outline: 2px solid #0071e3`, offset 2px); no focus traps except modals, which restore focus on close.
- Contrast: text ≥ 4.5:1, large text and UI boundaries ≥ 3:1. Note `#7a7a7a` on white is ~4.3:1 and fails for normal text; use `#6e6e73` for secondary text (see `08` §2).
- Status is never conveyed by color alone: always icon + text label (e.g., "✓ Verbatim", "OCR", "Perlu tinjauan").
- Targets ≥ 44×44px for primary actions; ≥ 24×24px minimum anywhere (WCAG 2.5.8).
- `prefers-reduced-motion`: disable sprite walking, press-scale and chart animations; the Office offers a **Tabel** mode with the same information (agents, state, current task, document).
- Live updates: counters and run status use `aria-live="polite"`, throttled; errors and budget alerts use `role="alert"`.
- PDF panel exposes the extracted text layer; charts have a data-table alternative and text summary.
- Forms: visible labels, `aria-describedby` for help and errors, errors stated in text next to the field.
- Language: `<html lang="id">`; legal text blocks also `lang="id"`; any English (e.g., raw LLM logs) marked `lang="en"`.
- Full validation needs manual testing with assistive tech (VoiceOver, NVDA) and an expert review; automated axe checks in CI are necessary but not sufficient.

## 6. Text and Status Integrity

1. Legal text is rendered from `node.text` exactly: no trimming, re-casing, hyphenation insertion, smart-quote conversion, number formatting or truncation without an explicit "Tampilkan semua" control. Whitespace is preserved (`white-space: pre-wrap`).
2. Search highlights use server offsets wrapping the original string; the text itself is not reconstructed.
3. Every provision shows its provenance on demand: source manifestation with original source website URL and domain, lines, `source_kind`, verifier result.
4. OCR or manually transcribed text is always badged; unpublished data always shows its actual stage ("Belum dipublikasikan — tahap: Version QC"). Nothing looks final before `published`.
5. Status labels come from one mapping (`lib/i18n/status.ts`) generated against the backend enums; unknown values render as "Status tidak dikenal (<value>)", never hidden.
6. Numbers on the dashboard come from the API; the UI never recomputes totals from partial pages. Each chart shows "data per <timestamp>".
7. Dates display in Indonesian (`12 Januari 2024`), with the `ditetapkan / diundangkan / mulai berlaku` distinction labelled.
8. Diffs are display-only and labelled as such.

## 7. Office, Dashboard, Logs, Control

Behavior follows [Appendix C](appendix/C-office-dashboard-spec.md), with these adjustments:
- Office scene uses the light palette (parchment floor, white rooms, ink outlines, Action Blue only for selectable/active items). Sprite assets must be original or properly licensed.
- Above ~150 agents, group sprites with counts. Replay mode reads `event_log`.
- Dashboard charts use a neutral grayscale ramp + Action Blue for the focused series; categories are distinguished by pattern/position and direct labels, not extra hues.
- Control wizard: scope → estimate (tokens, cost USD/IDR, duration) → budget & workers → confirm → start. Pause/stop show the effect before confirming.
- 1945+ Historical Coverage View: interactive timeline of Indonesian legal eras (1945–1949 Awal Kemerdekaan, 1949–1950 RIS, 1950–1959 UUDS, 1959–1965 Orde Lama, 1966–1998 Orde Baru, 1998–sekarang Reformasi). Highlights gaps in official series (LNRI/BNRI) and permits direct triggering of targeted search engine swarms for missing batches.
- Prompt & Skill Evolution Panel: lists active prompts vs candidate `@v(N+1)` proposals generated by reflection agents. Displays side-by-side prompt diffs, automated evaluation score changes across the Golden Set, token impact, and clear audit history with instant rollback buttons.

## 8. Frontend Implementation Notes

- Server state: TanStack Query; realtime: Zustand + WS reducer; the Pixi scene reads the store, never the reverse.
- Virtualize large trees, tables and logs; render PDFs lazily per page.
- Component tests (Vitest + Testing Library), Playwright e2e for search → viewer, review decision, manual-run wizard; axe checks in e2e.
