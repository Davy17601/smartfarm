# 09 — Localization & Currency

The app ships in **Khmer (km, default)** and **English (en)**, with an **in-app language toggle** that updates the UI live, and a **display-currency setting** (KHR/USD) for totals. All within the iOS 14 / Xcode 13 constraints.

## 1. Languages

| Code | Language | Role |
|------|----------|------|
| `km` | ខ្មែរ | **default** / development language |
| `en` | English | secondary |

Fallback order: selected language → `km`. The system font renders both Khmer and Latin, so no custom font bundling.

## 2. In-app language switch (no reinstall, no forced restart)

iOS doesn't natively re-render on a language change at runtime, so we override the bundle:

- `LocalizationManager: ObservableObject` (singleton, injected via `.environmentObject`)
  - `@AppStorage("appLanguage") var language: AppLanguage = .khmer` (persists choice)
  - `@Published` mirror so views re-render on change
- `enum AppLanguage: String { case khmer = "km", english = "en" }` with `displayName` + `locale`.
- **String lookup** goes through the selected `.lproj` bundle:
  ```swift
  func localized(_ key: String) -> String {
      guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path) else { return NSLocalizedString(key, comment: "") }
      return bundle.localizedString(forKey: key, value: nil, table: nil)
  }
  ```
- Convenience: `func L(_ key: String) -> String` (or `String.localized`) used everywhere instead of literals.
- Root view sets `.environment(\.locale, manager.language.locale)` so `DatePicker`, `Text(date, style:)`, etc. localize too.
- Changing the picker mutates `language` → `@Published` fires → whole tree re-renders with new strings. **Live, no restart.**

> Why not plain `LocalizedStringKey`? It binds to the *system* language and ignores an in-app override. The manager-based lookup is the standard iOS 14 pattern for user-selectable language.

## 3. String catalog

- `Resources/km.lproj/Localizable.strings` and `Resources/en.lproj/Localizable.strings` (+ `Base.lproj` optional).
- **Key convention:** `<area>.<thing>` — lowercase, dot-separated. No UI literals in Swift/SwiftUI files.

| Key | km | en |
|-----|----|----|
| `tab.dashboard` | ផ្ទាំងគ្រប់គ្រង | Dashboard |
| `tab.finance` | ហិរញ្ញវត្ថុ | Finance |
| `tab.calendar` | ប្រតិទិន | Calendar |
| `tab.settings` | ការកំណត់ | Settings |
| `common.save` | រក្សាទុក | Save |
| `common.cancel` | បោះបង់ | Cancel |
| `common.delete` | លុប | Delete |
| `common.edit` | កែប្រែ | Edit |
| `common.all` | ទាំងអស់ | All |
| `finance.income` | ចំណូល | Income |
| `finance.expense` | ចំណាយ | Expense |
| `finance.profit` | ចំណេញ / ខាត | Profit / Loss |
| `finance.add` | បន្ថែមប្រតិបត្តិការ | Add transaction |
| `finance.search` | ស្វែងរក | Search |
| `category.seeds` | គ្រាប់ពូជ | Seeds |
| `category.fertilizer` | ជី | Fertilizer |
| `category.labor` | កម្លាំងពលកម្ម | Labor |
| `category.tools` | ឧបករណ៍ | Tools |
| `category.sales` | ការលក់ | Sales |
| `category.other` | ផ្សេងៗ | Other |
| `calendar.activities` | សកម្មភាព | Activities |
| `calendar.reminders` | ការរំឭក | Reminders |
| `settings.language` | ភាសា | Language |
| `settings.currency` | រូបិយប័ណ្ណ | Display currency |
| `empty.transactions` | មិនមានប្រតិបត្តិការ | No transactions |

> `displayName` on enums (`TransactionType`, `TransactionCategory`, `RepeatType`, `Currency`) returns a **localized key lookup**, not a hardcoded Khmer literal as today.

## 4. Currency

- `Currency { khr, usd }` — `symbol` (`៛` / `$`), `displayName` (localized).
- **Per-transaction** currency is stored and shown on each row (unchanged).
- **Display currency** for totals: `@AppStorage("displayCurrency") var displayCurrency: Currency = .khr` on `AppSettings`.
  - Summary cards / Dashboard / Reports compute totals **in the display currency** via the existing `total…(in: currency)` methods.
  - Transactions in the *other* currency are **grouped, not converted** — they appear on their rows but aren't summed into the display-currency total (no FX rate in v1). Documented limitation.
- `CurrencyFormatter.string(_:currency:)` is locale-independent for the number grouping but currency-symbol driven; safe in both languages.

## 5. Locale-aware formatting

- Date utility (currently `KhmerDate`, **renamed `LocalizedDate`**) formats using `LocalizationManager.language.locale` instead of hardcoded `km_KH`.
- Numbers/amounts: `NumberFormatter` uses the app locale's grouping; money digits stay Arabic numerals for clarity in both languages.

## 6. Settings integration
See `07-settings.md` — adds **Language** (Khmer/English) and **Display currency** (KHR/USD) pickers, both bound to `AppSettings`/`LocalizationManager`.

## 7. Testing
- Toggle language in-app → every visible screen re-renders (no relaunch); tab bar, titles, buttons, category labels all switch.
- Launch arg `-AppleLanguages (en)` / `(km)` to spot untranslated keys.
- Missing key → returns the key string (visible in QA) rather than crashing.
- Switch display currency → totals recompute; rows keep their own currency.

## 8. Acceptance criteria
- [ ] Khmer is the default on first launch.
- [ ] Switching language in Settings updates the entire UI immediately, persists across relaunch.
- [ ] No hardcoded UI strings remain in Swift files (all via `L(key)` / localized `displayName`).
- [ ] Dates/pickers localize with the chosen language.
- [ ] Display-currency setting drives all totals; per-row currency unaffected.
- [ ] English and Khmer `.strings` files have identical key sets.
```
