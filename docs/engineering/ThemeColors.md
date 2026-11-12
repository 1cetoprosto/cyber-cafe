# Theme Colors Tables

## CoffeeWithMilk

Warm monochrome coffee palette (aligned with retention marketing art — cream + espresso, no green accent).

| Name | Light | Dark |
|---|---|---|
| PrimaryText | #3E2723 | #EDE0D4 |
| PrimaryBackground | #FBF6F0 | #2A201C |
| SecondaryText | #8D6E63 | #D7CCC8 |
| SecondaryBackground | #5D4037 | #8D6E63 |
| TabBarTint | #3E2723 | #D7CCC8 |
| TabBarUnselectedTint | #A1887F | #8D6E63 |
| CellBackground | #FFFFFF | #3E322C |
| NavBarBackground | #FBF6F0 | #241C19 |
| NavBarText | #3E2723 | #EDE0D4 |

### Content cards (app-wide)

Single surface language — do **not** invent per-screen corner/shadow styles.

| API | When |
|---|---|
| `applyCafeSoftCardStyle()` | Standalone / scroll-stack cards (Home KPIs, Reports hero, P&L, forms via `InputContainerView`) |
| `applyCafeListCardStyle()` | Custom UITableView row cards only where intentionally designed (Reports Hub, Trends/ABC rows, Home transactions) — **no** drop shadow |

**Content lists** (Orders, Costs, Stock, Products, …): `UITableView.standardList()` + `BaseListTableViewCell` — same system `insetGrouped` look as Settings (solid cell fill + separators). Do **not** apply floating cafe list cards to these screens.

Shared tokens: `UIConstants.cardCornerRadius` (20), hairline `Semantic.cardStroke`, soft shadow (opacity 0.06 / radius 8) only on elevated cards.

Card captions / KPI titles: `AppLabel` `.kpiTitle` (`calloutDemi`) → `Semantic.kpiLabel` (primary ≈ 88%). Values: `.kpiValue` (`title2DemiBold`). Footer/compare: `.kpiFooter` (`callout`). Accent when needed: `Semantic.positive` / `.cost` / `.negative`.

KPI semantics (`UIColor.Semantic`): positive `#4F7A55`, cost `#B87040`, negative `#B05446` (readable mid-tones; badge fills at 14% tint).

## Base (AssetTheme)

| Name | Light | Dark |
|---|---|---|
| PrimaryText | #1C3209 | #A4AD9C |
| PrimaryBackground | #C59E62 | #4E3F27 |
| SecondaryText | #EFD4A0 | #BFA980 |
| SecondaryBackground | #1C3209 | #606F52 |
| TabBarTint | #1C3209 | #8D9884 |
| TabBarUnselectedTint | #999999 | #999999 |
| CellBackground | #EFD4A0 | #473F30 |
| NavBarBackground | #1C3209 | #606F52 |
| NavBarText | #C59E62 | #4E3F27 |

## Alt (SoftLightTheme)

| Name | Light | Dark |
|---|---|---|
| PrimaryText | #408169 | #FFFFFF |
| PrimaryBackground | #F2F2F2 | #121212 |
| SecondaryText | #FFFFFF | #EBEBF5 |
| SecondaryBackground | #408169 | #1C1C1E |
| TabBarTint | #408169 | #0A84FF |
| TabBarUnselectedTint | #5A626E | #5A626E |
| CellBackground | #FFFFFF | #1C1C1E |
| NavBarBackground | #408169 | #0D0D0D |
| NavBarText | #F2F2F2 | #FFFFFF |
