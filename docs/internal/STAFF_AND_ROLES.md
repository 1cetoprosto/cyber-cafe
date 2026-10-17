# STAFF_AND_ROLES.md — Система персоналу та ролей (v1.2.0)

## 1. Огляд

Система багатокористувацького доступу для кафе. Власник додає співробітників, призначає їм ролі та надсилає запрошення для входу в застосунок. Кожна роль має обмежений набір доступних екранів та дій.

## 2. Ролі

| Роль | Значення | Назва в UI | Доступ |
|---|---|---|---|
| `administrator` | 0 | Власник | Усі таби, усі секції налаштувань (включно з Персоналом, Підпискою) |
| `moderator` | 1 | Менеджер | Усі таби, налаштування без Персоналу та Підписки |
| `waiter` | 2 | Офіціант | Тільки Orders + Settings (тільки Account/logout) |
| `techMod` | 3 | — | Залишено в enum для сумісності зі старими записами БД. **Не показується в UI.** |

> **Важливо:** не змінюйте числові значення існуючих ролей — це зламає дані в Firestore.

## 3. Моделі даних

### 3.1. Employee

Файл: `Data Layer/Models/Employee.swift`

Колекція Firestore: `technicians` (історична назва, **не перейменовувати**).

Ключові поля:
- `firebaseRef` — ID документа
- `firstName`, `lastName`, `middleName` — ПІБ
- `phone`, `email`, `address` — контакти
- `role: Role` — роль співробітника
- `enabled: Bool` — чи активний запис
- `avatarUrl`, `avatarThumbnailUrl` — аватар
- `comment` — примітка

### 3.2. RoleConfig

Колекція Firestore: `roles`.

Пов'язує email співробітника з закладом (`dataRef` = masterUserRef) та роллю. Один email може мати кілька `RoleConfig` для різних закладів.

Поля: `ref`, `email`, `dataRef`, `userRef`, `role`, `onlineVersion`.

### 3.3. OrderModel.createdBy

Поле `createdBy: String?` (employeeRef) додається при створенні замовлення. Використовується для фільтрації замовлень за роллю.

## 4. Потоки

### 4.1. Створення співробітника

1. Власник → Settings → Персонал → Офіціанти/Менеджери → "+"
2. Заповнює форму (ПІБ, email, телефон, адреса, примітка, аватар)
3. `StaffCreateEditViewModel.validate()` — перевіряє firstName, email (required + regex)
4. Перевіряється, що email ще не існує (`getRoles`)
5. Створюється `RoleConfig` + документ `Employee` в одному batch
6. Надсилається email-запрошення через `Auth.auth().sendSignInLink`
7. Співробітник проходить за посиланням, встановлює пароль, входить

### 4.2. Вхід співробітника

1. Співробітник входить через email/password
2. `AuthManager` визначає роль через `RoleConfig` (знаходить `dataRef` = masterUserRef)
3. `UserSession.current.employeeRef` = `firebaseRef` співробітника
4. UI фільтрується за роллю (таби, секції налаштувань)

### 4.3. Редагування співробітника

1. Власник → деталі співробітника → edit
2. Зміна ролі: видаляються старі `RoleConfig`, додається нова
3. Email не редагується після створення (зв'язок з аккаунтом Auth)

### 4.4. Видалення співробітника

1. Власник → деталі → delete
2. `FirestoreDatabaseService.deleteEmployee` — видаляє документ `Employee` + усі `RoleConfig` цього email для даного закладу
3. Логується дія в `RequestManager.shared.log`

### 4.5. Resend invite

1. Власник → деталі → "Надіслати запрошення"
2. `Auth.auth().sendSignInLink(toEmail:actionCodeSettings:)`

## 5. RBAC (Role-Based Access Control)

### 5.1. Фільтрація табів

`MainTabBarController.setupTabBar()`:
- `administrator`, `moderator` → усі 5 табів
- `waiter`, `techMod` → тільки Orders + Settings

### 5.2. Фільтрація секцій налаштувань

`SettingListViewController.configure()`:
- `administrator` → Establishment, Staff, Menu & Inventory, Orders & Appearance, AppInfo/Dev/Account
- `moderator` → Menu & Inventory, Orders & Appearance, AppInfo/Dev/Account
- `waiter`, `techMod` → тільки Account (logout)

### 5.3. Захист екранів

Хелпер `UIViewController.requiresRole(_:)` показує alert "Access Denied" та pop/dismiss, якщо поточна роль не в дозволеному наборі. Застосовано в:
- `CostsTabViewController` (тільки administrator, moderator)
- `ReportsHubViewController` (тільки administrator, moderator)

### 5.4. Фільтрація замовлень

`DomainDatabaseService.fetchOrders()` → `filterByRole(_:)`:
- `waiter` → тільки замовлення з `createdBy == employeeRef` (старі з `nil` приховуються)
- `administrator`, `moderator` → усі замовлення

## 6. Архітектура (MVVM)

### 6.1. Сервіси

- `StaffServiceProtocol` — абстракція доступу до даних персоналу
- `StaffService` — реалізація через `RequestManager` (кеш) + `FirestoreDatabaseService` (записи)

Методи: `employees`, `deleteEmployee`, `getRoles`, `getEmployeeRoles`.

### 6.2. ViewModels

- `StaffListViewModel` — список співробітників (фільтр за роллю, пошук, видалення)
- `StaffDetailsViewModel` — деталі (відображення, delete, resend invite)
- `StaffCreateEditViewModel` — створення/редагування (валідація, збереження, invite)

ViewModels приймають `StaffServiceProtocol` через init (DI для тестування).

### 6.3. ViewControllers

- `StaffCategoriesController` — меню (Власник, Офіціанти, Менеджери)
- `TechniciansListController` — список офіціантів
- `ModeratorListController` — список менеджерів
- `TechnicianDetailsController` — деталі співробітника
- `CreateEditTechnicianController` — форма створення/редагування

> **Примітка:** імена файлів контролерів залишено з `Technician` для мінімізації змін (issue #271 — опціонально). Логіка працює з `Employee`.

## 7. Онбординг

`OnboardingFeature.staff` з `versionTag: "1.2.0"`:
- Показується власнику в налаштуваннях (підсвічує пункт «Персонал»)
- Нічні користувачі бачать усі flow; існуючі — тільки з `versionTag` новішим за їхній last-seen
- Локалізація: `onboardingStaffTitle` / `onboardingStaffMessage` (uk + en)

## 8. Сумісність з БД

- Колекція `technicians` **не перейменовується** (міграція небезпечна)
- `techMod` (role = 3) залишено в enum; фільтри списків (`TechniciansListController`, `ModeratorListController`) включають `techMod` для показу старих записів
- `technician` → `employee` перейменування на рівні Swift-моделі; Firestore-шляхи (`users/{masterRef}/technicians/{id}`) не змінено

## 9. Джерела істини

- Список співробітників → `RequestManager.shared.employees` (кеш з Firestore `technicians`)
- Ролі → `FirestoreDatabaseService.getEmployeeRoles(email)` (фільтр за `dataRef == masterUserRef`)
- Приналежність замовлення → `OrderModel.createdBy`
- Поточна роль → `UserSession.current.role`
