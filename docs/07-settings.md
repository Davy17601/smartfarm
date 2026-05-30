# 07 — Settings tab

## Purpose
Hub for data tools (Reports, Backup & Restore) and app info. Keeps the tab bar at 4 tabs while giving secondary features a home.

## Wireframe
```
┌──────────────────────────────────────┐
│ ការកំណត់                                │
│ ចំណូលចិត្ត (Preferences)                 │
│ ┌──────────────────────────────────┐ │
│ │ 🌐 ភាសា / Language    [ខ្មែរ ▾]   │ │ Khmer | English  (live switch)
│ │ 💱 រូបិយប័ណ្ណ          [រៀល KHR ▾] │ │ KHR | USD (totals display)
│ └──────────────────────────────────┘ │
│ ទិន្នន័យ                                 │
│ ┌──────────────────────────────────┐ │
│ │ 📊 របាយការណ៍ & គំនូសតាង         › │ │ → Reports (06)
│ │ 🗄  បម្រុងទុក & ស្ដារ            › │ │ → Backup (08)
│ └──────────────────────────────────┘ │
│ អំពី                                    │
│ ┌──────────────────────────────────┐ │
│ │ កំណែ                         1.0 │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

## Structure — `SettingsView`
- `NavigationView` + `List` (`InsetGroupedListStyle`).
- Section **"ចំណូលចិត្ត / Preferences"** (bound to injected `LocalizationManager` + `AppSettings`):
  - **Language** `Picker` over `AppLanguage` (Khmer/English) → mutates `LocalizationManager.language`; UI re-renders live (see `09-localization.md §2`).
  - **Display currency** `Picker` over `Currency` (KHR/USD) → mutates `AppSettings.displayCurrency`; totals across the app recompute.
- Section "ទិន្នន័យ": `NavigationLink` → `ReportsView(repository:)`; `NavigationLink` → `BackupView(environment:)`.
- Section "អំពី": version row (static "1.0").
- Receives `environment: AppEnvironment` (+ reads the two app-wide `@EnvironmentObject`s) to construct child screens.

## Future rows (placeholders, not v1)
- Notification preferences · Clear-all-data (with confirm) · Theme override.

## Acceptance criteria
- [ ] Both links push their screens and back-navigate cleanly.
- [ ] Version row renders; list styled consistently in light/dark.
```
