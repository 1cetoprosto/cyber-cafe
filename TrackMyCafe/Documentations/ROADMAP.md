# Дорожня карта (Roadmap)

## Роль документа

Це короткий релізний план після `1.0.7`.

- Тут фіксується `що в якій версії випускаємо`.
- Тут не дублюється повна архітектура чи детальний опис модулів.
- За поточним станом продукту дивись `DEV_IMPLEMENTATION_GUIDE.md`.
- За target architecture дивись `ARCHITECTURE_AND_LOGIC.md`.

## База: що вже є в `1.0.7`

- `Home`, `Income`, `Costs`, `Settings` уже в релізі.
- `Products`, `Ingredients`, `Recipes`, `Purchases`, `Stock List`, `Opex`, `POS`, `Order History` уже в релізі.
- Є ручні складські коригування через `InventoryAdjustmentModel`.
- Є базові aggregation services для Home, але ще немає повного `P&L/reporting layer`.
- Немає `Reports Hub`, `Track Ingredients`, journal-based balances, full item-level `COGS snapshot`.

## Принцип черги

Йдемо не від "найбільшої фічі", а від `найбільшої користі для користувача при мінімумі переробок`.

Поточна прийнята стратегія:

1. `cash/card balances`
2. `COGS snapshot`
3. `inventory behavior`
4. `dashboard/reporting foundation`
5. `inventory audit later`

## Рекомендована черга релізів

### `1.0.8` — Cash/Card Balances

- Issue: `#147`
- Дає користувачу відчутну користь на Home одразу.
- Закриває базову довіру до залишків готівки та картки.
- Не змішувати в цей реліз `Reports Hub` або великий inventory workflow.

### `1.0.9` — Full COGS Snapshot

- Issue: `#143`
- Фіксує історичну собівартість на рівні продажу.
- Готує правильний фундамент для майбутнього `P&L`, `ABC`, `Trends`.
- Не змішувати в цей реліз reporting UI.

### `1.1.0` — Inventory Behavior

- Issue: `#156`
- Додає `Track Ingredients` як керовану поведінку системи.
- Відділяє користувачів, яким потрібен складський режим, від тих, кому потрібен тільки фінансовий облік.
- Це вже продуктова фіча, яку легко комунікувати як окрему цінність релізу.

### `1.1.x` або `1.2.0` — Dashboard/Reports Foundation

- Порядок усередині етапу:
  1. `#154`
  2. `#145`
  3. `#146`
- Спочатку centralized aggregation services.
- Потім finance/reporting facade.
- І лише потім `Reports Hub UI`.

### Later — Inventory Audit And Bulk Count

- Issue: `#144`
- Окремий inventory-heavy release.
- Не блокує фінансове ядро.
- Піднімати вище лише якщо inventory counting стає найбільшим реальним болем користувача.

## Залежності між задачами

- `#147` можна робити окремим першим релізом.
- `#143` не залежить від `Reports`, але критично потрібен для майбутнього reporting.
- `#156` не повинен змішуватись зі складним audit workflow.
- `#154` має опиратись на вже зрозумілі sales/opex/balance foundations.
- `#145` залежить від `#154`.
- `#146` залежить від `#145`.
- `#144` не повинен вриватися раніше за фінансовий фундамент без явної бізнес-потреби.

## Чого не робити

- Не випускати `Reports UI` раніше за стабільні reporting DTO.
- Не робити bulk inventory workflow в тому самому релізі, що і financial foundation.
- Не змішувати `Track Ingredients` з journal-based finance в один великий "суперреліз".
- Не дублювати фінансові формули між `Home`, сервісами та майбутніми reports.
