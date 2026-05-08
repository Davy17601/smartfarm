# SmartFarm Build Skill

You are helping build the SmartFarm iOS app — a SwiftUI MVVM app for Cambodian small-scale farmers.
Read `.claude/memory.md` for full project context and `.claude/plan.md` for the phased build order.

---

## Environment (NON-NEGOTIABLE)

| Item | Value |
|------|-------|
| Xcode | 13.x — Davy & Monineath use Xcode 13 on Virtual VM |
| Swift | 5.5 |
| iOS Deployment Target | **14.0** (already set in project.pbxproj) |
| Dependencies | None — no CocoaPods, no SPM packages |

---

## Team

| Member | Owns |
|--------|------|
| Leader | Phase 1 (Foundation), Phase 3 (Dashboard) |
| Davy | Finance Tracker, Navigation, Tab Coordination |
| Monineath | Calendar & Reminders |
| Davy + Monineath | CoreData, UI, Export, Backup (shared) |

---

## Xcode 13 Rules

### ALWAYS USE
- `NavigationView` + `NavigationLink(destination:label:)` — never `NavigationStack`
- `TabView` + `.tabItem`
- `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@Published`
- `@FetchRequest(sortDescriptors:animation:)` for CoreData
- `ToolbarItem(placement: .navigationBarTrailing / .navigationBarLeading)`
- `struct X_Previews: PreviewProvider` — never `#Preview {}` macro
- `UNUserNotificationCenter` for notifications
- `UIActivityViewController` in `UIViewControllerRepresentable` for sharing
- `UIDocumentPickerViewController` in `UIViewControllerRepresentable` for files
- `PDFKit` for PDF export
- `GeometryReader` + `Rectangle` for bar charts
- `if let x = x { }` — never `if let x { }` (shorthand requires Swift 5.7 / Xcode 14)

### NEVER USE
- `NavigationStack`, `NavigationSplitView` — iOS 16+
- `.searchable()` — use custom `TextField` search bar
- `Charts` / `Chart {}` — iOS 16+
- `SwiftData`, `@Model` — iOS 17+
- `ShareLink` — iOS 16+
- `@Observable` — iOS 17+
- `ContentUnavailableView` — iOS 17+
- `#Preview {}` — Xcode 15+

---

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
│   │   ├── SummaryCardView.swift
│   │   ├── AddTransactionView.swift
│   │   └── TransactionDetailView.swift
│   └── Calendar/
│       ├── CalendarView.swift
│       ├── AddActivityView.swift
│       └── ActivityDetailView.swift
└── Utilities/
    ├── PersistenceController.swift
    ├── NotificationManager.swift
    ├── BackupManager.swift
    └── DesignSystem.swift
```

---

## CoreData Entities

### Transaction
```
id: UUID | amount: Double | type: String | category: String | note: String | date: Date
type → "income" / "expense"
category → "Seeds" / "Fertilizer" / "Labor" / "Tools" / "Sales"
```

### FarmActivity
```
id: UUID | title: String | type: String | notes: String | date: Date | isNotified: Bool
```

---

## Code Templates

### PersistenceController.swift
```swift
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SmartFarm")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData failed: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
```

### FarmViewModel.swift
```swift
import CoreData
import SwiftUI

class FarmViewModel: ObservableObject {
    let context: NSManagedObjectContext

    @Published var transactions: [Transaction] = []
    @Published var activities: [FarmActivity] = []

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchAll()
    }

    func fetchAll() {
        transactions = (try? context.fetch(Transaction.fetchRequest())) ?? []
        activities = (try? context.fetch(FarmActivity.fetchRequest())) ?? []
    }

    func save() {
        try? context.save()
        fetchAll()
    }
}
```

### MainTabView.swift
```swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }
            FinanceListView()
                .tabItem { Label("Finance", systemImage: "dollarsign.circle") }
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
        }
    }
}
```

### NotificationManager.swift
```swift
import UserNotifications

struct NotificationManager {
    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func schedule(for activity: FarmActivity) {
        guard let date = activity.date else { return }
        let content = UNMutableNotificationContent()
        content.title = activity.title ?? "Farm Reminder"
        content.sound = .default

        // On the day at 08:00
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = 8
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let id = activity.id?.uuidString ?? UUID().uuidString
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        )

        // 1 day before at 08:00
        if let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: date) {
            var comps2 = Calendar.current.dateComponents([.year, .month, .day], from: dayBefore)
            comps2.hour = 8
            let trigger2 = UNCalendarNotificationTrigger(dateMatching: comps2, repeats: false)
            UNUserNotificationCenter.current().add(
                UNNotificationRequest(identifier: id + "_before", content: content, trigger: trigger2)
            )
        }
    }

    static func cancel(for activity: FarmActivity) {
        let id = activity.id?.uuidString ?? ""
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [id, id + "_before"]
        )
    }
}
```

### PreviewProvider pattern (Xcode 13)
```swift
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        MyView()
            .environment(\.managedObjectContext,
                PersistenceController(inMemory: true).container.viewContext)
    }
}
```

---

## When the user says "build [module]"

Generate complete Swift files for that module following all rules above. Always output:
1. Full Swift file content
2. File path where it should be saved (relative to `SmartFarm/`)
3. Any `.xcdatamodeld` changes needed
4. Any changes needed in `SmartFarmApp.swift`

Check `.claude/plan.md` for the correct build order before starting any module.
