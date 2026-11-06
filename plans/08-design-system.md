# 08 — Design System (Apple Web Design System, Light Theme)

Source of truth: `.agents/skills/apple-design/SKILL.md`, `references/apple-design-system.md`, `examples/tailwind-apple-guide.md`. This file records how Indonesia Law applies it. Indonesia Law is a **light-theme-only** product.

## 1. Adaptation Decisions

The skill describes a marketing site; Indonesia Law is a data-dense application. These adaptations keep the system's rules while fitting the product:

| Skill rule | Indonesia Law application |
|---|---|
| Alternating light ↔ dark tiles | **Light only:** alternate `#ffffff` ↔ `#f5f5f7`. Near-black tiles are not used. |
| Black global nav (`#000000`) | Replaced by a frosted parchment global nav (`rgba(245,245,247,0.8)` + `saturate(180%) blur(20px)`) with ink text, to keep the whole app light. |
| Section padding 80px | Used on Home and landing-like pages. App pages use 24–32px page padding; dense tools (viewer, tables, logs) use 16–24px. |
| Body 17px | Default for UI copy and legal text. Dense tables and logs may use `caption` (14px); never smaller than 12px. |
| Single accent | Action Blue `#0066cc` for every interactive element. Status uses icon + text in ink, not new hues (§3). |
| One shadow (product imagery) | No shadows anywhere in the app UI. Popovers, menus and modals use a 1px hairline + frosted background. |
| Utility cards 18px radius | Cards, panels, review workspace blocks: `rounded.lg` 18px, 1px hairline, 24px padding. |

## 2. Tokens

**Colors**

| Token | Hex | Use |
|---|---|---|
| `canvas` | `#ffffff` | Default surface |
| `parchment` | `#f5f5f7` | Alternate surface, app background behind panels, footer |
| `pearl` | `#fafafc` | Secondary button fill |
| `ink` | `#1d1d1f` | All primary text |
| `ink-80` | `#333333` | Text on pearl buttons |
| `ink-secondary` | `#6e6e73` | Secondary text (≥ 4.5:1 on white and parchment) |
| `ink-48` | `#7a7a7a` | Disabled text, large fine print only (fails 4.5:1 for normal text) |
| `blue` | `#0066cc` | Links, primary buttons, selection |
| `blue-focus` | `#0071e3` | Focus ring |
| `hairline` | `#e0e0e0` / `rgba(0,0,0,0.08)` | Card and input borders |
| `divider` | `#f0f0f0` / `rgba(0,0,0,0.04)` | Row separators |
| `critical`* | `#d70015` | Destructive actions, blocking errors, budget exceeded |

`*` Exception to the single-accent rule, **needs approval** (see `12`). It is never used for navigation or primary actions, and always paired with an icon and text.

**Typography** — stack `system-ui, -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", Inter, sans-serif`; mono for line IDs and raw text: `ui-monospace, "SF Mono", Menlo, monospace`. Weights 300/400/600 only (no 500).

| Token | Size / weight / line-height / tracking | Use in Indonesia Law |
|---|---|---|
| `hero-display` | 56 / 600 / 1.07 / -0.28px | Home hero only |
| `display-lg` | 40 / 600 / 1.10 / 0 | Page titles on Home and Dashboard overview |
| `display-md` | 34 / 600 / 1.47 / -0.374px | Work title in viewer header |
| `lead` | 28 / 400 / 1.14 / 0.196px | Home sub-copy |
| `tagline` | 21 / 600 / 1.19 / 0.231px | Sub-nav section name, panel titles |
| `body` | 17 / 400 / 1.47 / -0.374px | UI copy, legal text |
| `body-strong` | 17 / 600 / 1.24 / -0.374px | Provision labels (Pasal 5), emphasis |
| `caption` | 14 / 400 / 1.43 / -0.224px | Table cells, metadata, badges |
| `fine-print` | 12 / 400 / 1.0 / -0.12px | Timestamps, footnotes |

Inter fallback: tighten display tracking by -0.01em and body line-height to 1.44, per the reference.

**Spacing** — 8px base: 4, 8, 12, 17, 24, 32, 48, 80.
**Radii** — 0 (full-bleed sections), 8 (utility buttons, inner images), 11 (pearl capsules), 18 (cards/panels), pill (primary CTAs, search, chips, segmented controls).
**Motion** — buttons `active: scale(0.95)`, 150ms ease-out; disabled under `prefers-reduced-motion`.

## 3. Status Badges (no second accent)

Badges are `caption` text in `ink`, pill radius, `parchment` fill, 1px hairline, with a leading icon:

| Status | Icon | Label |
|---|---|---|
| verbatim ok | check | `Verbatim` |
| OCR source | scan | `OCR` |
| manual transcription | pencil | `Transkripsi manual` |
| needs review | flag | `Perlu tinjauan` |
| published | seal | `Dipublikasikan` |
| in progress | progress ring | `<stage name>` |
| failed / blocking | alert (in `critical`) | `Gagal` |

Selected or active state = Action Blue outline/text. Charts follow the same rule (`07` §7).

## 4. Components

Built in `frontend/src/design/` as typed React components using the Tailwind preset from the skill's guide (colors under `apple.*`, font sizes `apple-*`, radii `apple-sm|md|lg`, plus `ink-secondary` and `critical`). Remove `boxShadow.apple-product` from use in the app (no product imagery).

| Component | Spec |
|---|---|
| `Button` primary | Pill, `#0066cc`, white text, 17px, 11×22px padding, scale(0.95) active, focus outline |
| `Button` secondary | Ghost pill: transparent, blue text, 1px blue border |
| `Button` pearl | `#fafafc`, `ink-80` text, 14px, 11px radius |
| `Button` utility | 8px radius, compact (toolbar actions) |
| `Button` destructive | Ghost pill in `critical`, always behind a confirmation |
| `SearchInput` | Pill, 44px high, 1px hairline, leading icon |
| `GlobalNav` / `SubNav` | Frosted parchment, 44px / 52px, hairline bottom border, sticky |
| `Card` / `Panel` | White, 18px radius, 1px hairline, 24px padding, no shadow |
| `SegmentedControl`, `Chip` | Pill; selected = 2px `blue-focus` border |
| `Badge` | §3 |
| `Table` | Virtualized, 14px cells, `divider` row lines, sticky header on parchment |
| `ProvisionTree` | ARIA tree, `body-strong` labels, `body` text, indentation 24px per level |
| `DiffText` | Insertions underlined + "ditambah" label for SR; deletions struck + "dihapus"; no color-only meaning |
| `Timeline`, `DateSlider` | Ink track, blue thumb, current date as text |
| `Dialog`, `Popover`, `Toast` | Frosted or white, hairline, 18px radius, no shadow, focus-managed |
| `EmptyState`, `ErrorState`, `Skeleton` | Text-first; skeletons in `divider` tone, no shimmer under reduced motion |

## 5. Page Rhythm

- Home: full-bleed sections alternating white → parchment → white, 80px vertical padding (48px on mobile), centered `hero-display` + `lead` + one primary and one secondary pill.
- App pages: parchment background, white panels/cards, content max 1440px; reading column for legal text ~72ch.
- Breakpoints from the reference: 1440 (lock), 1068, 833, 734, 640, 480.

## 6. Review Checklist (every UI PR)

- [ ] Only light surfaces (`#ffffff`, `#f5f5f7`, `#fafafc`); no dark tiles, no gradients.
- [ ] No `box-shadow` anywhere; elevation via surface change, hairline or frosted blur.
- [ ] Interactive elements use Action Blue; `critical` only for destructive/blocking states.
- [ ] Body 17px (14px only in dense data), weights 300/400/600, negative tracking on display sizes.
- [ ] Radii from the scale; primary CTAs are pills with scale(0.95) press.
- [ ] Contrast, focus, keyboard, non-color status, reduced motion (`07` §5).
- [ ] Legal text rendered verbatim (`07` §6).
