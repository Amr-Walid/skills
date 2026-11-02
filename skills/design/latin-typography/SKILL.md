---
name: latin-typography
description: Professional English/Latin typography for web and apps - curated typeface catalog by personality (sans, serif, mono, display, variable), deliberate pairing, modular and fluid type scales with clamp(), line-height and measure, tracking, OpenType features (tabular numbers, stylistic sets), text-wrap balance/pretty, variable font axes, and type tokens for Tailwind, Flutter, Compose and SwiftUI. Use when choosing fonts, building a type scale or design tokens, when text looks generic or "AI-made", or when the user asks for strong or premium typography.
---

# Latin Typography

Typography carries most of a design's personality. The goal: **a deliberate face, a
clear scale, disciplined spacing**. For Arabic use `design/arabic-typography`; for
loading use `performance/web-font-performance`.

## 1. Choose by personality (not "Inter because it's safe")

Free = Google Fonts (OFL) unless marked *Fontshare* (free, ITF license) or *paid*.

| Personality | Sans | Serif | Notes |
|-------------|------|-------|-------|
| Precise / technical | **Geist**, **IBM Plex Sans**, **Inter** (opsz axis), **Instrument Sans** | IBM Plex Serif | Inter is fine for dense UI — but it's the default tell for marketing pages. |
| Warm / friendly | **Figtree**, **DM Sans**, **Nunito Sans**, **Onest** | **Literata**, **Lora** | Rounder terminals, open apertures. |
| Confident / modern brand | **Manrope**, **Plus Jakarta Sans**, **Satoshi** *(Fontshare)*, **General Sans** *(Fontshare)* | **Newsreader**, **Source Serif 4** | Good marketing headline faces. |
| Editorial / luxury | **Instrument Sans** (body) | **Fraunces** (variable: SOFT/WONK axes), **Playfair Display**, **Cormorant**, **EB Garamond**, **Instrument Serif** | High-contrast serifs need ≥ 32px to shine. |
| Bold / expressive display | **Bricolage Grotesque**, **Space Grotesk**, **Syne**, **Unbounded**, **Archivo** (width axis), **Clash Display** *(Fontshare)* | — | Headlines only; pair with a quiet text face. |
| Code / data | **JetBrains Mono**, **Geist Mono**, **IBM Plex Mono**, Berkeley Mono *(paid)* | — | Use mono for code, not as decoration for labels. |
| Zero-download | `system-ui, -apple-system, "Segoe UI", Roboto, sans-serif` | `ui-serif, Georgia, serif` | Fastest possible; great for apps and admin tools. |

Rules:
- **1 family** (with weights) is often enough. **2 max**: display + text. They must
  differ clearly (serif vs sans, or wide grotesque vs humanist).
- Prefer **variable fonts** when you need ≥ 3 weights (one file, smooth weights).
- Check language coverage (Latin Extended, Vietnamese, Cyrillic) if needed.

## 2. Type scale

Pick a ratio by density:

| Ratio | Use |
|-------|-----|
| 1.125–1.2 | dashboards, data-dense apps, mobile |
| 1.25 (major third) | most products |
| 1.333–1.5 | marketing, editorial, expressive heroes |

Fluid sizes with `clamp()` (min at 360px viewport, max at ~1280px):

```css
:root {
  --step--1: clamp(0.83rem, 0.80rem + 0.15vw, 0.94rem);
  --step-0:  clamp(1.00rem, 0.96rem + 0.20vw, 1.13rem);  /* body */
  --step-1:  clamp(1.25rem, 1.16rem + 0.45vw, 1.50rem);
  --step-2:  clamp(1.56rem, 1.39rem + 0.85vw, 2.00rem);
  --step-3:  clamp(1.95rem, 1.65rem + 1.50vw, 2.67rem);
  --step-4:  clamp(2.44rem, 1.93rem + 2.55vw, 3.55rem);
  --step-5:  clamp(3.05rem, 2.20rem + 4.25vw, 4.74rem);  /* hero */
}
```

Generate exact values with utopia.fyi; don't eyeball. Always keep `rem` (respects
user zoom/accessibility settings).

## 3. Spacing inside text

| Property | Body | Headings | Display (≥ 48px) | Small caps/labels |
|---------|------|----------|------------------|-------------------|
| line-height | 1.5–1.65 | 1.1–1.25 | 0.95–1.1 | 1.3 |
| letter-spacing | 0 | -0.01em | -0.02 to -0.04em | +0.02 to +0.06em |
| measure | 60–75ch (`max-width: 68ch`) | 15–25ch | — | — |

- Serif body: slightly more line-height than sans.
- Paragraph spacing ≈ 0.75–1× line-height; no first-line indent *and* gap together.
- Light text on dark: increase weight slightly or line-height; thin weights vanish.

## 4. Modern CSS typography features

```css
h1, h2, h3 { text-wrap: balance; }          /* even heading lines */
p, li      { text-wrap: pretty; }           /* avoid orphans */
.num, td   { font-variant-numeric: tabular-nums; }   /* aligned digits */
.price     { font-variant-numeric: lining-nums tabular-nums; }
body       { font-optical-sizing: auto; font-kerning: normal;
             -webkit-font-smoothing: antialiased; text-rendering: optimizeLegibility; }
.inter     { font-feature-settings: "cv11", "ss01"; } /* stylistic alternates — font-specific */
abbr, .caps{ font-variant-caps: all-small-caps; letter-spacing: 0.04em; }
```

Variable axes: `font-variation-settings: "wght" 650, "opsz" 32;` — prefer the
high-level properties (`font-weight`, `font-stretch`, `font-optical-sizing`) when they exist.

## 5. Hierarchy without noise

- Contrast by **size + weight** first, then color. Avoid more than 3 text colors
  (primary, secondary, disabled/tertiary).
- Avoid generic tells (see `frontend-design`): ALL-CAPS tracked eyebrows over every
  heading, a single highlighted word in each headline, mono labels as decoration.
- Weights: pick 2–3 (e.g. 400, 500/600, 700). More = mush.
- Links: underline in body text (`text-underline-offset: 0.2em`), not just color.

## 6. Tokens per platform

**Tailwind v4** (`@theme`):

```css
@theme {
  --font-sans: "Geist", system-ui, sans-serif;
  --font-display: "Fraunces", ui-serif, serif;
  --text-base: 1rem;  --text-base--line-height: 1.6;
  --text-5xl: 3.05rem; --text-5xl--line-height: 1.05; --text-5xl--letter-spacing: -0.03em;
}
```

**Flutter**: define a full `TextTheme` (displayLarge…labelSmall) with `height` and
`letterSpacing` set explicitly; expose brand-only styles via `ThemeExtension`.
**Compose**: `Typography(displayLarge = TextStyle(fontFamily = Brand, fontSize = 57.sp,
lineHeight = 64.sp, letterSpacing = (-0.25).sp), …)` — M3 type roles.
**SwiftUI**: prefer system text styles (`.largeTitle`…`.caption2`) for Dynamic Type;
custom fonts via `Font.custom(name, size:, relativeTo:)`.

## 7. QA checklist

- [ ] Typeface chosen for the brief's personality, with a one-line reason.
- [ ] ≤ 2 families, ≤ 3–4 weights actually loaded.
- [ ] Scale defined as tokens; no random font sizes in components.
- [ ] Body ≥ 16px web / 17pt iOS / 16sp Android; measure ≤ 75ch.
- [ ] Display text has negative tracking; small labels have positive tracking.
- [ ] Numbers in tables/KPIs are tabular.
- [ ] Zoom to 200% and OS large-text settings don't break layout.
- [ ] Fonts are subset/preloaded per `web-font-performance`; no layout shift on swap.
