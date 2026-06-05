# /calendar — Build Calendar & Reminders Module

Implement the Calendar & Reminders tab for SmartFarm. Read `docs/Calendar.md` and `PLAN.md` first.

## What to build

1. **`Utilities/NotificationManager.swift`** (new file — register in xcodeproj):
   ```swift
   class NotificationManager {
       static let shared = NotificationManager()
       func requestPermission()
       // schedules 2 notifications: 1 day before at 8am + day-of at 8am
       func scheduleReminder(id: UUID, title: String, dueDate: Date)
       func cancelReminder(id: UUID)  // removes all pending notifications with that id prefix
   }
   ```
   Use `UNUserNotificationCenter`. Notification body: "⏰ \(title) — ថ្ងៃនេះ" / "ថ្ងៃស្អែក".

2. **`CalendarReminders/ViewModels/CalendarViewModel.swift`** (new):
   ```swift
   class CalendarViewModel: ObservableObject {
       @Published var selectedDate: Date = Date()
       var context: NSManagedObjectContext
       init(context: NSManagedObjectContext)
       func addReminder(title: String, dueDate: Date, note: String, repeatType: String)
       func toggleComplete(_ entity: ReminderEntity)
       func delete(_ entity: ReminderEntity)
   }
   ```
   `addReminder` saves to CoreData AND calls `NotificationManager.shared.scheduleReminder(...)`.
   `delete` also calls `NotificationManager.shared.cancelReminder(id:)`.

3. **`CalendarReminders/Views/CalendarTabView.swift`** (new):
   - Navigation title: "ប្រតិទិន"
   - `DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)` with `.graphical` style
   - Below: List of ReminderEntity where `dueDate` falls on `selectedDate` (same calendar day)
   - Each row: `ReminderRowView`
   - Toolbar "+" → sheet presenting `AddReminderView`
   - `@StateObject var viewModel = CalendarViewModel(context: ...)`

4. **`CalendarReminders/Views/ReminderRowView.swift`** (new):
   - Leading: checkmark button (circle / checkmark.circle.fill) → calls `viewModel.toggleComplete(_:)`
   - Center: title (strikethrough if completed) + time formatted ("8:00 ព្រឹក")
   - Trailing: repeat badge ("ប្រចាំថ្ងៃ" / "ប្រចាំសប្ដាហ៍" / "ប្រចាំខែ") if not "none"
   - Swipe-to-delete

5. **`CalendarReminders/Views/AddReminderView.swift`** (new):
   - Form sections:
     - ព័ត៌មាន: title TextField, date+time DatePicker (`.dateAndTime`)
     - ការរំឭក: repeat Picker (none=មិនដដែលៗ / daily=ប្រចាំថ្ងៃ / weekly=ប្រចាំសប្ដាហ៍ / monthly=ប្រចាំខែ)
     - កំណត់ចំណាំ: note TextField
   - Save button → `viewModel.addReminder(...)` + dismiss

## Repeat type values (match ReminderEntity.repeatType String)
- "none", "daily", "weekly", "monthly"

## Notification behavior
- 1 day before: fire at 8:00 AM the day before `dueDate`
- Day-of: fire at 8:00 AM on `dueDate`
- Notification identifier prefix: `"reminder-\(id.uuidString)"` + suffix `-before` / `-today`
- Request permission in `CalendarTabView.onAppear`

## Constraints
- iOS 14 / Xcode 13. Use `PreviewProvider`.
- Khmer labels for all UI text.
- Register all new files in xcodeproj.

## File registration
```bash
# For each new file, add to xcodeproj using xcodeproj gem
bundle exec ruby -e "require 'xcodeproj'; ..."
```
