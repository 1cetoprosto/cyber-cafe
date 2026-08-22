# Дорожня карта (Roadmap)

## Роль документа

Це короткий релізний план **після shipped v1.1.0**.

- Тут фіксується `що в якій версії випускаємо`.
- Тут не дублюється повна архітектура чи детальний опис модулів.
- За поточним станом продукту дивись `DEV_IMPLEMENTATION_GUIDE.md`.
- За target architecture дивись `ARCHITECTURE_AND_LOGIC.md`.

## База: що вже shipped до `v1.1.0` включно

### v1.0.8 — Cash/Card Balances foundation
- Випущено. Issue: `#147`.
- Home відображає cash/card залишки як перший order-of-magnitude індикатор довіри.

### v1.0.9 — Full COGS Snapshot
- Випущено. Issue: `#143`.
- Історична собівартість фіксується на рівні продажу: `OrderModel.totalCost` + `OrderItemModel.costPrice`.
- Готує правильний фундамент для P&L, ABC, Trends.

### v1.0.10 — Inventory Behavior (Track Ingredients toggle)
- Випущено. Issue: `#156`.
- Глобальний `Track Ingredients` (on/off) керує автоматичним списанням/відновленням складу при продажу та поверненні.
- За замовчуванням `Off`, тому існуючим користувачам нічого не ламається.

### v1.1.0 — Dashboard/Reports Foundation
- Випущено. Issues: `#154`, `#145`, `#146`.
- Centralized aggregation services (Income / Opex / Finance).
- Finance/reporting facade для P&L / ABC / Trends DTO.
- Reports Hub UI у MainTabBarController (tab 4) з P&L, ABC-аналізом, Динамікою.

## Що ще не випущено (after v1.1.0)

- Journal-based cash/card balances + materialized DailyBalance.
- Bulk Inventory Audit workflow.
- Low-stock thresholds UI + InventoryAdjustment journal UI.
- Повне видалення Realm з продукційних кодових шляхів.
- FIR/Domain сервіси, переведені на uniform async/await.
- Досконалі доменні моделі Purchase/Opex/Sale/InventoryAdjustment.
- UI consistency: AppLabel migration, secondaryText, PopupFactory/InputPopupView, R.swift SPM.

## Принцип черги

Йдемо не від "найбільшої фічі", а від `найбільшої користі для користувача при мінімумі переробок`.

Прийнята стратегія для **1.1.x stability/feature-patch лінії** (v1.1.1 → v1.1.4):

1. UI stability + docs sync → v1.1.1
2. Inventory audit + low-stock thresholds → v1.1.2
3. Architecture cleanup (Realm → Firestore, async/await, domain) → v1.1.3
4. UI polish & component consistency → v1.1.4

## Рекомендована черга релізів після v1.1.0

### `v1.1.1` — UI Stability & Docs Sync

**Слоган:** прибираємо найвидиміші UX консистентності і синхронізуємо документацію з shipped v1.1.0.

- Issue `#190` tech-debt / high: Міграція UILabel → AppLabel для консистентної підтримки Dynamic Type / Accessibility.
- Issue `#240` docs / medium: chore(docs): sync product docs with current shipped state (цей самий документ, README, DEV guide, ARCH, REPORTS).
- **DoD:**
  - Основні екрани (Home, Reports Hub, Costs, Inventory, Settings) не мають bare `UILabel`, де це впливає на розміри/колір/динаміку шрифту.
  - docs/README.md + Documentations/*.md вже відповідають v1.1.x shipped реальності, описи “Reports ще не реалізовано” прибрані.

### `v1.1.2` — Inventory Audit & Bulk Count

**Слоган:** дозволяємо власнику “закрити склад за день” без 100+ ручних коригувань.

- Issue `#144` feature / medium: Implement InventoryAdjustment journal and bulk inventory workflow.
- Issue `#152` feature / low: Per-ingredient low stock thresholds for inventory highlighting.
- **DoD:**
  - Є окремий аудит-орієнтований екран/режим, де можна ввести фактичні залишки списком і отримати bulk-серію InventoryAdjustment з reason=inventory audit.
  - Low-stock thresholds зберігаються per-ingredient і підсвічуються на Stock List + Home warnings.

### `v1.1.3` — Architecture Cleanup (Storage + Concurrency)

**Слоган:** прибираємо технічний борг, який блокує далі product-швидкість.

- Issue `#141` refactor / medium: Remove remaining Realm usage from production code paths.
- Issue `#178` refactor / low: Повне видалення Realm з проекту та перехід на Firebase кешування.
- Issue `#140` refactor / medium: Migrate domain and FIR services to async/await.
- Issue `#142` refactor / medium: Refine domain models towards target architecture (Purchase/Opex/Sale/InventoryAdjustment).
- **DoD:**
  - Продукційні flow (Home, Reports, Costs/Purchases/Opex, POS/Orders, Inventory) читають/пишуть тільки Firestore/Firebase + ін-меморі кеш.
  - Realm залишається тільки як legacy migration-шар (або видалений повністю, якщо це пройшов 178).
  - Усі async-точки entrance (ViewModels → Services) використовують uniform async/await, legacy completion blocks із Firebase сервісів приховані всередині.
  - Моделі Purchase/Opex/Sale/InventoryAdjustment чітко розділені, дублювання CostModel зняте.

### `v1.1.4` — UI Polish & Consistency

**Слоган:** завершуємо 1.1.x лінію полищенням UI-консистентності і зачисткою старих залежностей.

- Issue `#173` refactor / low: Refactor UI to use secondaryText for auxiliary content.
- Issue `#100` fix / low: rewrite all Alerts to use PopFactory.
- Issue `#127` refactor / low: implement custom InputPopupView for PopupFactory to replace UIAlertController.
- Issue `#164` refactor / low: Migrate R.swift from CocoaPods to SPM.
- **DoD:**
  - На основних екранах всі другорядні підписи (дати, примітки, helper-text) консистентно використовують secondaryText стиль.
  - Девʼять десятків відсотків алертів/інпутів іде через PopupFactory + InputPopupView, UIAlertController залишається тільки в крайньому випадку і в legacy-місцях.
  - R.swift підключений через SPM; Pods R.swift прибрані (якщо це можливо без зриву інших Pods-залежностей).

## Залежності між задачами

- `#190` і `#240` незалежні; можна робити паралельно в межах v1.1.1.
- `#144` не залежить від `#152`, але краще починати з `#152` (threshold model) а потім добудовувати bulk workflow.
- `#141` → `#178`: спочатку прибрати Realm з продукційних шляхів, потім видалити залежність/моделі.
- `#142` залежить від `#140` (uniform async контракт дозволяє безболісно міняти моделі в сервісах).
- `#100` і `#127` можна робити паралельно з `#173`; `#164` тримати напередодні релізу v1.1.4, щоб не роздувати diff серед sprint-у.

## Чого не робити

- Не випускати `Reports UI` раніше за стабільні reporting DTO (вже зроблено в v1.1.0; тепер лише допрацьовуємо на основі відгуків).
- Не робити bulk inventory workflow в тому самому релізі, що і financial foundation (розділено: foundation = v1.1.0, bulk audit = v1.1.2).
- Не змішувати `Track Ingredients` з journal-based finance в один великий "суперреліз" (зробили окремо v1.0.10).
- Не дублювати фінансові формули між `Home`, сервісами та reports (залишаємо aggregation services + finance/reporting facade як єдине джерело метрик).
- Не починати v1.2 minor до того, як 1.1.x лінія не дійде стабільного v1.1.4 і не буде явного сигналу “потрібна нова велика фіча типу Multi-location / Roles / Receipt scanning”.
