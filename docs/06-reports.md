# 06 — Reports & Charts

> Pushed from **Settings → របាយការណ៍ & គំនូសតាង**.

## Purpose
Visualize monthly profit/loss and export the ledger as CSV or PDF to share (family, bank/MFI, advisor).

## Wireframe
```
┌──────────────────────────────────────┐
│ ‹ ការកំណត់      របាយការណ៍               │
│ ┌──────────────────────────────────┐ │
│ │ ចំណេញ/ខាត ៦ ខែចុងក្រោយ            │ │
│ │   █                  █            │ │  bars: green up = profit
│ │   █     ▁      █      █           │ │       red down = loss
│ │ ──┼──────█──────┼──────┼──        │ │  centre baseline (0)
│ │   ▔      ▔      ▔      ▔          │ │
│ │  មករា  កុម្ភៈ  មីនា  មេសា …        │ │  month labels
│ └──────────────────────────────────┘ │
│ [ 📊 នាំចេញ CSV ]                      │
│ [ 📄 នាំចេញ PDF ]                      │
└──────────────────────────────────────┘
```

## Chart — `MonthlyBarChartView` (NO Swift Charts)
- Built with `GeometryReader` + `Rectangle` (Swift Charts is iOS 16+ and not allowed).
- Input: `[MonthlyTotal]` (last 6 months). `maxMagnitude = max(|profit|)`.
- Bars grow from a **centre baseline**: profit upward (green), loss downward (red); height ∝ |profit|/maxMagnitude × halfHeight; min 2pt so non-zero is visible.
- Month labels (`km_KH`, `MMM`) under each column.

## ViewModel — `ReportsViewModel`
- `transactions`, `monthlyTotals` for the last 6 calendar months, computed in `AppSettings.displayCurrency` (default KHR).
- `MonthlyTotal { monthStart, label, income, expense, profit }`.

## Export — `ReportExporter`
- `csvString` / `csvFile` → `SmartFarm-Report.csv` (RFC-4180 escaping). Columns: Date, Title, Type, Category, Currency, Amount, Note.
- `pdfFile(...)` → `SmartFarm-Report.pdf` via `UIGraphicsPDFRenderer` (UIKit, iOS 14 safe): title, totals (income/expense/profit), then a paginated transaction list.
- Files written to `temporaryDirectory`; shared via `ActivityShareSheet` (`UIActivityViewController` wrapped in `UIViewControllerRepresentable`; `ShareLink` is iOS 16+).

## Edge cases
- No data → chart shows "មិនមានទិន្នន័យ"; export still produces a header-only file.
- Long ledgers → PDF paginates (`beginPage()` when y exceeds page height).
- Khmer glyphs in PDF: rendered with system UIFont (Core Text handles Khmer).

## Acceptance criteria
- [ ] Chart matches per-month profit/loss for the last 6 months (KHR).
- [ ] CSV opens in Sheets/Excel with correct columns and escaping.
- [ ] PDF shows totals + transactions and shares via the system sheet.
- [ ] Empty state doesn't crash export.
```
