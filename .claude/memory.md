# SmartFarm — Project Memory

ឯកសារនេះកត់ត្រា context, ការសម្រេចចិត្ត, និងព័ត៌មានសំខាន់ៗ
ដែលប្រើក្នុងការសាងសង់ SmartFarm app។

---

## Project Context

- **App:** SmartFarm iOS — កម្មវិធីសម្រាប់កសិករខ្នាតតូចនៅកម្ពុជា
- **Goal:** Finance tracking + activity scheduling + dashboard in one offline app
- **Version:** v1 — small-scale farmers only (medium-scale features planned for v2)
- **Repo:** https://github.com/Davy17601/smartfarm.git
- **Branch:** main

---

## Team

| Member | Role | Module |
|--------|------|--------|
| Leader (Supervisor) | Project Setup, Architecture, Dashboard, Export, Backup | Phases 1, 3, 4, 5, 6 (shared) |
| Davy | Finance Tracker, Navigation, Dashboard | Phase 2 + shared phases |
| Monineath | Calendar & Reminders, UI, Export, Backup | Phase 2 + shared phases |

---

## Environment Decisions

| Decision | Value | Why |
|----------|-------|-----|
| iOS Deployment Target | 14.0 | Davy & Monineath use Xcode 13 on VM — was 15.2, lowered to support all Xcode 13.x |
| Swift Version | 5.5 | Xcode 13 default |
| No 3rd-party packages | Zero deps | Xcode 13 VMs — avoid SPM/CocoaPods setup issues |
| No NavigationStack | Use NavigationView | NavigationStack is iOS 16+ |
| No .searchable | Custom TextField | .searchable is iOS 15+ |
| No Swift Charts | GeometryReader + Rectangle | Swift Charts is iOS 16+ |
| No #Preview macro | Use PreviewProvider | #Preview macro is Xcode 15+ |
| No @Observable | Use ObservableObject | @Observable macro is iOS 17+ |

---

## CoreData Entities

### Transaction
```
id: UUID, amount: Double, type: String, category: String, note: String, date: Date
```
- type values: "income" / "expense"
- category values: "Seeds", "Fertilizer", "Labor", "Tools", "Sales"

### FarmActivity
```
id: UUID, title: String, type: String, notes: String, date: Date, isNotified: Bool
```

---

## Key Architectural Decisions

- **PersistenceController** — singleton `shared` instance, injected via `.environment(\.managedObjectContext)`
- **FarmViewModel** — single shared `ObservableObject` passed via `@EnvironmentObject` to all views
- **FinanceViewModel** — owned by FinanceListView, uses `@FetchRequest` directly
- **CalendarViewModel** — owned by CalendarView, groups activities by date
- **Notifications** — scheduled in `NotificationManager` (static utility struct), not in ViewModel
- **Seed data** — loaded once via `UserDefaults` bool flag `"hasSeededData"`

---

## Files Already in Place

| File | Status | Notes |
|------|--------|-------|
| `SmartFarmApp.swift` | Exists | Needs PersistenceController + FarmViewModel injection |
| `ContentView.swift` | Exists — replace | Boilerplate Item list — replace with MainTabView |
| `Persistence.swift` | Exists | Already correct NSPersistentContainer setup |
| `SmartFarm.xcdatamodeld` | Exists — update | Currently only has `Item` entity — add Transaction, FarmActivity |
| `.claude/skills/smartfarm.md` | Exists | Skill with code templates and Xcode 13 rules |
| `.claude/plan.md` | Exists | Phased build plan |

---

## v2 Features (Not in v1 — Do Not Add Now)

- Multi-field / plot management
- Worker & labor attendance tracking
- Inventory & stock levels
- Yield recording per crop
- Profit per field / per crop
- Supplier contacts

---

## Khmer Language Notes

- Use Khmer for all UI labels and README text
- Keep technical words in English: Xcode, CoreData, MVVM, API, SwiftUI, etc.
- Wrong: `នឹង` (will/going to) — Right: `និង` (and)
- Currency: Riel = រៀល (KHR), Dollar = ដុល្លារ (USD)
