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

### 3.1. Екран "Склад" (Inventory)
*   **Список:** Інгредієнти, їх поточний залишок та середня ціна.
*   **Дії:**
    *   Кнопка "+ Закупівля" -> відкриває форму `PurchaseForm`.
    *   Кнопка "Коригування" -> відкриває форму `AdjustmentForm`.

### 3.2. Екран "Закупівлі" (Purchase History)
*   Замінює поточний екран витрат.
*   Відображає історію `PurchaseModel`.
*   Фільтри по даті та інгредієнту.

### 3.3. Екран "Витрати" (Opex)
*   Окремий екран або вкладка для `OpexExpense`.
*   Список постійних витрат (оренда, інше).
*   Додавання витрати з вибором категорії.

### 3.4. Екран "Продаж" (POS)
*   Вибір товарів.
*   При додаванні товару -> `CostingService` рахує поточну собівартість.
*   При збереженні -> `InventoryService` списує залишки.

---

## 4. План міграції

1.  **Створення нових моделей:** `PurchaseModel`, `OpexExpenseModel`.
2.  **Створення `InventoryService`:** Реалізація математики середньозваженої ціни.
3.  **UI Закупівель:** Створення екрану додавання закупівлі (замість старого екрану Cost).
4.  **UI Витрат:** Створення екрану додавання Opex.
5.  **Міграція Продажів:** Оновлення `OrderViewModel` для роботи з `CostingService` (фіксація COGS).
6.  **Видалення:** Видалення `CostModel` та старого коду екрану витрат.

---
*Документ створено: 10.02.2026*
