# /finance — Build Finance Module

Implement the complete Finance Tracker module for SmartFarm. Read `docs/Finance.md` and `PLAN.md` first for full specs.

## What to build

1. **`Utilities/CoreDataManager.swift`** — ensure save/delete helpers exist
2. **`Utilities/Formatters.swift`** — ensure currency + date formatters exist
3. **`Finance/ViewModels/FinanceViewModel.swift`** — convert stub to `ObservableObject`:
   - Properties: `@Published var filterType: String` ("all"/"Income"/"Expense"), `@Published var selectedCurrency: String`
   - Methods: `add(title:amount:type:category:date:note:currency:)`, `update(_:title:amount:type:category:date:note:currency:)`, `delete(_:)` all operating on `NSManagedObjectContext`
   - Computed helpers: `totalIncome(_:)`, `totalExpense(_:)`, `profit(_:)` take `[TransactionEntity]` and return `Double`

4. **`Finance/Views/FinanceTabview.swift`** — full NavigationView:
   - Navigation title: "ហិរញ្ញវត្ថុ"
   - Top: 3 `SummaryCardView` cards in HStack (ចំណូល / ចំណាយ / ចំណេញ)
   - Segmented `Picker`: ទាំងអស់ / ចំណូល / ចំណាយ
   - `TransactionListView` below picker
   - Toolbar button "+" → sheet presenting `AddTransactionView`

5. **`Finance/Views/TransactionListView.swift`**:
   - `@FetchRequest` sorted by `date` descending
   - Filter by `filterType` using NSPredicate when not "all"
   - Each row: `TransactionRowView`
   - Swipe-to-delete calls `viewModel.delete(_:)`

6. **`Finance/Views/TransactionRowView.swift`**:
   - Leading: colored circle (green=Income, red=Expense)
   - Center: title (bold) + category (small gray)
   - Trailing: formatted amount + short date

7. **`Finance/Views/AddTransactionView.swift`**:
   - Form with sections: ព័ត៌មានទូទៅ (title, amount, type, category, currency), កាលបរិច្ឆេទ (DatePicker), កំណត់ចំណាំ (note TextField)
   - Save button calls `viewModel.add(...)` then dismiss

8. **`Finance/Views/EditTransactionView.swift`**:
   - Same form pre-filled from `TransactionEntity`
   - Save button calls `viewModel.update(...)` then dismiss

9. **`Finance/Views/TransactionDetailView.swift`**:
   - Read-only display of all fields
   - Toolbar: Edit button → sheet with `EditTransactionView`
   - Delete button (red) → confirm alert → `viewModel.delete(_:)` → dismiss

## Constraints
- iOS 14 / Xcode 13 only — use `PreviewProvider`, not `#Preview {}`
- Use `@EnvironmentObject var viewModel: FinanceViewModel` (injected from `FinanceTabview`)
- Khmer labels for all user-facing text
- Currency display: KHR shows "៛", USD shows "$"
- `DynamicFilterView.swift` — can remain a stub or be used inside `FinanceTabview` for the segmented picker

## File registration
After creating any new Swift file, register it in xcodeproj:
```bash
bundle exec ruby -e "require 'xcodeproj'; proj = Xcodeproj::Project.open('SmartFarm.xcodeproj'); target = proj.targets.first; ref = proj.main_group.find_subpath('SmartFarm/Finance/Views', true).new_file('NewFile.swift'); target.add_file_references([ref]); proj.save"
```
