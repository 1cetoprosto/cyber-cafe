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

Стратегія для **v1.2 minor** (Multi-user & Staff Management):

1. Спершу — адаптація вже перенесеної з DTLab інфраструктури ролей під кафе (`#271`).
2. Потім — інтеграція розділу «Персонал» в UI та виправлення зламаних екранів (`#272`, `#273`, `#277`).
3. Паралельно — прив'язка замовлень до співробітника (`#275`) та прибирання лімітів (`#276`).
4. Далі — контроль доступу за ролями (`#274`) та фільтрація даних для Офіціанта (`#278`).
5. Наприкінці — технічний борг (MVVM, `#279`) та документація (`#280`).

## Рекомендована черга релізів після v1.1.0

### `v1.1.1` — UI Stability & Docs Sync

**Слоган:** прибираємо найвидиміші UX консистентності і синхронізуємо документацію з shipped v1.1.0.

- Issue `#190` tech-debt / high: Міграція UILabel → AppLabel для консистентної підтримки Dynamic Type / Accessibility.
- Issue `#240` docs / medium: chore(docs): sync product docs with current shipped state (цей самий документ, README, DEV guide, ARCH, REPORTS).
- **DoD:**
  - Основні екрани (Home, Reports Hub, Costs, Inventory, Settings) не мають bare `UILabel`, де це впливає на розміри/колір/динаміку шрифту.
  - docs/README.md + docs/internal/*.md вже відповідають v1.1.x shipped реальності, описи “Reports ще не реалізовано” прибрані.

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
  - Realm повністю видалено з проекту (залежності, моделі, сервіси); офлайн — через Firebase cache.
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

### `v1.2` — Multi-user & Staff Management

**Слоган:** відкриваємо кафе для команди — ролі, персонал, контроль доступу та зв'язок замовлень зі співробітником.

> **Передумова:** v1.1.x лінія дійшла стабільного v1.1.4. Явний сигнал — бізнес потреба в багатокористувацькій роботі (офіціанти приймають замовлення, менеджер керує касою).

#### Контекст перенесення з DTLab

Інфраструктура ролей (`Role`, `RoleConfig`, `Technician`, `Admin`, `UserSession`, email-link запрошення) вже перенесена з проекту DTLab, але:
- розділ «Персонал» **не підключений** до навігації;
- термінологія (`technician`, `techMod`, `isAllowedCalculationsForAdministrator`) лабораторія-специфічна;
- контроль доступу за ролями **не реалізований** (`isAdmin`/`isModerator` ніде не фільтрують екрани);
- замовлення не зберігають автора.

#### Рішення для кафе

- **3 ролі:** Власник (`.administrator`), Менеджер (`.moderator`), Офіціант (`.waiter`).
- `techMod` прибирається з UI (залишається в enum для зворотної сумісності БД).
- **Часткове перейменування:** `Role.technician` → `Role.waiter`, `Technician` → `Employee`, `techRef` → `employeeRef`. Firestore колекція `technicians` **не міняється** (уникаємо ризикованої міграції).
- **Без обмежень** за кількістю персоналу (прибирається `staffCount`).
- Замовлення прив'язуються до співробітника через `createdBy` (`employeeRef`). Офіціант бачить тільки свої.

#### Матриця доступу

| Функція | Власник | Менеджер | Офіціант |
|---|---|---|---|
| Замовлення (всі) | ✅ | ✅ | ❌ (тільки свої) |
| Гроші / P&L / Баланси | ✅ | ✅ | ❌ |
| Звіти (Reports Hub) | ✅ | ✅ | ❌ |
| Інвентар / Витрати (Costs) | ✅ | ✅ | ❌ |
| Персонал (Staff) | ✅ | ❌ | ❌ |
| Меню / Прайс | ✅ | ✅ | ❌ |
| Підписка | ✅ | ❌ | ❌ |
| Налаштування | всі | без підписки | тільки безпека |

#### Задачі

- Issue `#271` refactor / high: Адаптувати систему ролей під кафе (technician → waiter, прибрати techMod з UI, видалити `isAllowedCalculationsForAdministrator`).
- Issue `#272` feature / high: Інтегрувати розділ «Персонал» в налаштування (доступ тільки для Власника).
- Issue `#273` fix / high: Переписати `TechnicianDetailsController` на AutoLayout (реальні дані, edit/delete/resend invite).
- Issue `#274` feature / high: Контроль доступу за ролями (RBAC) — таби та секції налаштувань.
- Issue `#275` feature / high: Прив'язати замовлення до співробітника (поле `createdBy`) + фільтр для Офіціанта.
- Issue `#276` refactor / low: Прибрати ліміт кількості персоналу за підпискою.
- Issue `#277` feature / medium: Полірувати форму створення співробітника (спрощення ролей, валідація).
- Issue `#278` feature / medium: Фільтрація замовлень та дашборду для ролі Офіціант.
- Issue `#279` refactor / medium: MVVM-рефакторинг Staff-модуля (ViewModels + протоколи).
- Issue `#280` docs / low: Документація та онбординг системи персоналу та ролей.

- **DoD:**
  - Власник бачить пункт «Персонал» в налаштуваннях і може додавати/редагувати/видаляти співробітників (Менеджер та Офіціант).
  - Співробітник отримує email-link запрошення, входить і бачить тільки дозволені йому таби/секції.
  - Офіціант бачить тільки свої замовлення та метрики на дашборді.
  - Усі видимі тексти про ролі — кафе-специфічні (Власник / Менеджер / Офіціант), без згадок про лабораторію чи техніків.
  - Staff-модуль відповідає MVVM (ViewModels, без прямого доступу до RequestManager у ViewControllers).
  - Немає обмежень за кількістю персоналу.

## Залежності між задачами

- `#190` і `#240` незалежні; можна робити паралельно в межах v1.1.1.
- `#144` не залежить від `#152`, але краще починати з `#152` (threshold model) а потім добудовувати bulk workflow.
- `#141` → `#178`: спочатку прибрати Realm з продукційних шляхів, потім видалити залежність/моделі.
- `#142` залежить від `#140` (uniform async контракт дозволяє безболісно міняти моделі в сервісах).
- `#100` і `#127` можна робити паралельно з `#173`; `#164` тримати напередодні релізу v1.1.4, щоб не роздувати diff серед sprint-у.

### Залежності v1.2

- `#271` (рефакторинг ролей) — **фундамент**, від нього залежать `#272`, `#273`, `#274`, `#277`, `#278`.
- `#275` (поле `createdBy` в замовленнях) — незалежна, але `#274` та `#278` залежать від неї.
- `#276` (прибрати ліміти) — повністю незалежна, можна робити в будь-який момент.
- `#272` (інтеграція в налаштування) та `#273` (деталі співробітника) — залежать від `#271`, між собою незалежні.
- `#274` (RBAC) — залежить від `#271` та `#275`.
- `#277` (форма створення) — залежить від `#271`.
- `#278` (фільтрація для Офіціанта) — залежить від `#275` та `#274`.
- `#279` (MVVM) — залежить від `#272`, `#273`, `#277` (UI має стабілізуватися).
- `#280` (доки) — залежить від `#272`, `#274`; робити наприкінці.

**Рекомендована черга всередині v1.2:**
1. `#271` (ролі) — перший крок
2. Паралельно: `#275` (createdBy) + `#276` (прибрати ліміти)
3. Паралельно: `#272` (інтеграція) + `#273` (деталі) + `#277` (форма)
4. `#274` (RBAC)
5. `#278` (фільтрація Офіціанта)
6. `#279` (MVVM)
7. `#280` (доки)

## Чого не робити

- Не випускати `Reports UI` раніше за стабільні reporting DTO (вже зроблено в v1.1.0; тепер лише допрацьовуємо на основі відгуків).
- Не робити bulk inventory workflow в тому самому релізі, що і financial foundation (розділено: foundation = v1.1.0, bulk audit = v1.1.2).
- Не змішувати `Track Ingredients` з journal-based finance в один великий "суперреліз" (зробили окремо v1.0.10).
- Не дублювати фінансові формули між `Home`, сервісами та reports (залишаємо aggregation services + finance/reporting facade як єдине джерело метрик).
- Не додавати нові ролі (Бариста, Кухар тощо) в межах v1.2 — обмежуємося трьома (Власник / Менеджер / Офіціант). Розширення ролей — окремий майбутній реліз.
- Не реалізовувати granular-права (per-feature toggles) в v1.2 — використовуємо role-based доступ через матрицю. RBAC з permissions — для майбутнього.
- Не міняти структуру Firestore для існуючих `RoleConfig` та `Technician` документів без міграції — `techMod` залишається в enum для зворотної сумісності, але не показується в UI.
- Не додавати ліміти персоналу в v1.2 — кафе може мати будь-яку кількість співробітників без огляду на підписку.
