# TrackMyCafe (Cyber Cafe)

iOS додаток для обліку доходів та витрат в кафе.

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
- Звіти з графіками та діаграмами
- Синхронізація декількох пристроїв (Firebase Firestore)
- Біометрична автентифікація (Face ID / Touch ID)

## Вимоги

- **iOS**: 15.0+
- **Xcode**: 14.0+
- **Swift**: 5.x
- **CocoaPods**: 1.12+

## Залежності

Основні залежності проєкту:

- **Firebase**:
  - FirebaseAuth — автентифікація користувачів
  - FirebaseFirestore — хмарна база даних
  - FirebaseStorage — зберігання файлів
  - FirebaseFirestoreSwift — Swift розширення для Firestore
- **Realm** — локальна база даних
- **R.swift** — типобезпечні ресурси
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
│   │   └── Realm/        # Realm моделі
│   ├── Service/          # Сервіси зберігання
│   └── Utils/            # Утиліти та константи
├── Services/             # Бізнес-логіка
│   ├── Domain/           # Domain сервіси
│   ├── FIR/              # Firebase сервіси
│   └── Realm/            # Realm сервіси
├── View Layer/           # UI шар
│   ├── Flow/             # Екрани та флоу
│   │   ├── Auth/         # Авторизація
│   │   ├── Home/         # Головний екран
│   │   ├── Orders/       # Замовлення
│   │   ├── Costs/        # Витрати
│   │   ├── Inventory/    # Інвентар
│   │   ├── Settings/     # Налаштування
│   │   └── ...
│   └── UI/               # UI компоненти
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
| `settings.online` | Онлайн/офлайн режим |
| `hasSeenOnboarding` | Чи показувався onboarding |

### Firebase Collections

| Колекція | Опис |
|----------|------|
| `users` | Користувачі |
| `roles` | Ролі та доступи |
| `orders` | Замовлення |
| `productsPrice` | Продукти та ціни |
| `ingredients` | Інгредієнти |
| `purchases` | Закупівлі |
| `opexExpenses` | Операційні витрати |
| `inventoryAdjustments` | Коригування запасів |

## Тестування

Для запуску тестів використовуйте Xcode Test Navigator (Cmd+U).

## Додаткова документація

- [Architecture](architecture.md) — архітектура додатку
- [Conventions](conventions.md) — code style та правила розробки
- [API](api/openapi.yaml) — OpenAPI специфікація

## Ліцензія

Copyright © 2024 Leonid Kvit. All rights reserved.
