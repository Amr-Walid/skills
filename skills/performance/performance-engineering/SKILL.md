---
name: performance-engineering
description: End-to-end performance playbook for web sites, web apps, APIs and mobile apps - performance budgets, measure-first workflow (lab + field/RUM), Core Web Vitals targets (LCP, INP, CLS), critical rendering path, images/fonts/JS/CSS optimization, caching and CDN headers, backend/API latency (N+1, indexes, caching, compression), and mobile app startup, jank, memory and app size for Flutter, Android and iOS. Use when a site or app is slow, before launch, when setting budgets, when Lighthouse/PageSpeed scores are low, or when the user asks for performance, speed, "اداء" or optimization. Routes to the specialized performance skills.
---

# Performance Engineering

**Rule zero: measure → find the bottleneck → fix the biggest one → measure again.**
Never optimize from intuition, and never claim an improvement without before/after numbers.

Specialized skills: `performance/web-quality-audit`, `core-web-vitals`, `web-performance`,
`web-font-performance`, `vercel-react-best-practices`, `react-component-performance`,
`animation/animation-performance`, `flutter/flutter-pre-caching`,
`android/jetpack-compose-performance`, `android/android-profiler`, `android/anr-audit-and-fix`,
`android/r8-analyzer`, `ios/swiftui-performance-audit`, `database/sql-optimization-patterns`,
`dotnet/analyzing-dotnet-performance`.

## 1. Budgets (agree before building)

**Web (p75, mobile, field data)**

| Metric | Good | Budget to set |
|-------|------|---------------|
| LCP | ≤ 2.5s | ≤ 2.0s |
| INP | ≤ 200ms | ≤ 150ms |
| CLS | ≤ 0.1 | ≤ 0.05 |
| TTFB | ≤ 0.8s | ≤ 0.5s (HTML) |
| JS (compressed) on initial route | — | ≤ 150–200 KB (marketing ≤ 100 KB) |
| CSS critical | — | ≤ 50 KB |
| Fonts first load | — | ≤ 2–4 files, ≤ 100 KB |
| Hero image | — | ≤ 150–200 KB (AVIF/WebP) |

**API**: p95 latency ≤ 200ms for reads, ≤ 500ms for writes; payload ≤ 100 KB per list page.

**Mobile apps**

| Metric | Target |
|-------|--------|
| Cold start to first frame | Android ≤ 1.0–1.5s on mid-range; iOS ≤ 400ms to first frame (Apple guidance) |
| Frame rendering | 0 janky frames in core flows (16.6ms @60Hz, 8.3ms @120Hz) |
| ANR / hangs | Android ANR rate < 0.47% (Play bad-behavior threshold); iOS hangs > 250ms investigated |
| Crash-free users | ≥ 99.5% |
| Download size | Flutter/Android ≤ 20–30 MB per ABI; keep below cellular limits |
| Memory | no unbounded growth over a 10-minute session |

Put budgets in CI (Lighthouse CI `budgets.json`, `size-limit`, bundle analyzer, app-size reports).

## 2. Measure

| Layer | Lab | Field |
|------|-----|-------|
| Web | Chrome DevTools Performance panel (with CPU 4× + Slow 4G), Lighthouse, WebPageTest | CrUX / PageSpeed Insights, `web-vitals` library → analytics (RUM) |
| React | React DevTools Profiler, `why-did-you-render` | INP attribution via `web-vitals/attribution` |
| API | k6 / autocannon / bombardier load tests, APM traces (OpenTelemetry) | APM p50/p95/p99 dashboards |
| DB | `EXPLAIN (ANALYZE)` / actual execution plans, Query Store | slow-query log |
| Flutter | DevTools Performance + CPU profiler + Memory, **profile mode** on a real device | Firebase Performance, Crashlytics |
| Android | Android Studio Profiler, Perfetto, Macrobenchmark, Baseline Profiles | Play Console Android vitals |
| iOS | Instruments (Time Profiler, SwiftUI, Hangs, Allocations, App Launch) | Xcode Organizer metrics, MetricKit |

Always test on **mid/low-end hardware** (e.g. a ~$150 Android phone), not only a flagship or M-series Mac.

## 3. Web: the high-impact fixes (in order)

1. **LCP element**: identify it. If it's an image: serve AVIF/WebP, correct size via
   `srcset`/`sizes`, `fetchpriority="high"`, **never `loading="lazy"`** on it, preload if
   it's a CSS background. If it's text: fix font loading (`web-font-performance`).
2. **TTFB**: CDN for HTML (SSG/ISR/edge cache), `stale-while-revalidate`, avoid
   server waterfalls (parallelize data fetching), HTTP/2+/3, Brotli.
3. **Render-blocking**: inline critical CSS, `defer`/`type="module"` scripts, remove
   unused CSS (Tailwind purges by default), no sync third-party tags in `<head>`.
4. **JavaScript cost** (INP): code-split by route, lazy-load below-the-fold widgets
   (`import()`, `React.lazy`, `next/dynamic`), remove heavy deps (moment → date-fns/Intl,
   lodash → native), avoid hydrating static content (Server Components / islands),
   break long tasks (`scheduler.yield()` / `setTimeout` chunks), debounce input handlers,
   virtualize long lists (TanStack Virtual).
5. **CLS**: `width`/`height` or `aspect-ratio` on every image/video/iframe/ad slot,
   reserve space for banners/embeds, font fallback metrics, no content inserted above
   existing content after load (except in response to user input).
6. **Images**: responsive `srcset`, lazy-load below the fold, `decoding="async"`,
   image CDN (Cloudflare Images, imgix, Next `<Image>`), SVG for icons/illustrations.
7. **Third parties**: audit every tag; load analytics/chat after interaction or idle,
   use `Partytown` or server-side tagging; facade embeds (YouTube lite-embed).
8. **Caching headers**:
   - Hashed static assets: `Cache-Control: public, max-age=31536000, immutable`
   - HTML: `Cache-Control: no-cache` (or `s-maxage=60, stale-while-revalidate=600` at CDN)
   - API GETs: `ETag` + `Cache-Control: private, max-age=0, must-revalidate` or short `max-age`
9. **Navigation**: `<link rel="preconnect">` for critical origins, Speculation Rules
   (`prerender` likely next pages), bfcache-friendly pages (no `unload` handlers).

## 4. Backend / API

- Kill **N+1** queries (eager load / batch / DataLoader); project only needed columns.
- Index for the actual query predicates + sort; check plans, not guesses.
- Paginate (keyset for large tables), cap page sizes.
- Cache: in-memory (short TTL) → distributed (Redis) → HTTP/CDN; define invalidation.
- Compress responses (Brotli/gzip), avoid huge JSON — trim fields, use DTOs.
- Async I/O everywhere; no sync-over-async; connection pooling; timeouts on all outbound calls.
- Move slow work to background jobs/queues; return 202 + status endpoint.
- Rate limit & bulkhead to protect latency under load.

## 5. Mobile apps

**Startup**
- Defer non-critical init (analytics, remote config, SDKs) until after first frame.
- Android: Baseline Profiles + Startup Profiles, App Startup library, avoid heavy
  `Application.onCreate`, R8 full mode (`r8-analyzer`), splash via SplashScreen API.
- iOS: reduce dylibs/static initializers, lazy-load frameworks, avoid main-thread I/O at launch.
- Flutter: keep `main()` light, lazy-load features (deferred imports on web/Android),
  pre-cache only the first screen's images/fonts (`flutter-pre-caching`), consider
  shader warm-up only if on legacy renderer (Impeller removes most shader jank).

**Smoothness**
- Never do I/O, JSON parsing of large payloads, or image decoding on the UI thread:
  Flutter `compute()`/`Isolate.run`, Kotlin coroutines `Dispatchers.Default/IO`,
  Swift concurrency (`Task.detached`/actors, `@concurrent`).
- Lists: lazy/builders only (`ListView.builder`, `LazyColumn` with stable `key`s,
  SwiftUI `List`/`LazyVStack` with stable `id`), fixed item extents when possible,
  downsample images to display size (`cacheWidth`/`cacheHeight` in Flutter, Coil/Glide
  sizing, `UIImage.preparingThumbnail`).
- Minimize rebuild/recomposition scope: `const` widgets & small widgets (Flutter),
  stable/immutable params + `remember`/`derivedStateOf` (Compose), small views + `@Observable` (SwiftUI).

**Size**
- Android: App Bundles (AAB), R8 + resource shrinking, WebP images, split per ABI.
- Flutter: `--split-debug-info` + `--obfuscate`, `--analyze-size`, tree-shake icons, remove unused packages.
- iOS: asset catalogs (app thinning), on-demand resources for big assets.

**Network & battery**
- Cache responses (HTTP cache / local DB), offline-first for core screens.
- Batch requests, compress, paginate; use WorkManager / BGTaskScheduler for background work.

## 6. Report format

```
Metric      Before    After     Δ       How measured
LCP p75     3.4s      1.9s      -44%    PSI field (28d) / Lighthouse mobile ×5 median
INP p75     320ms     140ms     -56%    web-vitals RUM
JS initial  410KB     168KB     -59%    next build + bundle analyzer (gzip)
Cold start  2.1s      1.2s      -43%    Macrobenchmark, Pixel 6a, median of 10
```

State device, network profile, build mode (release/profile) and number of runs.
