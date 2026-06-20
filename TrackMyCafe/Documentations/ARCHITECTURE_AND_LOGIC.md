# Архітектура та Логіка TrackMyCafe

Цей документ описує target architecture: цільові доменні моделі, бізнес-правила, сервіси та взаємодію між ними.

Важливо:

- це не release roadmap;
- це не канонічний статус поточної реалізації;
- якщо треба зрозуміти, що реально вже shipped у `1.0.7`, дивись `DEV_IMPLEMENTATION_GUIDE.md`;
- якщо треба зрозуміти чергу релізів після `1.0.7`, дивись `ROADMAP.md`.

---

## 0. Версії та охоплення

- **Поточний release baseline: 1.0.7**
  - Основні екрани: `Home`, `Income`, `Costs`, `Settings`.
  - `Reports Hub` у поточному таббарі ще не ввімкнений.
  - `Home` вже має базові summaries і period-based aggregation для частини метрик, але це ще не повний `P&L dashboard`.
  - `InventoryAdjustmentModel` і ручні коригування вже існують, але bulk inventory workflow ще не добудований.
  - Firebase Firestore є primary storage; Realm лишається legacy-шаром.

- **Наступні релізи**
  - Довести до кінця `cash/card balances`.
  - Довести до кінця historical `COGS snapshot` на рівні `OrderModel`/`OrderItemModel`.
  - Додати `Track Ingredients`.
  - Після цього добудувати full aggregation/reporting stack.

Нижченаведені моделі та сервіси описують **цільову архітектуру**, до якої додаток рухається. Поточна реалізація `1.0.7` покриває лише частину цієї логіки.

---

## 1. Моделі даних (Data Layer)

Ми відмовляємось від загальної моделі `CostModel` та переходимо до спеціалізованих моделей для точного обліку.

### 1.1. Закупівля (Purchase)
Відповідає за поповнення складу та формування собівартості інгредієнтів.
**Вплив:** Збільшує `Ingredient.stockQuantity`, змінює `Ingredient.averageCost`.

```swift
struct PurchaseModel: Identifiable, Codable {
    let id: String
    let date: Date
    let ingredientId: String // Зв'язок з IngredientModel
    let quantity: Double     // Кількість закупленого (в одиницях інгредієнта)
    let price: Double        // Ціна за одиницю (unitPrice)
    let supplierId: String?  // Опціонально для MVP

    // Computed properties
    var totalCost: Double { quantity * price }
}
```


### 1.2. Операційна витрата (OpexExpense)
Відповідає за витрати, що не стосуються складу (оренда, комунальні, зарплата).
**Вплив:** Зменшує `NetProfit`, не впливає на `GrossProfit`.

```swift
struct OpexExpenseModel: Identifiable, Codable {
    let id: String
    let date: Date
    let amount: Double       // Сума витрати
    let note: String?        // Коментар
}
```

### 1.3. Продаж (Sale) / Замовлення (Order)
Фіксує факт продажу та списання собівартості.
**Вплив:** Зменшує `Ingredient.stockQuantity`, збільшує `Revenue`.

> **Важливо про стан моделі:**
> У кодовій базі 1.0.x `OrderModel` все ще зберігає переважно "шапку" чеку (`sum`, `cash`, `card`, `totalCost`), а item-level деталізація живе окремо.
> Для задач `#143`, `#145`, `#146` та `#154` цільовою моделлю вважаємо зв'язку `OrderModel` + `OrderItemModel`, де:
> - `OrderModel` відповідає за підсумок чеку;
> - `OrderItemModel` відповідає за item-level snapshot (`salePrice`, `costPrice`, `quantity`);
> - ABC/reporting більше не повинні спиратись на абстрактну single-line `Sale` модель.

```swift
struct OrderModel {
    let id: String
    let date: Date
    let items: [OrderItemModel]
    let totalAmount: Double  // Сума чеку (Sales)
    let totalCost: Double    // Сума собівартості (COGS) - фіксується в момент продажу!
}

struct OrderItemModel {
    let productId: String
    let quantity: Int
    let salePrice: Double    // Ціна продажу за одиницю
    let costPrice: Double    // Собівартість за одиницю (розрахована на момент продажу)
}
```

### 1.4. Коригування складу (InventoryAdjustment)
Для інвентаризації (списання псування, постановка надлишків).
**Вплив:** Змінює `Ingredient.stockQuantity`, не змінює `averageCost`.

```swift
struct InventoryAdjustmentModel {
    let id: String
    let date: Date
    let ingredientId: String
    let quantityDelta: Double // + або -
    let reason: String
}
```

---

## 2. Сервіси та Бізнес-логіка (Service Layer)

Вся бізнес-логіка виноситься у відповідні сервіси. ViewModels лише викликають методи сервісів.

### 2.1. InventoryService (Складський облік)
Відповідає за розрахунок середньозваженої ціни та залишків.

**Методи:**
*   `processPurchase(purchase: PurchaseModel)`
    *   Логіка:
        1.  Отримати поточний `Ingredient`.
        2.  Розрахувати нову кількість: `newQty = oldQty + purchase.quantity`.
        3.  Розрахувати нову ціну: `newAvg = ((oldQty * oldAvg) + (purchase.qty * purchase.price)) / newQty`.
        4.  Оновити `Ingredient` в БД.
*   `processSale(items: [OrderItemModel])`
    *   Логіка:
        1.  Перевірити глобальне налаштування `Track Ingredients`.
        2.  Якщо `Track Ingredients = Off`, продаж не змінює склад і не створює автоматичних stock-adjustments.
        3.  Якщо `Track Ingredients = On`, для кожного товару знайти його рецепт (`RecipeItem`).
        4.  Для кожного інгредієнта рецепту списати кількість: `stockQty -= item.qty * recipe.qty`.
*   `validateStock(for items: [OrderItemModel]) -> [StockWarning]`
    *   Перевіряє, чи не піде склад в мінус (для відображення попереджень).

### 2.2. CostingService (Розрахунок вартості)
Відповідає за калькуляцію.

**Методи:**
*   `calculateProductCost(productId: String) -> Double`
    *   Сумує `ingredient.avgCost * recipe.qty` для всіх компонентів.
*   `calculateOrderMetrics(items: [OrderItemModel]) -> (totalSale: Double, totalCost: Double)`
    *   Використовується при створенні замовлення для фіксації COGS.

### 2.3. Aggregation + Finance/Reporting Layer (з версії 1.1.0+)
Щоб не дублювати розрахунки між `Home`, `Reports` і окремими ViewModel, фінансовий шар розділяється на 2 рівні:

**1. Aggregation services**
*   `IncomeAggregationService`
    *   Повертає `Sales`, `cash`, `card` та базові order-based summaries за період.
*   `OpexAggregationService`
    *   Повертає `Opex` summaries за період.
*   `FinanceAggregationService`
    *   Комбінує sales/COGS/opex у `GrossProfit`, `NetProfit`, `GrossMargin`.

**2. Finance/Reporting facade**
*   Будує DTO для `P&L`, `ABC`, `Trends`, dashboard tiles та reports screens.
*   Не дублює формули, а використовує aggregation services як єдине джерело метрик.

**Базові формули:**
*   `Sales = sum(Orders.totalAmount)`
*   `COGS = sum(Orders.totalCost)`
*   `Opex = sum(OpexExpense.amount)`
*   `GrossProfit = Sales - COGS`
*   `NetProfit = GrossProfit - Opex`

У версії **1.0.7** Home уже використовує частину aggregation services, але повний шар, наведений у цьому підрозділі, все ще є таргетом для `#154` і `#145`.

---

## 3. Інтерфейс та Екрани (View Layer)

### 3.1. Структура вкладок (Tabs)
1. **Dashboard (Головна)**
   - У версії **1.0.7**: спрощений набір показників (базові суми продажів та витрат, останні операції, швидкі дії).
   - У цільовій реалізації (1.1.0+): показники за період — Sales, COGS, Opex, Gross/Net Profit.
   - Баланс готівка/картка (операційні залишки).
   - Попередження складу: низькі/негативні залишки.
   - Швидкі дії: Новий продаж, Додати витрату, Перейти до інвентаризації.

2. **Доходи (Sales/POS)**
   - Segmented: **Історія / Новий чек**.
   - Історія: список замовлень за день/період, пошук/фільтри.
   - Новий чек (POS): сітка товарів, швидкі кількості, збереження замовлення.
   - Логіка: при збереженні — фіксуємо Sales, розраховуємо COGS, списуємо склад.

3. **Витрати**
   - Верхній Segmented: **Склад / Витрати**.
   - Склад — внутрішній Segmented:
     - **Залишки**: перелік інгредієнтів з `stockQty`, `avgCost`, бейджі попереджень.
     - **Закупівлі**: журнал `PurchaseModel` з фільтрами за датою/інгредієнтом.
     - **Інвентаризація**: масове коригування залишків з причинами (`InventoryAdjustmentModel`).
  - Витрати (Opex): список витрат та форма додавання (дата, сума, примітка).

4. **Звіти (Reports Hub, з версії 1.1.0+)**
   - P&L (Sales − COGS − Opex = Net Profit).
   - ABC-аналіз: вклад топ-продуктів у виручку/маржу.
   - Динаміка: графіки за періодами (день/тиждень/місяць).
   - Деталізація: перехід у підзвіти з фільтрами та експортом CSV.
   - Reports Hub використовує готові reporting DTO, а не рахує фінанси на рівні UI.

5. **Налаштування (Settings)**
   - Продукти (меню) з рецептами.
   - Інгредієнти (довідник складу).
   - Inventory: `Track Ingredients` (global on/off для автоматичних списань за рецептом).
   - Типи чеків/оплат (Receipt Types).
   - Персонал (опціонально).
   - Загальні: мова, тема, біометрія, onboarding, feedback.

### 3.2. Екрани складського обліку (Inventory)
- **Залишки:** Інгредієнти, поточні залишки та середня ціна.
- **Закупівлі:** Історія приходу товару — `PurchaseModel` (фільтри за датою/інгредієнтом/постачальником).
- **Інвентаризація:** Пакетні коригування (`InventoryAdjustmentModel`), не змінює `averageCost`.

### 3.3. Витрати (Opex)
- Список постійних витрат (оренда, зарплата, комунальні).
- Форма додавання з датою, сумою та приміткою.
- Миттєвий вплив на Net Profit та дашборд.

### 3.4. Продаж (POS)
- Вибір товарів у вигляді сітки.
- `CostingService` рахує собівартість на момент додавання/збереження.
- `InventoryService` списує інгредієнти за рецептом при підтвердженні чеку лише якщо `Track Ingredients = On`.

---

## 4. План міграції

1.  **Settings + Inventory behavior**
    - Додати `Track Ingredients` як глобальне правило автоматичних списань.
    - Зафіксувати, що recipe/composition може редагуватись незалежно від того, увімкнений складський облік чи ні.
2.  **Sales/POS foundations**
    - Довести до кінця фіксацію `totalCost` на рівні `OrderModel`.
    - Зафіксувати `costPrice` на рівні `OrderItemModel`.
    - Перевести всі фінансові залежності на snapshot-логіку замість повторного розрахунку "з поточного рецепта".
3.  **Finance journal + dashboard aggregation**
    - Додати journal-based cash/card accounting та materialized daily balances.
    - Винести period-based метрики з UI у aggregation services.
4.  **Reports**
    - Поверх aggregation services додати reporting facade для `P&L`, `ABC`, `Trends`.
    - Лише після цього реалізувати Reports Hub UI та drill-down screens.
5.  **Inventory audit**
    - Розширити ручні коригування до окремого `InventoryAdjustment` журналу і bulk inventory workflow.

---
*Документ створено: 10.02.2026*
