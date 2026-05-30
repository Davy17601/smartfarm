# 03 — Dashboard (Home tab)

## Purpose
One-glance snapshot of the farm: this month's profit/loss, recent transactions, what's coming up — with quick jumps into each module.

## Wireframe
```
┌──────────────────────────────────────┐
│ ផ្ទាំងគ្រប់គ្រង            (large title)│
│ ┌──────────────────────────────────┐ │
│ │ 📈 ចំណេញ/ខាត ខែនេះ                 │ │  monthProfit (KHR, signed)
│ │ +1,300,000 ៛                      │ │
│ └──────────────────────────────────┘ │
│ ┌──────────────┐ ┌──────────────┐    │
│ │↓ ចំណូល        │ │↑ ចំណាយ        │    │  monthIncome / monthExpense
│ │ 1,500,000 ៛  │ │ 200,000 ៛    │    │
│ └──────────────┘ └──────────────┘    │
│ ┌──────────────┐ ┌──────────────┐    │
│ │ 💲 ហិរញ្ញវត្ថុ  │ │ 📅 ប្រតិទិន    │    │  quick actions → tabs
│ └──────────────┘ └──────────────┘    │
│ ប្រតិបត្តិការថ្មីៗ          មើលទាំងអស់ →│
│ ┌──────────────────────────────────┐ │
│ │ 🛒 លក់ស្រូវ        +1,500,000 ៛    │ │  latest 5, tap → Finance detail
│ │ 💧 ទិញជី          −200,000 ៛      │ │
│ └──────────────────────────────────┘ │
│ ខាងមុខ ៧ ថ្ងៃ                ប្រតិទិន →│
│ ┌──────────────────────────────────┐ │
│ │ 🌿 ស្រោចទឹក              31 ឧសភា   │ │  upcoming activities + reminders
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

## Components
`ScrollView` of: `SummaryCardView` (profit), 2× `SummaryCardView` row, quick-action buttons, `SectionHeader` + `FarmCard` lists, `TransactionRow` reused for recents.

## State & ViewModel — `DashboardViewModel`
Inputs: all three repositories. Reloads on `.onAppear`.
- `monthIncome / monthExpense / monthProfit` — current calendar month, computed in `AppSettings.displayCurrency` (default KHR).
- `latestTransactions` — newest 5 (repo returns newest-first).
- `upcomingActivities(within:7)`, `upcomingReminders(within:7)` — not completed, sorted by date.

## Interactions / navigation
- Quick-action + "មើលទាំងអស់"/"ប្រតិទិន" → set `selectedTab` (`@Binding` from `MainTabView`).
- Tap a recent transaction → `FinanceCoordinator.navigate(to:)` (sets `selectedTransactionID`) **and** `selectedTab = 1`; the Finance tab's `NavigationLink(tag:selection:)` activates the detail.

## Edge cases
- No transactions → profit shows `+0 ៛`; recents card shows "មិនមានប្រតិបត្តិការ".
- No upcoming items → "គ្មានកាលវិភាគ".

## Accessibility
- Each summary card is one VoiceOver element: "ចំណេញ ខែនេះ, បូក មួយលាន…". Quick actions are buttons with labels.

## Acceptance criteria
- [ ] Profit = income − expense for the current month, in the selected display currency.
- [ ] Tapping a recent transaction lands on its Finance detail screen.
- [ ] Quick actions switch tabs.
- [ ] Reflects newly added data after returning to the tab (reload on appear).
```
