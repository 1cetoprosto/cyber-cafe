# Звіти (Reports Hub)

> **Примітка про версії:**
> Цей документ описує дизайн модулю звітності для версій **після 1.0.0** (орієнтовно, починаючи з лінійки 1.1.0+). У першій публічній версії 1.0.0 Reports Hub та описані нижче P&L/ABC/Trends **ще не реалізовані** й виступають як цільова специфікація.

Цей документ описує склад і логіку основних звітів: P&L, ABC-аналіз, Динаміка. Усі звіти read‑only; історичні значення COGS не перераховуються при майбутніх змінах рецептів.

> **Важливо про межі відповідальності:**
> - aggregation services рахують базові period-based summaries для dashboard;
> - finance/reporting facade будує DTO для звітів поверх цих summaries;
> - Reports Hub UI тільки відображає готові DTO і не містить власних фінансових формул.

---

## 1. P&L (Profit & Loss)
**Мета:** показати прибутковість за період.

**Формули:**
- `Sales = Σ(Orders.totalAmount)`
- `COGS = Σ(Orders.totalCost)`
- `Opex = Σ(OpexExpense.amount)`
- `GrossProfit = Sales − COGS`
- `NetProfit = GrossProfit − Opex`
- `GrossMargin% = GrossProfit / Sales` (якщо Sales > 0)

**Джерела даних:**
- `OrderModel` (header-level totals)
- `OrderItemModel` (item-level snapshot для `salePrice`, `costPrice`, `quantity`)
- OpexExpenseModel

**Фільтри:**
- Період: день / тиждень / місяць / довільний
- За потреби: способи оплати (готівка/картка), але тільки після завершення journal-based finance layer

---

## 2. ABC-аналіз
**Мета:** виділити топ‑продукти за вкладом у виручку та маржу.

> **Передумова:** ABC звіт вважається коректним тільки якщо `OrderItemModel.costPrice` стабільно фіксується на момент продажу.

**Метрики на продукт:**
- `SalesByProduct = Σ( salePrice * qty )`
- `COGSByProduct = Σ( costPrice * qty )`
- `GrossProfitByProduct = SalesByProduct − COGSByProduct`
- `Share% = SalesByProduct / Σ(SalesByAllProducts)`

**Групування:**
- A — ~70–80% виручки
- B — наступні ~15–20%
- C — решта

**Фільтри:** період, категорії меню (за наявності).

---

## 3. Динаміка (Trends)
**Мета:** візуалізація змін у часі.

**Серії:**
- Виручка (Sales)
- Собівартість (COGS)
- Opex
- Чистий прибуток (Net Profit)

**Групування по часу:** день / тиждень / місяць.

**Примітки:**
- Для коректних графіків використовувати однаковий часовий пояс і агрегацію на кінці доби.

---

## 4. Технічні замітки
- Розрахунки для dashboard виконуються в aggregation services (`IncomeAggregationService`, `OpexAggregationService`, `FinanceAggregationService`).
- Розрахунки для `P&L`, `ABC`, `Trends` виконуються у finance/reporting facade поверх aggregation services.
- Дані можуть кешуватись за періодами, але кеш не є окремим source of truth.
- Експорт CSV планується на рівні UI контролера звіту.
