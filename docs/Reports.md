# Reports + Backup Module Spec

**Owner:** Monineath  
**Skill:** `/reports`  
**Tab:** របាយការណ៍ (Tab 4)

---

## Purpose
Visualize monthly profit/loss as a bar chart; export data as CSV or PDF to share with banks or family; backup all data to JSON and restore from JSON if phone is lost.

---

## MonthlyReport Model

```swift
struct MonthlyReport: Identifiable {
    var id: Date { month }
    var month: Date          // first day of that month
    var totalIncome: Double
    var totalExpense: Double
    var profit: Double { totalIncome - totalExpense }
}
```

---

## ReportViewModel (ObservableObject)

```swift
class ReportViewModel: ObservableObject {
    @Published var selectedMonth: Date = Date()
    
    func prevMonth()  // selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth)!
    func nextMonth()  // selectedMonth = Calendar.current.date(byAdding: .month, value: +1, to: selectedMonth)!
    
    // Returns [MonthlyReport] for last 6 months ending at selectedMonth
    func monthlyReports(from transactions: [TransactionEntity]) -> [MonthlyReport]
    
    // Returns transactions where date falls in selectedMonth
    func transactionsForSelectedMonth(_ transactions: [TransactionEntity]) -> [TransactionEntity]
}
```

---

## ReportTabView Layout

```
NavigationView (title: "របាយការណ៍")
└── ScrollView
    ├── Month Selector Row
    │   [<]  [មិថុនា 2026]  [>]
    │
    ├── Summary Cards (for selectedMonth)
    │   ចំណូល  |  ចំណាយ  |  ចំណេញ
    │
    ├── Bar Chart Section ("6 ខែចុងក្រោយ")
    │   BarChartView(reports: viewModel.monthlyReports(...))
    │
    ├── Export Section ("នាំចេញ")
    │   [CSV]  [PDF]
    │
    └── Backup Section ("បម្រុងទុកទិន្នន័យ")
        [Export JSON]  [Import JSON]
```

---

## BarChartView (GeometryReader — NO Swift Charts)

```swift
struct BarChartView: View {
    var reports: [MonthlyReport]
    // Renders last 6 months as paired bars
}
```

### Implementation pattern:
```swift
GeometryReader { geo in
    HStack(alignment: .bottom, spacing: 8) {
        ForEach(reports) { report in
            VStack(spacing: 2) {
                // Income bar
                Rectangle()
                    .fill(Color.green)
                    .frame(width: barWidth, height: incomeHeight(report, maxVal, geo.size.height))
                // Expense bar
                Rectangle()
                    .fill(Color.red)
                    .frame(width: barWidth, height: expenseHeight(report, maxVal, geo.size.height))
                // Month label
                Text(monthLabel(report.month))
                    .font(.caption2)
            }
        }
    }
}
```
- `maxVal` = max of all income and expense values in dataset
- Bar height = `(value / maxVal) * (availableHeight * 0.85)` (leave 15% for labels)
- Bar width = `(geo.size.width / CGFloat(reports.count)) * 0.35`
- Legend: green dot "ចំណូល", red dot "ចំណាយ"

---

## CSVExporter

```swift
struct CSVExporter {
    static func export(_ transactions: [TransactionEntity]) -> URL? {
        var csv = "កាលបរិច្ឆេទ,ចំណងជើង,ប្រភេទ,ប្រភេទ-ទំនិញ,ចំនួន,រូបិយប័ណ្ណ,កំណត់ចំណាំ\n"
        // loop transactions, append rows
        // write to FileManager.default.temporaryDirectory.appendingPathComponent("smartfarm_export.csv")
        // return URL
    }
}
```

CSV row format: `2026-06-05,លក់ស្រូវ,Income,Sales,1500000,KHR,`

---

## PDFGenerator (PDFKit)

```swift
struct PDFGenerator {
    static func generate(transactions: [TransactionEntity], month: Date) -> URL? {
        // Creates PDFDocument with one PDFPage
        // Draws with CGContext:
        //   - Header: "SmartFarm — របាយការណ៍ហិរញ្ញវត្ថុ"
        //   - Date range: "ខែ មិថុនា 2026"
        //   - Summary: total income / expense / profit
        //   - Table rows: date | title | type | amount
        // Saves to temp dir, returns URL
    }
}
```

Use `UIGraphicsBeginPDFContextToFile` or `PDFDocument` with `PDFPage`.

---

## ShareSheet (UIViewControllerRepresentable)

```swift
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
```

Usage: `.sheet(isPresented: $showShare) { ShareSheet(items: [exportURL]) }`

---

## DocumentPicker (UIViewControllerRepresentable)

```swift
struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.delegate = context.coordinator
        return picker
    }
    // Coordinator implements UIDocumentPickerDelegate
    // calls onPick(url) after user selects file
}
```

---

## Backup Data Structure

```swift
struct BackupData: Codable {
    var transactions: [Transaction]    // uses Finance/Models/Transaction.swift
    var reminders: [Reminder]          // uses CalendarReminders/Models/Reminder.swift
    var activities: [FarmActivity]     // uses Dashboard/Models/FarmActivity.swift
    var exportDate: Date
    var appVersion: String = "1.0"
}
```

### Export flow:
1. Fetch all entities from CoreData
2. Map to Swift model structs (Transaction, Reminder, FarmActivity)
3. Encode as JSON with `JSONEncoder()`
4. Write to temp file: `smartfarm_backup_YYYY-MM-DD.json`
5. Present `ShareSheet(items: [backupURL])`

### Import flow:
1. Present `DocumentPicker`
2. User picks `.json` file
3. Decode with `JSONDecoder()`
4. For each item: create new CoreData entity, populate fields, save context

---

## Khmer Labels

| English | Khmer |
|---------|-------|
| Reports | របាយការណ៍ |
| Last 6 months | 6 ខែចុងក្រោយ |
| Export | នាំចេញ |
| Backup | បម្រុងទុក |
| Export JSON | នាំចេញ JSON |
| Import JSON | នាំចូល JSON |
| Income bar legend | ចំណូល |
| Expense bar legend | ចំណាយ |
| Previous month | ខែមុន |
| Next month | ខែក្រោយ |

---

---

## UX/UI Design

### Visual Style
- **Background:** `Color(.systemGroupedBackground)` (matches iOS grouped table style)
- **Chart bars:** income = `Color.green`, expense = `Color.red`, profit line = `Color.blue`
- **Month selector:** large bold month label centered, `<` `>` chevron buttons on sides
- **Export buttons:** outlined style (`.overlay(RoundedRectangle.stroke(...))`) — not filled, to feel secondary
- **Backup buttons:** plain text links at the bottom — low emphasis, rarely used
- **Cards:** same style as Finance (white, `cornerRadius: 14`, subtle shadow)

---

### Screen Layout Ideas

Three layout options — pick one or mix elements from each.

---

#### Option A — Single Scroll (Recommended)
All content in one ScrollView from top to bottom. Simple, predictable, no tabs within a tab.

```
┌─────────────────────────────────────┐
│  NavigationBar: "របាយការណ៍"          │
├─────────────────────────────────────┤
│  ScrollView                         │
│                                     │
│  ┌─────────────────────────────┐    │
│  │   <    មិថុនា ២០២៦    >    │    │  ← month selector row
│  └─────────────────────────────┘    │
│                                     │
│  ┌──────────┐ ┌──────────┐ ┌──────┐ │
│  │ ចំណូល   │ │ ចំណាយ   │ │ចំណេញ│ │  ← 3 summary cards for selected month
│  │ 1,500,000│ │  800,000 │ │+700K │ │
│  └──────────┘ └──────────┘ └──────┘ │
│                                     │
│  ── 6 ខែចុងក្រោយ ─────────────────  │
│  ┌─────────────────────────────┐    │
│  │  ■ ■     ■ ■     ■ ■       │    │  ← BarChartView (GeometryReader)
│  │  ■ ■  ■ ■  ■ ■  ■ ■       │    │    green=income, red=expense
│  │  មករា ក្បោ មីនា ម.ស...    │    │
│  │  🟩 ចំណូល   🟥 ចំណាយ       │    │  ← legend
│  └─────────────────────────────┘    │
│                                     │
│  ── នាំចេញ ─────────────────────── │
│  ┌───────────────┐ ┌───────────────┐│
│  │  📄 CSV       │ │  📋 PDF       ││  ← outlined export buttons
│  └───────────────┘ └───────────────┘│
│                                     │
│  ── បម្រុងទុកទិន្នន័យ ────────────── │
│  [↑ នាំចេញ JSON]  [↓ នាំចូល JSON]   │  ← plain text buttons, low emphasis
└─────────────────────────────────────┘
```
**Best for:** straightforward — user reads top to bottom naturally.  
**Trade-off:** long scroll on phones; chart is far from summary cards.

---

#### Option B — Segmented Tabs within Reports
Top segmented control switches between "សង្ខេប" (Summary) and "ប្រវត្តិ" (History) panes. Chart stays visible in Summary; transaction list in History.

```
┌─────────────────────────────────────┐
│  NavigationBar: "របាយការណ៍"          │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │   <    មិថុនា ២០២៦    >    │    │  ← shared month selector
│  └─────────────────────────────┘    │
│  [   សង្ខេប   |   ប្រវត្តិ   ]       │  ← segmented control
│  ─────────────────────────────────  │
│                                     │
│  — if "សង្ខេប" selected: —          │
│  ┌──────────┐ ┌──────────┐ ┌──────┐ │
│  │ ចំណូល   │ │ ចំណាយ   │ │ចំណេញ│ │
│  └──────────┘ └──────────┘ └──────┘ │
│  BarChartView (6 months)             │
│  [CSV]  [PDF]                        │
│  [Export JSON]  [Import JSON]        │
│                                     │
│  — if "ប្រវត្តិ" selected: —         │
│  List of all transactions for month │
│  grouped by date (same as Finance)  │
└─────────────────────────────────────┘
```
**Best for:** separates analytics from raw data — two different use cases, two clean screens.  
**Trade-off:** another nested navigation level; segmented tabs inside a tab can feel redundant.

---

#### Option C — Chart-First with Drill-Down
Bar chart is the centerpiece. Tapping a bar column drills into that month's details inline.

```
┌─────────────────────────────────────┐
│  NavigationBar: "របាយការណ៍"          │
├─────────────────────────────────────┤
│  ScrollView                         │
│                                     │
│  ── 6 ខែចុងក្រោយ ─────────────────  │
│  ┌─────────────────────────────┐    │
│  │                   ▲ selected│    │
│  │  ▬▬    ▬▬   ▬▬   ▬▬   ▬▬  │    │  ← BarChartView — tappable columns
│  │  ▬▬  ▬▬  ▬▬  ▬▬  ▬▬  ▬▬  │    │    selected month highlighted
│  │  មក  ក្ប  មី  ម.ស  ម.ស ម.ថ │    │
│  └─────────────────────────────┘    │
│                                     │
│  ── មិថុនា ២០២៦ (selected) ──────── │  ← updates when bar tapped
│  ┌──────────┐ ┌──────────┐ ┌──────┐ │
│  │ ចំណូល   │ │ ចំណាយ   │ │ចំណេញ│ │  ← summary for tapped month
│  └──────────┘ └──────────┘ └──────┘ │
│                                     │
│  ── នាំចេញ ─────────────────────── │
│  [CSV]  [PDF]                        │
│                                     │
│  ── បម្រុងទុក ──────────────────── │
│  [Export JSON]  [Import JSON]        │
└─────────────────────────────────────┘
```
**Best for:** visual-first farmers who want to spot the best/worst month instantly, then drill in.  
**Trade-off:** requires `@State var selectedBarIndex` and tap gesture on each bar column — slightly more complex interaction.

---

### BarChartView Detail Design

```
GeometryReader { geo in
  VStack(spacing: 0) {
    // Chart area
    HStack(alignment: .bottom, spacing: 6) {
      ForEach(Array(reports.enumerated()), id: \.offset) { i, report in
        VStack(spacing: 2) {
          // Income bar (left of pair)
          RoundedRectangle(cornerRadius: 3)
            .fill(Color.green.opacity(i == selectedIndex ? 1.0 : 0.7))
            .frame(width: barWidth, height: incomeH(report))
          // Expense bar (right of pair)
          RoundedRectangle(cornerRadius: 3)
            .fill(Color.red.opacity(i == selectedIndex ? 1.0 : 0.7))
            .frame(width: barWidth, height: expenseH(report))
        }
        .onTapGesture { selectedIndex = i }  // Option C only
      }
    }
    .frame(height: geo.size.height - 28)

    // X-axis labels
    HStack(spacing: 6) {
      ForEach(reports) { report in
        Text(monthAbbrev(report.month))   // "មករ", "ក្បោ", "មីនា"...
          .font(.system(size: 9))
          .foregroundColor(.secondary)
          .frame(width: barWidth * 2 + 2)
      }
    }
    .frame(height: 20)
  }
}
.frame(height: 180)
.padding(.horizontal, 8)
```

Legend row below chart:
```
HStack(spacing: 16) {
  HStack(spacing: 4) {
    Rectangle().fill(Color.green).frame(width: 12, height: 12).cornerRadius(2)
    Text("ចំណូល").font(.caption2)
  }
  HStack(spacing: 4) {
    Rectangle().fill(Color.red).frame(width: 12, height: 12).cornerRadius(2)
    Text("ចំណាយ").font(.caption2)
  }
}
```

---

### Export Buttons Design
```
HStack(spacing: 12) {
  // CSV button
  Button(action: exportCSV) {
    HStack(spacing: 6) {
      Image(systemName: "doc.text")
      Text("CSV")
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green, lineWidth: 1.5))
    .foregroundColor(.green)
  }
  // PDF button
  Button(action: exportPDF) {
    HStack(spacing: 6) {
      Image(systemName: "doc.richtext")
      Text("PDF")
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 1.5))
    .foregroundColor(.blue)
  }
}
```

### Backup Buttons Design (low emphasis)
```
VStack(spacing: 10) {
  Button(action: exportJSON) {
    Label("នាំចេញ JSON", systemImage: "arrow.up.doc")
      .font(.subheadline).foregroundColor(.primary)
      .frame(maxWidth: .infinity)
      .padding(12)
      .background(Color(.secondarySystemGroupedBackground))
      .cornerRadius(10)
  }
  Button(action: importJSON) {
    Label("នាំចូល JSON", systemImage: "arrow.down.doc")
      .font(.subheadline).foregroundColor(.primary)
      .frame(maxWidth: .infinity)
      .padding(12)
      .background(Color(.secondarySystemGroupedBackground))
      .cornerRadius(10)
  }
}
```

---

### Spacing & Padding
| Element | Value |
|---------|-------|
| Screen horizontal padding | `16` |
| Month selector height | `44` |
| Chart height | `180` |
| Bar corner radius | `3` |
| Export button corner radius | `10` |
| Section spacing | `20` |

---

## Files to Implement

| File | Status |
|------|--------|
| `Reports/Models/MonthlyReport.swift` | stub → implement |
| `Reports/ViewModels/ReportViewModel.swift` | stub → implement |
| `Reports/Views/ReportTabView.swift` | stub → implement |
| `Reports/Views/BarChartView.swift` (rename BarChatView) | stub → implement |
| `Reports/Services/CSVExporter.swift` | stub → implement |
| `Reports/Services/PDFGenerator.swift` | stub → implement |
| `Shared/ShareSheet.swift` | stub → implement |
| `Shared/DocumentPicker.swift` | new |
