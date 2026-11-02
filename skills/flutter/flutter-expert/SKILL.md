---
name: flutter-expert
description: Entry point and house standards for building production Flutter apps (Android, iOS, web, desktop) - project structure (feature-first + layered), state management choice (Riverpod / Bloc / ChangeNotifier), go_router navigation, data layer (repositories, dio/http, json_serializable/freezed, drift/sqflite), theming with Material 3 + ThemeExtension tokens, Arabic/RTL and localization, performance, testing pyramid, flavors, CI and store release. Use at the start of any Flutter or Dart app task and to decide which specialized flutter skill to load next.
---

# Flutter Expert

Default contract for Flutter work in my projects. Project conventions win over this file.
Load the specialized skills as needed (all in `skills/flutter/`):

| Task | Skill |
|------|-------|
| Architecture & layers | `flutter-apply-architecture-best-practices` (official), `flutter-app-architecture`, `architecture-feature-first`, `flutter-best-practices` |
| State | `riverpod`, `bloc`, `provider`, `flutter-change-notifier` |
| Navigation | `flutter-setup-declarative-routing` (go_router) |
| Layout | `flutter-build-responsive-layout`, `flutter-use-column-row-first`, `flutter-fix-layout-issues`, `flutter-errors` |
| Data | `flutter-use-http-package`, `flutter-implement-json-serialization` |
| i18n / RTL | `flutter-setup-localization` + `design/arabic-typography` |
| Performance | `flutter-pre-caching` + `performance/performance-engineering` (mobile section) |
| Dart language | `effective-dart`, `dart-3-updates`, `dart-use-pattern-matching`, `dart-use-primary-constructors`, `dart-run-static-analysis`, `dart-fix-runtime-errors` |
| Tests | `flutter-testing`, `flutter-add-widget-test`, `flutter-add-integration-test`, `patrol-e2e-testing`, `mocktail`, `dart-generate-test-mocks`, `dart-collect-coverage` |
| Firebase | `flutterfire-configure`, `firebase-auth`, `firebase-cloud-firestore`, `firebase-messaging`, `firebase-crashlytics`, `firebase-analytics`, `firebase-remote-config` |
| Accessibility | `flutter-accessibility` |
| Motion | `animation/motion-system` |

## 1. Defaults <!-- EDIT to taste -->

| Concern | Default | Alternative |
|--------|---------|-------------|
| Flutter channel | latest **stable**, pinned via FVM (`.fvmrc`) | — |
| State | **Riverpod 3** (`riverpod_generator`) | **Bloc/Cubit** for large teams that want strict events; `ChangeNotifier` + `ListenableBuilder` for tiny apps |
| Navigation | **go_router** (typed routes via `go_router_builder`) | auto_route |
| HTTP | **dio** (interceptors: auth, retry, logging) | `package:http` for simple apps |
| Models | **freezed** + **json_serializable** | Dart 3 records/sealed classes for small value types |
| Local DB | **drift** (SQLite, typed queries, migrations) | sqflite; `shared_preferences` only for flags; `flutter_secure_storage` for tokens |
| DI | Riverpod providers | get_it + injectable (with Bloc) |
| Lints | `very_good_analysis` or `flutter_lints` + strict analyzer | — |
| Env/flavors | `--dart-define-from-file=env/dev.json` + Android productFlavors / iOS schemes | flutter_flavorizr |
| Errors/telemetry | Crashlytics or Sentry, `FlutterError.onError` + `PlatformDispatcher.instance.onError` | — |

## 2. Structure (feature-first, layered inside)

```
lib/
  main_dev.dart / main_prod.dart      # thin: flavor config → bootstrap()
  app/            app.dart (MaterialApp.router), router.dart, theme/ (tokens, ThemeExtensions)
  core/           network/ (dio client, interceptors), storage/, errors/ (Failure, Result), utils/
  l10n/           app_ar.arb, app_en.arb
  features/
    orders/
      data/        orders_api.dart, orders_repository_impl.dart, dto/
      domain/      order.dart (freezed), orders_repository.dart (abstract)   # optional for small apps
      presentation/ orders_screen.dart, widgets/, orders_controller.dart (Notifier/Cubit)
test/  integration_test/
```

Rules: UI never calls APIs directly → controller/cubit → repository → data source.
Repositories return domain models (not DTOs) and typed failures (`Result<T>` / sealed classes),
never throw raw `DioException` to the UI.

## 3. UI quality bar

- **Theme first**: `ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(...)` or a
  hand-tuned scheme) + `ThemeExtension<AppTokens>` for spacing, radii, brand colors, motion durations.
  No hard-coded colors/sizes in widgets.
- **Platform feel**: Material 3 by default; use `.adaptive` constructors (`Switch.adaptive`,
  `CircularProgressIndicator.adaptive`) and Cupertino page transitions on iOS where it helps.
- **Responsive**: `LayoutBuilder` / `MediaQuery.sizeOf(context)` breakpoints
  (compact < 600, medium < 840, expanded ≥ 840); `NavigationBar` → `NavigationRail` on wide screens.
- **RTL/Arabic**: `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`,
  `TextDirection`-aware icons; Arabic font bundled; line height per `arabic-typography`.
- **States**: every screen handles loading (skeleton), empty, error (retry), offline, and
  long content. `AsyncValue.when` / Bloc states map 1:1 to these.
- **Accessibility**: `Semantics` labels on icon buttons, tap targets ≥ 48dp, text scales to 200%
  without overflow (`MediaQuery.textScalerOf`), contrast ≥ 4.5:1.

## 4. Performance rules

- `const` constructors everywhere possible; split big `build` methods into small widgets
  (not helper methods) so rebuilds are scoped.
- Builders for lists/grids (`ListView.builder`, `SliverList.builder`), `itemExtent` /
  `prototypeItem` when fixed; never `shrinkWrap: true` inside scroll views for long lists.
- Images: `cached_network_image`, set `cacheWidth`/`memCacheWidth` to display size, precache the
  first screen's hero images.
- Heavy work off the UI isolate: `Isolate.run` / `compute` for JSON > ~100 KB, crypto, image processing.
- Select narrowly: `ref.watch(provider.select((s) => s.total))`, `BlocSelector`, `context.select`.
- Avoid `Opacity`/`ClipRRect`/`saveLayer` on large animated subtrees; use `FadeTransition`,
  `RepaintBoundary` around independently animating parts.
- Profile only in **profile mode on a real device** (`flutter run --profile`), DevTools Performance
  + "Track widget rebuilds". Impeller is default on iOS/Android — test both platforms.
- Release: `flutter build appbundle --obfuscate --split-debug-info=build/symbols`,
  check `--analyze-size`.

## 5. Testing pyramid

- **Unit**: repositories, controllers/cubits (`bloc_test`, `ProviderContainer` overrides), pure Dart logic.
- **Widget**: each screen's states (loading/empty/error/data) with mocked repositories (`mocktail`);
  golden tests for key components (`alchemist` or `golden_toolkit`) in both LTR and RTL.
- **Integration/E2E**: `integration_test` or **Patrol** for critical flows (login, checkout),
  including permissions and native dialogs.
- CI: `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test --coverage`,
  build both platforms. Codemagic or GitHub Actions (+ fastlane for store upload).

## 6. Platform integration checklist

- Android: `minSdk` per audience (≥ 23/24), `targetSdk` = latest required by Play, edge-to-edge
  (`SystemUiMode.edgeToEdge`), predictive back (`PopScope`), adaptive icon, notification
  permission (API 33+), R8 rules for plugins, signing via `key.properties` (never committed).
- iOS: `Info.plist` usage descriptions for every permission, privacy manifest
  (`PrivacyInfo.xcprivacy`), push entitlements, deployment target, App Tracking Transparency if tracking.
- Deep links: Android App Links (`assetlinks.json`) + iOS Universal Links
  (`apple-app-site-association`) wired into go_router.
- Platform code: Pigeon for type-safe channels; FFI (`dart-use-ffigen`) for C libs.

## 7. Definition of Done (Flutter)

- [ ] `flutter analyze` clean, formatted, tests green, coverage on domain/controllers.
- [ ] Runs on Android + iOS (and web if in scope) in release mode; no jank in core flows.
- [ ] All screen states implemented; RTL + Arabic verified; text scale 200% verified.
- [ ] No secrets in code (`--dart-define-from-file`, backend-issued tokens), tokens in secure storage.
- [ ] Crash reporting + analytics wired; app size checked; store metadata/screenshots updated.
