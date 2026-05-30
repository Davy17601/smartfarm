# 04 — Finance tab

## Purpose
Record income/expense, see running totals, filter/search, and drill into a transaction. The primary daily-use screen.

## Screens
1. **List** (`FinanceTabView`) — summary + filters + transaction list
2. **Add / Edit** (`AddEditTransactionView`) — modal form
3. **Detail** (`TransactionDetailView`) — read view + edit

## Wireframe — List
```
┌──────────────────────────────────────┐
│ ហិរញ្ញវត្ថុ                          + │  toolbar "+" → Add sheet
│ ┌────────────┐┌────────────┐          │
│ │↓ ចំណូល      ││↑ ចំណាយ      │          │  totals (KHR)
│ └────────────┘└────────────┘          │
│ ┌──────────────────────────────────┐ │
│ │ 📈 ចំណេញ/ខាត   +1,300,000 ៛        │ │
│ └──────────────────────────────────┘ │
│ 🔍 ស្វែងរក…                        ✕  │  custom search bar (NOT .searchable)
│ [ ទាំងអស់ | ចំណូល | ចំណាយ ]            │  segmented type filter
│ ( ទាំងអស់ )(គ្រាប់ពូជ)(ជី)(ការលក់)…    │  horizontal category chips
│ ┌──────────────────────────────────┐ │
│ │ 🛒 លក់ស្រូវ                         │ │
│ │    ការលក់ · 30 ឧសភា   +1,500,000 ៛ │ │  TransactionRow, tap → Detail
│ │ 💧 ទិញជី                            │ │  swipe → delete
│ │    ជី · 30 ឧសភា        −200,000 ៛  │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

## Wireframe — Add/Edit (Form sheet)
```
បោះបង់        បន្ថែមប្រតិបត្តិការ        រក្សាទុក
─ ចំណងជើង            [ ____________ ]
─ ចំនួនទឹកប្រាក់       [ 0            ]  decimalPad
─ ប្រភេទ        [ ចំណូល | ចំណាយ ]        segmented
─ ចំណាត់ថ្នាក់   [ ការលក់         ▾ ]
─ រូបិយប័ណ្ណ     [ រៀល (KHR)      ▾ ]
─ កាលបរិច្ឆេទ    [ 30 ឧសភា 2026   ]
─ កំណត់ចំណាំ      [ ____________ ]
```

## State & ViewModel — `FinanceViewModel`
- `@Published transactions` (newest-first from repo).
- `@Published filter: TransactionFilter` (all/income/expense), `selectedCategory: TransactionCategory?`, `searchText`.
- `searchText` is bound to a custom `TextField` search bar (`.searchable` is iOS 16+).
- Derived `filteredTransactions` = type ∧ category ∧ (title|note contains search).
- `totalIncome/Expense/profit(in:)` called with `AppSettings.displayCurrency`; `transaction(for: id)`.
- CRUD: `add/update/delete` → repository → `reload()`. `delete(at:)` maps offsets within the *filtered* list.

## Form (`AddEditTransactionView`)
- `enum TransactionFormMode { case add; case edit(Transaction) }` seeds `@State` in `init`.
- Validation: non-empty title **and** amount > 0 → enables "រក្សាទុក".
- Save builds a `Transaction` (preserves `id` on edit) and calls `onSave` closure.

## Detail (`TransactionDetailView`)
- Reached via `NavigationLink(tag: transaction.id, selection: $coordinator.selectedTransactionID)`.
- Re-reads from VM by id (reflects edits, handles deletion → "ប្រតិបត្តិការនេះមិនមានទៀតទេ").
- "កែប្រែ" presents the same form in `.edit` mode (`.sheet`).

## Navigation
- `NavigationView` + `.navigationViewStyle(.stack)`.
- `FinanceCoordinator` holds `@Published var selectedTransactionID: UUID?`; `navigate(to:)` sets it, `reset()` clears it. `NavigationLink(tag:selection:)` activates the detail when the id matches. Deep link in from Dashboard sets the id then switches tabs.

## Edge cases
- Empty filtered result → "មិនមានប្រតិបត្តិការ" row.
- Mixed currencies → totals are computed in the display currency (Settings, default KHR); rows still display in their own currency. No FX conversion (see architecture §8 / `09-localization.md §4`).
- Amount parse: `Double(amountText)`; invalid → 0 → save disabled.

## Acceptance criteria
- [ ] Add → appears in list and **persists across relaunch**.
- [ ] Filter + category chip + search compose correctly.
- [ ] Edit updates the row and detail; delete (swipe) removes it.
- [ ] Totals recompute live; profit sign/color correct.
- [ ] Deep link from Dashboard opens the right detail.
```
