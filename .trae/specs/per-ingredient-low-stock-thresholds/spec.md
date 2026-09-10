# TrackMyCafe — Per-Ingredient Low-Stock Thresholds (PRD)

## Overview
- **Summary**: Кожен інгредієнт може мати власний опціональний мінімальний поріг залишків (`minStockThreshold`), який використовується замість глобального хардкод-значення `5.0` при вирішенні, чи підсвічувати кількість червоним в списку Inventory → Stock. Користувач встановлює/редагує поріг в Settings → Ingredients (екран Create/Edit Ingredient). Поріг зберігається в Firestore та Realm із збереженням зворотної сумісності (існуючі документи без поля — `nil`, fallback на існуючу поведінку).
- **Purpose**: Зменшити шум "low stock" попереджень та зробити їх сенсовим для різних інгредієнтів (різна швидкість витрати, різні циклі замовлення).
- **Target Users**: Власники кафе/менеджери складу, які працюють з Inventory та Settings → Ingredients.

## Goals
- Додати опціональне поле `minStockThreshold: Double?` до кожної моделі інгредієнта (Domain / Firestore / Realm) і маперів.
- Додати поле введення для `minStockThreshold` в екран Create Ingredient / Edit Ingredient з валідацією (додатне число або порожньо = `nil`).
- Оновити логіку підсвітки в `StockItemCell.configure`: якщо `minStockThreshold != nil`, використовувати його; інакше fallback на `stockQuantity < 5.0` (наявна поведінка).
- Забезпечити зворотну сумісність: існуючі Firestore-документи без поля, існуючі Realm-об'єкти та існуючі користувачі не повинні отримувати регресії або міграційних помилок.
- Додати відповідні ключі локалізації UK/EN.

## Non-Goals
- Не змінювати логіку InventoryAdjustment, процес коригувань, `averageCost` чи закупки.
- Не реалізовувати глобальний (загальнододатковий) налаштування порогу; тільки per-ingredient.
- Не додати home-screen warnings/dashboard зараз (issue #152 scope це тільки model + UI edit + Stock list highlight).
- Не змінювати Realm-версії схеми / не додавати міграції (оскільки нове поле — опціональне, Realm 10+ додає `@Persisted var minStockThreshold: Double? = nil` без міграції).

## Background & Context
- Поточна логіка: [StockItemCell.configure](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/TrackMyCafe/View%20Layer/Flow/Inventory/StockList/View/StockItemCell.swift#L101-L105) — `if model.stockQuantity < 5.0 { quantityLabel.textColor = .systemRed }`.
- Issue: `#152`, Milestone: Release v1.1.2.
- Патерни моделей (FIR/Realm → Domain) можна побачити в [FIRInventoryAdjustmentModel](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/TrackMyCafe/Data%20Layer/Models/Firestore/FIRInventoryAdjustmentModel.swift) — опціональні поля `String?` / `Double?` використовуються для backward-compat auditing.
- Документація проекту підтверджує target: [DEV_IMPLEMENTATION_GUIDE.md](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/docs/internal/DEV_IMPLEMENTATION_GUIDE.md) p.50, [ROADMAP.md](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/cyber-coffe/docs/internal/ROADMAP.md).

## Functional Requirements
- **FR-1 (Data model)** — `IngredientModel` містить опціональне поле `minStockThreshold: Double?` (те ж одиниця виміру, що й `stockQuantity`: kg/g/l/ml/pcs).
- **FR-2 (Firestore model)** — `FIRIngredientModel` містить `minStockThreshold: Double?` (додатково, default `nil`); ініціалізатори `init(dataModel:)` та `IngredientModel(firebaseModel:)` маплять поле в обидві сторони.
- **FR-3 (Realm model)** — `RealmIngredientModel` містить `@Persisted var minStockThreshold: Double? = nil`; `init(dataModel:)` та `IngredientModel(realmModel:)` маплять.
- **FR-4 (Realm update)** — `RealmDatabaseService.updateIngredient(...)` приймає додатковий параметр `minStockThreshold: Double?` і записує його.
- **FR-5 (Edit / Create UI)** — `CreateIngredientViewController` показує нове секційне поле для порогу (текстове введення, decimalPad, maxFractionDigits = 3, як у stock); при create/updated передає значення в ViewModel → DataService → model.
- **FR-6 (ViewModel)** — `IngredientListViewModel.createIngredient` та `updateIngredient` приймають і передають `minStockThreshold: Double?`.
- **FR-7 (Stock list highlighting)** — `StockItemCell.configure` обчислює поріг: `model.minStockThreshold ?? 5.0`. Якщо `stockQuantity < threshold`, колір — `.systemRed`.
- **FR-8 (Validation)** — поріг може бути порожнім (== `nil`) або >= 0; від'ємні значення заборонені (алерт).
- **FR-9 (Backward compat)** — існуючі Firestore документи без `minStockThreshold` мапляться в `nil`; існуючі Realm об'єкти — `nil`; fallback на FR-7 повертає 5.0.
- **FR-10 (Localization)** — додано ключі `ingredientMinStockThreshold` (label), `ingredientMinStockThresholdPlaceholder` (placeholder), `ingredientMinStockThresholdExplanation` (explanation label) в обох `uk.lproj` та `en.lproj`.

## Non-Functional Requirements
- **NFR-1 (MVVM)** — ViewModels (`IngredientListViewModel` тощо) **не** імпортують UIKit; протоколи DI залишаються незмінними (додаткові параметри в існуючих методах допустимі).
- **NFR-2 (No force unwraps)** — Жоден новий / змінений код не використовує `!`.
- **NFR-3 (Async/await)** — Нові асинхронні шляхи використовують лише `async/await` (не Completion Handlers, окрім існування DomainDatabaseService completion path).
- **NFR-4 (Logging)** — Лише `Logger`/`OSLog`. Ніяких `print()`.
- **NFR-5 (Dynamic Type)** — Нові UILabel/TextField: не фіксовані висоти; 0 lines для пояснень; auto-shrink (за необхідності) для numeric полів.
- **NFR-6 (No .pbxproj / Info.plist ручних правок)** — нові файли не створюються (лише редагування існуючих).
- **NFR-7 (Zero warnings)** — Зміни не додають нових Swift compiler warnings / diagnostics.

## Constraints
- **Technical**: UIKit programmatic + TinyConstraints. Не SwiftUI, не Storyboard. Архітектура MVVM з протокольним DI. Firebase v10+, Realm v10+. iOS 15+.
- **Business**: Поле Optional. Існуюча поведінка (5.0 fallback) зберігається для інгредієнтів без порогу. Не ламаємо найнелі (Ingredient name, cost, stock, unit) — вони залишаються required.
- **Dependencies**: Заборонено нові Pods / SPM packages.

## Assumptions
- Realm `@Persisted var ...: Double? = nil` додається без ручної міграції / зміни `schemaVersion`, оскільки це нове опціональне property.
- Firestore Codable `@DocumentID` модель без проблем десериалізує документ без поля як `nil`.
- UI `CreateIngredientViewController` використовує той самий патерн `InputContainerView` + explanation label, як stock/cost; секція додається після `stock` секції перед `unit`.

## Acceptance Criteria

### AC-1: Domain model field
- **Type**: `rule`
- **Given**: Вже зкомпільований додаток з змінами
- **When**: Інспектувати `IngredientModel` структуру
- **Then**: Має опціональне властивість `minStockThreshold: Double?`; воно передається через всі init-и (memberwise, `init(realmModel:)`, `init(firebaseModel:)`, convenience default).
- **Pass Condition**: `IngredientModel.minStockThreshold` компілюється як `Double?` і не є implicitly unwrapped.
- **Evidence**: Static source inspection of IngredientModel.swift.

### AC-2: FIR & Realm models + mapper parity
- **Type**: `rule`
- **Given**: Existing Firestore/Realm documents without minStockThreshold
- **When**: Маппинг FIR → Domain, Realm → Domain, Domain → FIR, Domain → Realm
- **Then**: Опціональне поле мапиться коректно; відсутнє поле в FIR/Realm = `nil` в Domain; наявне поле передається без втрат.
- **Pass Condition**: FIRIngredientModel має `var minStockThreshold: Double?`, RealmIngredientModel має `@Persisted var minStockThreshold: Double? = nil`, ініціалізатори маплять поле без `!`.
- **Evidence**: Source inspection of FIRIngredientModel.swift, RealmIngredientModel.swift, IngredientModel.swift inits.

### AC-3: StockItemCell highlight logic uses per-ingredient threshold or fallback
- **Type**: `rule`
- **Given**: Інгредієнт A (minStockThreshold=12.0, stock=10.0), Інгредієнт B (threshold=nil, stock=3.0), Інгредієнт C (threshold=nil, stock=6.0)
- **When**: `StockItemCell.configure(with:)` викликано для кожного
- **Then**: A quantity = red (10<12); B quantity = red (3<5); C quantity = default color (6>=5).
- **Pass Condition**: Логіка в cell: `let threshold = model.minStockThreshold ?? 5.0; if model.stockQuantity < threshold { .systemRed } else { .cellLabel }`.
- **Evidence**: Source diff / inspection of StockItemCell.swift:90-106.

### AC-4: Create / Edit Ingredient UI exposes threshold field
- **Type**: `rule`
- **Given**: Відкритий CreateIngredientViewController (новий або edit режим)
- **When**: Користувач бачить екран
- **Then**: Є окрема секція з полем введення для мінімального порогу (label, placeholder, explanation, decimalPad, max 3 fraction digits); поле опціональне (не required для create).
- **Pass Condition**: `CreateIngredientViewController` містить `minStockInputContainer`, відповідну explanationLabel; додається до stackView; `fillData()` заповнює значення при редагуванні; `saveAction()` парсить Double? з порожнім значенням = `nil`.
- **Evidence**: Source inspection of CreateIngredientViewController.swift.

### AC-5: ViewModel & DataService propagate minStockThreshold
- **Type**: `rule`
- **Given**: Користувач ввів minStockThreshold в UI і натиснув Save / Add
- **When**: createIngredient / updateIngredient викликано
- **Then**: ViewModel передає `minStockThreshold` в IngredientModel, модель зберігається через DataService; поле доходить до FIR моделі.
- **Pass Condition**: `IngredientListViewModel.createIngredient(... minStockThreshold: Double? ...)` і `updateIngredient(_ ingredient:)` передають поле; в `saveIngredient(model:)` значення є вFIRIngredientModel.
- **Evidence**: Source inspection of IngredientListViewModel.swift + CreateIngredientViewController.saveAction.

### AC-6: Realm updateIngredient writes minStockThreshold
- **Type**: `rule`
- **Given**: Виклик `RealmDatabaseService.updateIngredient` з не-nil `minStockThreshold`
- **When**: `executeWrite` виконано
- **Then**: `model.minStockThreshold` встановлено в Realm об'єкті.
- **Pass Condition**: Сигнатура `updateIngredient(model:name:cost:stock:unit:minStockThreshold:)`; write-транзакція присвоює `model.minStockThreshold = minStockThreshold`; всі викликачі пройшли компіляцію (default value `nil` для сумісності).
- **Evidence**: Source inspection of RealmDatabaseService.swift updateIngredient.

### AC-7: Backward compatibility — no migration / crashes
- **Type**: `rule`
- **Given**: Існуючий користувач без міграції; Firestore документ без `minStockThreshold` поля
- **When**: Fetch / save / update
- **Then**: Код не крашить; nil мапиться коректно; StockItemCell fallback на 5.0.
- **Pass Condition**: Усі нові поля — Optional (Double?) з default nil; FIR `init(dataModel:)` та Domain init не використовують force-unwrap; Realm field — `@Persisted ... = nil`.
- **Evidence**: Source review (немає `!`; всі опціональні поля без default-значень у init-ах з безпечним доступом).

### AC-8: Localization UK/EN keys present
- **Type**: `rule`
- **Given**: Запущена збірка додатка з локалізацією UK / EN
- **When**: UI викликає R.string глобальні ключі для threshold label/placeholder/explanation
- **Then**: R.string генерує доступ; обидві локалізації містять ключі.
- **Pass Condition**: Global.strings (uk.lproj) містять `ingredientMinStockThreshold`, `ingredientMinStockThresholdPlaceholder`, `ingredientMinStockThresholdExplanation`; Global.strings (en.lproj) містять ті самі ключі з англ перекладами.
- **Evidence**: Grep по двох .strings файлах.

### AC-9: Zero force unwraps; compliance with project NFRs
- **Type**: `rubric`
- **Dimension**: Відповідність проекту код-стандартам (MVVM, no `!`, no `print()`, UIKit-only TinyConstraints).
- **Scale**: 1–5
- **Anchors**: 1 = кілька `!` або print() в зміненому коді; 3 = більшість правил дотримано, одна невідповідність; 5 = всі правила NFR-1…NFR-7 дотримано без винятків.
- **Pass Threshold**: >= 4
- **Evidence**: Source diff inspection + `GetDiagnostics` result.

### AC-10: Build & diagnostics
- **Type**: `rule`
- **Given**: Всі зміни внесені
- **When**: Збірка проекту (`xcodebuild` / MCP BuildProject) та `GetDiagnostics`
- **Then**: 0 errors, 0 нових warnings.
- **Pass Condition**: Build SUCESS; `GetDiagnostics` → порожній errors list.
- **Evidence**: Build command output / diagnostics output.

## Open Questions
- [x] Fallback значення? → Так, залишити існуюче `5.0` (додано до AC-3).
- [x] Чи потрібно нове поле в Realm мігрувати? → Ні, `@Persisted var ...: Double? = nil` — Realm 10+ не вимагає міграції для нових опціональних властивостей.
