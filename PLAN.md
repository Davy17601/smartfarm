# SmartFarm iOS — Master Implementation Plan

## Project Overview
SwiftUI MVVM app for Cambodian small-scale farmers. Tracks finances, farm activities, and schedules in one place.

**Stack:** Swift 5.5 · SwiftUI · CoreData · Xcode 13 · iOS 14 deployment target  
**Constraints:** No NavigationStack, SwiftData, Swift Charts, ShareLink, `#Preview`, `@Observable`

---

## Team & Ownership

| Module | Owner | Skill Command |
|--------|-------|---------------|
| Finance Tracker | Davy | `/finance` |
| Dashboard | Davy | `/dashboard` |
| Calendar & Reminders | Monineath | `/calendar` |
| Reports + Backup | Monineath | `/reports` |
| Utilities / Architecture | Leader | — |

---

## Tab Structure

| Tab | Khmer | Icon | View |
|-----|-------|------|------|
| 1 | ផ្ទះ (Dashboard) | `house.fill` | `DashboardView` |
| 2 | ហិរញ្ញវត្ថុ (Finance) | `dollarsign.circle.fill` | `FinanceTabview` |
| 3 | ប្រតិទិន (Calendar) | `calendar` | `CalendarTabView` |
| 4 | របាយការណ៍ (Reports) | `chart.bar.fill` | `ReportTabView` |

---

## Implementation Phases

### Phase 0 — Docs & Skills ✅
- [x] `PLAN.md` — this file
- [x] `.claude/commands/finance.md`
- [x] `.claude/commands/dashboard.md`
- [x] `.claude/commands/calendar.md`
- [x] `.claude/commands/reports.md`
- [x] `docs/Finance.md`
- [x] `docs/Dashboard.md`
- [x] `docs/Calendar.md`
- [x] `docs/Reports.md`

### Phase 1 — Utilities (Leader) [ ]
- [ ] `Utilities/CoreDataManager.swift` — save/delete helpers
- [ ] `Utilities/Formatters.swift` — KHR/USD + date formatters
- [ ] `Utilities/NotificationManager.swift` — UNUserNotificationCenter wrapper
- [ ] `SmartFarmApp.swift` — inject managedObjectContext into environment
- [ ] CoreData model — add `category` + `currency` to TransactionEntity

### Phase 2 — Finance Module (Davy) [ ]
- [ ] `Finance/ViewModels/FinanceViewModel.swift` — ObservableObject, CRUD, totals
- [ ] `Finance/Views/FinanceTabview.swift` — summary cards + filter + list
- [ ] `Finance/Views/TransactionListView.swift` — @FetchRequest with filter
- [ ] `Finance/Views/TransactionRowView.swift` — row component
- [ ] `Finance/Views/AddTransactionView.swift` — add form
- [ ] `Finance/Views/EditTransactionView.swift` — edit form
- [ ] `Finance/Views/TransactionDetailView.swift` — detail + delete

### Phase 3 — Calendar & Reminders (Monineath) [ ]
- [ ] `CalendarReminders/ViewModels/CalendarViewModel.swift` — new
- [ ] `CalendarReminders/Views/CalendarTabView.swift` — new
- [ ] `CalendarReminders/Views/AddReminderView.swift` — new
- [ ] `CalendarReminders/Views/ReminderRowView.swift` — new

### Phase 4 — Dashboard (Davy + Monineath) [ ]
- [ ] `Dashboard/Views/DashboardView.swift` — new
- [ ] `Dashboard/Views/SummaryCardView.swift` — new
- [ ] Wire `DashboardView` into `MainTabView`

### Phase 5 — Reports + Backup (Monineath) [ ]
- [ ] `Reports/Models/MonthlyReport.swift`
- [ ] `Reports/ViewModels/ReportViewModel.swift`
- [ ] `Reports/Views/ReportTabView.swift`
- [ ] `Reports/Views/BarChartView.swift` — GeometryReader bars
- [ ] `Reports/Services/CSVExporter.swift`
- [ ] `Reports/Services/PDFGenerator.swift`
- [ ] `Shared/ShareSheet.swift`
- [ ] `Shared/DocumentPicker.swift` — new

---

## CoreData Entities

### TransactionEntity
| Attribute | Type | Default |
|-----------|------|---------|
| id | UUID | — |
| title | String | "" |
| amount | Double | 0.0 |
| type | String | "Income" |
| category | String | "Other" |
| currency | String | "KHR" |
| date | Date | — |
| note | String | nil |

### FarmActivityEntity
| Attribute | Type | Default |
|-----------|------|---------|
| id | UUID | — |
| title | String | "" |
| date | Date | — |
| note | String | nil |
| isCompleted | Bool | NO |

### ReminderEntity
| Attribute | Type | Default |
|-----------|------|---------|
| id | UUID | — |
| title | String | "" |
| dueDate | Date | — |
| note | String | nil |
| isCompleted | Bool | NO |
| repeatType | String | "none" |

---

## Build & Test

```bash
# Build
xcodebuild -project SmartFarm.xcodeproj -scheme SmartFarm \
  -destination 'platform=iOS Simulator,name=iPhone 13,OS=15.5' build

# Register new Swift files (after adding them)
bundle exec ruby -e "
require 'xcodeproj'
proj = Xcodeproj::Project.open('SmartFarm.xcodeproj')
target = proj.targets.first
group = proj.main_group
# add file reference and build file
proj.save
"
```

## APIs Allowed (Xcode 13 / iOS 14)
- `NavigationView` + `NavigationLink`
- `TabView` with `tabItem`
- `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@FetchRequest`
- `ToolbarItem` with `.navigationBarTrailing / .navigationBarLeading`
- `UNUserNotificationCenter`
- `UIActivityViewController` via `UIViewControllerRepresentable`
- `UIDocumentPickerViewController` via `UIViewControllerRepresentable`
- `PDFKit`
- `GeometryReader` + `Rectangle` for charts
- `PreviewProvider` (NOT `#Preview {}`)

## APIs Forbidden
- `NavigationStack`, `NavigationSplitView` (iOS 16+)
- `Charts` / Swift Charts (iOS 16+)
- `SwiftData`, `@Model` (iOS 17+)
- `ShareLink` (iOS 16+)
- `@Observable` (iOS 17+)
- `ContentUnavailableView` (iOS 17+)
- `#Preview {}` macro (Xcode 15+)
