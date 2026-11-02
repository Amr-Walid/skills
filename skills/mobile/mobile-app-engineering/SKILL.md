---
name: mobile-app-engineering
description: Decision guide and quality bar for building mobile apps for Android and iPhone - choosing the stack (Flutter, native Kotlin + Jetpack Compose, native Swift + SwiftUI, React Native/Expo, Kotlin Multiplatform, PWA), shared architecture (UDF/MVVM, offline-first, sync), platform design (Material 3 vs Apple HIG), navigation and deep links, permissions, push notifications, security (secure storage, certificate pinning, root/jailbreak), accessibility, app store/Play release, versioning and OTA. Use when starting any mobile app, choosing between Flutter/native/React Native, reviewing a mobile architecture, or preparing a store release. Routes to flutter/, android/, ios/ and mobile/ skills.
---

# Mobile App Engineering

Pair with: `flutter/flutter-expert`, `android/compose-expert`, `ios/swiftui-expert-skill`,
`mobile/vercel-react-native-skills`, `mobile/animate-expo`, `mobile/mobile-native` (PWA feel),
`animation/motion-system`, `design/arabic-typography`, `performance/performance-engineering`,
`security/secure-by-default`.

## 1. Choose the stack (decide explicitly, write an ADR)

| Situation | Choose |
|-----------|--------|
| One team, Android + iOS (+ web/desktop), custom branded UI, fast delivery | **Flutter** (default) |
| Deep platform features (widgets, watch, CarPlay/Auto, camera/AR, background audio, heavy system integration) or platform-perfect feel | **Native**: Kotlin + **Jetpack Compose** / Swift + **SwiftUI** |
| Team is React/TypeScript; sharing logic with a React web app | **React Native + Expo** (New Architecture, Expo Router) |
| Share business logic but keep native UIs | **Kotlin Multiplatform** (+ Compose Multiplatform optionally) |
| Content/forms app, no store needed, instant updates | **PWA** (see `mobile/mobile-native`) |

Consider: team skills, required native APIs, design uniqueness, performance needs
(heavy animation/3D/camera), app size, long-term maintenance and hiring.

## 2. Architecture (same principles on every stack)

- **Unidirectional data flow**: UI renders immutable state → emits events/intents →
  ViewModel/Controller/Notifier → repository → data sources. UI holds no business logic.
- Layers: `presentation` (screens, view models) → `domain` (models, use cases — optional
  for small apps) → `data` (repositories, API clients, local DB).
- **Offline-first** for core flows: local DB is the source of truth (drift/Room/SwiftData/
  SQLite), network syncs into it; queue writes when offline with retry + idempotency keys.
- Typed errors (`Result`/sealed classes); map every failure to a UI state with recovery.
- Feature modules for medium+ apps; DI (Riverpod / Hilt / Swift environment or Factory).
- Config per environment (dev/staging/prod) with flavors/schemes; never hardcode URLs/keys.

| | Flutter | Android native | iOS native |
|---|---|---|---|
| UI | Widgets + Material 3/Cupertino | Jetpack Compose + Material 3 | SwiftUI (+ UIKit where needed) |
| State | Riverpod / Bloc | ViewModel + StateFlow | `@Observable` models |
| Async | Future/Stream, isolates | Coroutines/Flow | async/await, actors |
| Navigation | go_router | Navigation 3 / Navigation Compose | NavigationStack (+ coordinator) |
| Network | dio | Retrofit/Ktor + OkHttp | URLSession (+ async) |
| Local DB | drift | Room | SwiftData / GRDB / Core Data |
| DI | Riverpod | Hilt / Koin | Environment / Factory |
| Images | cached_network_image | Coil | AsyncImage / Nuke / Kingfisher |
| Tests | flutter_test, Patrol | JUnit, Compose UI test, Roborazzi | Swift Testing, XCUITest |

## 3. Design: respect the platform, keep the brand

- Android → **Material 3** (dynamic color optional, edge-to-edge, predictive back,
  bottom navigation / navigation rail, FAB where meaningful).
- iOS → **Human Interface Guidelines** (large titles, tab bar, sheets with detents,
  swipe-back, SF Symbols, Liquid Glass on iOS 26+ — see `ios/swiftui-liquid-glass`).
- Cross-platform apps: shared brand (color, type, illustration, motion) with
  platform-correct **navigation, gestures, controls and haptics**.
- Touch targets ≥ 48dp / 44pt; respect safe areas/notch/home indicator; support dark mode,
  Dynamic Type / font scale up to 200%, landscape + tablets/foldables if in scope
  (`android/compose-adaptive-layouts`, `flutter-build-responsive-layout`).
- Haptics for confirmations and gestures (light, sparingly).
- Arabic: full RTL mirroring, Arabic font, digits policy (`design/arabic-typography`).

## 4. Platform essentials checklist

- **Permissions**: ask in context, just-in-time, with a pre-prompt explaining value;
  handle "denied forever" with a path to Settings. Android 13+ notifications, photo
  picker instead of storage permission; iOS usage strings for every permission.
- **Push**: FCM (Android + iOS via APNs) or APNs directly; topic/segment strategy;
  deep link from notification; notification channels (Android).
- **Deep links**: Android App Links + iOS Universal Links, handled by the router; test
  cold and warm starts.
- **Background work**: WorkManager (Android), BGTaskScheduler (iOS); never rely on timers.
- **Lifecycle**: save/restore state (process death on Android, scene restoration on iOS).
- **Updates**: in-app update prompts (Play In-App Updates / version check endpoint) and a
  forced-update mechanism for breaking API changes.

## 5. Security (mobile-specific)

- Tokens in **Keychain / Android Keystore** (`flutter_secure_storage`, EncryptedFile/DataStore + Keystore);
  never in SharedPreferences/UserDefaults/plain files.
- Short-lived access tokens + refresh rotation; OAuth 2.0 **PKCE** for login (AppAuth).
- No secrets in the binary (it can be decompiled) — keys that must stay secret live on the backend.
- TLS only (ATS on iOS, `network_security_config` on Android); certificate pinning for
  high-risk apps (banking/health) with a rotation plan.
- Obfuscation (R8, Flutter `--obfuscate`); root/jailbreak & tamper detection
  (Play Integrity API / App Attest) for sensitive apps.
- Sanitize logs (no PII/tokens), disable debug logging in release, protect screenshots
  on sensitive screens (`FLAG_SECURE`, iOS privacy overlay in app switcher).
- Android: `android-permissions-security`, `android-intent-security` skills. OWASP MASVS as the checklist.

## 6. Quality & release

- CI: lint + tests + release builds for both platforms on every PR; fastlane / Codemagic /
  Xcode Cloud / GitHub Actions for signing and upload.
- Versioning: semantic `versionName`/`CFBundleShortVersionString` + monotonically
  increasing build number from CI.
- Staged rollout (Play % rollout, App Store phased release); internal → closed → open testing
  (Play tracks, TestFlight).
- Crash reporting (Crashlytics/Sentry) + analytics + performance monitoring before launch.
- Store readiness: privacy policy, data safety form (Play) / privacy nutrition labels +
  privacy manifest (iOS), screenshots per device size and language (Arabic + English),
  `play-policy-insights` for Play policy checks, `app-store-changelog` for release notes.
- OTA: Expo Updates / Shorebird (Flutter) only for bug fixes within store rules.

## 7. Definition of Done (mobile feature)

- [ ] Works on a low-end Android and an older supported iPhone, release build.
- [ ] Loading/empty/error/offline states; process death / backgrounding handled.
- [ ] RTL + Arabic, dark mode, font scale 200%, screen reader labels verified.
- [ ] No jank in the flow (profiler evidence), startup not regressed.
- [ ] Permissions/push/deep links tested on both platforms (cold + warm).
- [ ] Secrets and tokens handled per §5; analytics events and crash reporting wired.
