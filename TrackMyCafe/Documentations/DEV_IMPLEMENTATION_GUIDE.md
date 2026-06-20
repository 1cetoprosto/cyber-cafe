# TrackMyCafe — Product And Implementation Guide

## Роль документа

Це канонічний документ для трьох речей:

- що вже реально є в кодовій базі на поточному релізі;
- які межі між модулями та джерелами істини;
- куди дивитись за деталями в інших документах.

Якщо виникає конфлікт між документами, цей файл відповідає на питання:
`що зараз існує в продукті`, `що вважається поточним target state`, `де шукати деталізацію`.

## Ідея продукту

- Основний фокус: дати власнику маленької кав'ярні простий контроль над продажами, витратами, складом і прибутком.
- Killer feature: радикальна простота. Мінімум полів, автоматичні розрахунки, швидкі щоденні дії без "ERP-ваги".
- Головна цінність не в самих графіках, а в довірі до цифр: користувач відкриває додаток і швидко розуміє, що відбувається з грошима.

## Карта документації

- `DEV_IMPLEMENTATION_GUIDE.md`:
  канонічний стан продукту, модулі, джерела істини, межі між вже реалізованим і planned.
- `ARCHITECTURE_AND_LOGIC.md`:
  target architecture, доменні моделі, сервіси, long-term business rules.
- `ROADMAP.md`:
  релізна послідовність після `1.0.7`.
- `V1_1_IMPLEMENTATION_GUIDE.md`:
  solo-dev execution playbook, anti-rework правила, DoR/DoD, release discipline.
- `REPORTS.md`:
  окрема специфікація майбутнього reporting module.

## Поточний стан на `1.0.7`

### Що вже є в додатку

- Є 4 основні таби: `Home`, `Income`, `Costs`, `Settings`.
- Окремого `Reports` tab або `Reports Hub` у поточному UI ще немає.
- `Home` вже показує базову зведену інформацію і використовує period-based summaries для продажів та витрат.
- `Products`, `Ingredients`, `Recipes`, `Purchases`, `Stock List`, `Opex`, `Order History`, `POS` уже присутні в коді.
- Ручні складські коригування вже є через `InventoryAdjustmentModel` і `InventoryService.processStockAdjustment(...)`.

### Що реалізовано частково

- `HomeViewModel` уже використовує `IncomeAggregationService`, `OpexAggregationService` і простий `FinanceAggregationService`, але це ще не повний finance/reporting layer.
- `OrderModel` уже має поле `totalCost`, але повна модель для reporting ще не зведена до стабільної зв'язки `OrderModel + OrderItemModel` як єдиного джерела для `P&L`, `ABC`, `Trends`.
- `InventoryService.deductStock(...)` уже списує склад під час продажу, але глобальний toggle `Track Ingredients` ще не реалізований.
- `InventoryAdjustment` уже існує як модель і persisted event, але повного bulk inventory workflow та окремого audit-focused UI ще немає.

### Що ще не реалізовано

- journal-based `cash/card balances`;
- `Track Ingredients` setting;
- стабільний item-level `COGS snapshot` для звітності;
- повний `finance/reporting facade`;
- `Reports Hub UI`;
- bulk inventory count workflow.

## Поточні межі модулів

### Продажі

- Поточний факт продажу в коді живе навколо `OrderModel`.
- У `1.0.7` це ще переважно header-level модель чеку: `sum`, `cash`, `card`, `totalCost`, `note`.
- Для майбутньої аналітики canonical direction такий:
  - `OrderModel` = шапка чеку та totals;
  - `OrderItemModel` = item-level snapshot (`salePrice`, `costPrice`, `quantity`).

### Склад

- `IngredientModel` і `PurchaseModel` уже формують робочий inventory baseline.
- Середня ціна рахується через weighted average.
- `InventoryAdjustmentModel` змінює тільки кількість, не `averageCost`.
- Негативні залишки дозволені й повинні лишатись підтриманим сценарієм.

### Opex

- `OpexExpenseModel` уже є окремою сутністю.
- У поточному продукті Opex впливає на узагальнені показники Home.
- Payment-method accounting для Opex ще не завершений, тому balances поки не можна вважати фінансово завершеними.

### Dashboard

- `Home` у `1.0.7` уже не є "порожнім екраном", але це ще не повний `P&L dashboard`.
- У коді є period-based income/opex aggregation.
- Поточний `FinanceAggregationService` рахує тільки спрощений `net profit = sales - opex`.
- `COGS`, `gross profit`, `margin`, journal balances і report DTO ще не централізовані повністю.

### Reports

- `REPORTS.md` описує target spec.
- У коді `Reports Hub` ще не увімкнений.
- Тому всі report-oriented описи в docs треба читати як target state, а не як already shipped behavior.

## Джерела істини по зонах

- inventory quantities -> `IngredientModel.stockQuantity` + `PurchaseModel` + `InventoryAdjustmentModel`
- ingredient cost basis -> `IngredientModel.averageCost`
- current sales summary -> `OrderModel`
- future historical COGS truth -> `OrderModel.totalCost` + `OrderItemModel.costPrice`
- current Home sales/opex summaries -> aggregation services
- future balances -> `JournalEntry` + `DailyBalance`
- future report projections -> finance/reporting facade

## Що важливо не плутати

- `Sale` у старих описах це business shorthand, а не окрема canonical модель для reporting.
- `InventoryAdjustment` не дорівнює `Track Ingredients`.
- `InventoryAdjustment` це manual correction / audit trail.
- `Track Ingredients` це глобальне правило автоматичних списань при sale/refund.
- `DailyClose` у майбутньому може існувати лише як derived business snapshot, але не як окреме джерело фінансової істини.
- Realm у кодовій базі ще присутній, але нові фінансові сутності не повинні будуватись навколо нього як source of truth.

## Поточний target після `1.0.7`

Після стабілізації поточного релізу рух іде так:

1. `cash/card balances`
2. `COGS snapshot`
3. `Track Ingredients`
4. `aggregation services hardening`
5. `finance/reporting facade`
6. `Reports Hub UI`
7. `inventory audit / bulk count`

Детальний порядок релізів винесений у `ROADMAP.md`.

## Мінімальні правила консистентності

- Зміни рецепта не повинні переписувати історичний `COGS`.
- Складські коригування не повинні змінювати `averageCost`.
- UI не повинен бути власником фінансових формул.
- Якщо метрика вже порахована в сервісі, її не треба перераховувати в `ViewModel`.
- Якщо поведінка продажу щодо складу буде керуватись setting-ом, вона повинна бути зашита в сервісний шар, а не в контролери.

## Що читати далі

- Якщо треба зрозуміти target models/services:
  дивись `ARCHITECTURE_AND_LOGIC.md`.
- Якщо треба зрозуміти порядок релізів:
  дивись `ROADMAP.md`.
- Якщо треба зрозуміти як працювати одному без переробок:
  дивись `V1_1_IMPLEMENTATION_GUIDE.md`.
- Якщо треба деталізація майбутніх звітів:
  дивись `REPORTS.md`.
