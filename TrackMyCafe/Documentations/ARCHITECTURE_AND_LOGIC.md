# Архітектура та Логіка TrackMyCafe (MVP 2.0)

Цей документ описує технічну реалізацію бізнес-логіки, структуру даних та взаємодію компонентів для версії MVP з автоматичним розрахунком собівартості.

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
    let categoryId: String   // Зв'язок з категорією витрат (OpexCategory)
    let amount: Double       // Сума витрати
    let note: String?        // Коментар
}

struct OpexCategoryModel: Identifiable, Codable {
    let id: String
    let name: String         // Назва (Оренда, Інтернет...)
    let iconName: String?    // Для UI
}
```

### 1.3. Продаж (Sale) / Замовлення (Order)
Фіксує факт продажу та списання собівартості.
**Вплив:** Зменшує `Ingredient.stockQuantity`, збільшує `Revenue`.

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
        1.  Для кожного товару знайти його рецепт (`RecipeItem`).
        2.  Для кожного інгредієнта рецепту списати кількість: `stockQty -= item.qty * recipe.qty`.
*   `validateStock(for items: [OrderItemModel]) -> [StockWarning]`
    *   Перевіряє, чи не піде склад в мінус (для відображення попереджень).

### 2.2. CostingService (Розрахунок вартості)
Відповідає за калькуляцію.

**Методи:**
*   `calculateProductCost(productId: String) -> Double`
    *   Сумує `ingredient.avgCost * recipe.qty` для всіх компонентів.
*   `calculateOrderMetrics(items: [OrderItemModel]) -> (totalSale: Double, totalCost: Double)`
    *   Використовується при створенні замовлення для фіксації COGS.

### 2.3. FinanceService (Фінанси)
Агрегує дані для дашборду.

**Методи:**
*   `getMetrics(from: Date, to: Date) -> FinanceMetrics`
    *   `Sales = sum(Orders.totalAmount)`
    *   `COGS = sum(Orders.totalCost)`
    *   `Opex = sum(OpexExpense.amount)`
    *   `GrossProfit = Sales - COGS`
    *   `NetProfit = GrossProfit - Opex`

---

## 3. Інтерфейс та Екрани (View Layer)

### 3.1. Структура вкладок (Tabs)
1. **Dashboard (Головна)**
   - Показники за період: Sales, COGS, Opex, Gross/Net Profit.
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
   - Витрати (Opex): список витрат та форма додавання (категорія, дата, сума, примітка).

4. **Звіти (Reports Hub)**
   - P&L (Sales − COGS − Opex = Net Profit).
   - ABC-аналіз: вклад топ-продуктів у виручку/маржу.
   - Динаміка: графіки за періодами (день/тиждень/місяць).
   - Деталізація: перехід у підзвіти з фільтрами та експортом CSV.

5. **Налаштування (Settings)**
   - Продукти (меню) з рецептами.
   - Інгредієнти (довідник складу).
   - Типи чеків/оплат (Receipt Types).
   - Персонал (опціонально).
   - Загальні: мова, тема, біометрія, onboarding, feedback.

### 3.2. Екрани складського обліку (Inventory)
- **Залишки:** Інгредієнти, поточні залишки та середня ціна.
- **Закупівлі:** Історія приходу товару — `PurchaseModel` (фільтри за датою/інгредієнтом/постачальником).
- **Інвентаризація:** Пакетні коригування (`InventoryAdjustmentModel`), не змінює `averageCost`.

### 3.3. Витрати (Opex)
- Список постійних витрат (оренда, зарплата, комунальні).
- Форма додавання з категорією та датою.
- Миттєвий вплив на Net Profit та дашборд.

### 3.4. Продаж (POS)
- Вибір товарів у вигляді сітки.
- `CostingService` рахує собівартість на момент додавання/збереження.
- `InventoryService` списує інгредієнти за рецептом при підтвердженні чеку.

---

## 4. План міграції

1.  **Вкладка “Витрати” (Склад + Opex):**
    - Інтегрувати `StockList` в нову вкладку.
    - Перенести `PurchaseList` під “Склад → Закупівлі”.
    - Додати режим “Інвентаризація”.
2.  **Доходи (Sales/POS):**
    - Зібрати екран POS (“Новий чек”), переробити історію під періоди.
3.  **Звіти (Reports Hub):**
    - Реалізувати P&L, ABC, Динаміку на окремих під-екранах.
4.  **Dashboard:**
    - Додати баланс готівка/картка та ключові метрики.
5.  **Settings:**
    - Актуалізувати меню, рецепти, інгредієнти, типи оплат; підготовка до Staff.

---
*Документ створено: 10.02.2026*
