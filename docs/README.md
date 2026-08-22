# TrackMyCafe (Cyber Cafe)

iOS додаток для обліку доходів та витрат в кафе.
Поточний релізний baseline: **v1.1.0** (Reports Hub / P&L / ABC / Trends вже присутні в коді та таббарі).
Ближчі stability/feature-patch релізи: `v1.1.1 → v1.1.2 → v1.1.3 → v1.1.4` (див. `internal/ROADMAP.md`).

## Опис

TrackMyCafe — це мобільний додаток для власників кафе та ресторанів, який дозволяє вести облік фінансів, замовлень, інвентарю та персоналу. Додаток підтримує синхронізацію між декількома пристроями через хмарну базу даних.

### Основні можливості

- Облік витрат на закупівлю матеріалів (кава, цукор, стаканчики тощо)
- Облік витрат на закупівлю послуг (оренда, електроенергія, податки, технічне обслуговування)
- Облік надходжень коштів в розрізі видів надходжень
- Облік результатів діяльності (доходи - витрати)
- Облік продажів з виявленням ходових товарів
- Планування продаж та план-фактний аналіз
- Підтримка світлої та темної тем
- Локалізація (українська, англійська)
- Звіти з графіками та діаграмами (Reports Hub: P&L, ABC-аналіз, Динаміка)
- Dashboard (Home) з Sales/COGS/Opex/Gross/Net метриками за період
- Inventory behavior: глобальний перемикач `Track Ingredients` для автоматичного списання/відновлення складу при продажу/поверненні
- Журнал ручних складських коригувань на основі `InventoryAdjustmentModel`
- Синхронізація декількох пристроїв (Firebase Firestore)
- Біометрична автентифікація (Face ID / Touch ID)

## Вимоги

- **iOS**: 15.0+
- **Xcode**: 14.0+
- **Swift**: 5.x
- **CocoaPods**: 1.12+ (планується міграція R.swift на SPM у v1.1.4)

## Залежності

Основні залежності проєкту:

- **Firebase (v10+)**:
  - FirebaseAuth — автентифікація користувачів
  - FirebaseFirestore — хмарна база даних
  - FirebaseStorage — зберігання файлів
  - FirebaseFirestoreSwift — Swift розширення для Firestore
- **Realm (v10+)** — legacy локальна база (планується повне видалення з продукційних шляхів у v1.1.3)
- **R.swift** — типобезпечні ресурси
- **TinyConstraints** — programmatic Auto Layout (UIKit only, no Storyboards/SwiftUI)
- **SVProgressHUD** — індикатори завантаження
- **KeychainAccess** — безпечне зберігання даних

## Структура проєкту

```
TrackMyCafe/
├── Application/          # Точка входу в додаток
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
├── Configuration/        # Конфігурації для різних середовищ
│   ├── Config.plist
│   ├── TrackMyCafe Dev/
│   ├── TrackMyCafe Beta/
│   └── TrackMyCafe Prod/
├── Data Layer/           # Шар даних
│   ├── Models/           # Моделі даних
│   │   ├── Domain/       # Domain моделі
│   │   ├── Firestore/    # Firebase моделі
│   │   └── Realm/        # Realm моделі (legacy)
│   ├── Service/          # Сервіси зберігання
│   └── Utils/            # Утиліти та константи
├── Services/             # Бізнес-логіка
│   ├── Domain/           # Domain сервіси (aggregation, finance/reporting facade)
│   ├── FIR/              # Firebase сервіси
│   └── Realm/            # Realm сервіси (legacy)
├── View Layer/           # UI шар (UIKit + TinyConstraints, programmatic)
│   ├── Flow/             # Екрани та флоу
│   │   ├── Auth/         # Авторизація
│   │   ├── Home/         # Головний екран / Dashboard
│   │   ├── Orders/       # Замовлення / POS / Історія
│   │   ├── Costs/        # Витрати (Purchases / Opex / Inventory)
│   │   ├── Inventory/    # Інвентар / Закупівлі / Інвентаризація
│   │   ├── Reports/      # Reports Hub / P&L / ABC / Trends (v1.1.0+)
│   │   ├── Settings/     # Налаштування (Track Ingredients, Products, Ingredients)
│   │   └── ...
│   └── UI/               # UI компоненти, Onboarding, PopupFactory
├── Extensions/           # Swift розширення
├── Utilities/            # Допоміжні утиліти
└── Resources/            # Ресурси (Localizable, Assets)
```

## Як запустити

### 1. Клонування репозиторію

```bash
git clone <repository-url>
cd cyber-coffe
```

### 2. Встановлення залежностей

```bash
pod install
```

### 3. Налаштування Firebase

Додаток використовує Firebase для бекенду. Для кожного середовища (Dev, Beta, Prod) потрібен власний `GoogleService-Info.plist`:

1. Створіть проєкт в [Firebase Console](https://console.firebase.google.com/)
2. Додайте iOS додаток для кожного bundle ID:
   - Dev: `com.kvit.trackmycafe.dev`
   - Beta: `com.kvit.trackmycafe.beta`
   - Prod: `com.kvit.trackmycafe`
3. Завантажте `GoogleService-Info.plist` та розмістіть у відповідних папках:
   - `TrackMyCafe/Configuration/TrackMyCafe Dev/`
   - `TrackMyCafe/Configuration/TrackMyCafe Beta/`
   - `TrackMyCafe/Configuration/TrackMyCafe Prod/`

### 4. Збірка та запуск

Відкрийте `Cyber-coffe.xcworkspace` в Xcode та оберіть схему:

- **TrackMyCafe Dev** — для розробки
- **TrackMyCafe Beta** — для тестування
- **TrackMyCafe Prod** — для продакшену

## Конфігурація

### Конфігураційні файли

- `TrackMyCafe/Configuration/Config.plist` — облікові дані для тестових середовищ
- `TrackMyCafe/Configuration/TrackMyCafe */Info.plist` — налаштування для кожного середовища
- `TrackMyCafe/Configuration/TrackMyCafe */GoogleService-Info.plist` — Firebase конфігурація

### Налаштування через UserDefaults

| Ключ | Опис |
|------|------|
| `settings.language` | Мова додатку |
| `settings.theme` | Тема (світла/темна) |
| `settings.online` | Legacy-прапорець; не є цільовою частиною нової архітектури |
| `hasSeenOnboarding` | Чи показувався onboarding |
| `settings.trackIngredients` | Глобальний перемикач автоматичного списання складу за рецептом |

### Firebase Collections

| Колекція | Опис |
|----------|------|
| `users` | Користувачі |
| `roles` | Ролі та доступи |
| `orders` | Замовлення (шапка + totals, з COGS snapshot з v1.0.9+) |
| `orderItems` | Item-level чеку (з salePrice/costPrice замовчуванням з v1.0.9+) |
| `productsPrice` | Продукти та ціни |
| `ingredients` | Інгредієнти (залишки, середня ціна, low-stock thresholds) |
| `recipes` | Рецепти (Products → Ingredients) |
| `purchases` | Закупівлі (поповнення складу, зміна averageCost) |
| `opexExpenses` | Операційні витрати |
| `inventoryAdjustments` | Коригування запасів (manual correction / audit trail) |
| `journalEntries` / `dailyBalances` | (target) Журналізовані залишки cash/card (в розробці / roadmap) |

## Тестування

Для запуску тестів використовуйте Xcode Test Navigator (Cmd+U).

## Додаткова документація

Детальна продуктова/дев-документація лежить у `docs/internal/` та сусідніх підпапках:

- [DEV_IMPLEMENTATION_GUIDE.md](internal/DEV_IMPLEMENTATION_GUIDE.md) — канонічний поточний стан продукту (shipped vs planned), межі модулів, джерела істини.
- [ROADMAP.md](internal/ROADMAP.md) — релізна карта: v1.1.1 → v1.1.2 → v1.1.3 → v1.1.4 після shipped v1.1.0.
- [ARCHITECTURE_AND_LOGIC.md](internal/ARCHITECTURE_AND_LOGIC.md) — цільова архітектура, доменні моделі, сервіси, бізнес-правила.
- [REPORTS.md](internal/REPORTS.md) — специфікація Reports Hub (P&L / ABC / Trends) — вже відповідає shipped стану v1.1.0+.
- [V1_1_IMPLEMENTATION_GUIDE.md](internal/V1_1_IMPLEMENTATION_GUIDE.md) — execution playbook, anti-rework правила, DoR/DoD, release discipline.

## Ліцензія

Copyright © 2024 Leonid Kvit. All rights reserved.
