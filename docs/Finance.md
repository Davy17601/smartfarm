# Finance Module Spec

**Owner:** Davy  
**Skill:** `/finance`  
**Tab:** ហិរញ្ញវត្ថុ (Tab 2)

---

## Purpose
Let farmers track daily income and expenses. Shows running profit/loss with KHR and USD support.

---

## CoreData Entity: TransactionEntity

| Attribute | Type | Default | Notes |
|-----------|------|---------|-------|
| id | UUID | auto | |
| title | String | "" | e.g. "លក់ស្រូវ" |
| amount | Double | 0.0 | always positive |
| type | String | "Income" | "Income" or "Expense" |
| category | String | "Other" | see categories below |
| currency | String | "KHR" | "KHR" or "USD" |
| date | Date | now | |
| note | String | nil | optional |

### Categories
`Seeds` · `Fertilizer` · `Labor` · `Tools` · `Sales` · `Other`

---

## FinanceViewModel (ObservableObject)

```swift
class FinanceViewModel: ObservableObject {
    @Published var filterType: String = "all"    // "all" | "Income" | "Expense"
    @Published var selectedCurrency: String = "KHR"
    
    var context: NSManagedObjectContext
    
    // Computed from passed-in array (view provides via @FetchRequest)
    func totalIncome(_ transactions: [TransactionEntity]) -> Double
    func totalExpense(_ transactions: [TransactionEntity]) -> Double
    func profit(_ transactions: [TransactionEntity]) -> Double
    
    // CRUD
    func add(title: String, amount: Double, type: String, category: String,
             date: Date, note: String, currency: String)
    func update(_ entity: TransactionEntity, title: String, amount: Double,
                type: String, category: String, date: Date, note: String, currency: String)
    func delete(_ entity: TransactionEntity)
}
```

---

## View Hierarchy

```
FinanceTabview (NavigationView)
├── SummaryRow (HStack of 3 SummaryCardView)
│   ├── Card: ចំណូល (green)
│   ├── Card: ចំណាយ (red)
│   └── Card: ចំណេញ (blue)
├── FilterPicker (Segmented: ទាំងអស់ / ចំណូល / ចំណាយ)
└── TransactionListView (@FetchRequest)
    └── TransactionRowView (each row)
        └── NavigationLink → TransactionDetailView
                             └── Sheet → EditTransactionView
Sheet: AddTransactionView
```

---

## Khmer Labels

| English | Khmer |
|---------|-------|
| Finance | ហិរញ្ញវត្ថុ |
| Income | ចំណូល |
| Expense | ចំណាយ |
| Profit | ចំណេញ |
| All | ទាំងអស់ |
| Add Transaction | បន្ថែមប្រតិបត្តិការ |
| Title | ចំណងជើង |
| Amount | ចំនួនទឹកប្រាក់ |
| Category | ប្រភេទ |
| Date | កាលបរិច្ឆេទ |
| Note | កំណត់ចំណាំ |
| Save | រក្សាទុក |
| Cancel | បោះបង់ |
| Delete | លុប |
| Edit | កែប្រែ |
| Seeds | គ្រាប់ពូជ |
| Fertilizer | ជី |
| Labor | ការងារ |
| Tools | ឧបករណ៍ |
| Sales | លក់ |
| Other | ផ្សេងៗ |

---

## Currency Formatting
```swift
// KHR: "1,500,000 ៛"
// USD: "$25.00"
Formatters.currency(amount, currency: entity.currency ?? "KHR")
```

---

## Summary Cards Display
- **ចំណូល**: sum of all Income transactions this month (green)
- **ចំណាយ**: sum of all Expense transactions this month (red)
- **ចំណេញ**: Income − Expense (blue if positive, red if negative)

---

## Filter Logic
```swift
// In TransactionListView @FetchRequest predicate:
var predicate: NSPredicate? {
    switch filterType {
    case "Income":  return NSPredicate(format: "type == %@", "Income")
    case "Expense": return NSPredicate(format: "type == %@", "Expense")
    default:        return nil
    }
}
```

---

---

## UX/UI Design

### Visual Style
- **Color scheme:** white cards on light gray (`Color(.systemGroupedBackground)`) background
- **Income accent:** `Color.green` / `Color(red: 0.2, green: 0.7, blue: 0.3)`
- **Expense accent:** `Color.red` / `Color(red: 0.9, green: 0.2, blue: 0.2)`
- **Profit accent:** `Color.blue` (positive) / `Color.red` (negative)
- **Card style:** `cornerRadius: 14`, `shadow(color: .black.opacity(0.07), radius: 5, x: 0, y: 2)`
- **Font:** `.title3.bold()` for amounts, `.caption` for labels, `.subheadline` for row titles

---

### Screen Layout Ideas

Three layout options — pick one or mix elements from each.

---

#### Option A — Fixed Header + Scrolling List (Recommended)
Summary cards and filter are pinned; only the transaction list scrolls. Farmers always see their totals.

```
┌─────────────────────────────────────┐
│  NavigationBar: "ហិរញ្ញវត្ថុ"    [+] │  ← "+" opens AddTransactionView sheet
├─────────────────────────────────────┤
│  ┌──────────┐ ┌──────────┐ ┌──────┐ │
│  │ ចំណូល   │ │ ចំណាយ   │ │ចំណេញ│ │  ← 3 summary cards (always visible)
│  │ 1,500,000│ │  800,000 │ │+700K │ │
│  │    ៛    │ │    ៛    │  │  ៛  │ │
│  └──────────┘ └──────────┘ └──────┘ │
│  ┌─────────────────────────────────┐ │
│  │ [ទាំងអស់] [ចំណូល] [ចំណាយ]     │ │  ← segmented filter (sticky)
│  └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│  ↕ scrollable list below            │
│  ── មិថុនា ២០២៦ ──────────────────  │  ← date group header
│  ┌─────────────────────────────────┐ │
│  │ 🟢 លក់ស្រូវ     [លក់]  +1.5M ៛│ │  ← TransactionRowView
│  │                        ០៥/០៦   │ │
│  ├─────────────────────────────────┤ │
│  │ 🔴 ទិញជី        [ជី]  -250K ៛ │ │
│  │                        ០៣/០៦   │ │
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```
**Best for:** financial apps — balance always visible, list is secondary.  
**Trade-off:** less list space on small phones (iPhone SE).

---

#### Option B — Full ScrollView with Collapsible Header
Everything in one ScrollView. Header shrinks as user scrolls down, giving more room to the list.

```
┌─────────────────────────────────────┐
│  NavigationBar: "ហិរញ្ញវត្ថុ"    [+] │
├─────────────────────────────────────┤
│  ScrollView                         │
│                                     │
│  ╔═════════════════════════════╗    │
│  ║  ខែ មិថុនា ២០២៦             ║    │  ← month summary card (collapsible)
│  ║  ចំណូល  1,500,000 ៛         ║    │
│  ║  ចំណាយ    800,000 ៛         ║    │
│  ║  ចំណេញ  +700,000 ៛  ✅      ║    │
│  ╚═════════════════════════════╝    │
│                                     │
│  [ទាំងអស់]  [ចំណូល]  [ចំណាយ]       │  ← filter chips (not segmented — pill style)
│                                     │
│  ── ០៥ មិថុនា ────────────────────  │
│  🟢 លក់ស្រូវ          +1,500,000 ៛  │
│  ── ០៣ មិថុនា ────────────────────  │
│  🔴 ទិញជី               -250,000 ៛  │
│  🔴 ថ្លៃឈ្នួលពលករ       -150,000 ៛  │
└─────────────────────────────────────┘
```
**Best for:** users who scroll naturally through history; summary visible at top before scrolling.  
**Trade-off:** summary disappears as list grows — user must scroll back up to check totals.

---

#### Option C — Two-Panel with Quick Actions
Top half is visual summary with a mini trend line. Bottom half is the list with a floating "+" button. Feels like a modern fintech app.

```
┌─────────────────────────────────────┐
│  NavigationBar: "ហិរញ្ញវត្ថុ"        │
├─────────────────────────────────────┤
│  ░░░░░░ gradient panel (green) ░░░░ │
│  ░                               ░ │
│  ░  ចំណេញខែនេះ                   ░ │  ← large profit number (hero figure)
│  ░  +700,000 ៛                   ░ │
│  ░                               ░ │
│  ░  ━━━━━━━━━━━━━━━━━━━━━━━      ░ │  ← mini sparkline (Rectangle shapes)
│  ░  ចំណូល 1.5M  |  ចំណាយ 0.8M  ░ │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│                                     │
│  [ទាំងអស់] [ចំណូល] [ចំណាយ]         │
│  ─────────────────────────────────  │
│  🟢 លក់ស្រូវ          +1,500,000 ៛  │
│  🔴 ទិញជី               -250,000 ៛  │
│  🔴 ថ្លៃឈ្នួល            -150,000 ៛  │
│                                     │
│                         ╭───╮       │
│                         │ + │       │  ← floating action button (FAB)
│                         ╰───╯       │
└─────────────────────────────────────┘
```
**Best for:** visually impressive — profit is the hero figure, secondary details follow.  
**Trade-off:** sparkline requires extra GeometryReader logic; FAB button overlaps list rows.

---

### TransactionRowView Detail Design
```
HStack(spacing: 12) {
  // Leading: type indicator
  Circle().fill(type == "Income" ? Color.green : Color.red)
    .frame(width: 10, height: 10)
    .padding(.leading, 4)

  // Center: title + category badge
  VStack(alignment: .leading, spacing: 3) {
    Text(title).font(.subheadline).fontWeight(.medium)
    Text(category)
      .font(.caption2).foregroundColor(.white)
      .padding(.horizontal, 6).padding(.vertical, 2)
      .background(categoryColor(category))
      .cornerRadius(4)
  }

  Spacer()

  // Trailing: amount + date
  VStack(alignment: .trailing, spacing: 3) {
    Text(sign + Formatters.currency(amount, currency: currency))
      .font(.subheadline).bold()
      .foregroundColor(type == "Income" ? .green : .red)
    Text(Formatters.shortDate(date))
      .font(.caption2).foregroundColor(.secondary)
  }
}
.padding(.vertical, 8)
```

Category badge colors:
| Category | Color |
|----------|-------|
| Seeds | `.orange` |
| Fertilizer | `.brown` |
| Labor | `.purple` |
| Tools | `.gray` |
| Sales | `.green` |
| Other | `.secondary` |

---

### AddTransactionView Design
Sheet modal (`.sheet`) with a Form:
```
╔══════════════════════════════════════╗
║  ✕  បន្ថែមប្រតិបត្តិការ    [រក្សាទុក] ║  ← custom header row
╠══════════════════════════════════════╣
║                                      ║
║  Section: ព័ត៌មានទូទៅ               ║
║  ┌──────────────────────────────┐   ║
║  │ ចំណងជើង:  [លក់ស្រូវ        ] │   ║
║  │ ចំនួន:    [1500000          ] │   ║
║  │ ប្រភេទ:   (● ចំណូល  ○ ចំណាយ) │   ║  ← inline toggle, not picker
║  │ ប្រភេទទំនិញ: [លក់  ▾]       │   ║
║  │ រូបិយប័ណ្ណ: [KHR ▾]          │   ║
║  └──────────────────────────────┘   ║
║                                      ║
║  Section: កាលបរិច្ឆេទ               ║
║  ┌──────────────────────────────┐   ║
║  │  [DatePicker]                │   ║
║  └──────────────────────────────┘   ║
║                                      ║
║  Section: កំណត់ចំណាំ                ║
║  ┌──────────────────────────────┐   ║
║  │  [Optional note text field]  │   ║
║  └──────────────────────────────┘   ║
╚══════════════════════════════════════╝
```
- Income/Expense: use a 2-button toggle row (custom, not Picker) so it's one tap
- Amount field: `.keyboardType(.decimalPad)` with a "Done" toolbar button to dismiss keyboard

---

### TransactionDetailView Design
```
┌─────────────────────────────────────┐
│  < ហិរញ្ញវត្ថុ          [កែប្រែ]    │
├─────────────────────────────────────┤
│                                     │
│        🟢  ចំណូល                    │  ← large type icon + label centered
│    +1,500,000 ៛                     │  ← hero amount
│                                     │
│  ─────────────────────────────────  │
│  ចំណងជើង          លក់ស្រូវ          │
│  ប្រភេទទំនិញ      [លក់]  badge      │
│  រូបិយប័ណ្ណ        KHR              │
│  កាលបរិច្ឆេទ      ០៥ មិថុនា ២០២៦   │
│  កំណត់ចំណាំ       —                 │
│  ─────────────────────────────────  │
│                                     │
│  ┌─────────────────────────────┐   │
│  │        លុប          │        │   │  ← red delete button, full width
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

### Spacing & Padding
| Element | Value |
|---------|-------|
| Screen horizontal padding | `16` |
| Card inner padding | `14` |
| Card corner radius | `14` |
| Card shadow radius | `5` |
| Row vertical padding | `8` |
| Summary cards spacing | `10` |
| Filter picker top/bottom padding | `8` |

---

## Files to Implement

| File | Status |
|------|--------|
| `Finance/ViewModels/FinanceViewModel.swift` | stub → implement |
| `Finance/Views/FinanceTabview.swift` | stub → implement |
| `Finance/Views/TransactionListView.swift` | stub → implement |
| `Finance/Views/TransactionRowView.swift` | stub → implement |
| `Finance/Views/AddTransactionView.swift` | stub → implement |
| `Finance/Views/EditTransactionView.swift` | stub → implement |
| `Finance/Views/TransactionDetailView.swift` | stub → implement |
| `Finance/Views/DynamicFilterView.swift` | stub (can stay or use inline) |
