# SmartFarm — Design Docs

Design source-of-truth. **Read in order.** No code is written/changed until this set is approved.

| # | Doc | Scope |
|---|-----|-------|
| 00 | [Architecture](00-architecture.md) | MVVM + Repository + Coordinator, constraints, DI, folders, testing |
| 01 | [Design System](01-design-system.md) | colors, type, spacing, components, formatting, a11y |
| 02 | [Splash](02-splash.md) | **new** launch screen → tabs transition |
| 03 | [Dashboard](03-dashboard.md) | home snapshot + cross-module navigation |
| 04 | [Finance](04-finance.md) | list/filter/search, add/edit, detail |
| 05 | [Calendar & Reminders](05-calendar.md) | scheduling + local notifications |
| 06 | [Reports](06-reports.md) | bar chart + CSV/PDF export |
| 07 | [Settings](07-settings.md) | hub for data tools + info |
| 08 | [Backup & Restore](08-backup.md) | JSON export/import |
| 09 | [Localization & Currency](09-localization.md) | Khmer/English in-app switch, KHR/USD display currency |

## Conventions
- Each screen doc: **Purpose → Wireframe → Components → State/ViewModel → Interactions → Edge cases → Acceptance criteria**.
- **Bilingual: Khmer (default) + English** with an in-app language toggle (`09-localization.md`); wireframes show the Khmer rendering, English lives in the `.strings` files.
- Every doc respects the **iOS 14 / Xcode 13** constraint list in `00-architecture.md §2`.

## Status legend
- Docs marked **new** (e.g. Splash) describe screens to be added.
- Acceptance-criteria checkboxes are the definition-of-done per screen, verified by building + running.
