# v1.1.4 — UI Polish & Consistency — Execution Plan

> **Milestone:** [Release v1.1.4](https://github.com/1cetoprosto/cyber-cafe/milestone/13)
> **Date created:** 2026-10-12
> **Status:** In Progress (1/4 issues complete)
> **Type:** Refactor / UI Polish — no external behavior changes

---

## Як використовувати цей файл (новий діалог)

В новому діалозі просто скажи:
- **"Реалізуй етап 1"** — асистент прочитає цей файл, знайде секцію «Етап 1» і виконає її.
- **"Реалізуй етап 2"** — наступний етап, і т.д.
- Або назвати по issue: **"Зроби #127"**.

Асистент ОБОВ'ЯЗКОВО повинен:
1. Прочитати цей файл повністю перед початком.
2. Прочитати відповідну секцію етапу.
3. Слідувати правилам проєкту (`AGENTS.md`, `.trae/rules/project_rules.md`).
4. Після завершення — вказати у відповіді, що етап готовий і який наступний.
5. Оновити поле «Прогрес» внизу цього файлу.

---

## Порядок виконання (залежності)

```
Етап 1 (#127)  →  Етап 2 (#100)  →  Етап 3 (#173)  →  Етап 4 (#164)
InputPopupView     Rewrite alerts     secondaryText      R.swift → SPM
(фундамент)        (використовує      (незалежний UI      (опціонально,
                    showInputPopup)     polish)             тех-борг)
```

**Чому в такому порядку:**
1. **#127 першим** — створює `InputPopupView` + `showInputPopup`, без чого неможливо замінити input-алерти в #100.
2. **#100 другим** — переписує всі алерти (включно з input, які тепер йдуть через `showInputPopup` з Етапу 1). Це найбільший за обсягом етап.
3. **#173 третім** — повністю незалежний UI-polish (кольори вторинного тексту). Робиться після #100, щоб не конфліктувати зі змінами у попапах.
4. **#164 останнім** — опціональна міграція R.swift на SPM (технічний борг). Ізольована зміна інфраструктури, робиться окремим PR після замикання #127/#100/#173. Якщо немає часу/ризику — можна пропустити.

---

## Поточний стан коду (інвентаризація на 2026-10-12)

### PopupFactory (`View Layer/UI/Popup/PopupFactory.swift`)

Існуючі статичні методи:
- `presentAttributes` — налаштування SwiftEntryKit (центр, float, фон .systemBackground).
- `showOrderModePopup(selectPerOrder:selectOpenTab:)` — кастомний `OrderModePopupView`.
- `showChooseRoleAlert(_:completion:)` — через `EKAlertMessageView` (список ролей).
- `showPopup(title:description:buttonAction:)` — один алерт з OK.
- `showPopup(title:description:buttonTitle:buttonAction:)` — алерт з Cancel + action.
- `showDestructivePopup(title:description:buttonTitle:buttonAction:)` — алерт з деструктивною кнопкою.

**Відсутнє:**
- Метод для вводу тексту (`showInputPopup`).
- Метод для actionSheet (вибір опцій).
- Закоментований `showEditPricePopup` згаданого в issue **не знайдено** (видалено раніше).

### UIAlertController — де ще використовується (18 swift-файлів)

**Хелпери/розширення:**
- `Extensions/UI/UIViewController+AlertLanguage.swift` — `alertLanguage` (actionSheet: мова), `alertTheme` (actionSheet: тема).
- `Extensions/UI/UIViewController+Extension.swift` — `showAlert` x2, `showWarning`, `askConfirmOperation`, `topMostViewController`.
- `Staff/View/Technician/TechnicianDetailsController.swift` — глобальні дублікати `showAlert`/`showWarning` (видалити).

**Пряме використання (файл → функція → тип):**
- `Orders/OrderDetails/View/OrderDetailsViewController.swift` — `verifyRequiredData` (OK), `handleSaveError` x2 (OK), `showStockWarning` (Cancel/Proceed).
- `Orders/OrderDetails/View/OrderReceiptPadViewController.swift` — `handleSaveError` x2 (OK), `showStockWarning` (Cancel/Proceed).
- `Flow/MainTabBarController.swift` — `handleDemoDataDelete` (Cancel/Delete).
- `Auth/SignIn/Controller/SignInController.swift` — `.retry` (Cancel/Retry), `showConfirmEmail` (**input: email**).
- `Auth/SignUp/SignUpController.swift` — `.retry` (Cancel/Retry).
- `Home/View/HomeViewController.swift` — `confirmDeleteDemoData` (Cancel/Delete).
- `Inventory/StockList/View/StockListViewController.swift` — `showAdjustmentAlert` (**input: 2 поля** — кількість decimalPad + причина).
- `ManualMovements/List/ManualMovementListViewController.swift` — `showError` (OK).
- `Purchase/PurchaseList/View/PurchaseListViewController.swift` — `filterButtonTapped` (actionSheet: фільтри), `presentIngredientFilter` (actionSheet: інградієнти).
- `Settings/Ingredients/View/CreateIngredientViewController.swift` — `saveAction` x3 (OK, валідація).
- `Settings/ProductCategories/ProductCategoryDetailsViewController.swift` — `imageTapped` (actionSheet: Gallery/Delete/Cancel).
- `Settings/Products/ProductDetail/View/ProductDetailsViewController.swift` — `imageTapped` (actionSheet), `categoryTapped` (actionSheet), `addIngredientAction` x2 (OK + actionSheet), `showQuantityInput` (**input: кількість**), `overwriteAlert` (Yes/No).
- `Settings/Products/ProductList/View/ProductListViewController.swift` — `showSortOptions` (actionSheet: A–Z/Z–A).
- `Settings/SettingList/View/SettingListViewController.swift` — `presentTrackIngredientsEnableConfirmation` (Cancel/Enable), `presentTrackIngredientsLockedAlertAndRollbackSwitch` (OK), reset onboarding (OK), seed test data (**input: кількість днів**), `showErrorAlert` (OK), `showSuccessAlert` (OK), `confirmDeleteDemoData` (Cancel/Delete), `confirmDeleteAllData` (Cancel/Delete).
- `View Layer/UI/ImagePicker.swift` — `showPickerOptions` (actionSheet, **закоментовано**), `showAlert` (Settings/Cancel).

**Алерти з текстовими полями (input):** `SignInController.showConfirmEmail`, `StockListViewController.showAdjustmentAlert` (2 поля), `ProductDetailsViewController.showQuantityInput`, `SettingListViewController` seed test data.

### Кольори вторинного тексту (#173)

`UIColor.Main.secondaryText` = `Theme.current.secondaryText` — існує і коректно працює в усіх 3 палітрах (Standard / Alt / CoffeeWithMilk), див. `Theme.swift`.
Еталон правильного використання: `SubscriptionBannerView` — `titleLabel` = `.Main.text`, `descriptionLabel`/`termsLabel` = `.Main.secondaryText`.

**Де вторинний контент ще використовує основний колір (потрібна заміна на `.Main.secondaryText`):**
1. `View Layer/UI/Base/InputContainerView.swift` — `titleLabel.textColor` (базовий компонент полів вводу, використовується скрізь).
2. `View Layer/UI/Base/BaseListTableViewCell.swift` — `detailTextLabel?.textColor` (системний сабтайтл клітинки).
3. `Flow/Costs/CostDetails/View/CostDetailsListViewController.swift` — `paymentMethodLabel.textColor`.
4. `Flow/Purchase/CreatePurchase/View/CreatePurchaseViewController.swift` — `titleLabel.textColor` (підпис "Payment Method").
5. `Flow/ManualMovements/Edit/ManualMovementEditViewController.swift` — `configureTitleLabel` (`label.textColor`).
6. `Flow/Staff/View/Technician/CreateEditTechnicianController.swift` — `makeField`/`makeTextViewField`/`makeSwitch` → `titleLabel.textColor`.
7. `Flow/Orders/OrderDetails/View/OrderReceiptPadViewController.swift` — `OrderCompactFieldView.titleLabel.textColor`.
8. `Flow/Inventory/Sessions/View/Cells/InventorySessionCell.swift` — `noteLabel.textColor`.
9. `Flow/Settings/Subscription/Views/Cells/SubscriptionCell.swift` — `infoLabel` (за замовчанням `.Main.text`, не перевизначено).
10. `Flow/Settings/Subscription/Views/Cells/SubscriptionTextCell.swift` — `textLabel?.textColor`.
11. `Extensions/UI/UILabel+Extension.swift` — `convenience init(text:font:aligment:)` → `.black` (не використовується, але видалити/виправити).

### R.swift (#164)

- Підключено через CocoaPods: `pod 'R.swift'` у 3 таргетах (Beta, Dev, Prod) — `Podfile`.
- `R.generated.swift` генерується в корені проєкту через run script build phase (налаштований у project.pbxproj).
- Усі звернення — через `R.string.global.*` (локалізація), `R.image.*` тощо.

---

# ЕТАП 1 — #127: InputPopupView для PopupFactory (заміна input UIAlertController)

**Issue:** https://github.com/1cetoprosto/cyber-cafe/issues/127
**Пріоритет:** low
**Мета:** створити кастомний попап для вводу тексту та підключити його до `PopupFactory`; замінити input-алерти `UIAlertController`.

> `AnimatedTextInput` у коді **не існує** (лише в `docs/engineering/AnaliseCodeBase.md`). Використовувати звичайний `UITextField` у поєднанні зі стилізованим контейнером (аналогічно `InputContainerView`).

## Дії

### 1.1 Створити `InputPopupView`
Файл: `TrackMyCafe/View Layer/UI/Popup/InputPopupView.swift` (новий).

Структура `UIView`:
- `titleLabel` (AppLabel, `.Main.text`, центрований).
- `descriptionLabel` (AppLabel, `.Main.secondaryText`, numberOfLines = 0, центрований).
- Контейнер з `UITextField`(ами):
  - фон `UIColor.Main.secondaryBackground`, cornerRadius.
  - колір тексту `.Main.text`, placeholder `.Main.secondaryText`.
  - підтримка `keyboardType` та `initialText`.
- Кнопки `Cancel` (`.systemBlue`) / `Save` (`.systemBlue`, bold) або деструктивний колір за потреби.
- Вертикальний `UIStackView`, відступи TinyConstraints.

**Рішення щодо кількості полів:** зробити гнучку конфігурацію — масив `InputFieldConfig` (placeholder, keyboardType, initialText, isSecure). `InputPopupView` рендерить 1 або 2 поля за масивом. Це покриває `StockListViewController.showAdjustmentAlert` (2 поля) без окремих класів.

```swift
struct InputFieldConfig {
    let placeholder: String
    let keyboardType: UIKeyboardType
    let initialText: String?
    let isSecureTextEntry: Bool
}
```

### 1.2 Додати метод у `PopupFactory`
У `PopupFactory.swift` додати:

```swift
static func showInputPopup(
    title: String,
    description: String,
    fields: [InputFieldConfig],
    saveTitle: String = R.string.global.save(),
    onSave: @escaping ([String]) -> Void,
    onCancel: (() -> Void)? = nil
)
```

- Створити `InputPopupView`, передати конфігурацію.
- `onSave` повертає масив значень текстових полів у тому ж порядку.
- `SwiftEntryKit.dismiss()` у обох кнопках перед викликом колбеків.
- Використовувати `PopupFactory.presentAttributes`.

### 1.3 Замінити input-алерти
Замінити використання `UIAlertController` з `addTextField` у:
- `StockListViewController.showAdjustmentAlert(for:)` — 2 поля (кількість, причина).
- `ProductDetailsViewController.showQuantityInput(for:)` — 1 поле (кількість, decimalPad).
- `SignInController.showConfirmEmail(_:)` — 1 поле (email, emailAddress).
- `SettingListViewController` seed test data — 1 поле (кількість днів, numberPad).

Для кожного: видалити створення `UIAlertController`, викликати `PopupFactory.showInputPopup`, у `onSave` передати логику, яка раніше була в handler `UIAlertAction`.

### 1.4 Валідація
- Build Dev/Beta/Prod — success.
- Smoke-тест: редагування залишку інградієнта (2 поля), додавання інградієнта в рецепт (кількість), підтвердження email, seed test data.
- Перевірка клавіатури (decimalPad/numberPad/emailAddress), placeholder-ів, dismiss по Cancel.

## Очікуваний результат
- Користувач більше не бачить системний `UIAlertController` для вводу — всюди кастомний попап у стилі застосунку.
- `PopupFactory` має універсальний `showInputPopup` для 1–2 полів.

## Acceptance Criteria
- [ ] `InputPopupView` створено, підтримує 1 та 2 поля.
- [ ] `PopupFactory.showInputPopup` існує й приймає `[InputFieldConfig]`.
- [ ] Жоден `UIAlertController.addTextField` не залишилось у продакшн-коді.
- [ ] Build Dev/Beta/Prod — success.

---

# ЕТАП 2 — #100: Переписати всі alerts на PopupFactory

**Issue:** https://github.com/1cetoprosto/cyber-cafe/issues/100
**Пріоритет:** low
**Мета:** повністю прибрати пряме використання `UIAlertController` (`.alert` та `.actionSheet`) у продакшн-коді; єдиний хаб для попапів — `PopupFactory`.

> Найбільший за обсягом етап. Рекомендується робити окремим PR після замикання #127.

## Дії

### 2.1 Розширити `PopupFactory` (фундамент)
Додати в `PopupFactory.swift`:
- `showActionSheet(title:message:actions:sourceView:)` — для вибору опцій.
  - Параметр `actions: [PopupAction]`, де `PopupAction(title:style:handler:)`.
  - `.actionSheet` через SwiftEntryKit не є нативним — реалізувати як кастомний вертикальний список кнопок (аналог `OrderModePopupView`, але з динамічними кнопками) **або** залишити нативний `UIAlertController` лише для actionSheet, якщо кастомний варіант надто складний.
  - **Рішення:** спочатку створити кастомний `ActionSheetView` (вертикальний список кнопок + Cancel у стилі `OrderModePopupView`). Це забезпечує візуальну консистентність.
- `showConfirm(title:message:confirmTitle:isDestructive:onConfirm:onCancel:)` — обгортка над `showPopup`/`showDestructivePopup` для зручності (опціонально, можна без нього).

### 2.2 Переписати хелпери `UIViewController+*`
- `Extensions/UI/UIViewController+Extension.swift`:
  - `showAlert(_:body:)` x2 → `PopupFactory.showPopup`.
  - `showWarning(body:buttonTitle:action:)` → `PopupFactory.showDestructivePopup`.
  - `askConfirmOperation(_:action:)` → `PopupFactory.showPopup` (з Confirm/Cancel).
  - `topMostViewController(base:)` залишити (використовується для презентації).
- `Extensions/UI/UIViewController+AlertLanguage.swift`:
  - `alertLanguage` → `PopupFactory.showActionSheet`.
  - `alertTheme` → `PopupFactory.showActionSheet`.
- `Staff/View/Technician/TechnicianDetailsController.swift` — **видалити** глобальні дублікати `showAlert`/`showWarning` (використовувати extension).

### 2.3 Замінити actionSheet у VC
- `PurchaseListViewController.filterButtonTapped` / `presentIngredientFilter` → `showActionSheet`.
- `ProductCategoryDetailsViewController.imageTapped` → `showActionSheet`.
- `ProductDetailsViewController.imageTapped` / `categoryTapped` / `addIngredientAction` (вибір інградієнта) → `showActionSheet`.
- `ProductListViewController.showSortOptions` → `showActionSheet`.
- `ImagePicker.showAlert` (Settings/Cancel) → `showPopup`; `showPickerOptions` — закоментовано, прибрати.

### 2.4 Замінити `.alert` (повідомлення/підтвердження) у VC
- `OrderDetailsViewController` — `verifyRequiredData`, `handleSaveError` x2 → `showPopup`; `showStockWarning` → `showPopup` (Cancel/Proceed).
- `OrderReceiptPadViewController` — `handleSaveError` x2 → `showPopup`; `showStockWarning` → `showPopup`.
- `MainTabBarController.handleDemoDataDelete` → `showDestructivePopup`.
- `SignInController` `.retry` → `showPopup` (Cancel/Retry).
- `SignUpController` `.retry` → `showPopup` (Cancel/Retry).
- `HomeViewController.confirmDeleteDemoData` → `showDestructivePopup`.
- `ManualMovementListViewController.showError` → `showPopup`.
- `CreateIngredientViewController.saveAction` x3 → `showPopup`.
- `ProductDetailsViewController.addIngredientAction` (warning "немає інградієнтів") → `showPopup`; `overwriteAlert` (Yes/No) → `showPopup`.
- `SettingListViewController` — усі алерти (TrackIngredients confirmation/locked, reset onboarding, showErrorAlert, showSuccessAlert, confirmDeleteDemoData, confirmDeleteAllData) → `showPopup`/`showDestructivePopup`.

> Input-алерти (`showConfirmEmail`, `showAdjustmentAlert`, `showQuantityInput`, seed test data) вже замінені в Етапі 1 — їх не чіпати.

### 2.5 Валідація
- `Grep` по проєкту: `UIAlertController` — 0 збігів у продакшн-коді (дозволено лише у коментарях/документації).
- Build Dev/Beta/Prod — success.
- Ручний тест усіх сценаріїв: видалення даних, валідація форм, фільтри/сортування, вибір зображення/категорії/інградієнта, помилки збереження.

## Очікуваний результат
- Усі системні алерти замінені кастомними попапами `PopupFactory`.
- Візуальна консистентність попапів у всьому застосунку.

## Acceptance Criteria
- [ ] `grep -r "UIAlertController" --include="*.swift" TrackMyCafe/` — 0 збігів (крім закоментованого коду).
- [ ] `PopupFactory.showActionSheet` існує й використовується для вибору опцій.
- [ ] Хелпери `UIViewController+Extension`/`AlertLanguage` викликають `PopupFactory`.
- [ ] Build Dev/Beta/Prod — success.

---

# ЕТАП 3 — #173: Використовувати `secondaryText` для вторинного контенту

**Issue:** https://github.com/1cetoprosto/cyber-cafe/issues/173
**Пріоритет:** low
**Мета:** усі описи, підзаголовки, каптіони та підписи використовують `UIColor.Main.secondaryText`; покращити візуальну ієрархію.

## Дії

Замінити `textColor` на `UIColor.Main.secondaryText` (або `Theme.current.secondaryText`) у наступних файлах:

### 3.1 Базові компоненти (найбільший ефект)
1. `View Layer/UI/Base/InputContainerView.swift` — `titleLabel.textColor` (L34): `.Main.text` → `.Main.secondaryText`.
2. `View Layer/UI/Base/BaseListTableViewCell.swift` — `detailTextLabel?.textColor` (L19): `.TableView.cellLabel` → `.Main.secondaryText`.

### 3.2 Підписи полів форми
3. `Flow/Costs/CostDetails/View/CostDetailsListViewController.swift` — `paymentMethodLabel.textColor` (L80).
4. `Flow/Purchase/CreatePurchase/View/CreatePurchaseViewController.swift` — `titleLabel.textColor` (L133).
5. `Flow/ManualMovements/Edit/ManualMovementEditViewController.swift` — `configureTitleLabel` (`label.textColor`, L210).
6. `Flow/Staff/View/Technician/CreateEditTechnicianController.swift` — `makeField`/`makeTextViewField`/`makeSwitch` → `titleLabel.textColor` (L171, L210, L247).
7. `Flow/Orders/OrderDetails/View/OrderReceiptPadViewController.swift` — `OrderCompactFieldView.titleLabel.textColor` (L12).

### 3.3 Нотатки / допоміжний текст
8. `Flow/Inventory/Sessions/View/Cells/InventorySessionCell.swift` — `noteLabel.textColor` (L31).
9. `Flow/Settings/Subscription/Views/Cells/SubscriptionCell.swift` — `infoLabel` — явно встановити `.Main.secondaryText`.
10. `Flow/Settings/Subscription/Views/Cells/SubscriptionTextCell.swift` — `textLabel?.textColor` (L25).

### 3.4 Захардкоджений колір
11. `Extensions/UI/UILabel+Extension.swift` — `convenience init(text:font:aligment:)` (L17): `.black` → `.Main.text` (або видалити ініціалізатор, якщо не використовується).

### 3.5 Перевірка тем
- Прогнати візуальну перевірку у всіх 3 палітрах: Standard (Light/Dark), Alt (Light/Dark), CoffeeWithMilk (Light/Dark).
- Переконатися, що вторинний текст достатньо контрастний (WCAG AA) на усіх фонах. Якщо десь контраст низький — залишити основний колір або скоригувати fallback у `Theme.swift`.

### 3.6 Валідація
- Build Dev/Beta/Prod — success.
- Візуальний smoke-тест: форми (Create Purchase, Cost Details, Manual Movement, Technician), квитанція замовлення, клітинки інвентарних сесій, екрани підписки, списки з detailTextLabel.

## Очікуваний результат
- Візуальна ієрархія: основний текст (`secondaryText`) відрізняється від заголовків і значень.
- Консистентність у всіх темах.

## Acceptance Criteria
- [ ] Усі вторинні лейбли використовують `UIColor.Main.secondaryText`.
- - [ ] `InputContainerView.titleLabel` та `BaseListTableViewCell.detailTextLabel` оновлено.
- [ ] Немає `.black` для `textColor` у продакшн-коді.
- [ ] Контраст вторинного тексту задовольняє WCAG AA у всіх темах.
- [ ] Build success.

---

# ЕТАП 4 — #164: Міграція R.swift з CocoaPods на SPM (опціонально)

**Issue:** https://github.com/1cetoprosto/cyber-cafe/issues/164
**Пріоритет:** low (tech-debt)
**Мета:** прибрати `pod 'R.swift'`, перейти на SPM-пакет R.swift з build tool plugin.

> **Опціональний етап.** Якщо є ризики або обмеження по часу — пропустити. Вимагає ручних дій у Xcode (SPM не редагується через MCP).

## Дії

### 4.1 Прибрати R.swift з CocoaPods
- Відкрити `Podfile`, видалити `pod 'R.swift'` у 3 таргетах (Beta, Dev, Prod).
- Запустити `pod install` (локально, в терміналі).
- Перевірити `Podfile.lock` — `R.swift` зник.

### 4.2 Прибрати стару генерацію
- Видалити `R.generated.swift` з проєкту (його більше не генеруватиме run script).
- Видалити run script build phase «R.swift» у Xcode: Target → Build Phases → видалити скрипт, що викликає `rswift`.
- **Не редагувати `project.pbxproj` вручну** — усі зміни через Xcode.

### 4.3 Додати SPM-пакет
- Xcode → File → Add Packages → `https://github.com/mac-cain13/R.swift`.
- Додати `RswiftLibrary` до залежностей 3 таргетів (Prod, Beta, Dev).
- Додати build tool плагін `RswiftGenerateInternalResources` до Build Phases кожного таргета.

### 4.4 Перевірити сумісність
- SPM-версія R.swift генерує `R` з `internal` access modifier (через `RswiftGenerateInternalResources`).
- Усі звернення `R.string.global.*`, `R.image.*` мають працювати без змін (оскільки вони всередині модуля).
- Якщо десь є `public` звернення до `R` — виправити (малоймовірно).

### 4.5 Валідація
- Clean build Dev/Beta/Prod — success.
- Перевірити, що `R.generated.swift` не створюється вручну, а генерується плагіном у DerivedData.
- Smoke-тест: локалізація (EN/UK), зображення, кольори.

## Очікуваний результат
- `Podfile` не містить `R.swift`.
- R.swift підключено через SPM, `R` генерується плагіном.
- Усі звернення до `R.*` працюють.

## Acceptance Criteria
- [ ] `Podfile` не містить `pod 'R.swift'`.
- [ ] SPM-пакет `R.swift` додано, `RswiftLibrary` у залежностях, `RswiftGenerateInternalResources` у Build Phases (усі 3 таргети).
- [ ] `R.generated.swift` видалено з репозиторію.
- [ ] Clean build Dev/Beta/Prod — success.
- [ ] Локалізація та ресурси працюють.

---

## Ризики та застереження (для всіх етапів)

1. **SwiftEntryKit + actionSheet.** Нативний `.actionSheet` через `UIAlertController` зручний для великих списків (напр. вибір інградієнта). Кастомний `ActionSheetView` через SwiftEntryKit може не обробляти довгі списки так само зручно. Якщо список великий — розглянути використання `UITableView` у попапі або залишити нативний actionSheet для таких випадків.
2. **Клавіатура в попапах.** `PopupFactory.presentAttributes` вже має `positionConstraints.keyboardRelation = .bind` — текстові поля не будуть перекриватись клавіатурою. Перевірити на реальному пристрої/симуляторі.
3. **Контрастність `secondaryText`.** У темі CoffeeWithMilk `secondaryText` — світло-коричневий; на кремовому фоні контраст може бути низьким. Обов'язково перевірити WCAG AA; за потреби скоригувати fallback кольори у `CoffeeWithMilkTheme`.
4. **R.swift SPM міграція.** Зміна способу генерації `R` може вплинути на всі файли, що використовують `R.*`. Виконувати останнім етапом, ізольованим PR, і ретельно тестувати. Якщо виникнуть проблеми — відкатити (вернути `pod 'R.swift'`).
5. **Правило проєкту:** не редагувати `project.pbxproj` вручну. SPM-дії та видалення run script — через Xcode GUI або Xcode MCP (`UpdateFileCompilerFlags` не підходить; використовувати Xcode вручну).
6. **Dynamic Type.** У новому `InputPopupView` та `ActionSheetView` не використовувати фіксовані висоти для текстових блоків; `numberOfLines = 0` для описів, авто-скейл для кнопок.
7. **Swift 6 `#ImplicitStrongCapture`.** У замиканнях кнопок `InputPopupView` та колбеках `PopupFactory` використовувати `[weak self]` та явні capture lists.

---

## Прогрес (оновлювати після кожного етапу)

| Етап | Issue | Статус | Дата завершення |
|------|-------|--------|-----------------|
| 1 — InputPopupView | #127 | ✅ Done | 2026-10-12 |
| 2 — Rewrite alerts | #100 | ⬜ Planned | — |
| 3 — secondaryText | #173 | ⬜ Planned | — |
| 4 — R.swift → SPM | #164 | ⬜ Planned | — |

---

## Посилання

- [Milestone v1.1.4](https://github.com/1cetoprosto/cyber-cafe/milestone/13)
- [Issue #127 — InputPopupView](https://github.com/1cetoprosto/cyber-cafe/issues/127)
- [Issue #100 — Rewrite alerts](https://github.com/1cetoprosto/cyber-cafe/issues/100)
- [Issue #173 — secondaryText](https://github.com/1cetoprosto/cyber-cafe/issues/173)
- [Issue #164 — R.swift SPM](https://github.com/1cetoprosto/cyber-cafe/issues/164)
- `TrackMyCafe/View Layer/UI/Popup/PopupFactory.swift` — існуючі попапи
- `TrackMyCafe/View Layer/Flow/Settings/Subscription/Views/SubscriptionBannerView.swift` — еталон використання `secondaryText`
- `TrackMyCafe/Extensions/UI/UIColor+Extension.swift`, `TrackMyCafe/View Layer/UI/Theme/Theme.swift` — система кольорів
- `Podfile` — R.swift через CocoaPods
- `AGENTS.md`, `.trae/rules/project_rules.md` — правила кодування
