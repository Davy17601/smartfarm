# SmartFarm Build Skill

You are helping build the SmartFarm iOS app — a SwiftUI MVVM app for Cambodian small-scale farmers.

## Environment (NON-NEGOTIABLE)
| Item | Value |
|------|-------|
| Xcode | 13.x — Davy & Monineath use Xcode 13 on Virtual VM |
| Swift | 5.5 |
| iOS Deployment Target | **14.0** (set in project.pbxproj) |
| Dependencies | None — no CocoaPods, no SPM packages |

## Team
- **Leader (Supervisor)**: Project Setup, Architecture, CoreData, Navigation, Dashboard, UI, Export, Backup
- **Davy**: Finance Tracker Module
- **Monineath**: Calendar & Reminders Module

## Project Folder Structure
```
SmartFarm/
├── Models/
│   ├── Transaction+CoreDataClass.swift
│   └── FarmActivity+CoreDataClass.swift
├── ViewModels/
│   ├── FarmViewModel.swift
│   ├── FinanceViewModel.swift
│   └── CalendarViewModel.swift
├── Views/
│   ├── MainTabView.swift
│   ├── Dashboard/
│   │   └── DashboardView.swift
│   ├── Finance/
│   │   ├── FinanceListView.swift
│   │   ├── AddTransactionView.swift
│   │   └── TransactionDetailView.swift
│   └── Calendar/
│       ├── CalendarView.swift
│       └── AddActivityView.swift
└── Utilities/
    ├── PersistenceController.swift
    ├── NotificationManager.swift
    └── DesignSystem.swift
```

## CoreData Entities

### Transaction
- `id: UUID`
- `amount: Double`
- `type: String` (income / expense)
- `category: String` (Seeds, Fertilizer, Labor, Tools, Sales)
- `note: String`
- `date: Date`

### FarmActivity
- `id: UUID`
- `title: String`
- `type: String`
- `notes: String`
- `date: Date`
- `isNotified: Bool`

## Xcode 13 Compatibility Rules

### ALWAYS USE (safe on Xcode 13 / iOS 14+)
- `NavigationView` + `NavigationLink(destination:label:)` — never `NavigationStack`
- `TabView` with `.tabItem`
- `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@Published`
- `@FetchRequest(sortDescriptors:animation:)` for CoreData
- `ToolbarItem(placement: .navigationBarTrailing)` / `.navigationBarLeading`
- `PreviewProvider` + `struct X_Previews: PreviewProvider` (not `#Preview` macro)
- `UNUserNotificationCenter` for local notifications
- `UIActivityViewController` wrapped in `UIViewControllerRepresentable`
- `UIDocumentPickerViewController` wrapped in `UIViewControllerRepresentable`
- `PDFKit` for PDF export
- `GeometryReader` + `Rectangle` shapes for bar charts

### NEVER USE (unavailable on Xcode 13)
- `NavigationStack`, `NavigationSplitView` — iOS 16+
- `.searchable()` modifier — use a custom `TextField` search bar instead
- `Charts` / `Chart {}` — iOS 16+ (Swift Charts framework)
- `SwiftData`, `@Model` macro — iOS 17+
- `ShareLink` — iOS 16+, use `UIActivityViewController` instead
- `@Observable` macro — iOS 17+
- `ContentUnavailableView` — iOS 17+
- `#Preview { }` macro — Xcode 15+, use `PreviewProvider` instead

## Key Rules
- iOS deployment target: **14.0** — every API used must have iOS 14 availability
- Currency: support both Riel (KHR) and Dollar (USD) via `NumberFormatter`
- Charts: `GeometryReader` + `Rectangle` shapes only — no Swift Charts
- All data must persist via CoreData; no UserDefaults for business data
- Notifications via `UNUserNotificationCenter` (1 day before + on the day at 08:00)
- PDF export via `PDFKit`, CSV export via string + `UIActivityViewController`
- Backup: JSON export/import via `UIDocumentPickerViewController`

## When the user asks to build a module, follow this process:

### For Leader modules (Architecture / CoreData / Navigation / Dashboard / UI / Export / Backup):
1. Scaffold the folder structure first
2. Create `PersistenceController.swift` with `NSPersistentContainer`
3. Create `FarmViewModel.swift` as `ObservableObject` with `@Published` arrays
4. Build `MainTabView.swift` with 3 tabs: Dashboard, Finance, Calendar
5. Implement each sub-feature in order: model → viewmodel → view

### For Davy — Finance Tracker:
1. Create `FinanceViewModel.swift` with filtering logic (all / income / expense)
2. Build `FinanceListView.swift` with a summary card (balance, income, expenses)
3. Build `AddTransactionView.swift` with category `Picker` and amount `TextField`
4. Add `TransactionDetailView.swift` with edit/delete support
5. Format currency: `NumberFormatter` with KHR and USD options

### For Monineath — Calendar & Reminders:
1. Create `CalendarViewModel.swift` with activities grouped by date
2. Build `CalendarView.swift` using `DatePicker` + list of activities for selected date
3. Build `AddActivityView.swift` with type picker and notes field
4. Implement `NotificationManager.swift` — request permission, schedule/cancel notifications
5. On save: schedule notification 1 day before and on the day at 8:00 AM

## Code Templates

### FarmViewModel.swift (starter)
```swift
import CoreData
import Combine

class FarmViewModel: ObservableObject {
    let container: NSPersistentContainer

    @Published var transactions: [Transaction] = []
    @Published var activities: [FarmActivity] = []

    init() {
        container = NSPersistentContainer(name: "SmartFarm")
        container.loadPersistentStores { _, error in
            if let error = error { fatalError("CoreData failed: \(error)") }
        }
        fetchAll()
    }

    func fetchAll() {
        transactions = (try? container.viewContext.fetch(Transaction.fetchRequest())) ?? []
        activities = (try? container.viewContext.fetch(FarmActivity.fetchRequest())) ?? []
    }

    func save() {
        try? container.viewContext.save()
        fetchAll()
    }
}
```

### NotificationManager.swift (starter)
```swift
import UserNotifications

struct NotificationManager {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func schedule(for activity: FarmActivity) {
        guard let date = activity.date else { return }
        let content = UNMutableNotificationContent()
        content.title = activity.title ?? "Farm Reminder"
        content.sound = .default

        // On the day at 8:00 AM
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = 8
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: activity.id?.uuidString ?? UUID().uuidString,
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
```

## Invocation
When the user says "build [module name]" or "scaffold [module name]", generate the complete Swift files for that module following the templates and rules above. Always include:
- The Swift file with full implementation
- The file path where it should be saved
- Any CoreData `.xcdatamodeld` changes needed
