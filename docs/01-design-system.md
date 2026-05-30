# 01 — Design System

Shared visual language. All screens compose these tokens and components — no ad-hoc colors, spacing, or fonts in feature code.

## 1. Color tokens (semantic, dark-mode aware)

| Token | Light/Dark source | Usage |
|-------|-------------------|-------|
| `brand` | `Color.green` | primary actions, accents |
| `income` | green | positive amounts |
| `expense` | red | negative amounts |
| `background` | `systemGroupedBackground` | screen background |
| `cardBackground` | `secondarySystemGroupedBackground` | cards, search bar, chips |
| `primaryText` | `label` | titles, values |
| `secondaryText` | `secondaryLabel` | captions, metadata |

Using system semantic colors gives **automatic dark mode**. Defined in `Theme.swift`.

## 2. Typography

| Token | Font |
|-------|------|
| `title` | `title2` bold |
| `heading` | `headline` |
| `body` | `body` |
| `caption` | `caption` |
| `amount` | `title3` semibold, **monospaced digits** |

System font renders both Khmer (Khmer OS) and Latin (English) correctly — no bundled fonts. Amounts use monospaced digits so columns align.

## 3. Spacing & radius

`Spacing`: xs 4 · s 8 · m 16 · l 24 · xl 32
`Radius`: card 12 · button 10

## 4. Components

| Component | Role | Key API |
|-----------|------|---------|
| `FarmCard<Content>` | rounded container w/ padding + shadow | `FarmCard { … }` |
| `SummaryCardView` | metric tile: icon + caption + value | `title, value, systemImage, tint` |
| `SectionHeader<Accessory>` | section title + optional trailing action | `SectionHeader("…") { Button(…) }` |
| `PrimaryButton` | full-width brand CTA | `title, systemImage?, action` |

## 5. Modifiers & styles

- `.cardStyle()` — padding + `cardBackground` + radius + subtle shadow.
- `.fadeIn()` — opacity 0→1 + 8pt rise on appear (lists/sections).
- `ScaleButtonStyle` — 0.97 press scale; applied to buttons/chips.

## 6. Iconography (SF Symbols)

Category icons: seeds `leaf.fill`, fertilizer `drop.fill`, labor `person.2.fill`, tools `hammer.fill`, sales `cart.fill`, other `tag.fill`.
Tabs: dashboard `chart.bar.fill`, finance `dollarsign.circle.fill`, calendar `calendar`, settings `gearshape.fill`.

## 7. Formatting utilities

- `CurrencyFormatter.string(_:currency:)` → `1,500,000 ៛` / `$12.50`; `signedString` prefixes `+`/`−` for profit.
- `LocalizedDate` (formats with the **current app locale** from `LocalizationManager`, not hardcoded `km_KH`): `mediumString`, `dayMonthString`, `dateTimeString`.

## 8. Accessibility & localization

- All interactive elements ≥ 44×44 pt tap target.
- Respect Dynamic Type (use `Font` text styles, not fixed sizes).
- Color is never the *only* signal — income/expense also carry `+`/`−` and icons.
- **Bilingual (Khmer default + English)** via `L("key")`; no hardcoded literals. Money numerals stay Arabic in both languages. Full spec: `09-localization.md`.

## 9. Empty & loading states (global pattern)

Every list/section shows a centered `secondaryText` message when empty (e.g. "មិនមានប្រតិបត្តិការ"). Data loads synchronously from CoreData → no spinner needed; reload on `.onAppear`.
```
