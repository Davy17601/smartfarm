# /reports — Build Reports + Backup Module

Implement the Reports tab (Tab 4) for SmartFarm. Read `docs/Reports.md` and `PLAN.md` first.

## What to build

### 1. `Reports/Models/MonthlyReport.swift`
```swift
struct MonthlyReport: Identifiable {
    var id: Date { month }
    var month: Date
    var totalIncome: Double
    var totalExpense: Double
    var profit: Double { totalIncome - totalExpense }
}
```

### 2. `Reports/ViewModels/ReportViewModel.swift`
Convert stub to `ObservableObject`:
```swift
class ReportViewModel: ObservableObject {
    @Published var selectedMonth: Date = Date()
    func prevMonth() / func nextMonth()
    func monthlyReports(from transactions: [TransactionEntity]) -> [MonthlyReport]  // last 6 months
    func transactionsForSelectedMonth(_ transactions: [TransactionEntity]) -> [TransactionEntity]
}
```

### 3. `Reports/Views/BarChartView.swift`
GeometryReader-based bar chart. NO Swift Charts framework.
- Input: `[MonthlyReport]` (last 6 months)
- Two bars per month: income (green) + expense (red), side by side
- X-axis: month abbreviation labels below each group
- Y-axis: optional scale label on left
- Use `Rectangle()` shapes with `.fill(Color.green)` / `.fill(Color.red)`
- Scale bars relative to the max value in the dataset

### 4. `Reports/Views/ReportTabView.swift`
NavigationView with title "របាយការណ៍":
- **Month selector row**: `< [ខែ ឆ្នាំ] >` (prev/next buttons + formatted month label)
- **Summary cards**: ចំណូល / ចំណាយ / ចំណេញ for selected month
- **Bar chart section**: `BarChartView` for last 6 months
- **Export section** ("នាំចេញ"): "CSV" button + "PDF" button → both open `ShareSheet`
- **Backup section** ("បម្រុងទុកទិន្នន័យ"): "Export JSON" button + "Import JSON" button

### 5. `Reports/Services/CSVExporter.swift`
```swift
struct CSVExporter {
    // Returns URL to a temp file at FileManager.default.temporaryDirectory
    static func export(_ transactions: [TransactionEntity]) -> URL?
}
```
CSV columns: Date, Title, Type, Category, Amount, Currency, Note. Header row in Khmer + English.

### 6. `Reports/Services/PDFGenerator.swift`
PDFKit-based. Returns `URL?` to temp PDF file.
- Header: "SmartFarm — របាយការណ៍ហិរញ្ញវត្ថុ" + date range
- Summary block: total income / expense / profit
- Transaction table: date | title | type | amount
- Use `PDFDocument`, `PDFPage`, draw with `CGContext`

### 7. `Shared/ShareSheet.swift`
Replace stub with working implementation:
```swift
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    // presents UIActivityViewController
}
```

### 8. `Shared/DocumentPicker.swift` (new)
```swift
struct DocumentPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    // UIDocumentPickerViewController for JSON import
    // allows picking .json files from Files app
}
```

### 9. Backup logic in `ReportTabView`
- **Export JSON**: encode all TransactionEntity + ReminderEntity + FarmActivityEntity into a single JSON object (`BackupData`). Write to temp file. Present `ShareSheet`.
- **Import JSON**: present `DocumentPicker`. On pick, decode JSON. Insert entities into CoreData. Save.

```swift
struct BackupData: Codable {
    var transactions: [Transaction]
    var reminders: [Reminder]
    var activities: [FarmActivity]
    var exportDate: Date
}
```

## Constraints
- iOS 14 / Xcode 13. Use `PreviewProvider`.
- NO Swift Charts — use GeometryReader + Rectangle only.
- Khmer labels throughout.
- Register `DocumentPicker.swift` in xcodeproj.

## Wire into MainTabView
Replace `Text("Setting")` with `ReportTabView()`, tab label "របាយការណ៍", icon `chart.bar.fill`.
