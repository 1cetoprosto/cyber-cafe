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
  релізна послідовність після **shipped v1.1.0** (лінія 1.1.x patches).
- `V1_1_IMPLEMENTATION_GUIDE.md`:
  solo-dev execution playbook, anti-rework правила, DoR/DoD, release discipline.
- `REPORTS.md`:
  специфікація Reports Hub, яка вже відповідає поточному shipped стану v1.1.0+.

## Поточний стан на **shipped v1.1.0** (baseline для 1.1.x)

### Що вже є в додатку (reality після v1.1.0)

- Є 5 основних табів: `Home (Dashboard)`, `Income (Sales/POS + Order History)`, `Costs (Inventory / Opex)`, `Reports Hub`, `Settings`.
- Reports Hub (tab 4) вже увімкнений і містить: P&L, ABC-аналіз, Trends (Динаміка).
- `Home` показує period-based summaries для Sales / COGS / Opex / Gross Profit / Net Profit і використовує централізовані aggregation services.
- `Products`, `Ingredients`, `Recipes`, `Purchases`, `Stock List`, `Opex`, `Order History`, `POS` вже присутні в коді.
- Ручні складські коригування вже є через `InventoryAdjustmentModel` і `InventoryService.processStockAdjustment(...)`.
- **Track Ingredients**: глобальний toggle (on/off) для автоматичного списання/відновлення складу при продажу/поверненні (v1.0.10).
- **COGS snapshot**: на рівні `OrderModel.totalCost` + `OrderItemModel.costPrice` стабільно фіксується в момент продажу (v1.0.9).
- **Finance/reporting layer**: centralized aggregation (`IncomeAggregationService`, `OpexAggregationService`, `FinanceAggregationService`) + facade для reports DTO (v1.1.0).

### Що реалізовано частково (in progress / next patches)

- Cash/card balances показані на Home, але ще **не вирішено через journal-based `JournalEntry` + materialized `DailyBalance`**. Поки це aggregation-based approximation; для повної фінансової довіри потрібен окремий реліз (target — додасться після 1.1.x, якщо буде явно необхідно).
- `InventoryAdjustment` існує як модель і persisted event, але ще **немає bulk audit workflow** і audit-focused UI (target v1.1.2, `#144`).
- Low-stock thresholds ще не повністю інтегровані в UI і моделі (target v1.1.2, `#152`).
- Realm ще присутній у продукційних кодових шляхах десь (legacy), хоча нові фінансові/репорт-модулі вже не побудовані на ньому (plan v1.1.3, `#141`/`#178`).
- Деякі FIR/Domain сервіси ще змішують completion blocks і async/await; треба uniform async/await entrance (v1.1.3, `#140`).
- UI-консистентність: bare UILabel ще зустрічаються; secondaryText ще не ввезено всюди; попапи частини через UIAlertController (v1.1.1 та v1.1.4).

### Що ще не реалізовано явно (за потреби після 1.1.x)

- Journal-based `cash/card balances` + `DailyBalance` як materialized джерело істини;
- Додаткові Reports drill-down (CSV export, фільтри по receipt types, payment methods breakdown — доки немає явного user ask);
- Multi-location / roles / permissions;
- OCR/сканування чеків для закупівель.

## Поточні межі модулів

### Продажі

- Поточний факт продажу в коді живе навколо `OrderModel`.
- У **v1.1.0** це вже не "тільки шапка": canonical snapshot = `OrderModel` + `OrderItemModel` (з `salePrice`, `costPrice`, `quantity`).
- Для звітності (P&L, ABC, Trends) беремо **samе snapshot**, не перераховуючи COGS з поточних рецептів.

### Склад

- `IngredientModel` і `PurchaseModel` формують робочий inventory baseline.
- Середня ціна рахується через weighted average при purchase.
- `InventoryAdjustmentModel` змінює тільки кількість, не `averageCost`.
- Негативні залишки дозволені й повинні лишатись підтриманим сценарієм.
- Track Ingredients (v1.0.10):
  - `On` → `processSale` списує склад за рецептом; refund відновлює.
  - `Off` → sale/refund не змінюють склад автоматично; ручні InventoryAdjustment залишаються доступними.

### Opex

- `OpexExpenseModel` — окрема сутність; впливає на Net Profit і Home summaries.
- Payment-method accounting для Opex ще незавершений; тому cash/card balances поки вважаються aggregation-based.

### Dashboard (Home)

- У **v1.1.0** це вже не "порожній екран", це робочий P&L dashboard для періоду: Sales / COGS / Opex / Gross Profit / Net Profit.
- Period-based income/opex aggregation централізована в aggregation services; HomeViewModel не містить власних фінансових формул.

### Reports (v1.1.0 shipped)

- `REPORTS.md` тепер описує **shipped специфікацію**, а не тільки target.
- Reports Hub UI: P&L / ABC / Trends.
- Reports Hub використовує готові reporting DTO з finance/reporting facade; UI не рахує фінанси сам.

## Джерела істини по зонах

- inventory quantities → `IngredientModel.stockQuantity` + `PurchaseModel` + `InventoryAdjustmentModel`
- ingredient cost basis → `IngredientModel.averageCost` (weighted average at purchase)
- historical COGS snapshot for a sale → `OrderModel.totalCost` + `OrderItemModel.costPrice` (фікс в момент продажу v1.0.9+)
- current sales summary → aggregation over `OrderModel` (+ `OrderItemModel` для деталізації)
- Home dashboard summaries → aggregation services + finance facade (UI не рахує)
- Reports (P&L/ABC/Trends) → finance/reporting facade (використовує aggregation services як нижній шар)
- Track Ingredients behavior → global setting + enforcement in service layer, not in VC/VM
- Realm → legacy-шар; нові фінансові/репорт-модулі не повинні будуватись навколо нього

## Що важливо не плутати

- `Sale` у старих описах це business shorthand, а не окрема canonical модель для reporting. Канонічний запис = `OrderModel` + `OrderItemModel`.
- `InventoryAdjustment` не дорівнює `Track Ingredients`:
  - `InventoryAdjustment` = ручна коригування / audit trail;
  - `Track Ingredients` = глобальне правило автоматичних списань при sale/refund.
- `DailyClose` у майбутньому може існувати лише як derived business snapshot, але не окреме джерело фінансової істини.
- Якщо метрика вже порахована в сервісі, її не треба перераховувати в ViewModel; UI тільки відображає DTO.
- Зміни рецепта **не переписують** історичний COGS; історичний COGS = snapshot.

## Поточний target після shipped v1.1.0

Релізна лінія 1.1.x (див. `ROADMAP.md`):

1. v1.1.1 — UI stability (UILabel → AppLabel, Dynamic Type) + docs sync.
2. v1.1.2 — Inventory audit/bulk count workflow + per-ingredient low-stock thresholds.
3. v1.1.3 — Architecture cleanup (Realm removal from prod paths, async/await uniform, domain models refine).
4. v1.1.4 — UI polish (secondaryText, PopupFactory/InputPopupView, R.swift SPM migration).

Після v1.1.4 вирішуємо, чи потрібен next minor (v1.2) для великих фіч типу journal balances / multi-location / roles / CSV export reports.

## Мінімальні правила консистентності

- Зміни рецепта не повинні переписувати історичний `COGS`.
- Складські коригування не повинні змінювати `averageCost`.
- UI не повинен бути власником фінансових формул.
- Якщо метрика вже порахована в сервісі, її не треба перераховувати в `ViewModel`.
- Якщо поведінка продажу щодо складу керується setting-ом, вона повинна бути зашита в сервісний шар, а не в контролери.
- Onboarding versionTag (див. `OnboardingManager`) рівний версії випуску, в якій фіча вперше зʼявилася, щоб upgrade-користувачі бачили тільки нові tours.

## Що читати далі

- Якщо треба зрозуміти target models/services:
  дивись `ARCHITECTURE_AND_LOGIC.md`.
- Якщо треба зрозуміти порядок релізів 1.1.x:
  дивись `ROADMAP.md`.
- Якщо треба зрозуміти як працювати одному без переробок:
  дивись `V1_1_IMPLEMENTATION_GUIDE.md`.
- Якщо треба специфікація Reports Hub (shipped v1.1.0+):
  дивись `REPORTS.md`.
