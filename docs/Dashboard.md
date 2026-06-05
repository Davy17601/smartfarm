# Dashboard Module Spec

**Owner:** Davy + Monineath  
**Skill:** `/dashboard`  
**Tab:** ផ្ទះ (Tab 1)

---

## Purpose
Home screen giving farmers an at-a-glance view of their farm's financial health, upcoming tasks, and recent activity — all in one place.

---

## View Hierarchy

```
MainTabView → Tab 1
└── DashboardView (NavigationView)
    └── ScrollView
        ├── Greeting Section
        ├── This Month Summary (3 SummaryCardView)
        ├── Upcoming Reminders Section (next 7 days)
        └── Recent Transactions Section (last 5)
```

---

## SummaryCardView (reusable)

```swift
struct SummaryCardView: View {
    var icon: String     // SF Symbol
    var label: String    // Khmer label
    var amount: String   // pre-formatted (use Formatters.currency)
    var color: Color     // card accent color
}
```

Visual: RoundedRectangle background (white/systemBackground), `color`-tinted icon top-left, label below icon, large amount text at bottom. `.shadow(radius: 4)`.

---

## Data Sources

### This Month Cards
```swift
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)],
    predicate: NSPredicate(format: "date >= %@ AND date <= %@", startOfMonth as CVarArg, endOfMonth as CVarArg)
) var monthTransactions: FetchedResults<TransactionEntity>
```
- **ចំណូល** = sum where type == "Income" — green, icon `arrow.down.circle.fill`
- **ចំណាយ** = sum where type == "Expense" — red, icon `arrow.up.circle.fill`
- **ចំណេញ** = Income − Expense — blue (positive) or red (negative), icon `chart.line.uptrend.xyaxis`

### Upcoming Reminders
```swift
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \ReminderEntity.dueDate, ascending: true)],
    predicate: NSPredicate(format: "dueDate >= %@ AND dueDate <= %@ AND isCompleted == NO",
                           Date() as CVarArg, sevenDaysLater as CVarArg),
    fetchLimit: 5  // Note: fetchLimit on FetchRequest via NSFetchRequest
) var upcomingReminders: FetchedResults<ReminderEntity>
```

### Recent Transactions
```swift
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
    // fetchLimit 5 via .nsFetchRequest.fetchLimit in .onAppear or use a separate fetch
) var recentTransactions: FetchedResults<TransactionEntity>
```
Show only first 5 items from the result.

---

## Section Layout

### Greeting Section
```
ថ្ងៃទី [date]
សួស្ដី! Farm របស់អ្នក 🌾
```
Left-aligned, padding top 16.

### This Month (ខែនេះ)
Section header: "ខែនេះ"
HStack of 3 `SummaryCardView` with equal width (using `GeometryReader` or `.frame(maxWidth: .infinity)`).

### Upcoming Reminders (ការរំឭកខាងមុខ)
Section header + "មើលទាំងអស់" trailing button.
Each row: calendar icon + title + date formatted as "DD/MM HH:mm".
If empty: "គ្មានការរំឭកក្នុង 7 ថ្ងៃខាងមុខ" gray text.

### Recent Transactions (ប្រតិបត្តិការចុងក្រោយ)
Section header + "មើលទាំងអស់" trailing button.
Each row: color dot (green/red) + title + amount + short date.
If empty: "គ្មានប្រតិបត្តិការ" gray text.

---

## Khmer Labels

| English | Khmer |
|---------|-------|
| Dashboard / Home | ផ្ទះ |
| This month | ខែនេះ |
| Income | ចំណូល |
| Expense | ចំណាយ |
| Profit | ចំណេញ |
| Upcoming Reminders | ការរំឭកខាងមុខ |
| Recent Transactions | ប្រតិបត្តិការចុងក្រោយ |
| See all | មើលទាំងអស់ |
| No reminders in next 7 days | គ្មានការរំឭកក្នុង 7 ថ្ងៃខាងមុខ |
| No transactions | គ្មានប្រតិបត្តិការ |

---

---

## UX/UI Design

### Visual Style
- **Color scheme:** light green tones (`Color(red: 0.9, green: 0.97, blue: 0.9)` background) — evokes nature/farm
- **Card background:** `.white` with `cornerRadius: 16` and `shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)`
- **Accent colors:**
  - Income: `Color.green` / `Color(red: 0.2, green: 0.7, blue: 0.3)`
  - Expense: `Color.red` / `Color(red: 0.9, green: 0.2, blue: 0.2)`
  - Profit (positive): `Color.blue` / `Color(red: 0.2, green: 0.4, blue: 0.9)`
  - Profit (negative): same red as expense
- **Typography:** `.title2` for amounts, `.caption` for labels, `.headline` for section headers
- **Font:** system default (supports Khmer script automatically on iOS)

---

### Screen Layout Ideas

Three layout options — pick one or mix elements from each.

---

#### Option A — Hero Banner (Recommended)
Full-width gradient hero at the top; cards float below overlapping it. Feels modern and premium.

```
┌─────────────────────────────────────┐
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
│  ░  🌾 សួស្ដី! Farm របស់អ្នក      ░  │  ← tall green gradient hero (height 180)
│  ░     ថ្ងៃ ៥ មិថុនា ២០២៦         ░  │    no NavigationBar title (inline)
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
│       ┌────────┐ ┌────────┐         │
│       │ ចំណូល │ │ ចំណាយ │         │  ← 2 cards overlap the hero bottom edge
│       │ 1.5M ៛│ │ 0.8M ៛│         │    (negative offset: .offset(y: -32))
│       └────────┘ └────────┘         │
│            ┌──────────┐             │
│            │ ចំណេញ   │             │  ← profit card centered below
│            │ +0.7M ៛ │             │
│            └──────────┘             │
│                                     │
│  ── ការរំឭក ──────── [មើលទាំងអស់] │
│  ┌─────────────────────────────┐    │
│  │ 📅 ស្រោចទឹក    [ស្អែក 🔴]  │    │
│  │ 📅 បាច់ជី      [០៦/០៨ ⚪]  │    │
│  └─────────────────────────────┘    │
│                                     │
│  ── ប្រតិបត្តិការ ── [មើលទាំងអស់] │
│  ┌─────────────────────────────┐    │
│  │ 🟢 លក់ស្រូវ    +1,500,000 ៛ │    │
│  │ 🔴 ទិញជី        -250,000 ៛  │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```
**Best for:** strong first impression, shows brand identity immediately.  
**Trade-off:** hero takes screen space — less content visible above the fold.

---

#### Option B — Compact Scrollable Feed
No large hero. Tight, information-dense layout. Good for farmers who check the app quickly in the field.

```
┌─────────────────────────────────────┐
│  NavigationBar: "ផ្ទះ"         [🔔] │  ← bell icon for reminders shortcut
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │ ☀️  ថ្ងៃ ៥ មិថុនា           │    │  ← thin date strip (height 44, green tint)
│  └─────────────────────────────┘    │
│                                     │
│  ┌──────┐  ┌──────┐  ┌──────┐      │
│  │ ↓    │  │ ↑    │  │ ≈    │      │  ← 3 equal cards, compact (height ~80)
│  │ ចំណូល│  │ចំណាយ│  │ចំណេញ│      │
│  │1.5M ៛│  │0.8M ៛│  │0.7M ៛│      │
│  └──────┘  └──────┘  └──────┘      │
│                                     │
│  ── ការរំឭក (2) ──── [មើលទាំងអស់] │  ← (2) shows count badge
│  │ 📅 ស្រោចទឹក            ស្អែក  │
│  │ 📅 បាច់ជី              ០៦/០៨ │
│  ─────────────────────────────────  │
│  ── ប្រតិបត្តិការ ── [មើលទាំងអស់] │
│  │ 🟢 លក់ស្រូវ       +1,500,000 ៛│
│  │ 🔴 ទិញជី           -250,000 ៛ │
│  │ 🟢 លក់បន្លែ        +200,000 ៛ │
└─────────────────────────────────────┘
```
**Best for:** quick daily check — maximum info above the fold with no scrolling.  
**Trade-off:** denser feel, less visual polish.

---

#### Option C — Card Feed (Instagram-style sections)
Each section is its own floating card. Feels like a clean dashboard app. Easy to extend with new sections later.

```
┌─────────────────────────────────────┐
│  NavigationBar: "ផ្ទះ"               │
├─────────────────────────────────────┤
│  ScrollView (bg: Color(.systemGroupedBackground))
│                                     │
│  ╔═════════════════════════════╗    │
│  ║ 🌾 Farm របស់អ្នក           ║    │  ← Greeting card (white, rounded)
│  ║    ថ្ងៃ ៥ មិថុនា ២០២៦      ║    │
│  ╚═════════════════════════════╝    │
│                                     │
│  ╔═════════════════════════════╗    │
│  ║  ខែនេះ                      ║    │  ← Finance summary card
│  ║  ┌──────┐ ┌──────┐ ┌──────┐║    │
│  ║  │ ចំណូល│ │ចំណាយ│ │ចំណេញ│║    │
│  ║  │1.5M ៛│ │0.8M ៛│ │+0.7M│║    │
│  ║  └──────┘ └──────┘ └──────┘║    │
│  ╚═════════════════════════════╝    │
│                                     │
│  ╔═════════════════════════════╗    │
│  ║  ការរំឭក          [មើលទាំងអស់]║  │  ← Reminders card
│  ║  📅 ស្រោចទឹក      [ស្អែក]  ║    │
│  ║  📅 បាច់ជី        [០៦/០៨] ║    │
│  ╚═════════════════════════════╝    │
│                                     │
│  ╔═════════════════════════════╗    │
│  ║  ប្រតិបត្តិការ    [មើលទាំងអស់]║  │  ← Transactions card
│  ║  🟢 លក់ស្រូវ  +1,500,000 ៛ ║    │
│  ║  🔴 ទិញជី     -250,000 ៛   ║    │
│  ╚═════════════════════════════╝    │
└─────────────────────────────────────┘
```
**Best for:** clean, structured feel — easy to add new "cards" (weather, quick actions) in the future.  
**Trade-off:** more scrolling required; sections feel separate rather than unified.

---

### Greeting Card
```
RoundedRectangle(cornerRadius: 16)
  .fill(LinearGradient(
      colors: [Color(red:0.25,green:0.6,blue:0.3), Color(red:0.15,green:0.45,blue:0.2)],
      startPoint: .topLeading, endPoint: .bottomTrailing))
  .frame(height: 90)
  .overlay(
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("សួស្ដី! Farm របស់អ្នក 🌾").font(.headline).foregroundColor(.white)
        Text(Formatters.date(Date())).font(.subheadline).foregroundColor(.white.opacity(0.85))
      }
      Spacer()
    }.padding()
  )
```

---

### SummaryCardView Design
```
VStack(alignment: .leading, spacing: 8) {
  HStack {
    Image(systemName: icon)
      .foregroundColor(color)
      .font(.title3)
    Spacer()
  }
  Text(label)
    .font(.caption)
    .foregroundColor(.secondary)
  Text(amount)
    .font(.title3).bold()
    .foregroundColor(color)
    .minimumScaleFactor(0.6)
    .lineLimit(1)
}
.padding(14)
.background(Color.white)
.cornerRadius(16)
.shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
```
Cards sit in an `HStack(spacing: 10)` with `.frame(maxWidth: .infinity)` on each card.

---

### Section Header Style
```swift
HStack {
  Text("ខែនេះ")
    .font(.headline)
    .foregroundColor(.primary)
  Spacer()
  // optional "see all" button (Button with Text in .caption blue)
}
.padding(.horizontal)
.padding(.top, 8)
```

---

### Reminder Row Design
```
HStack(spacing: 12) {
  Image(systemName: "calendar.badge.clock")
    .foregroundColor(.orange)
    .frame(width: 32)
  VStack(alignment: .leading, spacing: 2) {
    Text(reminder.title ?? "")
      .font(.subheadline).fontWeight(.medium)
    Text(Formatters.shortDate(reminder.dueDate ?? Date()))
      .font(.caption).foregroundColor(.secondary)
  }
  Spacer()
  // Urgency badge: "ថ្ងៃនេះ" (red) / "ស្អែក" (orange) / date string (gray)
  Text(urgencyLabel(reminder.dueDate))
    .font(.caption2).bold()
    .padding(.horizontal, 8).padding(.vertical, 3)
    .background(urgencyColor(reminder.dueDate).opacity(0.15))
    .foregroundColor(urgencyColor(reminder.dueDate))
    .cornerRadius(8)
}
.padding(.vertical, 6)
```

Urgency logic:
- Same day → "ថ្ងៃនេះ" red badge
- Tomorrow → "ស្អែក" orange badge
- Otherwise → "DD/MM" gray badge

---

### Transaction Row Design
```
HStack(spacing: 12) {
  Circle()
    .fill(entity.type == "Income" ? Color.green : Color.red)
    .frame(width: 10, height: 10)
  VStack(alignment: .leading, spacing: 2) {
    Text(entity.title ?? "")
      .font(.subheadline).fontWeight(.medium)
    Text(entity.category ?? "")
      .font(.caption).foregroundColor(.secondary)
  }
  Spacer()
  VStack(alignment: .trailing, spacing: 2) {
    Text((entity.type == "Income" ? "+" : "-") +
         Formatters.currency(entity.amount, currency: entity.currency ?? "KHR"))
      .font(.subheadline).bold()
      .foregroundColor(entity.type == "Income" ? .green : .red)
    Text(Formatters.shortDate(entity.date ?? Date()))
      .font(.caption2).foregroundColor(.secondary)
  }
}
.padding(.vertical, 6)
```

---

### Empty State Design
When a section has no data:
```swift
VStack(spacing: 8) {
  Image(systemName: "tray")
    .font(.largeTitle)
    .foregroundColor(.secondary.opacity(0.5))
  Text("គ្មានទិន្នន័យ")
    .font(.subheadline)
    .foregroundColor(.secondary)
}
.frame(maxWidth: .infinity)
.padding(.vertical, 24)
```

---

### Spacing & Padding
| Element | Value |
|---------|-------|
| Screen horizontal padding | `16` |
| Section spacing (VStack) | `16` |
| Card inner padding | `14` |
| Card corner radius | `16` |
| Card shadow radius | `6` |
| Row vertical padding | `6` |
| Section header top padding | `8` |

---

### Tab Bar Icons
| Tab | Icon | Color when active |
|-----|------|-------------------|
| ផ្ទះ | `house.fill` | green |
| ហិរញ្ញវត្ថុ | `dollarsign.circle.fill` | green |
| ប្រតិទិន | `calendar` | green |
| របាយការណ៍ | `chart.bar.fill` | green |

Set with `.accentColor(Color(red: 0.2, green: 0.6, blue: 0.3))` on the `TabView`.

---

## Files to Implement

| File | Status |
|------|--------|
| `Dashboard/Views/DashboardView.swift` | new |
| `Dashboard/Views/SummaryCardView.swift` | new |
| `Dashboard/Views/MainTabView.swift` | update — wire DashboardView + Khmer tab labels |
