# Аналіз системи персоналу, ролей та керування лабораторією в DTLab

> Документ описує архітектуру роботи з персоналом, системою ролей (рівнів доступу) та створенням/керуванням лабораторією в iOS-додатку DTLab. Мета — надати переказ патернів, які можна перевикористати в іншому проекті.

---

## 1. Загальна структура домену

Додаток побудований навколо моделі **«лабораторія (Lab)**. Кожна лабораторія має одного **власника (Admin)** та наймає персонал. Усі дані лабораторії ізольовані в окремому вузлі Firebase за ключем `masterUserRef` (власника лабораторії).

Персонал поділений на дві великі групи:

| Група | Опис | Має обліковий запис Firebase Auth |
|---|---|---|
| **Персонал з доступом до додатку** | Адміністратор, Модератор, Технік | Так (вхід через email) |
| **Персонал без доступу (довідник)** | Лікар, Ліпляр (Caster), CAD/CAM | Ні (тільки як категорії в замовленнях) |

Ключова ідея: **роль визначається не моделлю користувача, а окремим записом `RoleConfig`**, який пов'язує email користувача з лабораторією (`dataRef`) та конкретним рівнем доступу (`role`). Один email може мати кілька ролей в одній лабораторії (наприклад, одночасно Технік і Модератор — це роль `techMod`).

---

## 2. Ролі та рівні доступу

Ролі визначені як enum `Role` (Int) у файлі [RoleConfig.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/Data%20Layer/Models/RoleConfig.swift):

| Значення | Роль | Опис |
|---|---|---|
| 0 | `administrator` | Власник лабораторії. Повний доступ. |
| 1 | `moderator` | Модератор. Близько до адміна, але без розділів «Персонал» та «Гроші». |
| 2 | `technician` | Технік. Бачить тільки свої замовлення. |
| 3 | `techMod` | Комбінована роль: Технік + Модератор. |

### 2.1 Комбінована роль `techMod`

Цікава особливість системи: замість того щоб мати окрему «права, користувач може мати два записи `RoleConfig` (для `.technician` та `.moderator`) і в моделі `Technician.role` зберігається `.techMod`. При вході в лабораторію користувач обирає, в якій ролі працювати.

При створенні техніка з правами модератора (або модератора з правами техніка) в таблиці `Roles` створюються **два записи `RoleConfig`.

---

## 3. Моделі даних

### 3.1 `RoleConfig` — прив'язка ролі

Файл: [RoleConfig.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/Data%20Layer/Models/RoleConfig.swift)

Це ключова модель, яка пов'язує користувача з лабораторією:

```
RoleConfig {
  firebaseRef   // ключ запису в таблиці Roles
  email         // email користувача (у нижньому регістрі)
  dataRef       // ID лабораторії (власника) — masterUserRef
  userRef       // ID запису користувача в таблиці Users
  role          // Role (0-3)
  timestamp
}
```

**Призначення:**
- `dataRef` — вказує, до якої лабораторії належить ця роль.
- `userRef` — вказує на персональний вузол користувача в `Users` (для особистих налаштувань).
- Один email → кілька `RoleConfig` → кілька ролей в одній/різних лабораторіях.

### 3.2 `Admin` — профіль власника лабораторії

Файл: [Admin.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/Data%20Layer/Models/Admin.swift)

Поля: `firstName`, `lastName`, `middleName`, `email`, `phone`, `address`, `comment`, `avatarUrl`, `avatarThumbnailUrl`.

Особливість: `Admin` **не має власної колекції** — дані зберігаються прямо у вузлі `Users/<masterUserRef> (тобто в кореневому вузлі лабораторії). `RequestManager.admin` завантажується з `mainRef`.

### 3.3 `Technician` — технік/модератор

Файл: [Technician.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/Data%20Layer/Models/Technician.swift)

Наслідує `BaseDatabaseModel`. Ключові поля:
- `role: Role` — роль техніка в цій лабораторії (`.technician`, `.moderator`, `.techMod`).
- `enabled: Bool` — м'яке видалення.
- `isAllowedCalculationsForAdministrator: Bool` — дозвіл брати участь в розрахунках для адміна (обмежений доступ до фінансів).
- Стандартні: ПІБ, контакти, аватар.

### 3.4 `Doctor`, `Caster`, `CadCam` — довідниковий персонал

- [Doctor.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/Data%20Layer/Models/Doctor.swift) — клієнти лабораторії (лікарі). Мають `ordersCount`, `order` (сортування).
- [Caster.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/Data%20Layer/Models/Caster.swift) — ліпляр. Має `isDefault` (ліпляр за замовчуванням для замовлень).
- [CadCam.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/Data%20Layer/Models/CadCam.swift) — CAD/CAM система. Має `title` замість ПІБ, `isDefault`.

Ці моделі **не мають ролей** і не можуть входити в додаток.

### 3.5 `Settings` — налаштування лабораторії

Файл: [Settings.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/Data%20Layer/Models/Settings.swift)

Поля: валюта (`currencyName`, `currencySymbol`, `currencyCode`, `supportedCurrencies`), логотип (`imageUrl`, `imageThumbnailUrl`), `universalComment`, `isAllowed` (зарезервовано).

### 3.6 `UserSession` — поточна сесія

Файл: [UserSession.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/Data%20Layer/Utils/UserSession.swift)

Singleton, зберігає контекст поточного користувача:
- `userId`, `userEmail`, `role: Role`, `userRef`, `dataRef` (лабораторія), `masterUserRef`.
- `techRef` — для ролі техніка повертає `firebaseRef` техніка в поточній лабораторії.
- Зберігається в Keychain (з опцією «Запам'ятати мене»).
- `isAdmin`, `isModerator` — допоміжні властивості.

---

## 4. Структура бази даних (Firebase Realtime Database)

Вузли (enum `Refs` у [Constants.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/Data%20Layer/Utils/Constants.swift)):

```
/
├── Users/
│   └── <masterUserRef>/          ← корінь лабораторії (власник)
│       ├── Doctors/
│       ├── Technicians/
│       ├── CadCams/
│       ├── Casters/
│       ├── MainElements/
│       ├── ExtraElements/
│       ├── ElementTypes/
│       ├── Orders/
│       ├── Settings/
│       ├── Subscription/
│       ├── Logs/
│       ├── Comments/
│       └── (поля Admin: firstName, email, ...)
│
└── Roles/                         ← глобальна таблиця ролей
    └── <roleRef>/
        ├── email
        ├── dataRef               ← masterUserRef (якій лабораторії)
        ├── userRef               ← вузол користувача в Users
        ├── role                  ← 0-3
        └── timestamp
```

**Принцип ізоляції:** усі дані лабораторії лежать під `Users/<masterUserRef>`. `Roles` — глобальна таблиця, яка шукається за email і дозволяє користувачу знайти свої лабораторії.

---

## 5. Створення лабораторії

Файл: [AuthManager.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/View%20Layer/Flow/Auth/AuthManager.swift), метод `createNewLab`.

### Кроки:
1. Користувач реєструється через Firebase Auth (`signUp`).
2. `createUserOrLogin` шукає `RoleConfig` за email.
3. Якщо ролей немає — створюється **нова лабораторія**:
   - Генерується `userKey` (ID власника).
   - Створюється запис `RoleConfig` з роллю `.administrator`, `dataRef = userKey`, `userRef = userKey`.
   - Створюється вузол `Users/<userKey>` з профілем адміна, дефолтними `ElementTypes` (вінір, протез, металокераміка) та `Settings` (валюта Dollar/$).
4. Створюється сесія, запускаються слухачі Firebase.

```swift
private func createNewLab(_ id: String, _ email: String, ...) {
    let role = RoleConfig(ref: roleKey, email: email, dataRef: userKey, userRef: userKey, role: .administrator)
    // updateNodes:
    //   Users/<userKey> = userData (admin profile + ElementTypes + Settings
    //   Roles/<roleKey> = role.forDatabase()
}
```

---

## 6. Створення персоналу з доступом (Технік/Модератор)

Файл: [CreateEditTechnicianController.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/View%20Layer/Flow/Staff/Technician/CreateEditTechnicianController.swift).

### Валідація:
- Обов'язкові: `firstName`, `email` (валідний regex).
- Email не повинен бути вільним (перевіряється через `DatabaseService.getRoles`).

### Кроки створення:
1. Адмін заповнює форму (ПІБ, контакти, роль, перемикач прав).
2. При збереженні:
   - Якщо обрано роль `.technician` → створюється `RoleConfig(role: .technician).
   - Якщо обрано `.moderator` → створюється `RoleConfig(role: .moderator).
   - Якщо обрано `techMod` → створюються **обидва `RoleConfig`.
   - Усі `RoleConfig` мають `dataRef = masterUserRef` (поточна лабораторія), `userRef` — новий ключ в `Users`).
   - Створюється запис `Technician` в `Users/<masterUserRef>/Technicians/<techKey>`.
3. Надсилається **email-запрошення`Auth.auth().sendSignInLink(toEmail:)` (passwordless вхід).
4. Логується дія в `Logs`.

```swift
// Успішно створено → sendInviteEmail() надсилає лінк для входу.
```

### Важливо:
- Привітання з паролем (magic link). Пароль не встановлюється.
- Обмеження кількості персоналу: `staffCount >= IAPManager.shared.currentSubscription.staffCount` — при перевищенні пропонується змінити підписку.

---

## 7. Редагування персоналу

При редагуванні техніка можна змінити роль. Логіка синхронізації ролей (метод `saveTechnicianToDatabase`):

1. Завантажуються поточні `RoleConfig` техніка для цієї лабораторії (`getTechRoles`).
2. Обчислюється різниця:
   - **Видаляються ролі, які більше не потрібні (наприклад, була `.technician`, стала `.moderator`).
   - **Додаються ролі, яких не вистачає (наприклад, для `techMod` додається друга роль).
3. Оновлюється запис `Technician`.
4. Усі зміни застосовуються через один батч `updateChildValues`.

Поле `email` **не редагується** після створення (`isEditing: false`).

---

## 8. Видалення персоналу

Файл: [DatabaseService.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/Data%20Layer/Service/DatabaseService.swift), метод `deleteTechnician`.

- **М'яке видалення:** `Technician.enabled = false`.
- Видаляються усі `RoleConfig` техніка для цієї лабораторії.
- Обліковий запис Firebase Auth не видаляється (користувач може бути в інших лабораторіях).

---

## 9. Курування ролями (рівні доступу)

### 9.1 Меню (розділи)

Файл: [MenuSection.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/View%20Layer/Flow/Menu/MenuSection.swift).

Набір розділів залежить від ролі:

| Розділ | Admin | Moderator/TechMod | Technician |
|---|---|---|---|
| Замовлення | ✅ | ✅ | ✅ |
| Календар | ✅ | ✅ | ✅ |
| Нотатки | ✅ | ✅ | ✅ |
| Лікарі | ✅ | ✅ | ❌ |
| Персонал | ✅ | ❌ | ❌ |
| Гроші | ✅ | ❌ | ✅ (тільки свої) |
| Статистика | ✅ | ✅ | ❌ |
| Налаштування | ✅ (всі) | ✅ (тільки безпека) | ✅ (тільки безпека) |
| Посилання | ✅ | ✅ | ✅ |

### 9.2 Налаштування

Файл: [SettingsSectionCell.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/View%20Layer/Flow/Settings/SettingsController.swift).

- Адмін бачить усі розділи (протези, надбудови, типи, безпека, валюта, тема, підписка, друк).
- Персонал бачить тільки «Безпека».

### 9.3 Фільтрація замовлень

Файл: [OrdersBaseController.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/View%20Layer/Flow/Order/Base/OrdersBaseController.swift).

```swift
if UserSession.current.role == .technician {
    orders = orders.filter { $0.technician == UserSession.current.techRef }
}
```

Технік бачить тільки замовлення, призначені йому.

### 9.4 `isAllowedCalculationsForAdministrator

Особливий прапорець на техніці: якщо увімкнено, технік з'являється в списку для розрахунків адміна (борги техніка, [AccountingController.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/View%20Layer/Flow/Accounting/AccountingController.swift)).

### 9.5 Вибір ролі при вході

Якщо email має кілька ролей в лабораторії, при вході показується діалог вибору ролі (`AuthModelAction.chooseRole`). Адмінська роль виключається зі списку вибору (братимуться перша не-адмін роль).

---

## 10. Обмеження за підпискою

Файл: [Subscription.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/Data%20Layer/Models/Subscription.swift).

- `IAPManager.shared.currentSubscription.staffCount` — максимальна кількість активного персоналу (`enabled == true`).
- При досягненні ліміту показується попап з пропозицією змінити тариф.
- Ліміт діє і на техніків, і на модераторів.

---

## 11. Аудит дій

Файл: [RequestManager.swift](file:///Users/leonidkvit/Documents/Swift/Projekts/Freelance/dtlab-ios/DTLab/Data%20Layer/Utils/RequestManager.swift), метод `log`.

Кожна дія з персоналом (створення, редагування, видалення, зміна аватара) логується в `Users/<masterUserRef>/Logs/`:

```
Log {
  timestamp, object (Refs), action (add/update/delete/system),
  description, firebaseRef, objectRef
}
```

---

## 12. Загальний потік взаємодії (діаграма)

```
Реєстрація нового користувача
        │
        ▼
Firebase Auth (signUp)
        │
        ▼
Пошук RoleConfig за email
        │
   ┌────┴────────────────────┐
   │                     │
Ролей немає          Ролі є
   │                     │
   ▼                     ▼
Створення нової      Перевірка dataRef   користувач існує?
лабораторії                │
(Admin + Settings +         ├─ Ні → створення вузла Users
 дефолтні елементи)         └─ Так → вибір ролі (якщо кілька)
   │                     │
   └─────────┬───────────┘
             ▼
      UserSession.createSession
             │
             ▼
      RequestManager.startListening
      (слухачі Firebase для лабораторії)
```

```
Додавання техніка адміном:
  Форма → валідація → getRoles(email)
       → створення RoleConfig(s)
       → створення Technician в Users/<lab>/Technicians
       → sendSignInLink (email-запрошення)
       → Log
```

---

## 13. Недоліки та варіанти покращення

### 🔴 Серйозні:

1. **Відсутність правил безпеки на рівні Firebase Rules.
   Усі доступи контролюються лише на клієнті. Хакер може змінити роль в `Roles` або отримати доступ до чужої лабораторії. Потрібні Firestore/Firebase Rules з перевіркою `dataRef == auth.uid` або спеціальних кастомних claims.

2. **`RoleConfig` і `Technician.role` дублюють інформацію.**
   Роль зберігається і в глобальній таблиці `Roles`, і в локальній моделі `Technician.role`. Це може призвести до невідповідності. Варто залишити одне джерело істини (краще — `Roles`).

3. **Жорстко зашиті назви ролей.**
   Enum `Role` не можна розширити без зміни коду. Для гнучкості можна винести ролі та їхні права в конфігурацію.

4. **Email не можна змінити.**
   Якщо технік змінив email — потрібно видаляти й створювати заново.

5. **Немає механізму видалення облікового запису Firebase Auth.**
   Видалений технік залишає «осірий аккаунт в Firebase.

6. **`Settings.isAllowed` не використовується.**
   Поле існує в моделі, але жодного перевірки в коді немає. Схоже, зарезервовано для майбутнього.

### 🟡 Середні:

7. **Логіна парольного входу (magic link) без пароля.**
   Зручно, але якщо email не відкривається в іншому пристрої — вимагає підтвердження. Немає можливості встановити пароль.

8. **Немає групування прав за дозволами.**
   Доступ керується через роллю, а не через набір permission. Для масштабування краще використати RBAC з правами (наприклад, `canManageStaff`, `canViewMoney`).

9. **Дублікати email не перевіряються в межах лабораторії.**
   Перевірка `getRoles` глобальна, але можна створити техніка з email, який вже є в цій лабораторії в іншої ролі.

10. **Обмеження `staffCount` рахує усі техніків, але не лікарем/ліплярів.**
    Якщо ліміт — для «персоналу, то чому тільки техніки? Логіка непослідовна.

### 🟢 Дрібні:

11. **`Admin` не наслідує `BaseDatabaseModel`** — незгідно з іншими моделями.
12. **Велика кількість `String`-копіювань коду** між `CreateEditTechnicianController`, `CreateEditCasterController`, `CreateEditDoctorController`. Можна винести в базовий клас або протокол.
13. **`UserSession.role` — implicity unwrapped optional.** Краще використати `guard` або optional.

---

## 14. Рекомендації для перевикористання в іншому проекті

Щоб перенести цей підхід:

1. **Залиште модель «лабораторія (тенант) як корінь даних** ізоляції. Усі дані під `Tenant/<id>/`.
2. **Використовуйте окрему таблицю `Members` (Roles)`** для прив'язки користувача до тенанта з роллю. Один користувач → кілька тенантів.
3. **Для персоналу з доступом** створюйте запис у глобальній таблиці ролей + локальний профіль у тенанті.
4. **Для довідкового персоналу** — тільки локальний профіль у тенанті без ролей.
5. **Запрошення через email-link** — зручний безпарольний вхід для персоналу.
6. **М'яке видалення** через `enabled: false`.
7. **Рольові меню/налаштування** через enum з мапами `Role → [Section]`.
8. **Аудит дій** в окремій колекції логів.
9. **Обмеження за підпискою** — ліміт активного персоналу.
10. **Обов'язково додайте серверні правила безпеки** (Firebase Rules або backend), оскільки клієнтські перевірки недостатні.
