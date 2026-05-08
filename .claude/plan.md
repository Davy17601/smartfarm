# SmartFarm — Implementation Plan

## Phase 1 — Leader: Project Foundation
> ត្រូវបញ្ចប់មុនគេ — Davy និង Monineath រង់ចាំ phase នេះ

### 1.1 Folder Structure
```
SmartFarm/
├── Models/
├── ViewModels/
├── Views/
│   ├── Dashboard/
│   ├── Finance/
│   └── Calendar/
└── Utilities/
```

### 1.2 CoreData Schema
Define `.xcdatamodeld` with 2 entities:

**Transaction**
- id: UUID
- amount: Double
- type: String (income / expense)
- category: String (Seeds / Fertilizer / Labor / Tools / Sales)
- note: String
- date: Date

**FarmActivity**
- id: UUID
- title: String
- type: String
- notes: String
- date: Date
- isNotified: Bool

### 1.3 Core Files to Create
- `Utilities/PersistenceController.swift` — NSPersistentContainer setup
- `ViewModels/FarmViewModel.swift` — shared ObservableObject with @Published arrays
- `SmartFarmApp.swift` — inject managedObjectContext via .environment
- `Views/MainTabView.swift` — TabView with 3 tabs: Dashboard, Finance, Calendar

### 1.4 Seed Data
Add `seedSampleData()` in PersistenceController — called once on first launch via `UserDefaults` flag.

**Deliverable:** Project builds and runs with empty tab view. Davy and Monineath can now branch off.

---

## Phase 2 — Parallel: Finance (Davy) + Calendar (Monineath)
> ធ្វើដំណាលគ្នា បន្ទាប់ពី Phase 1 រួច

### Davy — Finance Tracker

**Step 1: FinanceViewModel**
- `@Published var transactions: [Transaction]`
- `var totalIncome: Double`, `totalExpense: Double`, `profit: Double`
- `func add(amount:type:category:note:date:)`
- `func delete(_ transaction: Transaction)`
- Filter: `func filtered(by type: String) -> [Transaction]`

**Step 2: Views**
- `FinanceListView` — List + filter segmented control (All / Income / Expense)
- `SummaryCardView` — balance, income, expense in colored cards
- `AddTransactionView` — Form with TextField, Picker for category, DatePicker
- `TransactionDetailView` — read + edit + delete

**Step 3: Currency Formatting**
```swift
// NumberFormatter for KHR and USD
```

**Deliverable:** Finance tab fully functional with CRUD.

---

### Monineath — Calendar & Reminders

**Step 1: CalendarViewModel**
- `@Published var activities: [FarmActivity]`
- `@Published var selectedDate: Date`
- `func activitiesFor(date: Date) -> [FarmActivity]`
- `func add(title:type:notes:date:)`
- `func delete(_ activity: FarmActivity)`

**Step 2: Views**
- `CalendarView` — DatePicker + List of activities for selected date
- `AddActivityView` — Form with title, type Picker, notes, DatePicker
- `ActivityDetailView` — read + edit + delete

**Step 3: NotificationManager**
```swift
// Utilities/NotificationManager.swift
// requestPermission()
// schedule(for activity: FarmActivity)  — on the day at 08:00 + 1 day before
// cancel(for activity: FarmActivity)
```

**Deliverable:** Calendar tab functional with local notifications working.

---

## Phase 3 — Leader: Dashboard Integration

- Create `DashboardView` with 4–6 summary cards
- Pull data from FarmViewModel: recent transactions, upcoming activities, monthly profit
- NavigationLink from each card to the relevant tab/detail
- Show next 7 days reminders list

**Deliverable:** Dashboard shows live data from Finance and Calendar modules.

---

## Phase 4 — Davy និង Monineath: Advanced UI

- Create `Utilities/DesignSystem.swift` — colors, fonts, spacing constants
- Build reusable components: `FarmCard`, `PrimaryButton`, `SectionHeader`
- Add animations: `.transition(.opacity)` on lists, `.scaleEffect` on button tap
- Apply dark mode colors via `Color` assets
- Pull-to-refresh using `RefreshControl` via `UIViewRepresentable`

**Deliverable:** Consistent design system across all screens.

---

## Phase 5 — Davy និង Monineath: Export & Reports

- `ReportViewModel` — group transactions by month, calculate monthly profit/loss
- Bar chart using `GeometryReader` + `Rectangle` shapes (no Swift Charts)
- CSV export: loop transactions → comma-separated string → `UIActivityViewController`
- PDF export: `PDFKit` — draw text/chart onto `PDFPage`
- Share sheet via `UIActivityViewController` wrapped in `UIViewControllerRepresentable`

**Deliverable:** Monthly report screen with chart + share button.

---

## Phase 6 — Davy និង Monineath: Backup & Restore

- `BackupManager.swift`
  - `exportJSON() -> Data` — encode all Transactions + Activities to JSON
  - `importJSON(_ data: Data)` — decode and insert into CoreData
- `DocumentPickerView` — `UIDocumentPickerViewController` wrapped in `UIViewControllerRepresentable`
  - Save mode: write JSON file
  - Open mode: read JSON file and restore
- Weekly backup reminder via `UNUserNotificationCenter`
- iCloud Drive: use `FileManager` with `.url(for: .documentDirectory)` + iCloud container

**Deliverable:** Full backup and restore working across device restart.

---

## Build Order Summary

```
Phase 1 (Leader)
    └── Phase 2 (Davy + Monineath in parallel)
            └── Phase 3 (Leader)
                    └── Phase 4 (Davy + Monineath)
                            └── Phase 5 (Davy + Monineath)
                                    └── Phase 6 (Davy + Monineath)
```

## Definition of Done
- [ ] App builds with 0 errors and 0 warnings on Xcode 13
- [ ] All CRUD operations work and persist after app restart
- [ ] Notifications fire correctly when app is closed
- [ ] Export produces a valid CSV and PDF file
- [ ] Backup JSON can be restored on a fresh install
- [ ] UI looks correct in both light and dark mode
