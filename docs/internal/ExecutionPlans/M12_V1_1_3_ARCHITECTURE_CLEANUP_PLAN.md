# v1.1.3 — Architecture Cleanup (Storage + Concurrency) — Execution Plan

> **Milestone:** [Release v1.1.3](https://github.com/1cetoprosto/cyber-cafe/milestone/12)
> **Date created:** 2026-10-11
> **Status:** Completed (4/4 issues complete)
> **Type:** Refactor — no external behavior changes

---

## Як використовувати цей файл (новий діалог)

В новому діалозі просто скажи:
- **"Реалізуй етап 1"** — асистент прочитає цей файл, знайде секцію «Етап 1» і виконає її.
- **"Реалізуй етап 2"** — наступний етап, і т.д.
- Або назвати по issue: **"Зроби #141"**.

Асистент ОБОВ'ЯЗКОВО повинен:
1. Прочитати цей файл повністю перед початком.
2. Прочитати відповідну секцію етапу.
3. Слідувати правилам проєкту (`AGENTS.md`, `.trae/rules/project_rules.md`).
4. Після завершення — вказати у відповіді, що етап готовий і який наступний.
5. Оновити поле «Прогрес» внизу цього файлу.

---

## Порядок виконання (залежності)

```
Етап 1 (#142)  →  Етап 2 (#141)  →  Етап 3 (#178)  →  Етап 4 (#140)
domain models      видалити Realm     повне видалення    async/await
(фундамент)        з prod-потоків     Realm з проекту    сервісів
```

**Чому в такому порядку:**
1. Спочатку робимо доменні моделі єдиним джерелом істини — щоб рефакторити сервіси на правильних моделях.
2. Потім прибираємо Realm з живих потоків даних (низький ризик, кілька рядків).
3. Потім повністю видаляємо бібліотеку (не можна робити раніше Етапу 2 — будуть зламані імпорти).
4. async/await — наприкінці, щоб не мігрувати код, який все одно видаляється.

---

## Поточний стан коду (інвентаризація на 2026-10-11)

### Realm — де ще живий

**Папки повністю Realm-ові (будуть видалені в Етапі 3):**
- `TrackMyCafe/Services/Realm/` — `RealmDatabaseService.swift`, `RealmDB.swift`, `DateContainableType.swift`
- `TrackMyCafe/Data Layer/Models/Realm/` — 9 файлів: `RealmProductModel`, `RealmOrderModel`, `RealmPurchaseModel`, `RealmIngredientModel`, `RealmSaleGoodModel`, `RealmRecipeItemModel`, `RealmProductsPriceModel`, `RealmTypeModel`

**Production-код, де Realm ще згадується (Етап 2):**
| Файл | Що треба зробити |
|------|------------------|
| `Services/Domain/DomainDatabaseService.swift` | Видалити `import RealmSwift` (L9), метод `transferCollectionToFIR` (L1651), закоментовані методи міграції (L1143-1145) |
| `Application/SceneDelegate.swift` | Видалити `import RealmSwift` (L9) і весь метод `configureRealm()` (L27-71); виклик уже закоментований (L81) |
| `View Layer/.../SettingList/View/SettingListViewController.swift` | Видалити `import RealmSwift` (L10) — не використовується |
| `View Layer/.../Types/TypeList/View/TypesListViewController.swift` | Видалити `import RealmSwift` (L9) — не використовується |
| `View Layer/.../Products/ProductList/View/ProductListViewController.swift` | Видалити `import RealmSwift` (L8) + закоментовані `localRealm`/`productsArray` (L19-20) |
| `View Layer/.../Types/TypeDetail/View/TypeDetailsViewController.swift` | Видалити `import RealmSwift` (L8) — не використовується |
| `Services/Domain/DomainDB.swift` | Видалити закоментовані методи міграції Realm (L109-111) |
| `Services/Domain/InventoryService.swift` | Видалити застарілий коментар про Realm (L244-245) |

### Domain-моделі (#142)

**Уже існують** в `TrackMyCafe/Data Layer/Models/Domain/`:
- `PurchaseModel`
- `OpexExpenseModel` — поля: id, date, categoryId, amount, paymentAccount, note
- `OpexCategoryModel`
- `OrderModel`, `OrderItemModel`
- `InventoryAdjustmentModel`
- `ProductOfOrderModel` — **перевірити дублювання з `OrderItemModel`**
- `ProductCategoryModel`, `ProductsPriceModel`, `RecipeItemModel`, `TypeModel`, `IngredientModel`
- `PaymentAccount`, `JournalEntryModel`, `JournalSourceType`, `DailyBalanceModel`, `ManualMovementKind`

**Legacy `CostModel`** — не знайдено (ймовірно вже видалено).

### Concurrency (#140)

**Ще на completion handlers:**
- `Services/FIR/FirestoreDatabaseService.swift` — основні методи `read`, `readWhere`, `readDocumentIdRange`, `update`, `delete`, `deleteDocuments`, `fetchObjectById`, `readProducts`, `readTypes`, `readOrdersOfProducts`, `readOrder`, `deleteAllData`, `deleteUserAndRoles`
- `Services/FIR/FirestoreDB.swift` — 4 методи
- `Services/Domain/DomainDB.swift` — 33 методи (протокол)
- `Services/Domain/DomainDatabaseService.swift` — 39 completion + 15 async (частково)
- `Services/Domain/DemoDataManager.swift`, `CostingService.swift`, `DomainCostDataService.swift`, `FinanceHistoryBackfillService.swift`

**Вже async/await:**
- `DomainInventoryAdjustmentDataService`, `DomainProductPriceDataService`, `FinanceReportingService`, `DomainIngredientDataService`, `InventoryAuditService`, `InventoryService`, `DomainManualMovementService`, `DomainProductCategoryDataService`, `ImageStorageService`

---

# ЕТАП 1 — #142: Refine domain models (Purchase/Opex/Sale/InventoryAdjustment)

**Issue:** https://github.com/1cetoprosto/cyber-cafe/issues/142
**Пріоритет:** medium
**Мета:** доменні моделі — єдине джерело істини, відповідно до `ARCHITECTURE_AND_LOGIC.md`

## Дії

### 1.1 Прочитати специфікацію
- Відкрити `docs/internal/ARCHITECTURE_AND_LOGIC.md`, секції 1.1–1.4 (Purchase, OpexExpense, Sale/Order, InventoryAdjustment).
- Зафіксувати потрібні поля, інваріанти, зв'язки.

### 1.2 Аудит кожної моделі
Для кожної моделі в `Data Layer/Models/Domain/` перевірити відповідність специфікації:
- `PurchaseModel` — поля: id, date, supplier?, items?, totalAmount? (згідно специфікації)
- `OpexExpenseModel` — id, date, categoryId, amount, paymentAccount, note
- `OpexCategoryModel`
- `OrderModel` / `OrderItemModel` — структура чеку, позиції, статус, сума
- `InventoryAdjustmentModel` — тип коригування, причина, залишок до/після

### 1.3 Виявити дублікати
- Перевірити `ProductOfOrderModel` vs `OrderItemModel` — чи обидва потрібні? Якщо дублюють один бізнес-концепт — лишити один, другий позначити на видалення (видалити якщо ніхто не використовує).
- `Grep` по всьому проєкту для кожної моделі — хто нею користується.

### 1.4 Внести зміни (мінімальні)
- Якщо модель не відповідає специфікації — поправити поля/інваріанти.
- Якщо є дублікат — видалити зайвий тип і оновити всі посилання.
- Документувати навмисні відхилення коментарем в коді.

### 1.5 Валідація
- Build усіх схем: Dev, Beta, Prod.
- Smoke-тест у симуляторі: Purchase, Opex, Sale (Order), Inventory Adjustment флоу.
- Запустити існуючі тести, якщо є.

## Очікуваний результат
- Усі 4 цільові моделі (Purchase, OpexExpense, Order, InventoryAdjustment) відповідають специфікації.
- Немає дубльуючих типів для одного бізнес-концепту.
- Проєкт компілюється, флоу працюють.

## Acceptance Criteria
- [ ] Кожна модель має коментар з посиланням на секцію `ARCHITECTURE_AND_LOGIC.md`.
- [ ] Немає `ProductOfOrderModel` якщо вона дублює `OrderItemModel` (або навпаки).
- [ ] Build Dev/Beta/Prod — success.

---

# ЕТАП 2 — #141: Remove remaining Realm usage from production code paths

**Issue:** https://github.com/1cetoprosto/cyber-cafe/issues/141
**Пріоритет:** medium
**Мета:** жоден живий флоу не залежить від Realm; Realm ізольований у своїх папках.

> **Чому це робиться окремо від Етапу 3:** низький ризик (видалення невикористовуваних імпортів і мертвого коду), можна перевірити build перед повним видаленням бібліотеки.

## Дії

### 2.1 ViewControllers — видалити невикористані імпорти
Для кожного файлу — `Edit` (видалити рядок `import RealmSwift`):
- [SettingListViewController.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/TrackMyCafe/View%20Layer/Flow/Settings/SettingList/View/SettingListViewController.swift#L10)
- [TypesListViewController.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/TrackMyCafe/View%20Layer/Flow/Settings/Types/TypeList/View/TypesListViewController.swift#L9)
- [TypeDetailsViewController.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/TrackMyCafe/View%20Layer/Flow/Settings/Types/TypeDetail/View/TypeDetailsViewController.swift#L8)
- [ProductListViewController.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/TrackMyCafe/View%20Layer/Flow/Settings/Products/ProductList/View/ProductListViewController.swift#L8-L20) — також видалити закоментовані L19-20

### 2.2 DomainDatabaseService — прибрати Realm
- [DomainDatabaseService.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/TrackMyCafe/Services/Domain/DomainDatabaseService.swift#L9) — видалити `import RealmSwift`
- Видалити метод `transferCollectionToFIR` (L1651) — використовує `try! Realm()`
- Видалити закоментовані методи міграції (L1143-1145)

### 2.3 SceneDelegate — видалити configureRealm
- [SceneDelegate.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/TrackMyCafe/Application/SceneDelegate.swift#L9-L81) — видалити `import RealmSwift` і весь метод `configureRealm()` (L27-71) + закоментований виклик (L81)

### 2.4 DomainDB + InventoryService — застарілі коментарі
- [DomainDB.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/TrackMyCafe/Services/Domain/DomainDB.swift#L109-L111) — видалити закоментовані методи міграції
- [InventoryService.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/TrackMyCafe/Services/Domain/InventoryService.swift#L244-L245) — видалити застарілий коментар про Realm thread

### 2.5 Валідація
- `Grep` по проєкту: `import RealmSwift` — залишились лише файли в `Services/Realm/` та `Models/Realm/`.
- Build Dev/Beta/Prod — success.
- Перевірка, що `DomainDatabaseService` працює виключно через `FirestoreDatabaseService`.

## Очікуваний результат
- Production-код не звертається до Realm.
- Realm-код ізольований у `Services/Realm/` та `Models/Realm/` (готовий до видалення в Етапі 3).

## Acceptance Criteria
- [ ] `grep -r "import RealmSwift"` показує тільки `Services/Realm/**` та `Models/Realm/**`.
- [ ] Немає `try! Realm()` поза папками Realm.
- [ ] Build success.

---

# ЕТАП 3 — #178: Повне видалення Realm з проекту + Firebase cache

**Issue:** https://github.com/1cetoprosto/cyber-cafe/issues/178
**Пріоритет:** low (tech-debt)
**Мета:** бібліотека Realm повністю видалена; офлайн-кеш через Firestore persistence.

> **Попередня умова:** Етап 2 має бути завершений. Інакше будуть зламані імпорти.

## Дії

### 3.1 Видалити файли
- Видалити папку `TrackMyCafe/Services/Realm/` (3 файли): `RealmDatabaseService.swift`, `RealmDB.swift`, `DateContainableType.swift`
- Видалити папку `TrackMyCafe/Data Layer/Models/Realm/` (9 файлів)

### 3.2 Перевірити посилання
- `Grep` по всьому проєкту на `RealmDB`, `RealmDatabaseService`, `RealmProductModel` тощо — не повинно бути посилань.
- Перевірити `DomainDB.swift` — чи є ще посилання на Realm-типи.

### 3.3 Видалити залежність
- Відкрити `Podfile`, переконатись що там є `pod 'Realm'` / `pod 'RealmSwift'` (проєкт на CocoaPods, НЕ на SPM — незважаючи на те, що в issue згадується `project.pbxproj`).
- Видалити рядки `pod 'Realm'` і `pod 'RealmSwift'`.
- Запустити `pod install` (в терміналі, локально — Fastlane sandbox не дозволяє).
- Перевірити `Podfile.lock` — Realm зник.

### 3.4 Firestore persistence (офлайн-кеш)
- Знайти де налаштовується Firestore (`FirebaseApp.configure()` + `Firestore.firestore().settings`).
- Переконатись, що `isPersistenceEnabled = true` (Firestore persistence за замовчуванням увімкнено на iOS, але явно вказати).
- Якщо не налаштовано — додати конфігурацію.

### 3.5 Валідація
- Build Dev/Beta/Prod — success (більше немає `Realm` в target).
- Офлайн-тест: ввімкнути airplane mode, перевірити що дані читаються з кешу.
- Регресійний тест: Sales, Inventory, Opex, Settings флоу.

## Очікуваний результат
- Проєкт не містить `Realm`/`RealmSwift`.
- Усі дані через Firebase Firestore з persistence (офлайн-кеш).

## Acceptance Criteria
- [ ] `grep -ri "realm" --include="*.swift"` — 0 збігів.
- [ ] `Podfile` не містить `Realm`.
- [ ] Build success.
- [ ] Офлайн-режим працює (дані читаються з Firestore cache).

---

# ЕТАП 4 — #140: Migrate domain & FIR services to async/await

**Issue:** https://github.com/1cetoprosto/cyber-cafe/issues/140
**Пріоритет:** medium
**Мета:** усі основні data-flows на async/await; немає callback-ланцюгів.

> **Найбільший за обсягом етап** (100+ completion-методів у 10 файлах). Рекомендується окремим PR після замикання #141 + #178.

## Стратегія — знизу вгору

```
FIR-шар (FirestoreDatabaseService)  →  Domain-шар (DomainDB + DomainDatabaseService)  →  ViewModels
```

## Дії

### 4.1 FIR-шар: async-обгортки
Файл: [FirestoreDatabaseService.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/TrackMyCafe/Services/FIR/FirestoreDatabaseService.swift)

Додати async-версії для методів (через `withCheckedThrowingContinuation`):
- `read<T: Decodable>(collection:firModel:)` — returns `[(String, T)]`
- `readWhere<T: Decodable>(collection:field:isEqualTo:firModel:)`
- `readDocumentIdRange<T: Decodable>(...)`
- `fetchObjectById<T: Decodable>(ofType:collection:id:)` — returns `T`
- `update<T: Encodable>(firModel:collection:documentId:)`
- `delete(collection:documentId:)`
- `deleteDocuments(...)`
- `readProducts`, `readTypes`, `readOrdersOfProducts`, `readOrder`

**Патерн обгортки:**
```swift
func read<T: Decodable>(collection: String, firModel: T.Type) async throws -> [(String, T)] {
    try await withCheckedThrowingContinuation { continuation in
        self.read(collection: collection, firModel: firModel) { result in
            switch result {
            case .success(let models):
                continuation.resume(returning: models)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
```

### 4.2 Domain-шар: конвертувати DomainDB протокол
Файл: [DomainDB.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/TrackMyCafe/Services/Domain/DomainDB.swift)

Перетворити 33 completion-методи на async:
- `fetchIngredients()` async -> `[IngredientModel]`
- `saveIngredient(model:)` async -> `Bool`
- `deleteIngredient(model:)` async -> `Bool`
- ... і всі інші (purchases, opex, orders, inventory, etc.)

### 4.3 DomainDatabaseService — імплементація
Файл: [DomainDatabaseService.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/TrackMyCafe/Services/Domain/DomainDatabaseService.swift)

- Конвертувати 39 completion-методів на async (використовуючи нові async-методи FIR-шару).
- Дотримуватись SwiftLint `cyclomatic_complexity ≤ 10` — великі методи розбивати на helper-и (як зроблено для `updateOrder` → `prepareProducts`, `computeDeltaItems`, `persistProducts`, `applyInventoryUpdates`).

### 4.4 ViewModels
- Оновити виклики на async/await, де це доречно.
- Правила: ViewModels **не імпортують UIKit**, використовують протоколи для DI.
- Логування: `OSLog/Logger`, кожен обробник помилок з контекстом.

### 4.5 Сумісність
- Залишити completion-версії лише якщо є зовнішні споживачі, які складно мігрувати одразу. Краще — мігрувати все одразу, щоб не дублювати API.

### 4.6 Валідація
- Build Dev/Beta/Prod — success.
- Ручне тестування: Sales, Costs, Home, Settings флоу.
- (Опціонально) Легкі unit-тести для критичних сервіс-методів.

## Очікуваний результат
- Callback-ланцюги замінені на async/await.
- Поведінка без змін.
- Код чистіший, менше вкладеності.

## Acceptance Criteria
- [ ] `FirestoreDatabaseService` має async-версії всіх CRUD-методів.
- [ ] `DomainDB` протокол — усі методи async.
- [ ] Немає `completion: @escaping` у нових/оновлених методах (крім обгорток сумісності).
- [ ] Build success.
- [ ] Основні флоу працюють без регресій.

---

## Ризики та застереження (для всіх етапів)

1. **SwiftLint `cyclomatic_complexity ≤ 10`** — при рефакторингу великих методів `DomainDatabaseService` розбивати на helper-и. Інакше `fastlane archive` впаде з exit 65.
2. **Realm підключено через SPM, а не Pods** — `Podfile` містить лише `R.swift`; Realm додано як Swift Package (`realm-swift`). Видалення файлів Realm зроблено через Xcode MCP (`XcodeRM`), щоб не редагувати `project.pbxproj` вручну. SPM-посилання на `realm-swift` залишилось у проєкті (немає MCP-інструмента для видалення SPM-пакета; прибрати одним кліком у Xcode: File → Packages → Remove).
3. **Firestore persistence** — за замовчуванням увімкнено на iOS, але явно перевірити конфігурацію перед видаленням Realm (офлайн-функціональність).
4. **Змішаний стан async/completion** у `DomainDatabaseService` — мігрувати функція за функцією, не зламати build.
5. **Правило проєкту:** `_ = await MainActor.run` для придушення попереджень про невикористаний результат.
6. **Swift 6 `#ImplicitStrongCapture`** — `[weak self]` у вкладених замиканнях, явні capture lists.

---

## Прогрес (оновлювати після кожного етапу)

| Етап | Issue | Статус | Дата завершення |
|------|-------|--------|-----------------|
| 1 — Domain models | #142 | ✅ Done | 2026-10-11 |
| 2 — Realm з prod | #141 | ✅ Done | 2026-10-11 |
| 3 — Повне видалення Realm | #178 | ✅ Done | 2026-10-11 |
| 4 — async/await | #140 | ✅ Done | 2026-10-11 |

---

## Посилання

- [Milestone v1.1.3](https://github.com/1cetoprosto/cyber-cafe/milestone/12)
- [Issue #140 — async/await](https://github.com/1cetoprosto/cyber-cafe/issues/140)
- [Issue #141 — Realm з prod](https://github.com/1cetoprosto/cyber-cafe/issues/141)
- [Issue #142 — Domain models](https://github.com/1cetoprosto/cyber-cafe/issues/142)
- [Issue #178 — Повне видалення Realm](https://github.com/1cetoprosto/cyber-cafe/issues/178)
- `docs/internal/ARCHITECTURE_AND_LOGIC.md` — специфікація доменних моделей
- `docs/internal/DEV_IMPLEMENTATION_GUIDE.md` — поточний стан проєкту
- `AGENTS.md`, `.trae/rules/project_rules.md` — правила кодування
