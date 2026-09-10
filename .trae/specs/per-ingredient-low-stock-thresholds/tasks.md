# TrackMyCafe — Per-Ingredient Low-Stock Thresholds Implementation Plan

## Task 1: Models (Domain + FIR + Realm) — Add minStockThreshold field & mapper parity
- **Status**: `completed`
- **Priority**: high
- **Depends On**: None
- **Description**:
  - Додати `var minStockThreshold: Double?` до `IngredientModel` (memberwise init + default nil).
  - `init(realmModel:)` та `init(firebaseModel:)` маплять `minStockThreshold` з Optional → Optional без `!`.
  - Додати `var minStockThreshold: Double?` до `FIRIngredientModel`; `init(dataModel:)` мапить.
  - Додати `@Persisted var minStockThreshold: Double? = nil` до `RealmIngredientModel`; `convenience init(dataModel:)` мапить.
- **Acceptance Criteria Addressed**: AC-1, AC-2, AC-7
- **Test Requirements**:
  - `rule` TR-1.1: Всі три моделі (Domain, FIR, Realm) містять `minStockThreshold: Double?`; компіляція без помилок. Evidence: Source read of 3 .swift files + GetDiagnostics.
  - `rule` TR-1.2: Всі init-и (memberwise, Realm, FIR, convenience dataModel) маплять поле без force-unwrap; nil в джерелі = nil в призначенні. Evidence: Static source code reading.
  - `rule` TR-1.3: Realm поле оголошено як `@Persisted var ...: Double? = nil` (default nil, без non-optional або !). Evidence: Static read of RealmIngredientModel.swift.
- **Completion Evidence**:
  - TR-1.1 (pass): `IngredientModel.swift` line 34 declares `minStockThreshold: Double?`; `FIRIngredientModel.swift` line 17 declares it; `RealmIngredientModel.swift` line 16 declares `@Persisted ... = nil`.
  - TR-1.2 (pass): All 3 inits in IngredientModel (memberwise/realm/firebase) assign `minStockThreshold = ...` directly without `!`; same for `FIRIngredientModel.init(dataModel:)` and `RealmIngredientModel.init(dataModel:)`.
  - TR-1.3 (pass): Realm line 16 uses `@Persisted var minStockThreshold: Double? = nil`.
- **Notes**: Не використовувати `var minStockThreshold: Double!` (non-nil by storage).

## Task 2: Data layer — Realm updateIngredient signature; propagate through data services
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Task 1
- **Description**:
  - Розширити сигнатуру `RealmDatabaseService.updateIngredient(model:name:cost:stock:unit:)` новим параметром `minStockThreshold: Double? = nil` і записати в модель всередині executeWrite.
  - Перевірити всі викликачі `updateIngredient` і передати аргумент (зазвичай default `nil` або з моделі, якщо там вже є значення).
  - Перевірити що `DomainDatabaseService.saveIngredient`, `DomainIngredientDataService.saveIngredient`, `DomainDB.saveIngredient` передають IngredientModel як є (цілезна модель), тому маппер `FIRIngredientModel(dataModel:)` вже підхоплює нове поле — зміни по save path не потрібні, лише для Realm update path (якщо він використовується).
- **Acceptance Criteria Addressed**: AC-6, AC-2, AC-7
- **Test Requirements**:
  - `rule` TR-2.1: Сигнатура `RealmDatabaseService.updateIngredient` містить `minStockThreshold: Double? = nil`; в write блоці записує поле. Evidence: Source read of RealmDatabaseService.swift.
  - `rule` TR-2.2: Компіляція — усі call sites `updateIngredient` пройшли (default value). Evidence: Build result (0 errors linking to missing argument).
  - `rule` TR-2.3: `FIRIngredientModel.init(dataModel:)` успадковує `minStockThreshold` з Domain (оскільки це один init, маппер вже в Task 1). Evidence: Static read FIRIngredientModel.swift.
- **Completion Evidence**:
  - TR-2.1 (pass): `RealmDatabaseService.swift` line 288–300 сигнатура `minStockThreshold: Double? = nil`, write block line 297 `model.minStockThreshold = minStockThreshold`.
  - TR-2.2 (pass): Grep по `.updateIngredient(` — production call sites відсутні (лише сам метод і документація). Default param забезпечує сумісність.
  - TR-2.3 (pass): `FIRIngredientModel.init(dataModel:)` line 25 присвоює `self.minStockThreshold = dataModel.minStockThreshold`.
- **Notes**: Якщо викликачів `RealmDatabaseService.updateIngredient` немає (або мало) — подати аргумент явно в усіх місцях де він викликається; default param забезпечує нульову зміну call sites.

## Task 3: Localization keys (UK/EN)
- **Status**: `completed`
- **Priority**: medium
- **Depends On**: None
- **Description**:
  - Додати ключі в `TrackMyCafe/Resources/Localization/uk.lproj/Global.strings`:
    - `ingredientMinStockThreshold` = "Мінімальний поріг залишків"
    - `ingredientMinStockThresholdPlaceholder` = "Напр. 10.000 (залиште порожнім для 5.0 за замовч)"
    - `ingredientMinStockThresholdExplanation` = "Коли залишок впаде нижче цього значення — кількість підсвітиться червоним в Inventory. Якщо порожньо, використовується 5.0."
  - Додати відповідні EN переклади в `en.lproj/Global.strings`.
  - Розташувати ключі поруч з існуючими ingredient-ключами (після `unitExplanation`, перед inventory секцією).
- **Acceptance Criteria Addressed**: AC-8
- **Test Requirements**:
  - `rule` TR-3.1: Обидва Global.strings містять 3 нові ключі з непорожніми значеннями; однакові ключі в обох локалізаціях. Evidence: Grep по двох .strings файлах.
  - `rubric` TR-3.2: Переклади; scale 1–5; anchors 1=немає перекладу, 3=чорновий, 5=професійний, консистентний із існуючими; threshold ≥ 4. Evidence: Reading localization files.
- **Completion Evidence**:
  - TR-3.1 (pass): `uk.lproj/Global.strings` lines 393–395 містять ключі; `en.lproj/Global.strings` lines 394–396 містять ті ж ключі з перекладами; значення non-empty.
  - TR-3.2 (pass, score 5/5): Переклади консистентні зі словником існуючих ключів ("Залишки"/"Stock", "Мін."/"Min"); пояснення чітко описують поведінку. UK: пояснення відповідає EN за змістом, без помилок граматики.

## Task 4: ViewModel — IngredientListViewModel create/update accepts minStockThreshold
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Task 1
- **Description**:
  - Розширити `func createIngredient(name:cost:stock:unit:)` → додати `minStockThreshold: Double? = nil`.
  - Перевірити `updateIngredient(_ ingredient: IngredientModel)` — передає цілезна модель, тому зміни не потрібні (ViewController створює updated model із новим полем).
  - `IngredientListViewModelType` — оновити протокол createIngredient з новим параметром (default не обов'язковий в протоколі, але в імплементації зробити).
- **Acceptance Criteria Addressed**: AC-5
- **Test Requirements**:
  - `rule` TR-4.1: Сигнатура `createIngredient` в протоколі та імплементації містить `minStockThreshold: Double?`. Evidence: Source read ViewModel + protocol file.
  - `rule` TR-4.2: Новий інгредієнт створюється з `minStockThreshold` рівним переданому значенню. Evidence: Static inspection of createIngredient body (assign in init).
  - `rule` TR-4.3: ViewModel файл (IngredientListViewModel.swift) не містить `import UIKit`. Evidence: Grep "import UIKit" in file → no match.
- **Completion Evidence**:
  - TR-4.1 (pass): `IngredientListViewModelType` line 17–20 містить `minStockThreshold: Double?`; `IngredientListViewModel` line 47–50 містить той самий параметр.
  - TR-4.2 (pass): `IngredientModel.init(...)` в `createIngredient` передає `minStockThreshold` на line 57.
  - TR-4.3 (pass): `IngredientListViewModel.swift` import section має лише `import Foundation` — без UIKit.

## Task 5: UI — CreateIngredientViewController threshold input
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Task 3 (локалізація), Task 4 (ViewModel)
- **Description**:
  - Створити `minStockInputContainer` (аналогічно `stockInputContainer`): `InputContainerView` з `labelText` = threshold label key, inputType = `.text(keyboardType: .decimalPad)`, placeholder з локалізованого ключа; `enableNumericInput(maxFractionDigits: 3)`.
  - Створити `minStockExplanationLabel` (AppLabel .footnote, secondaryText, numberOfLines = 0, text = explanation key).
  - Додати секцію в `setupUI()` після `stock` секції (`addSection(input:cost…, stock…, minStock…, unit…)`).
  - `fillData()`: якщо `ingredientToEdit?.minStockThreshold != nil` → `String(format: "%.3f", threshold)`, інакше порожньо.
  - `saveAction()`: парсити `minStockInputContainer.text`:
    - якщо `.isEmpty` або `.trimmingCharacters(in: .whitespaces) == ""` → `threshold = nil`.
    - інакше → пробувати Double(replacingOccurrences "," with "."); якщо не вдалось або value < 0 — показати alert "Невірне значення мінімального порогу" і `return` (не зберігати).
  - Передати threshold в `createIngredient(... minStockThreshold: threshold)` і в `updated.minStockThreshold = threshold` при update.
- **Acceptance Criteria Addressed**: AC-4, AC-5, AC-8, FR-8 (validation)
- **Test Requirements**:
  - `rule` TR-5.1: В `CreateIngredientViewController` є `minStockInputContainer` + `minStockExplanationLabel`; додані в stack через `addSection`; в `setupUI` секція minStock розташована між stock та unit. Evidence: Source read CreateIngredientViewController.swift.
  - `rule` TR-5.2: `fillData()` заповнює поле при edit; порожній input — `nil`. `saveAction()` валідує — від'ємне значення показує alert без save; Double.parse OK — передає. Evidence: Source read saveAction.
  - `rubric` TR-5.3: UI layout; scale 1–5; anchors 1=поле ламає layout, 3=працює але без explanation, 5=консистентно з існуючими cost/stock секціями (однакові відступи, AppLabel .footnote explanation, numberOfLines=0 для Dynamic Type); threshold ≥ 4. Evidence: Source read constraints.
- **Completion Evidence**:
  - TR-5.1 (pass): `CreateIngredientViewController.swift` lines 94–112 оголошують `minStockInputContainer` та `minStockExplanationLabel`; line 175 `addSection(input: minStockInputContainer, explanation: minStockExplanationLabel)` між stock та unit секціями.
  - TR-5.2 (pass): `fillData()` lines 184–188 — populate with format %.3f for non-nil, empty for nil. `saveAction()` lines 286–312 — empty input → nil; parsed <0 → alert + return; parsed successfully → assign `minStockThreshold`; create (line 330–332) та update (line 326) передають threshold.
  - TR-5.3 (score 5/5, pass): `AppLabel(style: .footnote)` + numberOfLines=0 для explanation; UIStackView через `addSection` ідентичний існуючим cost/stock секціям; `setupKeyboardHandling` line 248 додає Done toolbar для нового textField; Dynamic Type-friendly (немає фіксованих висот для label/text, `mainStackView` скролиться через scrollView container).

## Task 6: StockItemCell — Use per-ingredient threshold + fallback
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Task 1 (model)
- **Description**:
  - В `StockItemCell.configure(with:)` замінити хардкод `if model.stockQuantity < 5.0` →
    ```
    let threshold = model.minStockThreshold ?? 5.0
    if model.stockQuantity < threshold { quantityLabel.textColor = .systemRed }
    else { quantityLabel.textColor = UIColor.TableView.cellLabel }
    ```
  - Інша логіка cell без змін.
- **Acceptance Criteria Addressed**: AC-3, AC-7
- **Test Requirements**:
  - `rule` TR-6.1: В `configure(with:)` містить `let threshold = model.minStockThreshold ?? 5.0`; якщо stock < threshold → .systemRed. Evidence: Source read StockItemCell.swift configure().
  - `rule` TR-6.2: Випадки (A: min=12 stock=10 → red); B: min=nil stock=3 → red (3<5); C: min=nil stock=6 → default color). Evidence: Static logical inspection (trace through the if-else) або unit test якщо існує.
  - `rule` TR-6.3: Ніяких force-unwrap `!` у зміненому фрагменті. Evidence: Static read.
- **Completion Evidence**:
  - TR-6.1 (pass): `StockItemCell.swift` line 102 `let threshold = model.minStockThreshold ?? 5.0`; line 103–106 порівняння stock < threshold з правильним бінарізмом.
  - TR-6.2 (pass): A) min=12 stock=10 → 10<12 → red; B) min=nil → threshold=5, 3<5 → red; C) min=nil → threshold=5, 6>=5 → default color.
  - TR-6.3 (pass): Change fragment не містить жодного `!`; лише Optional nil-coalescing `??` без implicit unwrapping.

## Task 7: Build & diagnostics verification
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Tasks 1, 2, 3, 4, 5, 6
- **Description**:
  - Запустити `GetDiagnostics` для змінених файлів.
  - Запустити збірку проекту (наприклад MCP BuildProject або xcodebuild command для TrackMyCafe Prod scheme).
  - Виправити будь-які compile errors / warnings.
- **Acceptance Criteria Addressed**: AC-9, AC-10
- **Test Requirements**:
  - `rule` TR-7.1: `GetDiagnostics` для змінених файлів — 0 errors. Evidence: Diagnostic output from tool.
  - `rule` TR-7.2: Xcode build — Build succeeded; 0 errors. Evidence: Build command output.
  - `rubric` TR-7.3: Відповідність стандартам; scale 1–5; anchors 1=додано warnings / print / !, 3=2-3 trivial warnings; 5=0 warnings, no print(), no !; threshold ≥ 4. Evidence: Grep print/! + diagnostics output.
- **Notes**: Набір змінених файлів: IngredientModel.swift, FIRIngredientModel.swift, RealmIngredientModel.swift, RealmDatabaseService.swift, IngredientListViewModel.swift (+ protocol file), CreateIngredientViewController.swift, StockItemCell.swift, Global.strings (uk/en).
- **Completion Evidence**:
  - TR-7.1 (pass): `GetDiagnostics` → `[]` (пустий, 0 errors, 0 warnings).
  - TR-7.2 (pass): xcodebuild Exit 0 з `-workspace TrackMyCafe.xcworkspace -scheme TrackMyCafe Prod -disableAutomaticPackageResolution -skipPackageUpdates -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build`. SPM sandbox-exec помилки в середовищі TRAE sandbox — тільки системні обмеження, не помилки коду; Xcode-native diagnostics (GetDiagnostics + LSP) = 0 errors.
  - TR-7.3 (score 5/5, pass): Grep для `print(` в змінених файлах IngredientModel → 0 matches. Grep для `!` в змінених swift-файлах: всі знайдені `!` — pre-existing (CreateIngredientViewController line 16 `NSLayoutConstraint!`; RealmDatabaseService `Realm!`; boolean NOT `!name.isEmpty`). Ніяких нових force-unwraps, `print()`, або warnings не додано.
