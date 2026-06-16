# SmartFarm — Project Guide for Claude Code

SwiftUI + MVVM + CoreData app for Cambodian small-scale farmers (finance, farm
activities, schedules). UI is in **Khmer**. See `PLAN.md` for the module roadmap
and `README.md` for the product overview.

---

## Environment — DO NOT CHANGE

The team builds on **Xcode 13.x on macOS VMs**. Every change must compile and run
there. Treat the following as locked:

| Setting | Value |
|---------|-------|
| Xcode | 13.x |
| `IPHONEOS_DEPLOYMENT_TARGET` | `14.0` |
| `SWIFT_VERSION` | `5.0` (as set in `project.pbxproj`) |
| Persistence | CoreData (`SmartFarm.xcdatamodeld`) |
| Dependencies | **None** — no SPM packages, no CocoaPods |

> Note: a contributor's local machine may have a newer Xcode (e.g. 16.x). That is
> fine for a quick compile check, but never adopt an API that requires it.

## Allowed APIs (iOS 14 / Xcode 13 safe)
- `NavigationView` + `NavigationLink`, `TabView` + `tabItem`
- `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@FetchRequest`
- `ToolbarItem` with `.navigationBarLeading` / `.navigationBarTrailing`
- `UNUserNotificationCenter` for local notifications
- `UIActivityViewController` / `UIDocumentPickerViewController` via `UIViewControllerRepresentable`
- `PDFKit`; `GeometryReader` + `Rectangle` for charts
- `PreviewProvider` for previews

## Forbidden APIs (require newer iOS/Xcode — never use)
- `NavigationStack`, `NavigationSplitView` (iOS 16+)
- Swift Charts / `Charts` (iOS 16+), `.searchable()` — use a custom `TextField`
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

New `.swift` files must be added to the Xcode target or they won't compile. One-time
setup, then register per file:

```bash
bundle install   # one time — installs the xcodeproj gem (see Gemfile)

bundle exec ruby -e "require 'xcodeproj'; \
  proj = Xcodeproj::Project.open('SmartFarm.xcodeproj'); \
  ref = proj.main_group.find_subpath('SmartFarm/Finance/Views', true).new_file('NewFile.swift'); \
  proj.targets.first.add_file_references([ref]); proj.save"
```

---

## Conventions
- **Architecture:** MVVM. ViewModels are `class ... : ObservableObject` with
  `@Published` properties — never a `View` (the old `FinanceViewModel.swift` stub is a
  View by mistake; fix it when building Finance).
- **Folders:** feature-first — `SmartFarm/<Feature>/{Models,ViewModels,Views}`.
  Shared code in `Shared/`, `Utilities/`.
- **Formatting:** reuse `Utilities/Formatters.swift` — `currency(_:currency:)`
  (KHR shows `៛`, USD shows `$`), `date`, `shortDate`, `time`, `monthYear`.
- **CoreData:** access via `PersistenceController.shared` / `CoreDataManager.shared`;
  use `@FetchRequest` in views. Entities: `TransactionEntity`, `FarmActivityEntity`,
  `ReminderEntity`.
- **Strings:** all user-facing text in Khmer.
- **Previews:** `PreviewProvider`, inject `PersistenceController.preview.container.viewContext`.

## Module map & skill commands
| Tab | View | Skill | Status |
|-----|------|-------|--------|
| Dashboard (ផ្ទះ) | `DashboardView` | `/dashboard` | done |
| Finance (ហិរញ្ញវត្ថុ) | `FinanceTabview` | `/finance` | stub |
| Calendar (ប្រតិទិន) | `CalendarTabView` | `/calendar` | not built |
| Reports (របាយការណ៍) | `ReportTabView` | `/reports` | stub |

Build a module with its skill command; each command reads its `docs/<Module>.md` spec.
