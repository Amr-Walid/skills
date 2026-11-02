---
name: design-direction
description: Process for producing distinctive, high-end UI designs instead of generic "AI-looking" interfaces - define a design direction (mood, references, typography, color, layout, motion), build tokens, design all states, support Arabic/RTL, and self-critique against a quality rubric. Use before designing any landing page, dashboard, admin panel, mobile screen, or design system, and when the user asks for a "strong", "premium", "modern" or "professional" design. Works together with ui-ux-pro-max (data/search) and frontend-design (implementation aesthetics).
---

# Design Direction — Strong, Deliberate Design

Generic output happens when no decisions are made. This skill forces decisions.
Use `design/ui-ux-pro-max` for data-driven palettes/fonts/styles, `design/frontend-design`
for bold implementation, `design/design-system` / `design/design-system-patterns` for tokens,
`design/accessibility-compliance` for WCAG, `design/impeccable` for critique/polish/audit commands,
`design/arabic-typography` + `design/latin-typography` for type, `animation/motion-system` for motion,
and `performance/performance-engineering` so the design stays fast.

## Step 1 — Brief (5 lines max)

- Product & audience (e.g. "ERP for Egyptian SMEs; accountants 30–55; desktop-first").
- Primary job of this screen (one sentence).
- Brand personality — pick 3 adjectives (e.g. *trustworthy, calm, precise*).
- Constraints: languages (Arabic RTL + English?), light/dark, devices, stack (Tailwind/shadcn/Blazor/MudBlazor…).
- What to **avoid** (e.g. "no purple gradients, no glassmorphism, no stock 3D blobs").

## Step 2 — Choose a direction (commit to ONE)

| Direction | Feels | Good for |
|-----------|-------|----------|
| Swiss / Editorial | precise, typographic, grid-strict | SaaS marketing, docs, finance |
| Soft Modern | rounded, airy, subtle shadows | consumer apps, health, education |
| Data-Dense Pro | compact, high information density, neutral | ERPs, dashboards, admin, trading |
| Bold Brutalist | high contrast, big type, raw | creative brands, portfolios |
| Luxury Minimal | lots of space, serif headings, muted palette | premium products, real estate |
| Warm Organic | natural tones, textures, friendly type | food, local business, community |
| Dark Technical | dark surfaces, neon accents, mono type | dev tools, AI, security |

Run: `python <ui-ux-pro-max-dir>/scripts/search.py "<product> <industry> <adjectives>" --design-system -p "<Name>"`
and adapt the result to the chosen direction — don't accept it blindly.

## Step 3 — Tokens (decide numbers, not vibes)

- **Type scale**: one display/heading family + one text family (max 2). Ratio 1.2–1.333.
  Arabic pairing examples: *IBM Plex Sans Arabic*, *Cairo*, *Tajawal*, *Noto Kufi Arabic* (headings), *Noto Naskh Arabic* (long reading). Latin: *Inter*, *Geist*, *Manrope*, *IBM Plex Sans*, serif *Fraunces*/*Playfair* for luxury.
  Arabic needs ~10–15% larger size and more line-height (1.6–1.8) than Latin.
- **Color**: 1 brand primary + 1 accent max; neutral ramp (50–950); semantic success/warning/danger/info. Check contrast ≥ 4.5:1 for text, 3:1 for UI.
  60-30-10 rule: neutrals 60, surfaces/secondary 30, brand/accent 10.
- **Spacing**: 4/8-pt scale (4, 8, 12, 16, 24, 32, 48, 64, 96).
- **Radius**: pick one personality (0–2px sharp, 6–8px balanced, 12–16px soft) and apply consistently.
- **Elevation**: 2–3 shadow levels max; prefer borders + subtle shadow over heavy shadows.
- **Motion**: 150–250ms, ease-out for entering; respect `prefers-reduced-motion`.

Express tokens as CSS variables / Tailwind theme so they're reusable.

## Step 4 — Layout & hierarchy

- One clear focal point per screen; the primary action is visually dominant, secondary actions are quiet.
- Grid: 12 columns desktop, 4 mobile; consistent max content width (e.g. 1200–1280px).
- Use whitespace to group (proximity) before using borders/boxes.
- Dashboards: KPIs top (3–5 max), then trends, then detail tables; filters persistent and visible.
- Tables: right-align numbers (left in RTL context depends — numbers stay LTR), sticky header, zebra or row hover, density toggle, empty state.
- Forms: single column, labels above fields, inline validation, clear required markers, logical grouping.

## Step 5 — Every state, not just the happy path

For each component/screen design: default, hover, focus-visible, active, disabled, loading (skeletons), empty (with a call to action), error (with recovery), success, permission denied, offline, very long text, very many items, RTL.

## Step 6 — Arabic / RTL checklist

- `dir="rtl"` + `lang="ar"` on the root; use **logical CSS properties** (`margin-inline-start`, `ps-4`/`pe-4` in Tailwind, `start`/`end`).
- Mirror directional icons (arrows, chevrons, back), **don't** mirror logos, media controls, checkmarks, clocks.
- Numbers, code, emails, phone numbers stay LTR inside RTL text (`<bdi>` / `dir="ltr"`).
- Decide Arabic-Indic (٠١٢) vs Western (012) digits per audience and keep consistent.
- Test truncation and line-height with real Arabic copy, not lorem ipsum.

## Step 7 — Make it distinctive (pick at least 2)

- A signature typographic moment (oversized heading, unusual weight contrast).
- A consistent graphic motif (grid lines, geometric pattern inspired by local/Islamic geometry, custom illustration style).
- Purposeful micro-interactions (number count-up on KPIs, smooth tab indicator).
- Real content and data in mockups (realistic names, Egyptian pound amounts, Arabic text).
- Thoughtful empty states and onboarding.

Avoid AI-cliché tells: purple-blue gradients everywhere, random glassmorphism, emoji as icons,
centered everything, identical card grids, meaningless 3D blobs, inconsistent radii, too many colors.

## Step 8 — Self-critique rubric (score 1–5, iterate until all ≥ 4)

1. **Hierarchy** — can you tell the primary action in 3 seconds?
2. **Consistency** — spacing, radius, type, colors all from tokens?
3. **Clarity** — labels and copy unambiguous? jargon removed?
4. **Accessibility** — contrast, focus states, keyboard, alt text, touch targets ≥ 44px?
5. **Distinctiveness** — would someone recognize this product without the logo?
6. **Completeness** — all states designed? RTL verified? responsive?
7. **Polish** — alignment, optical balance, no orphan words, icons same family/weight?

Report the scores and what you changed. Take a screenshot (Playwright, see `testing/webapp-testing`) and review it visually before declaring done.
