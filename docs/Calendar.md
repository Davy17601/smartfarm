# Calendar & Reminders Module Spec

**Owner:** Monineath  
**Skill:** `/calendar`  
**Tab:** ប្រតិទិន (Tab 3)

---

## Purpose
Farmers schedule farm activities (planting, watering, fertilizing, harvesting) and receive local notifications the day before and on the day — even when the app is closed.

---

## CoreData Entity: ReminderEntity

| Attribute | Type | Default | Notes |
|-----------|------|---------|-------|
| id | UUID | auto | used as notification id prefix |
| title | String | "" | e.g. "ស្រោចទឹក" |
| dueDate | Date | now | date + time of the activity |
| note | String | nil | optional |
| isCompleted | Bool | NO | toggled by checkmark |
| repeatType | String | "none" | "none" / "daily" / "weekly" / "monthly" |

---

## CalendarViewModel (ObservableObject)

```swift
class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext)
    
    func addReminder(title: String, dueDate: Date, note: String, repeatType: String)
    // → saves ReminderEntity to CoreData
    // → calls NotificationManager.shared.scheduleReminder(...)
    
    func toggleComplete(_ entity: ReminderEntity)
    // → flips isCompleted, saves
    
    func delete(_ entity: ReminderEntity)
    // → calls NotificationManager.shared.cancelReminder(id: entity.id!)
    // → deletes from CoreData, saves
    
    func remindersForDate(_ date: Date, from results: FetchedResults<ReminderEntity>) -> [ReminderEntity]
    // → filters results where Calendar.current.isDate(entity.dueDate!, inSameDayAs: date)
}
```

---

## NotificationManager

```swift
class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission()
    // UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    
    func scheduleReminder(id: UUID, title: String, dueDate: Date)
    // Notification 1: "reminder-{id}-before"
    //   body: "ការរំឭក: \(title) — ស្អែក!"
    //   trigger: dueDate - 1 day at 08:00 AM
    // Notification 2: "reminder-{id}-today"
    //   body: "ការរំឭក: \(title) — ថ្ងៃនេះ!"
    //   trigger: dueDate at 08:00 AM
    
    func cancelReminder(id: UUID)
    // removePendingNotificationRequests(withIdentifiers: ["reminder-{id}-before", "reminder-{id}-today"])
}
```

---

## View Hierarchy

```
CalendarTabView (NavigationView)
├── DatePicker (displayedComponents: .date, style: .graphical)
│   → selectedDate binding
└── List (filtered to selectedDate)
    └── ReminderRowView (each matching reminder)
        ├── Checkmark button (toggleComplete)
        ├── Title + time
        └── Repeat badge
Sheet: AddReminderView
Toolbar: "+" button
```

---

## ReminderRowView Layout
```
[✓ or ○]  [Title (strikethrough if completed)]    [Repeat badge]
           [Time: "8:00 ព្រឹក"]
```
- Checkmark tapped → `viewModel.toggleComplete(entity)`
- Swipe left → Delete action → `viewModel.delete(entity)`

---

## AddReminderView Form

```
Form {
  Section("ព័ត៌មាន") {
    TextField("ចំណងជើង", text: $title)
    DatePicker("កាលបរិច្ឆេទ និងម៉ោង", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
  }
  Section("ការដដែលៗ") {
    Picker("ប្រភេទ", selection: $repeatType) {
      Text("មិនដដែលៗ").tag("none")
      Text("ប្រចាំថ្ងៃ").tag("daily")
      Text("ប្រចាំសប្ដាហ៍").tag("weekly")
      Text("ប្រចាំខែ").tag("monthly")
    }
  }
  Section("កំណត់ចំណាំ") {
    TextField("កំណត់ចំណាំ", text: $note)
  }
}
```

---

## Khmer Labels

| English | Khmer |
|---------|-------|
| Calendar | ប្រតិទិន |
| Add Reminder | បន្ថែមការរំឭក |
| Title | ចំណងជើង |
| Date and Time | កាលបរិច្ឆេទ និងម៉ោង |
| Repeat | ការដដែលៗ |
| None | មិនដដែលៗ |
| Daily | ប្រចាំថ្ងៃ |
| Weekly | ប្រចាំសប្ដាហ៍ |
| Monthly | ប្រចាំខែ |
| Note | កំណត់ចំណាំ |
| Save | រក្សាទុក |
| Cancel | បោះបង់ |
| Delete | លុប |
| Completed | បានបញ្ចប់ |
| Tomorrow reminder | ការរំឭក: ... — ស្អែក! |
| Today reminder | ការរំឭក: ... — ថ្ងៃនេះ! |

---

## Notification Behavior
- Permission requested on first `CalendarTabView.onAppear`
- Each reminder gets 2 notification slots: day-before (08:00) + day-of (08:00)
- Deleting or completing a reminder should cancel its pending notifications
- Notifications fire even when app is closed (local notifications, not push)

---

---

## UX/UI Design

### Visual Style
- **Color scheme:** white on `Color(.systemGroupedBackground)` (light mode) / dark grouped (dark mode)
- **Calendar accent:** `Color(red: 0.2, green: 0.6, blue: 0.3)` (farm green) — tints selected date dot
- **Completed reminder:** title gets `.strikethrough()`, row fades to `.opacity(0.45)`
- **Urgency colors:** today = red · tomorrow = orange · future = `.secondary`
- **Repeat badge:** small pill — `.caption2`, colored background, `cornerRadius: 6`
- **Font:** `.subheadline.medium` for titles, `.caption` for time + badges

---

### Screen Layout Ideas

Three layout options — pick one or mix elements from each.

---

#### Option A — Full Graphical Calendar + List (Recommended)
Standard iOS Calendar feel. DatePicker takes top half; matching reminders listed below.

```
┌─────────────────────────────────────┐
│  NavigationBar: "ប្រតិទិន"       [+] │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │  < មិថុនា ២០២៦ >            │    │
│  │  អា  ច  អ  ព  ព  សុ  ស    │    │  ← graphical DatePicker
│  │   1   2  3  4  5  6  7     │    │    (.graphical style)
│  │   8   9 10 11 12 13 14     │    │
│  │  ···  ·  ·  ·  ·  · ●17   │    │    selected date = green dot
│  │  ···                       │    │
│  └─────────────────────────────┘    │
│                                     │
│  ── ១៧ មិថុនា ២០២៦ ─────────────── │  ← header: selected date
│  ┌─────────────────────────────┐    │
│  │ ○  ស្រោចទឹក          ០៨:០០│    │  ← ReminderRowView
│  │    [ប្រចាំថ្ងៃ]  🔴 ថ្ងៃនេះ │    │
│  ├─────────────────────────────┤    │
│  │ ✓  បាច់ជី             ១០:០០│    │  ← completed (strikethrough + faded)
│  │    [ប្រចាំសប្ដាហ៍]          │    │
│  └─────────────────────────────┘    │
│  + បន្ថែមការរំឭក                    │  ← inline add shortcut at bottom of list
└─────────────────────────────────────┘
```
**Best for:** farmers who think in dates — pick a day, see what's due.  
**Trade-off:** graphical calendar is tall (~300pt) — less list space on small phones.

---

#### Option B — Compact Week Strip + Agenda List
Horizontal scrollable week strip at the top (like Fantastical or Google Calendar). Much more list space.

```
┌─────────────────────────────────────┐
│  NavigationBar: "ប្រតិទិន"       [+] │
├─────────────────────────────────────┤
│  < មិថុនា ២០២៦ >                    │  ← month label + prev/next arrows
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐│
│  │អា│ │ច │ │អ │ │ព │ │ព │ │សុ│ │ ●││  ← horizontal week strip
│  │15│ │16│ │17│ │18│ │19│ │20│ │21││    selected = filled green circle
│  └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘│    dots below day = has reminders
│  · · ·    ·         ·              │  ← activity dots
│  ─────────────────────────────────  │
│  ── ១៧ មិថុនា ──────────────────── │
│  │ ○  ស្រោចទឹក   ០៨:០០  [ថ្ងៃនេះ]│
│  │ ✓  បាច់ជី     ១០:០០           │
│  ── ១៨ មិថុនា ──────────────────── │
│  │ ○  ច្រូតកាត់  ០៧:០០           │
│  ── ១៩ មិថុនា ──────────────────── │
│  │ (គ្មានការរំឭក)                 │
└─────────────────────────────────────┘
```
**Best for:** users who want to see multiple days at once; agenda-style view feels familiar.  
**Trade-off:** requires custom week strip component (more SwiftUI work than `.graphical` DatePicker).

---

#### Option C — Month Overview with Activity Heatmap
Full month grid where each day cell is color-coded by number of reminders. Tap a day → slide up sheet with that day's list.

```
┌─────────────────────────────────────┐
│  NavigationBar: "ប្រតិទិន"       [+] │
├─────────────────────────────────────┤
│  < មិថុនា ២០២៦ >                    │
│  ┌───┬───┬───┬───┬───┬───┬───┐     │
│  │ ១ │ ២ │ ③ │ ④ │ ⑤ │ ⑥ │ ⑦ │     │  ← each cell: day number
│  ├───┼───┼───┼───┼───┼───┼───┤     │    ③ = 3 reminders → green tint
│  │   │   │ ░ │ ░░│   │ ● │   │     │    ● = selected (solid green)
│  ├───┼───┼───┼───┼───┼───┼───┤     │
│  │   │   │   │   │   │   │   │     │
│  └───┴───┴───┴───┴───┴───┴───┘     │
│  Legend: ░ = មានការរំឭក  ● = ជ្រើស  │
│  ─────────────────────────────────  │
│  ── ១៧ មិថុនា ──────────────────── │
│  │ ○  ស្រោចទឹក     ០៨:០០         │
│  │ ○  បន្លិចទឹក    ១៦:០០         │
└─────────────────────────────────────┘
```
**Best for:** at-a-glance busy days — farmers plan crop cycles a month ahead.  
**Trade-off:** most complex to implement (custom grid, color logic); smaller tap targets on 7-column grid.

---

### ReminderRowView Detail Design
```
HStack(alignment: .top, spacing: 12) {
  // Checkmark toggle
  Button(action: { viewModel.toggleComplete(entity) }) {
    Image(systemName: entity.isCompleted ? "checkmark.circle.fill" : "circle")
      .font(.title3)
      .foregroundColor(entity.isCompleted ? .green : .secondary)
  }
  .buttonStyle(.plain)

  // Content
  VStack(alignment: .leading, spacing: 4) {
    Text(entity.title ?? "")
      .font(.subheadline).fontWeight(.medium)
      .strikethrough(entity.isCompleted)
      .foregroundColor(entity.isCompleted ? .secondary : .primary)
    HStack(spacing: 6) {
      Text(timeString(entity.dueDate))   // "០៨:០០ ព្រឹក"
        .font(.caption).foregroundColor(.secondary)
      if entity.repeatType != "none" {
        Text(repeatLabel(entity.repeatType))  // "ប្រចាំថ្ងៃ"
          .font(.caption2).foregroundColor(.white)
          .padding(.horizontal, 6).padding(.vertical, 2)
          .background(Color.blue.opacity(0.8))
          .cornerRadius(6)
      }
    }
  }

  Spacer()

  // Urgency badge
  Text(urgencyLabel(entity.dueDate))
    .font(.caption2).bold()
    .padding(.horizontal, 8).padding(.vertical, 3)
    .background(urgencyColor(entity.dueDate).opacity(0.15))
    .foregroundColor(urgencyColor(entity.dueDate))
    .cornerRadius(8)
}
.opacity(entity.isCompleted ? 0.45 : 1.0)
.padding(.vertical, 6)
```

---

### AddReminderView Design
Sheet with navigation bar buttons (not Form toolbar):
```
╔══════════════════════════════════════╗
║  បោះបង់   បន្ថែមការរំឭក   រក្សាទុក ║
╠══════════════════════════════════════╣
║  Form {                              ║
║    Section("ព័ត៌មាន") {             ║
║      TextField "ចំណងជើង"            ║  ← e.g. "ស្រោចទឹក"
║      DatePicker (.dateAndTime)       ║
║    }                                 ║
║    Section("ការដដែលៗ") {            ║
║      Picker (inline style)           ║
║        ○ មិនដដែលៗ                   ║
║        ○ ប្រចាំថ្ងៃ                  ║
║        ○ ប្រចាំសប្ដាហ៍               ║
║        ○ ប្រចាំខែ                   ║
║    }                                 ║
║    Section("កំណត់ចំណាំ") {          ║
║      TextField multiline             ║
║    }                                 ║
║  }                                   ║
╚══════════════════════════════════════╝
```
- Use `.pickerStyle(.inline)` for repeat type so all options show without extra tap
- `DatePicker` shows both date + time in one row (compact style on iOS 14)

---

### Spacing & Padding
| Element | Value |
|---------|-------|
| Calendar horizontal padding | `0` (DatePicker fills width) |
| List row vertical padding | `6` |
| Badge horizontal padding | `6` |
| Badge corner radius | `6` |
| Section header font | `.subheadline.bold` |

---

## Files to Implement

| File | Status |
|------|--------|
| `Utilities/NotificationManager.swift` | new |
| `CalendarReminders/ViewModels/CalendarViewModel.swift` | new |
| `CalendarReminders/Views/CalendarTabView.swift` | new |
| `CalendarReminders/Views/AddReminderView.swift` | new |
| `CalendarReminders/Views/ReminderRowView.swift` | new |
