---
name: apple-design
description: >-
  Use this skill whenever designing, building, reviewing, or refactoring web UI components, landing pages, layouts, or application surfaces following the Apple Web Design System. Enforces Apple's signature typography (SF Pro / Inter with negative display tracking, 17px body), strict single-accent color palette (Action Blue #0066cc, near-black ink #1d1d1f, parchment/dark tile surfaces), 8px spacing rhythm, alternating edge-to-edge tile sections, full-pill CTAs with scale(0.95) press feedback, and single product-drop-shadow elevation rules.
---

# Apple Web Design System Skill

This skill guides the design, implementation, and review of web interfaces adhering strictly to the **Apple Web Design System**.

Apple's design philosophy centers on **reverent presentation framed by near-invisible UI**. The canvas recedes, density is deliberately low, decorative chrome (borders, gradients, box shadows on cards) is eliminated, and content/product speaks for itself.

---

## 1. Quick Reference: Core Tokens

### Color Palette
- **Primary / Interactive:**
  - `Action Blue`: `#0066cc` (The **only** brand accent color for all links, buttons, and focus signals on light surfaces)
  - `Focus Blue`: `#0071e3` (Keyboard focus ring: `outline: 2px solid #0071e3`)
  - `Sky Link Blue`: `#2997ff` (In-copy links & inline callouts on dark surfaces)
- **Surfaces:**
  - `Pure White (Canvas)`: `#ffffff`
  - `Parchment`: `#f5f5f7` (Signature off-white for alternating light tiles & footer)
  - `Pearl Button`: `#fafafc` (Secondary ghost button fill)
  - `Near-Black Tile 1`: `#272729` (Primary dark tile)
  - `Near-Black Tile 2`: `#2a2a2c` (Micro-step lighter tile)
  - `Near-Black Tile 3`: `#252527` (Micro-step darker tile)
  - `Pure Black`: `#000000` (Global nav bar, video frames)
- **Text:**
  - `Near-Black Ink / Body`: `#1d1d1f` (Never pure black for light surface text)
  - `Body On Dark`: `#ffffff`
  - `Body Muted`: `#cccccc`
  - `Ink Muted 80`: `#333333`
  - `Ink Muted 48`: `#7a7a7a` (Disclaimers & fine-print)
- **Borders & Separators:**
  - `Divider Soft`: `#f0f0f0` or `rgba(0, 0, 0, 0.04)`
  - `Hairline`: `#e0e0e0` or `rgba(0, 0, 0, 0.08)` (1px border on utility cards)

### Typography Ladder
- **Font Stack:** `SF Pro Display` (≥ 19px) & `SF Pro Text` (< 20px), fallback: `system-ui, -apple-system, BlinkMacSystemFont, sans-serif` (macOS/iOS) or **Inter** (non-Apple platforms).
- **Golden Rules:**
  - **Body text is 17px** (never 16px) with line-height 1.47 and letter-spacing `-0.374px`.
  - **Negative letter-spacing** on display sizes (`-0.12px` to `-0.374px`) for the "Apple tight" headline feel.
  - **Weights:** strictly `300` (rare/airy), `400` (regular/body), `600` (semibold/display). **Weight 500 does not exist in this system.**

| Token | Size | Weight | Line Height | Tracking | Purpose |
|---|---|---|---|---|---|
| `hero-display` | 56px | 600 | 1.07 | -0.28px | Hero headlines |
| `display-lg` | 40px | 600 | 1.10 | 0 | Section & tile headlines |
| `display-md` | 34px | 600 | 1.47 | -0.374px | Sub-section heads |
| `lead` | 28px | 400 | 1.14 | +0.196px | Product subcopy |
| `tagline` | 21px | 600 | 1.19 | +0.231px | Sub-tile tagline & sub-nav title |
| `body` | 17px | 400 | 1.47 | -0.374px | Default paragraph text |
| `caption` | 14px | 400 | 1.43 | -0.224px | Captions & utility labels |
| `fine-print` | 12px | 400 | 1.00 | -0.12px | Legal & footer fine-print |

### Radii & Elevation
- **Border Radius:**
  - `rounded.none` (0px): Full-bleed product tiles
  - `rounded.sm` (8px): Dark utility buttons, inner card images
  - `rounded.md` (11px): Pearl button capsules
  - `rounded.lg` (18px): Store utility cards & accessory cards
  - `rounded.pill` (9999px): Primary CTAs, search input, configurator chips
- **Elevation / Shadows:**
  - **Exactly one drop shadow exists in the entire system:** `rgba(0, 0, 0, 0.22) 3px 5px 30px 0` — **only applied to product imagery/renders resting on a surface**.
  - **Never** add shadows to cards, buttons, or text.
  - Elevation is achieved purely via background alternation (`white` ↔ `parchment` ↔ `near-black`) or frosted glass (`backdrop-filter: blur(20px)` at 80% opacity).

---

## 2. Unbreakable Laws (Do's & Don'ts)

### DO:
1. **Single Accent Rule:** Use Action Blue (`#0066cc`) for all primary actions and interactive elements.
2. **Press Micro-interaction:** Apply `transform: scale(0.95)` and transition on active/pressed button states.
3. **Alternating Tiles:** Stack full-bleed tiles (`#ffffff` / `#f5f5f7` ↔ `#272729`) edge-to-edge. The background color change is the divider.
4. **17px Body Text:** Always default body copy to 17px (`SF Pro Text` or `Inter`).
5. **Tight Headline Tracking:** Tighten letter spacing on headers (17px and above) by `-0.01em` to `-0.02em`.
6. **Airy Whitespace:** Provide at least 64px–80px vertical padding per tile section (`spacing.section`).

### DON'T:
1. **No Second Accent:** Never introduce green, orange, purple, or secondary branding colors for UI controls.
2. **No Box Shadows on UI Elements:** No drop shadows on cards, modals, or buttons.
3. **No Decorative Gradients:** Backgrounds are solid tiles or frosted blurs. Depth comes from crisp photography.
4. **No Weight 500:** Use 400 for regular and 600 for semibold.
5. **No Rounded Tiles:** Hero tiles must touch the viewport edges with `0px` radius.

---

## 3. Implementation Workflow

When building or reviewing a UI component or page using this skill:

1. **Check Canvas & Section Rhythm:**
   - Determine whether the section is a **Light Tile** (`#ffffff`), **Parchment Tile** (`#f5f5f7`), or **Dark Tile** (`#272729`).
   - Ensure edge-to-edge full width with 0 gap between consecutive tiles.
2. **Set Typography:**
   - Verify font stack (`SF Pro Display` / `SF Pro Text` / `Inter`).
   - Check body text is set to 17px, line-height ~1.47.
   - Apply negative tracking on headlines.
3. **Style Buttons & CTAs:**
   - Primary action: Full pill (`rounded-full`), `#0066cc`, white text, `scale(0.95)` on active.
   - Secondary action: Ghost pill (transparent, `#0066cc` text & 1px border) or pearl capsule.
4. **Inspect Spacing & Padding:**
   - Section vertical padding: 80px (desktop) scaling down to 48px (mobile).
   - Card internal padding: 24px (`spacing.lg`).
5. **Audit Shadows & Borders:**
   - Remove any `box-shadow` from cards or buttons.
   - Apply product shadow (`rgba(0, 0, 0, 0.22) 3px 5px 30px`) only to transparent product PNG/WebP assets.

---

## 4. Key References & Examples

- **Full Design System Specification:**
  Read the complete verbatim token tables, component definitions, and responsive breakpoints in:
  [references/apple-design-system.md](./references/apple-design-system.md)

- **Tailwind CSS Preset & Component Recipes:**
  Inspect Tailwind CSS utility mappings, Tailwind config snippets, and React component examples in:
  [examples/tailwind-apple-guide.md](./examples/tailwind-apple-guide.md)

