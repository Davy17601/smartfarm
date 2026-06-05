# /dashboard — Build Dashboard Module

Implement the Dashboard tab for SmartFarm. Read `docs/Dashboard.md` and `PLAN.md` first.

## What to build

1. **`Dashboard/Views/SummaryCardView.swift`** — reusable card component:
   ```swift
   struct SummaryCardView: View {
       var icon: String        // SF Symbol name
       var label: String       // Khmer label
       var amount: String      // pre-formatted string
       var color: Color        // accent color
   }
   ```
   Card has rounded rectangle background, icon + label on top, amount large below. Shadow and padding.

2. **`Dashboard/Views/DashboardView.swift`** — main dashboard:
   - Navigation title: "ផ្ទះ"
   - `ScrollView` with `VStack(spacing: 16)`:
     - **Greeting section**: "សួស្ដី! Farm របស់អ្នក" + today's date
     - **This Month section** ("ខែនេះ"): 3 `SummaryCardView` side by side (ចំណូល/green, ចំណាយ/red, ចំណេញ/blue) — data from `@FetchRequest` on TransactionEntity filtered to current calendar month
     - **Upcoming Reminders** ("ការរំឭកខាងមុខ"): next 7 days from ReminderEntity; each row shows title + dueDate time; "មើលទាំងអស់" button navigates to Calendar tab
     - **Recent Transactions** ("ប្រតិបត្តិការចុងក្រោយ"): last 5 TransactionEntity; each row shows title + amount + date; "មើលទាំងអស់" button navigates to Finance tab

3. **Update `Dashboard/Views/MainTabView.swift`**:
   - Replace `Text("Dashboard")` with `DashboardView()`
   - Tab label: "ផ្ទះ", icon: `house.fill`
   - Pass managedObjectContext if needed

## Data Sources
- `@FetchRequest` for TransactionEntity: predicate `date >= startOfMonth AND date <= endOfMonth`, sorted by date desc
- `@FetchRequest` for ReminderEntity: predicate `dueDate >= now AND dueDate <= now+7days AND isCompleted == NO`, sorted by dueDate asc, fetchLimit 5
- `@FetchRequest` for recent transactions: no predicate, sorted by date desc, fetchLimit 5

## Constraints
- iOS 14 / Xcode 13 only — use `PreviewProvider`
- No cross-tab navigation via programmatic tab selection (just show a "see all" row that user taps to switch tabs manually) — keep it simple
- Khmer labels everywhere
- Use `Formatters.currency()` and `Formatters.shortDate()` from `Utilities/Formatters.swift`

## File registration
Register `DashboardView.swift` and `SummaryCardView.swift` in xcodeproj after creation.
