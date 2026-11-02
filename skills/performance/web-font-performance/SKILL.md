---
name: web-font-performance
description: Load web and app fonts fast without layout shift or invisible text - WOFF2, subsetting (including Arabic with shaping features preserved), unicode-range splitting, self-hosting vs Google Fonts, preload rules, font-display strategy, fallback metric overrides (size-adjust, ascent-override) to kill CLS, variable vs static trade-offs, next/font and Flutter/mobile font bundling. Use when adding custom fonts, when Lighthouse flags fonts, when text flashes/shifts on load, or when Arabic fonts are heavy.
---

# Web Font Performance

Fonts are often the 2nd-largest render-blocking resource after CSS and a top cause of
CLS. Target: **≤ 2 families, ≤ 4 font files on first load, ≤ ~100 KB total WOFF2 for
critical fonts, zero font-caused CLS.**

## 1. Format & hosting

- **WOFF2 only** (universal support). Drop TTF/WOFF/EOT fallbacks.
- **Self-host** on your own domain/CDN with
  `Cache-Control: public, max-age=31536000, immutable` and hashed filenames.
  Browser cache is partitioned per site, so a third-party Google Fonts cache hit no
  longer helps; self-hosting removes 1–2 extra connections.
- If you must use Google Fonts CSS: add `<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>`
  and request only the weights you use with `&display=swap`.

## 2. Subset aggressively

Ship only the glyphs you need. With `fonttools`:

```bash
pip install fonttools brotli
# Latin
pyftsubset Inter.ttf --output-file=inter-latin.woff2 --flavor=woff2 \
  --unicodes="U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+2000-206F,U+20AC,U+2122,U+2212" \
  --layout-features='*' --no-hinting
# Arabic — KEEP all layout features or letters won't join/position correctly
pyftsubset IBMPlexSansArabic-Regular.ttf --output-file=plex-ar-400.woff2 --flavor=woff2 \
  --unicodes="U+0600-06FF,U+0750-077F,U+0870-089F,U+08A0-08FF,U+FB50-FDFF,U+FE70-FEFF,U+200C-200F,U+0020-0040" \
  --layout-features='*' --no-hinting
```

- `--layout-features='*'` is mandatory for Arabic (`init medi fina isol rlig calt
  liga mark mkmk ccmp`). Removing them produces disconnected letters.
- Remove diacritic ranges only if you are 100% sure content never uses tashkeel.
- Verify the output by rendering a test page with real text after subsetting.

## 3. Split by script with `unicode-range`

The browser downloads a face only if the page contains characters in its range, so an
English page never downloads the Arabic file:

```css
@font-face {
  font-family: "Brand"; font-weight: 100 900; font-style: normal; font-display: swap;
  src: url("/fonts/brand-arabic.var.woff2") format("woff2");
  unicode-range: U+0600-06FF, U+0750-077F, U+0870-089F, U+08A0-08FF, U+FB50-FDFF, U+FE70-FEFF;
}
@font-face {
  font-family: "Brand"; font-weight: 100 900; font-style: normal; font-display: swap;
  src: url("/fonts/brand-latin.var.woff2") format("woff2");
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+2000-206F, U+20AC, U+2122;
}
```

## 4. Preload only what renders above the fold

```html
<link rel="preload" href="/fonts/brand-latin.var.woff2" as="font" type="font/woff2" crossorigin>
```

- `crossorigin` is required even for same-origin fonts, or it double-downloads.
- Preload **1–2 files max** (the body face of the page's primary script). Preloading
  everything competes with the LCP image and CSS.
- For Arabic-first pages, preload the Arabic file, not the Latin one.

## 5. `font-display` strategy

| Value | Use for |
|-------|---------|
| `swap` | Body/brand text that must eventually show the custom face. Pair with metric overrides to avoid CLS. |
| `optional` | Non-critical or decorative faces; on slow networks the fallback stays → zero CLS. Great for performance-first pages. |
| `fallback` | Middle ground (short block, short swap window). |
| `block` | Icon fonts only (and prefer SVG icons over icon fonts). |

## 6. Kill layout shift with fallback metrics

Make the fallback system font occupy the same space as the web font:

```css
@font-face {
  font-family: "Brand Fallback";
  src: local("Arial");
  size-adjust: 107%;
  ascent-override: 90%;
  descent-override: 22%;
  line-gap-override: 0%;
}
body { font-family: "Brand", "Brand Fallback", system-ui, sans-serif; }
```

Compute the numbers instead of guessing: **next/font** (does it automatically),
**fontaine** (Vite/Nuxt/Webpack), **Capsize**, or `@capsizecss/metrics`. For Arabic,
use a local Arabic fallback (`local("Segoe UI")`, `local("Geeza Pro")`, `local("Noto Sans Arabic")`)
and tune similarly.

## 7. Variable vs static

- Variable wins when you use **≥ 3 weights/widths** of one family (1 request).
- Static wins when you need **1–2 weights** (each static file is usually smaller than
  the full variable file). Measure both after subsetting.
- Italics: separate file — load only if the design uses them.

## 8. Framework specifics

- **Next.js**: `next/font/local` or `next/font/google` (self-hosts at build, adds
  fallback metrics, `display: 'swap'`, `subsets: ['latin', 'arabic']`, `variable: '--font-sans'`).
- **Vite/Astro/Nuxt**: `@fontsource-variable/<name>` packages or `fontaine` / `unplugin-fonts`.
- **Tailwind**: register the CSS variable in `@theme { --font-sans: var(--font-brand), … }`.
- **Icon fonts** → replace with inline SVG / sprite (smaller, no FOIT, accessible).

## 9. Mobile apps

- **Flutter**: bundle fonts in `pubspec.yaml`; in production disable runtime fetching
  (`GoogleFonts.config.allowRuntimeFetching = false`) and ship the files. Pre-cache with
  `GoogleFonts.pendingFonts([...])` if you use the package. Only include weights you use.
  Release builds tree-shake Material icons automatically — keep it on.
  **Flutter Web**: bundle an Arabic font, otherwise the engine fetches fallback Noto
  fonts from the network on first Arabic glyph (slow + flash).
- **Android**: `res/font` or Downloadable Fonts (shared cache via Google Play services);
  avoid shipping 10 static weights — use a variable font (API 26+).
- **iOS**: add only used weights to the bundle; system SF fonts cost nothing.

## 10. Verify

- DevTools → Network → Font: count files and bytes on first load.
- Lighthouse: "Ensure text remains visible during webfont load", "Avoid layout shifts".
- Performance panel: check font requests don't delay LCP; Layout Shift regions on swap.
- Throttle to "Slow 4G" and watch the first paint with real Arabic/English content.
