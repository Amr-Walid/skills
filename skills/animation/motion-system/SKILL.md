---
name: motion-system
description: Design and implement a coherent motion system across web, Flutter, Android (Compose) and iOS (SwiftUI) - motion tokens (durations, easings, springs), choosing the right tool (CSS, View Transitions, WAAPI, Motion/Framer Motion, GSAP, Lottie, Rive, Flutter implicit/explicit animations, Compose animate*AsState, SwiftUI withAnimation/spring), choreography, scroll-driven animation, reduced-motion, and 60/120fps performance rules. Use when adding animations or micro-interactions to any product, building a landing page with motion, defining motion guidelines, or when the user asks for "animations", "smooth", "alive" or "انيميشن".
---

# Motion System

Motion must **explain change** (where did this come from, what happened, what can I do).
Decoration-only motion is noise. One orchestrated moment beats twenty scattered fades.

Deep dives in this repo: `animation/animate` (decision order), `animation/review-animations`,
`animation/animation-performance`, `animation/gsap-*` (official GSAP), `design/apple-design`
(springs & gestures), `animation/vercel-react-view-transitions`, `mobile/animate-expo`.

## 1. Motion tokens (define once, use everywhere)

| Token | Value | Use |
|-------|-------|-----|
| `instant` | 100ms | hover/press color, toggles, checkbox |
| `fast` | 150–200ms | tooltips, small fades, button feedback |
| `base` | 250–300ms | dropdowns, cards expanding, tab indicator |
| `slow` | 400–500ms | modals, sheets, page/route transitions |
| `deliberate` | 600–1000ms | hero intro, onboarding, one-off storytelling only |

Easings:

| Token | Curve | Use |
|-------|-------|-----|
| `ease-out` (enter) | `cubic-bezier(0.16, 1, 0.3, 1)` | things appearing / responding to user |
| `ease-in` (exit) | `cubic-bezier(0.7, 0, 0.84, 0)` | things leaving (keep exits ~20–30% shorter than enters) |
| `ease-in-out` (move) | `cubic-bezier(0.65, 0, 0.35, 1)` | element moving A → B on screen |
| `linear` | `linear` | progress, spinners, continuous loops, scroll-scrubbed motion |
| spring (default) | stiffness ~300–400, damping ~30, mass 1 (≈ iOS `.smooth`/`.snappy`) | gestures, drag release, anything interruptible |

```css
:root {
  --dur-fast: 180ms; --dur-base: 280ms; --dur-slow: 450ms;
  --ease-out: cubic-bezier(0.16, 1, 0.3, 1);
  --ease-in: cubic-bezier(0.7, 0, 0.84, 0);
  --ease-move: cubic-bezier(0.65, 0, 0.35, 1);
}
```

Mobile durations are slightly shorter than desktop; large-distance motion slightly longer.
Never animate > 500ms for something the user triggers repeatedly.

## 2. Pick the tool

**Web**

| Need | Tool |
|------|------|
| hover/press/focus, simple enter | CSS transitions + `@starting-style` (entry from `display:none`) |
| page/route/shared-element transitions | **View Transitions API** (`document.startViewTransition`, cross-document `@view-transition { navigation: auto; }`); React → `vercel-react-view-transitions` |
| scroll-linked effects | CSS `animation-timeline: view()` / `scroll()` (progressive enhancement), else **GSAP ScrollTrigger** |
| React component motion, layout animations, gestures, exit animations | **Motion** (`motion/react`, formerly Framer Motion): `AnimatePresence`, `layout`, `whileTap` |
| complex timelines, SVG morphing, text splitting, pinning, marketing sites | **GSAP** (free incl. all plugins: ScrollTrigger, SplitText, MorphSVG, Flip) |
| designer-made illustrations/icons | **Lottie** (`dotlottie` format, smaller) or **Rive** (interactive state machines, tiny runtime) |
| 3D / WebGL | three.js / React Three Fiber — only if the brief needs it; lazy-load |

**Flutter**: implicit (`AnimatedContainer`, `AnimatedOpacity`, `AnimatedSwitcher`,
`TweenAnimationBuilder`) → explicit (`AnimationController` + `Tween` + `AnimatedBuilder`)
→ `Hero` for shared elements → `package:animations` (Material motion: container transform,
shared axis, fade through) → `flutter_animate` for chained effects → Rive/Lottie for art.
**Android (Compose)**: `animate*AsState`, `AnimatedVisibility`, `AnimatedContent`,
`updateTransition`, `Animatable` (gestures), `SharedTransitionLayout` for shared elements,
`MotionScheme` (M3 Expressive springs). See `android/compose-expert` → material3-motion.
**iOS (SwiftUI)**: `withAnimation(.snappy)`, `.animation(_:value:)`, `.spring(duration:bounce:)`,
`matchedGeometryEffect`, `.navigationTransition(.zoom)`, `PhaseAnimator`, `KeyframeAnimator`,
`.contentTransition(.numericText())`, SF Symbols `.symbolEffect`. See `ios/swiftui-expert-skill`.

## 3. Choreography rules

- **Origin matters**: popovers/menus scale from their trigger (`transform-origin` at the
  anchor), sheets come from the edge they live on, toasts from their corner.
- **Stagger** lists 30–60ms per item, cap total at ~300ms (stagger first 6–8 items only).
- **Scale** never from 0 — from 0.95–0.98 with opacity. Exits scale to 0.98, not 0.
- **Distance**: 8–24px translate for enters; large slides only for full-screen transitions.
- **One focal motion per view.** Hero intro OR scroll reveals, not both everywhere.
- **Interruptible**: user can act mid-animation; springs/transitions retarget, never queue.
- **Never animate** keyboard-initiated actions in high-frequency tools (command palette
  open, typing), data tables while reading, or content the user is trying to read.
- **RTL**: horizontal motion mirrors (slide-in from the start edge). Use logical values
  or flip sign with `dir`.

## 4. Performance rules (60fps / 120fps)

- Animate only **`transform` and `opacity`** (and `filter` sparingly). Never `width`,
  `height`, `top`, `left`, `margin`, `box-shadow` per frame — use FLIP (`Motion layout`,
  `GSAP Flip`) or animate a pseudo-element's opacity for shadows.
- `will-change: transform` only right before/while animating; remove after. Don't
  blanket-apply.
- Avoid animating `backdrop-filter`/large `blur()` on mobile.
- Batch DOM reads/writes; no layout reads inside animation frames.
- React: animate via refs/motion values, not state on every frame.
- Flutter: wrap animated subtrees in `RepaintBoundary`; use `AnimatedBuilder(child:)` to
  avoid rebuilding static children; avoid `Opacity` widget on large trees — use
  `FadeTransition`; profile in **profile mode** with the Performance overlay.
- Compose: read animated values in **lambda modifiers** (`Modifier.graphicsLayer { alpha = a }`,
  `Modifier.offset { }`) to skip recomposition; use `derivedStateOf` for scroll-driven values.
- SwiftUI: animate value-typed state; avoid `AnyView`; keep heavy views out of animated
  containers; test with Instruments → SwiftUI / Animation Hitches.
- Lottie: avoid huge JSON with masks/mattes/effects; prefer dotLottie or Rive.

## 5. Accessibility (non-negotiable)

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation-duration: 0.01ms !important; animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important; scroll-behavior: auto !important; }
}
```

Better: design a reduced variant (cross-fade instead of slide/zoom/parallax), not just "off".
- GSAP: `gsap.matchMedia()` with `(prefers-reduced-motion: reduce)`.
- Motion: `useReducedMotion()` / `<MotionConfig reducedMotion="user">`.
- Flutter: `MediaQuery.of(context).disableAnimations`.
- Compose/Android: respect `Settings.Global.ANIMATOR_DURATION_SCALE` (system handles most).
- SwiftUI: `@Environment(\.accessibilityReduceMotion)`.
- No flashing > 3 times/second. Auto-playing motion > 5s needs a pause control (WCAG 2.2.2).

## 6. Landing page recipe (high-end, not generic)

1. One hero moment: headline split by lines (GSAP SplitText, `mask` reveal) + product
   visual entrance, ≤ 1.2s total, `ease-out`.
2. Scroll: 2–3 sections with *meaningful* scroll-linked motion (pinning a product while
   features change, a progress-driven diagram). Others static.
3. Micro-interactions: buttons (press scale 0.97, 100ms), links (underline grow),
   cards (subtle lift on hover only on `(hover: hover)` devices).
4. Lazy-init heavy animation code below the fold; no animation library in the critical path
   if CSS can do the first paint.
5. Test on a mid-range Android phone; if it drops frames, cut, don't optimize forever.

## 7. Review checklist

- [ ] Every animation has a purpose (feedback, orientation, continuity, delight-once).
- [ ] Uses motion tokens; no magic numbers.
- [ ] Enters ease-out, exits faster ease-in, moves ease-in-out, gestures springs.
- [ ] Only transform/opacity animated per frame; no layout thrash.
- [ ] Interruptible; no queued animations on repeated clicks.
- [ ] Reduced-motion variant exists and was tested.
- [ ] 60fps on a mid-range phone (Performance panel / Flutter DevTools / Android profiler / Instruments).
- [ ] RTL direction correct.
