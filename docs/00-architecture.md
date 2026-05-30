# 00 — Architecture

> Design source-of-truth for SmartFarm (កសិកម្ម ឆ្លាតវៃ). Build only after this doc set is approved.

## 1. Product context

Offline-first SwiftUI app for Cambodian smallholder farmers. Tracks **finance**, **farm activities & reminders**, shows a **dashboard**, and supports **reports/export** and **backup/restore**. Khmer UI, KHR + USD.

## 2. Hard constraints (non-negotiable)

| Item | Value |
|------|-------|
| iOS deployment target | **14.0** |
| Xcode | 13.x (team builds on VM) → project `objectVersion = 55` |
| Swift | 5.5 |
| Dependencies | **none** (no SPM/CocoaPods) |
| Persistence | CoreData |

**Forbidden APIs** (iOS 16/17+ / Xcode 15+ — won't compile in Xcode 13): `NavigationStack`, `NavigationSplitView`, `.searchable`, Swift Charts, `SwiftData`/`@Model`, `ShareLink`, `@Observable`, `ContentUnavailableView`, `#Preview` macro.
**Use instead:** `NavigationView`+`NavigationLink(tag:selection:)`, custom `TextField` search, `GeometryReader`+`Rectangle` charts, `UIActivityViewController`/`UIDocumentPickerViewController` via `UIViewControllerRepresentable`, `ObservableObject`+`@Published`, `PreviewProvider`.
> Xcode 13 ships only the iOS 15 SDK, so the "forbidden" APIs cannot be compiled or even `#available`-gated here — this list is a hard build constraint, not a style preference.

## 3. Architectural style — MVVM + Repository + Coordinator

```
            ┌─────────────────────────────────────────────┐
   View ───▶│ ViewModel (ObservableObject, @Published)     │
 (SwiftUI)  │   • presentation logic, derived values        │
            └───────────────┬─────────────────────────────┘
                            │ depends on PROTOCOL (not concrete)
                            ▼
            ┌─────────────────────────────────────────────┐
            │ Repository (protocol)                        │
            │   CoreData impl maps Entity ⇄ domain struct  │
            └───────────────┬─────────────────────────────┘
                            ▼
            ┌─────────────────────────────────────────────┐
            │ PersistenceController (NSPersistentContainer)│
            └─────────────────────────────────────────────┘
```

**Rules**
- Views never import CoreData and never see `*Entity` types.
- ViewModels publish **domain structs** (`Transaction`, `FarmActivity`, `Reminder`) and depend only on repository **protocols** → unit-testable with mocks.
- Repositories are the **only** place `Entity ⇄ struct` mapping happens.
- Navigation state that must be triggered from elsewhere lives in a **Coordinator** (e.g. `FinanceCoordinator`).

## 4. Folder structure

```
SmartFarm/
  App/            SmartFarmApp, AppEnvironment (DI), AppSettings, RootView (splash→tabs)
  Core/
    Persistence/  PersistenceController, SmartFarm.xcdatamodeld
    Repositories/ <Entity>Repository.swift  (protocol + CoreData impl + mappers)
    DesignSystem/ Theme, Components/, Modifiers/
    Localization/ LocalizationManager, String+Localized (L(key))
    Utilities/    CurrencyFormatter, LocalizedDate, NotificationService,
                  ActivityShareSheet, DocumentPicker
  Resources/      km.lproj/Localizable.strings, en.lproj/Localizable.strings
  Finance/        Models, ViewModels, Coordinators, Views
  CalendarReminders/ ViewModels, Views
  Dashboard/      ViewModels, Views (MainTabView lives here)
  Reports/        ViewModels, Views, ReportExporter
  Backup/         BackupService, BackupView
  Settings/       SettingsView
```
> Note: `PersistenceController`/`.xcdatamodeld` may physically stay at `SmartFarm/` root — layering is enforced in code, not by folder location.

## 5. Dependency injection — `AppEnvironment`

Single `ObservableObject` created once in `SmartFarmApp`, injected via `.environmentObject`. Owns `PersistenceController` + the three repositories and exposes `make…ViewModel()` factories so views construct ViewModels without wiring dependencies by hand.

Two more app-wide `ObservableObject`s are injected alongside it (see `09-localization.md`):
- `LocalizationManager` — selected language (`@AppStorage`), live UI re-render, sets `\.environment(\.locale)`.
- `AppSettings` — `displayCurrency` (`@AppStorage`) used for all totals.

```swift
FinanceTabView(repository: environment.transactionRepository)
// inside: _viewModel = StateObject(wrappedValue: FinanceViewModel(repository: repository))
```
This solves the "`@StateObject` needs an injected dependency at init" problem cleanly.

## 6. Domain model

| Struct | Key fields | Enums |
|--------|-----------|-------|
| `Transaction` | id, title, amount, type, **category**, **currency**, date, note | `TransactionType` (income/expense), `TransactionCategory` (seeds/fertilizer/labor/tools/sales/other), `Currency` (KHR/USD) |
| `FarmActivity` | id, title, date, note, isCompleted | — |
| `Reminder` | id, title, dueDate, note, isCompleted, repeatType | `RepeatType` (none/daily/weekly/monthly) |

All structs are `Codable` (→ enables JSON backup) + `Identifiable`.

## 7. Persistence & seeding

- 3 CoreData entities mirror the structs; `id: UUID` is the identity key.
- `PersistenceController.seedIfEmpty()` inserts sample data on first launch only (store empty check).
- Mutations call `context.save()` inside repositories; `viewContext.automaticallyMergesChangesFromParent = true`.

## 8. Multi-currency rule

Summing across currencies is semantically wrong, so **totals are computed per-currency** via `total…(in: currency)`. A **display-currency setting** (`AppSettings.displayCurrency`, default KHR) selects which currency the summary/dashboard/reports totals show; each transaction row always shows its own currency. Amounts in the other currency are grouped, **not converted** (no FX in v1). Full spec: `09-localization.md §4`.

## 9. Testing strategy

- ViewModels tested against in-memory mock repositories (e.g. `InMemoryTransactionRepository`).
- Assert: profit math, filtering, `upcoming*` windows, backup round-trip (`exportFile` → `restore` → equal sets).
- `PersistenceController(inMemory: true)` for repository integration tests.

## 10. Conventions

- One feature per top-level folder; `Views/`, `ViewModels/`, `Models/` inside.
- File = one primary type; previews use `PreviewProvider`.
- **No hardcoded UI strings** — all user-facing text via `L("key")` / localized enum `displayName`, with `km`/`en` `.strings` files (see `09-localization.md`). Khmer is the default language.
- Project file edited via the `xcodeproj` Ruby gem (keep `objectVersion = 55`), never by hand.
```
