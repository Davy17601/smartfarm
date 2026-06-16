# SmartFarm — Project Guide for Claude Code

Offline-first SwiftUI app for Cambodian smallholder farmers: **finance**, **farm
activities & reminders**, **dashboard**, **reports/export**, **backup/restore**.
**Bilingual** (Khmer default + English), KHR + USD.

**Design source of truth:** `docs/00-architecture.md` … `docs/09-localization.md`.
**Visual preview:** open `docs/index.html`. **User survey:** `docs/question.html`.

---

## Environment — DO NOT CHANGE

The team builds on **Xcode 13.x on macOS VMs**. Every change must compile and run there.

| Setting | Value |
|---------|-------|
| Xcode | 13.x |
| `IPHONEOS_DEPLOYMENT_TARGET` | `14.0` |
| `SWIFT_VERSION` | `5.0` (as set in `project.pbxproj`) |
| `objectVersion` (pbxproj) | `55` |
| Persistence | CoreData (`SmartFarm.xcdatamodeld`) |
| Dependencies | **None** — no SPM packages, no CocoaPods |

> A contributor's machine may have a newer Xcode (e.g. 16.x) — fine for a quick compile
> check, but never adopt an API that requires it. Xcode 13 ships only the iOS 15 SDK, so
> the forbidden APIs below can't even be `#available`-gated — they simply won't compile.

## Allowed APIs (iOS 14 / Xcode 13 safe)
- `NavigationView` + `NavigationLink(tag:selection:)`, `TabView` + `tabItem`
- `@StateObject`, `@ObservedObject`, `@EnvironmentObject`
- `ToolbarItem` with `.navigationBarLeading` / `.navigationBarTrailing`
- `UNUserNotificationCenter` for local notifications
- `UIActivityViewController` / `UIDocumentPickerViewController` via `UIViewControllerRepresentable`
- `PDFKit`; `GeometryReader` + `Rectangle` for charts
- custom `TextField` search bar; `PreviewProvider` for previews

## Forbidden APIs (require newer iOS/Xcode — never use)
- `NavigationStack`, `NavigationSplitView` (iOS 16+)
- Swift Charts / `import Charts` (iOS 16+); `.searchable()` (iOS 15+) — use a custom `TextField`
- `SwiftData`, `@Model` (iOS 17+), `@Observable` (iOS 17+)
- `ShareLink` (iOS 16+) — use `UIActivityViewController`
- `ContentUnavailableView` (iOS 17+)
- `#Preview {}` macro (Xcode 15+) — use `PreviewProvider`

---

## Build & Test

```bash
xcodebuild -project SmartFarm.xcodeproj -scheme SmartFarm \
  -destination 'platform=iOS Simulator,name=iPhone 13,OS=15.5' build
```
Adjust the simulator name/OS to one available locally (`xcrun simctl list devices`).

## Adding new Swift files (register without opening Xcode)

New `.swift` files must be added to the Xcode target or they won't compile. Keep
`objectVersion = 55`; never hand-edit the pbxproj.

```bash
bundle install   # one time — installs the xcodeproj gem (see Gemfile)

bundle exec ruby -e "require 'xcodeproj'; \
  proj = Xcodeproj::Project.open('SmartFarm.xcodeproj'); \
  ref = proj.main_group.find_subpath('SmartFarm/Finance/Views', true).new_file('NewFile.swift'); \
  proj.targets.first.add_file_references([ref]); proj.save"
```

---

## Architecture — MVVM + Repository + Coordinator

```
View (SwiftUI) → ViewModel (ObservableObject, @Published) → Repository (protocol)
                                                              → PersistenceController (CoreData)
```
- **Views never import CoreData** and never see `*Entity` types. They render **domain structs**
  (`Transaction`, `FarmActivity`, `Reminder` — all `Codable` + `Identifiable`).
- **ViewModels** are `final class … : ObservableObject`, depend only on repository **protocols**
  (e.g. `TransactionRepositoryProtocol`) → unit-testable with mocks. Never make a ViewModel a `View`.
- **Repositories** (`Core/Repositories/`) are the **only** place `Entity ⇄ struct` mapping happens;
  CoreData impls save via a `hasChanges`-guarded `context.save()`.
- **DI:** `App/AppEnvironment` owns `PersistenceController` + the repositories and exposes
  `make…ViewModel()` factories; injected via `.environmentObject`. Views build VMs through it.
- **Navigation** that must be triggered from elsewhere lives in a **Coordinator** (`FinanceCoordinator`).

### Folder layout
```
SmartFarm/
  App/                SmartFarmApp, AppEnvironment (DI), AppSettings
  Core/
    Repositories/     <Entity>Repository.swift (protocol + CoreData impl + mappers)
    DesignSystem/     Theme, Components/ (FarmCard, PrimaryButton, SectionHeader, SummaryCardView)
    Localization/     LocalizationManager, L("key")
    Utilities/        CurrencyFormatter, LocalizedDate, NotificationService, DocumentPicker, ActivityShareSheet
  Finance/  CalendarReminders/  Dashboard/  Reports/  Backup/  Settings/   (Models/ViewModels/Views)
  en.lproj/ km.lproj/  Localizable.strings
  Persistence.swift, SmartFarm.xcdatamodeld
```

## Conventions
- **No hardcoded UI strings** — every user-facing string via `L("key")` or a localized enum
  `displayName`, with matching `km`/`en` `Localizable.strings`. **Khmer is the default.**
- **Formatting:** reuse `Core/Utilities/CurrencyFormatter` (KHR `៛`, USD `$`) and `LocalizedDate`.
- **Multi-currency:** never sum across currencies — totals are **per-currency**
  (`total…(in:)`); `AppSettings.displayCurrency` (default KHR) picks the summary currency. No FX.
- **Notifications:** `Core/Utilities/NotificationService` (`UNUserNotificationCenter`).
- **Previews:** `PreviewProvider` only.

## Module map
| Tab | View | Status |
|-----|------|--------|
| ផ្ទះ Dashboard | `DashboardView` (+ `DashboardViewModel`) | ✅ built |
| ហិរញ្ញវត្ថុ Finance | `FinanceTabView` (+ `FinanceViewModel`, `FinanceCoordinator`) | ✅ built |
| ប្រតិទិន Calendar | `CalendarTabView` (+ `CalendarViewModel`) | ✅ built |
| របាយការណ៍ Reports | `ReportsView` (+ `ReportsViewModel`, `MonthlyBarChartView`, `ReportExporter`) | ✅ built |
| Settings | `SettingsView` | ✅ built |
| Backup | `BackupView` (+ `BackupService`) | ✅ built |

> Tests: the strategy in `docs/00-architecture.md §9` (mock repositories) is not yet implemented —
> no test target exists. Splash (`docs/02-splash.md`) is specced but not yet built.
