# 02 — Splash (new screen)

> **Status: not yet built.** This is a new screen to add after approval.

## Purpose
First frame on launch. Shows branding while the CoreData store loads and first-run seeding completes, then transitions to the main tabs. Replaces an abrupt cold-start into the tab bar.

## Wireframe
```
┌───────────────────────────┐
│                           │
│                           │
│           🌱              │   ← app logo (SF Symbol "leaf.circle.fill"
│      កសិកម្ម ឆ្លាតវៃ        │      or asset), brand green
│        SmartFarm          │
│                           │
│        ◜ ◝ (spinner)      │   ← subtle ProgressView, hidden if instant
│                           │
└───────────────────────────┘
        brand background
```

## Behavior / state machine
```
.loading  → (store ready + min 0.8s elapsed) → .ready → RootView shows MainTabView
```
- Owned by `RootView` (in `App/`), which `SmartFarmApp` shows instead of `MainTabView` directly.
- `RootView` holds `@State private var phase: AppPhase = .loading`.
- On appear: ensure `AppEnvironment` is constructed (store load + `seedIfEmpty()` already happen in its init). Enforce a **minimum display time** (~0.8s) so the splash doesn't flash.
- Transition with `.opacity`/`.easeInOut` cross-fade.

## iOS 14 notes
- There is **no SwiftUI launch-screen API**; the static launch screen is the storyboard/Info.plist `LaunchScreen`. This splash is an in-app view shown *after* the launch image, hosted by `RootView`.
- Use `DispatchQueue.main.asyncAfter` or a timer (`Timer`/`onReceive`) for the min-duration gate, then flip `phase` with `withAnimation`.
- Preview via `PreviewProvider`.

## Components
`Theme.brand` background, logo, `Text` (title + subtitle), optional `ProgressView`. New `SplashView` + `RootView`.

## Edge cases
- Store fails to load: `PersistenceController` currently `fatalError`s — doc'd as acceptable for v1; future: show a recoverable error state here.
- Very fast device: min-duration gate prevents a flicker.

## Accessibility
- Logo `accessibilityLabel("SmartFarm")`; mark splash as not interactive; VoiceOver announces app name.

## Acceptance criteria
- [ ] Launch shows splash, then cross-fades to Dashboard tab.
- [ ] Splash visible ≥ 0.8s and ≤ ~1.5s on a warm start.
- [ ] No double-init of `AppEnvironment`; seeding runs exactly once.
- [ ] Works in light & dark mode.
```
