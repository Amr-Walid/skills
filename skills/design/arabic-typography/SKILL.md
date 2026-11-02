---
name: arabic-typography
description: Choose, pair, size and render Arabic fonts correctly and beautifully on web, Flutter, Android and iOS - curated Arabic font catalog by use case (UI, reading, display, bilingual), Arabic+Latin pairing, line-height, weights, numerals (Arabic-Indic vs Western), RTL/bidi, diacritics, and the rules that break Arabic shaping (letter-spacing, italics, uppercase). Use whenever a UI, document, landing page or app contains Arabic text, is bilingual Arabic/English, or the user asks for Arabic fonts, RTL, or "خط عربي".
---

# Arabic Typography

Arabic is a connected, cursive script with contextual letter forms, ligatures and
diacritics. Most "ugly Arabic UI" comes from treating it like Latin. This skill
gives defaults that are safe, then the levers to make it distinctive.

Pair with: `design/latin-typography` (English side), `performance/web-font-performance`
(loading/subsetting), `design/design-direction` (overall direction).

## 1. Pick the font by job, not by habit

All fonts below are free (SIL OFL) on Google Fonts unless noted. Verify the license
before shipping any font not in this list.

| Job | Strong choices | Notes |
|-----|---------------|-------|
| **Product UI / dashboards** (dense, small sizes) | **IBM Plex Sans Arabic**, **Noto Sans Arabic**, **Vazirmatn**, **Readex Pro** | Open counters, legible at 12–14px. Plex & Readex ship matching Latin. |
| **Friendly consumer apps** | **Tajawal**, **Almarai**, **Alexandria**, **Rubik** (Arabic subset) | Geometric/rounded feel. Almarai has few weights (300/400/700/800). |
| **Marketing / bold headings** | **Cairo** (variable 200–1000), **Changa**, **Alexandria**, **El Messiri**, **Reem Kufi** | Kufi-flavoured, strong at large sizes. Cairo is everywhere — choose it deliberately, not by default. |
| **Long reading** (articles, books, legal) | **Noto Naskh Arabic**, **Amiri**, **Scheherazade New** | Naskh is the reading style Arabic readers learned in school. Amiri = classical/book. |
| **Display / personality** | **Aref Ruqaa** (Ruqaa), **Lalezar**, **Rakkas**, **Marhey**, **Lemonada**, **Kufam** | Headlines and logos only, never body text. |
| **Quran / religious text** | **Amiri Quran**, **Scheherazade New** | Need full diacritics support and generous line-height. |
| **System (zero download)** | iOS/macOS: SF Arabic · Android: Noto Naskh/Sans Arabic · Windows: Segoe UI / Sakkal Majalla | Good fallback; use when performance > personality. |

Commercial/regional options worth knowing (license required): Dubai Font (free with
license terms), 29LT, GE SS, Thmanyah-style custom fonts. Never ship a font you can't
license.

**Decision rule:** one Arabic family for UI + optionally one for display. Max 2 Arabic
families per product.

## 2. Bilingual pairing (Arabic + English)

Arabic glyphs look ~10–20% smaller than Latin at the same `font-size` (lower x-height
equivalent), and stroke contrast differs. Options, best first:

1. **One superfamily that covers both scripts** — IBM Plex Sans Arabic + IBM Plex Sans,
   Noto Sans Arabic + Noto Sans, Readex Pro (both scripts in one file), Cairo, Tajawal.
   Most consistent result.
2. **Composite family via `unicode-range`** — declare the Arabic font and the Latin
   font under the *same* `font-family` name so each script gets its best font:

```css
@font-face { font-family: "Brand"; src: url(/f/plex-arabic-400.woff2) format("woff2");
  font-weight: 400; font-display: swap;
  unicode-range: U+0600-06FF, U+0750-077F, U+0870-089F, U+08A0-08FF, U+FB50-FDFF, U+FE70-FEFF, U+200C-200F; }
@font-face { font-family: "Brand"; src: url(/f/inter-400.woff2) format("woff2");
  font-weight: 400; font-display: swap;
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+2000-206F, U+20AC, U+2122; }
body { font-family: "Brand", system-ui, sans-serif; }
```

3. **Match visually** — if fonts differ, tune with `size-adjust` on the Latin
   `@font-face` (e.g. `size-adjust: 92%`) so mixed lines look even. Check a real
   sentence like: «تم دفع 1,250 ج.م عبر Visa بتاريخ 12/03».

Pair by *structure*: geometric Arabic (Tajawal, Alexandria) ↔ geometric Latin
(Manrope, Outfit); humanist Arabic (Plex, Noto) ↔ humanist Latin (Plex Sans, Source
Sans); Naskh reading ↔ serif Latin (Source Serif, Literata).

## 3. Size, line-height, weight

| Token | Latin | Arabic |
|------|-------|--------|
| Body size (web) | 16px | **16–18px** (never below 14px for UI text) |
| Body line-height | 1.5 | **1.7–1.9** (Naskh with diacritics: up to 2.0) |
| Heading line-height | 1.1–1.25 | **1.3–1.5** (tall ascenders/descenders, dots) |
| Max line length | 60–75ch | **50–70ch** |
| Bold | 700 | Often **600** is enough — Arabic bold reads heavier |

Use separate tokens if the product is bilingual:

```css
:root { --lh-body: 1.55; --lh-heading: 1.2; }
:root:lang(ar) { --lh-body: 1.8; --lh-heading: 1.4; font-size: 106.25%; }
```

## 4. Hard rules — these break Arabic

- **Never `letter-spacing`** on Arabic text (disconnects letters). Reset it:
  `:lang(ar) { letter-spacing: 0 !important; }` — check Tailwind `tracking-*` classes.
- **No `text-transform: uppercase`**, no small-caps — Arabic has no case. Emphasis =
  weight, color, or size.
- **No synthetic italic.** Arabic has no italic tradition; `font-style: italic` produces
  a slanted mess. Use weight or a contrasting family for quotes/emphasis.
- **Don't break words with `word-break: break-all`** — it cuts connected letters.
  Use `overflow-wrap: anywhere` only for URLs/codes.
- **Justified text:** browsers don't do kashida (ـ) stretching well; prefer
  `text-align: start`. If you justify, test real paragraphs.
- **Never put Arabic in images/SVG text** without outlining or embedding the font;
  shaping often fails in renderers.
- **Underlines** collide with dots/descenders: `text-underline-offset: 0.3em;
  text-decoration-skip-ink: auto;`
- **Font must support shaping features** (`init medi fina isol rlig calt mark mkmk`).
  When subsetting, keep all layout features (see `web-font-performance`).

## 5. Numbers, dates, currency

- Decide per audience and keep it consistent across the whole product:
  - Egypt/Gulf consumer apps often use **Arabic-Indic digits ٠١٢٣** in prose; finance,
    dashboards, tables, codes, phone numbers usually use **Western digits 0123**.
- Format with locale APIs, never by string replace:

```js
new Intl.NumberFormat("ar-EG").format(1250.5)            // "١٬٢٥٠٫٥"
new Intl.NumberFormat("ar-EG-u-nu-latn").format(1250.5)  // "1,250.5"
new Intl.NumberFormat("ar-EG", { style: "currency", currency: "EGP" }).format(99)
new Intl.DateTimeFormat("ar-EG", { dateStyle: "long" }).format(new Date())
```

- Tables/KPIs: `font-variant-numeric: tabular-nums;` so digits align.
- Phone numbers, IBANs, codes, emails, URLs stay **LTR** inside RTL text: wrap with
  `<bdi>` or `<span dir="ltr">`.

## 6. RTL & bidi essentials

- Root: `<html lang="ar" dir="rtl">`. User-generated content: `dir="auto"`.
- Layout with **logical properties** only: `margin-inline-start`, `padding-inline`,
  `inset-inline-end`, `text-align: start`, `border-start-start-radius`.
  Tailwind: `ms-* me-* ps-* pe-* start-* end-* text-start rtl:` variant.
- Mirror directional icons (back/forward arrows, chevrons, progress, "reply");
  **don't** mirror logos, play/pause, checkmarks, clocks, charts' time axis decisions
  without thinking, or brand marks.
- Mixed-direction strings: `unicode-bidi: isolate` (or `<bdi>`) around inserted values
  so punctuation doesn't jump: `تم إرسال <bdi>{{email}}</bdi> بنجاح`.
- Inputs: `dir="auto"` on text inputs; force `dir="ltr"` on email, phone, password,
  URL, code inputs.
- Test with real Arabic copy, long words, diacritics (تَشْكِيل), and mixed English.

## 7. Platform recipes

**Flutter**

```dart
MaterialApp(
  locale: const Locale('ar', 'EG'),
  supportedLocales: const [Locale('ar', 'EG'), Locale('en')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates, // + AppLocalizations.delegate
  theme: ThemeData(
    fontFamily: 'IBMPlexSansArabic',                 // bundled in pubspec.yaml fonts:
    fontFamilyFallback: const ['NotoSansArabic'],
    textTheme: base.textTheme.apply(heightFactor: 1.15), // or set height per style
  ),
);
// Layout: EdgeInsetsDirectional, AlignmentDirectional, PositionedDirectional,
// Icon(Icons.arrow_back, matchTextDirection: true) is NOT automatic for all icons — check.
// Numbers: NumberFormat.decimalPattern('ar_EG') from package:intl.
```

Bundle fonts as assets in production (don't rely on runtime `google_fonts` fetching —
set `GoogleFonts.config.allowRuntimeFetching = false` and ship the files).

**Android (Compose / Views)**

- `android:supportsRtl="true"` in the manifest; use `start/end`, never `left/right`.
- Fonts in `res/font/` (or Downloadable Fonts); `FontFamily(Font(R.font.plex_arabic_regular), ...)`.
- Compose: layout follows `LocalLayoutDirection`; use `Modifier.padding(start=…)`;
  `Icons.AutoMirrored.*` for directional icons.
- Line height: `TextStyle(lineHeight = 1.7.em)` and
  `LineHeightStyle(alignment = LineHeightStyle.Alignment.Center, trim = None)` for Arabic.

**iOS (SwiftUI / UIKit)**

- Add fonts to target + `UIAppFonts` in Info.plist. Use
  `Font.custom("IBMPlexSansArabic-Regular", size: 17, relativeTo: .body)` so
  **Dynamic Type still scales**.
- Layout uses `leading/trailing` automatically; `.flipsForRightToLeftLayoutDirection(true)`
  for custom directional images; preview with `.environment(\.layoutDirection, .rightToLeft)`
  and `.environment(\.locale, Locale(identifier: "ar"))`.
- System font (SF Arabic) is excellent — custom font only if the brand needs it.

## 8. Make it distinctive (optional, deliberate)

- A **Kufi or Ruqaa display headline** over a clean Naskh/Sans body creates instant
  identity without hurting legibility.
- Use weight contrast (300 body vs 800 headline in Cairo/Alexandria) instead of colors.
- Geometric motifs inspired by Islamic patterns as *structure* (grids, dividers),
  not wallpaper.
- Large Arabic numerals (٢٠٢٦) as a hero element when the audience reads them.

## 9. QA checklist

- [ ] Real Arabic copy (no lorem ipsum), with diacritics and mixed English/numbers.
- [ ] No letter-spacing/uppercase/italic applied to Arabic (search CSS + Tailwind classes).
- [ ] Line-height ≥ 1.7 for body; headings don't clip dots or descenders.
- [ ] Digits policy consistent; numbers/codes isolated LTR.
- [ ] Icons mirrored correctly; layout uses logical properties.
- [ ] Font files include Arabic shaping features; fallback font declared.
- [ ] Tested on iOS Safari, Android Chrome, desktop Chrome/Firefox, and in the native apps.
- [ ] Contrast ≥ 4.5:1 — thin Arabic weights (200/300) fail contrast faster than Latin.
