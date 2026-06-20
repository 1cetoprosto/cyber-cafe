# Release Strategy And Execution Rules

## Роль документа

Це не ще один `architecture spec` і не ще один `feature guide`.

Цей файл потрібен для того, щоб:

- рухатись по релізах без переробок;
- не змішувати в одній задачі кілька відповідальностей;
- тримати дисципліну solo development.

За поточним станом продукту дивись `DEV_IMPLEMENTATION_GUIDE.md`.
За target architecture дивись `ARCHITECTURE_AND_LOGIC.md`.
За коротким релізним планом дивись `ROADMAP.md`.

## Базова стратегія після `1.0.7`

Прийнята черга така:

1. `#147` — cash/card balances
2. `#143` — full COGS snapshot
3. `#156` — inventory behavior (`Track Ingredients`)
4. `#154` — centralized aggregation services
5. `#145` — finance/reporting facade
6. `#146` — Reports Hub UI
7. `#144` — inventory audit / bulk count later

Логіка цієї черги:

- спочатку даємо користувачу довіру до грошей;
- потім даємо довіру до собівартості;
- потім вмикаємо керовану поведінку складу;
- тільки після цього добудовуємо shared analytics/reporting layer;
- inventory-heavy workflow тримаємо окремо, щоб він не з'їв темп.

## Що з чим не змішувати

- `#147` не змішувати з `Reports Hub`.
- `#143` не змішувати з reporting UI.
- `#156` не змішувати з bulk inventory workflow.
- `#154` не змішувати з report-specific DTO.
- `#145` не змішувати з UI-розрахунками.
- `#144` не змішувати з finance foundation, якщо inventory не є головним user pain.

## Anti-Rework Rules

### 1. Не будувати UI раніше за контракти

Перед складним UI мають бути зафіксовані:

- domain model;
- service protocol;
- output DTO;
- period/filter contract.

### 2. Не дублювати фінансові формули

Якщо метрика вже рахується в сервісі, її не треба рахувати ще раз:

- у `ViewModel`;
- у `ViewController`;
- у `Reports Hub`;
- у тимчасових helper-ах.

### 3. Історичні факти мають бути стабільними

- `COGS` не можна перераховувати заднім числом з поточного рецепта.
- balances не можна збирати "на льоту" зі всіх моделей без явного journal/source of truth.
- inventory adjustment не повинен змінювати `averageCost`.

### 4. Кожна зона має одного owner

- inventory behavior -> settings + inventory-aware services
- historical COGS -> order snapshot
- balances -> journal + daily balances
- dashboard metrics -> aggregation services
- reports DTO -> finance/reporting facade
- reports screens -> UI layer

## Working Pattern For Solo Dev

### WIP Limit

- `WIP = 1`
- одна велика задача за раз
- максимум одна дрібна технічна підзадача паралельно

### Внутрішня послідовність по issue

1. `Contract`
2. `Domain`
3. `Persistence`
4. `Service`
5. `ViewModel`
6. `UI`
7. `Validation`
8. `Cleanup`

### Definition Of Ready

Issue готовий до старту, якщо:

- зрозуміло джерело істини;
- зрозумілі залежності;
- зрозуміло, чи потрібна міграція;
- зрозуміло, які екрани зачіпаються;
- є короткий manual QA plan.

### Definition Of Done

Issue завершений, якщо:

- дані зберігаються консистентно;
- сервісний контракт стабільний;
- UI не дублює бізнес-логіку;
- базові ручні сценарії перевірені;
- не лишилось "тимчасової" логіки, яку треба буде потім виносити.

## Чекліст перед стартом задачі

### Domain

- які моделі змінюються;
- які поля додаються;
- які інваріанти не можна порушити.

### Storage

- що є source of truth;
- чи потрібен backfill;
- чи потрібні індекси;
- чи не з'являється нова залежність від Realm там, де її не повинно бути.

### Services

- хто owner логіки;
- який протокол потрібен для DI;
- які async methods потрібні;
- які DTO повертаються назовні.

### UI

- чи UI тільки відображає готові дані;
- які empty/loading/error стани потрібні;
- які цифри повинні збігатися з Home або source lists.

## Найтиповіші ризики

### Duplicate Financial Logic

Виникає, коли `Home`, `Reports` і helpers рахують схожі метрики по-різному.

Як уникнути:

- завершити `#154` раніше за `#145` і `#146`;
- не переносити формули в `ViewModel`.

### Unstable Historical Numbers

Виникає, коли `COGS` не збережений як snapshot, а balances не мають явного journal.

Як уникнути:

- `#143` перед reporting;
- `#147` перед розширеними balances/report filters.

### Inventory Scope Explosion

Виникає, коли audit/bulk inventory починається раніше, ніж закрито фінансовий фундамент.

Як уникнути:

- тримати `#144` окремим later-stage release.

## Короткий висновок

Для одного розробника найкраще працює така дисципліна:

- кожен реліз дає одну чітку користь користувачу;
- кожен наступний шар спирається на вже стабілізований попередній;
- усе, що не дає користі одразу і не блокує ядро, переноситься з релізу далі.
