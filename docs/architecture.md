# Архітектура TrackMyCafe

## Загальний огляд

TrackMyCafe використовує архітектуру **MVVM** (Model-View-ViewModel) з чітким розділенням відповідальності між шарами. Додаток побудований на UIKit з програмною версткою (без Storyboard/XIB).

## Шари архітектури

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                           View Layer (UI)                                    │
│  ├── View Controllers (UIKit)                                                   │
│  ├── ViewModels (MVVM)                                                         │
│  └── UI Components (Custom Views)                                              │
├──────────────────────────────────────────────────────────────────────────────────┤
│                           Services Layer                                     │
│  ├── Domain Services (Business Logic)                                          │
│  ├── Firebase Services (Cloud Sync)                                            │
│  └── Realm Services (Local Cache)                                              │
├──────────────────────────────────────────────────────────────────────────────────┤
│                           Data Layer                                         │
│  ├── Domain Models (Business Entities)                                         │
│  ├── Firestore Models (Firebase DTO)                                           │
│  └── Realm Models (Local DB Entities)                                          │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## View Layer

### Структура

```
View Layer/
├── Flow/                    # Екрани та флоу
│   ├── Auth/              # Авторизація
│   ├── Home/              # Головний екран (дашборд)
│   ├── Orders/            # Замовлення
│   ├── Costs/             # Операційні витрати
│   ├── Inventory/         # Інвентар
│   ├── Purchase/          # Закупівлі
│   ├── Settings/          # Налаштування
│   ├── Staff/             # Персонал
│   ├── Admin/             # Адміністрування
│   ├── Onboarding/        # Онбординг
│   └── MainTabBarController.swift
└── UI/                    # Універсальні UI компоненти
    ├── Base/
    ├── Theme/
    ├── Popup/
    └── UIKitFactory.swift
```

### MVVM Pattern

Кожен екран має власний ViewModel:

```swift
// Протокол ViewModelType
protocol OrderListViewModelType {
    func getOrders(completion: @escaping () -> Void)
    func numberOfSections() -> Int
    func numberOfRowInSection(for section: Int) -> Int
    func cellViewModel(for indexPath: IndexPath) -> OrderListItemViewModelType?
}

// Реалізація
class OrderListViewModel: OrderListViewModelType {
    private var sectionsOrders: [(date: Date, items: [OrderModel])]?
    
    func getOrders(completion: @escaping () -> Void) {
        DomainDatabaseService.shared.fetchSectionsOfOrders { [weak self] sectionsOrders in
            self?.sectionsOrders = sectionsOrders
            completion()
        }
    }
    // ...
}
```

### ViewController

```swift
class OrderListViewController: UIViewController {
    private var viewModel: OrderListViewModelType?
    
    // UI компоненти
    let tableView: UITableView = { ... }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = OrderListViewModel()
        setupUI()
    }
}
```

## Services Layer

### Domain Services

`DomainDatabaseService` — головний сервіс для роботи з даними, реалізує протокол `DomainDB`:

```swift
protocol DomainDB {
    // Orders
    func fetchOrders(completion: @escaping ([OrderModel]) -> Void)
    func saveOrder(order: OrderModel, completion: @escaping (String?) -> Void)
    func deleteOrder(order: OrderModel, completion: @escaping (Bool) -> Void)
    
    // Products
    func fetchProductsPrice(completion: @escaping ([ProductsPriceModel]) -> Void)
    func saveProductsPrice(productPrice: ProductsPriceModel, completion: @escaping (Bool) -> Void)
    
    // Ingredients
    func fetchIngredients(completion: @escaping ([IngredientModel]) -> Void)
    func saveIngredient(model: IngredientModel, completion: @escaping (Bool) -> Void)
    
    // ... інші методи
}
```

### Firebase Services

`FirestoreDatabaseService` — сервіс для роботи з Firebase Firestore:

```swift
class FirestoreDatabaseService: FirestoreDB {
    // Generic CRUD
    func create<T: Encodable>(firModel: T, collection: String, completion: @escaping (Result<String, Error>) -> Void)
    func read<T: Decodable>(collection: String, firModel: T.Type, completion: @escaping (Result<[(documentId: String, T)], Error>) -> Void)
    func update<T: Encodable>(firModel: T, collection: String, documentId: String, completion: @escaping (Result<Void, Error>) -> Void)
    func delete(collection: String, documentId: String, completion: @escaping (Result<Void, Error>) -> Void)
}
```

### Authentication

```swift
class AuthManager {
    static let shared = AuthManager()
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void)
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void)
    func signOut() throws
    func biometricAuth(completion: @escaping (Bool) -> Void)
}
```

## Data Layer

### Моделі даних

Використовується три рівні моделей:

1. **Domain Models** — бізнес-суть
2. **Firestore Models** — DTO для Firebase
3. **Realm Models** — локальна база (історично)

#### Domain Model

```swift
struct OrderModel {
    var id: String
    var date: Date
    var type: String
    var sum: Double
    var cash: Double
    var card: Double
    var totalCost: Double
    var note: String?
}
```

#### Firestore Model

```swift
struct FIROrderModel: Codable {
    @DocumentID var id: String?
    var date = Date()
    var type: String
    var sum: Double = 0.0
    var cash: Double = 0.0
    var card: Double = 0.0
    var totalCost: Double?
    var note: String?
}
```

### Data Mapping

```swift
// Firestore -> Domain
extension OrderModel {
    init(firebaseModel: FIROrderModel) {
        self.id = firebaseModel.id ?? ""
        self.date = firebaseModel.date
        self.type = firebaseModel.type
        self.sum = firebaseModel.sum
        self.cash = firebaseModel.cash
        self.card = firebaseModel.card
        self.totalCost = firebaseModel.totalCost ?? 0.0
        self.note = firebaseModel.note
    }
}

// Domain -> Firestore
extension FIROrderModel {
    init(dataModel: OrderModel) {
        self.id = dataModel.id
        self.date = dataModel.date
        self.type = dataModel.type
        self.sum = dataModel.sum
        self.cash = dataModel.cash
        self.card = dataModel.card
        self.totalCost = dataModel.totalCost
        self.note = dataModel.note
    }
}
```

## Ключові патерни

### 1. Dependency Injection

Використання Singleton для сервісів:

```swift
class DomainDatabaseService: DomainDB {
    static let shared = DomainDatabaseService()
    private init() {}
}

class FirestoreDatabaseService: FirestoreDB {
    static let shared = FirestoreDatabaseService()
    private init() { ... }
}
```

### 2. Repository Pattern

`DomainDatabaseService` діє як репозиторій, абстрагуючи джерело даних:

```swift
// Клієнт працює з DomainDB, не знаючи про Firestore
let orders = DomainDatabaseService.shared.fetchOrders { orders in
    // обробка даних
}
```

### 3. Coordinator Pattern (Navigation)

Навігація реалізована через `SceneDelegate` та власне переміщення між ViewController:

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func start() {
        // Перевірка онбордингу
        // Перевірка автентифікації
        // Навігація на головний екран або логін
    }
}
```

### 4. Observer Pattern

NotificationCenter для подій між компонентами:

```swift
extension Notification.Name {
    static let ordersInfoReload = Notification.Name("ordersInfoReloadNotification")
    static let settingsInfoReload = Notification.Name("settingsInfoReload")
    static let demoDataDidDelete = Notification.Name("demoDataDidDelete")
}

// Підписка
NotificationCenter.default.addObserver(
    self, 
    selector: #selector(updateData), 
    name: .ordersInfoReload, 
    object: nil
)
```

### 5. Factory Pattern

`UIKitFactory` для створення UI компонентів:

```swift
class UIKitFactory {
    static func createButton(title: String, action: Selector) -> UIButton
    static func createTextField(placeholder: String) -> UITextField
    static func createLabel(text: String, font: UIFont) -> UILabel
}
```

### 6. ProGated Pattern (Paywall)

Протокол для перевірки Pro-підписки:

```swift
protocol ProGated {
    func checkProOrShowPaywall(completion: @escaping () -> Void)
}

extension ProGated where Self: UIViewController {
    func checkProOrShowPaywall(completion: @escaping () -> Void) {
        if IAPManager.shared.isProPlan {
            completion()
        } else {
            // Показати paywall
        }
    }
}
```

## Типові флоу

### Авторизація

```
App Launch
    ↓
SceneDelegate.start()
    ↓
Has seen Onboarding? — No —> OnboardingViewController
    ↓ Yes
Valid Session? — No —> SignInController
    ↓ Yes
MainTabBarController
```

### Створення замовлення

```
OrderListViewController
    ↓ (tap +)
OrderDetailsViewController
    ↓ (select products)
ProductListViewController / OrderReceiptPadViewController
    ↓ (save)
DomainDatabaseService.saveOrder()
    ↓
FirestoreDatabaseService.create()
    ↓
NotificationCenter.post(.ordersInfoReload)
```

### Синхронізація даних

```
ViewController
    ↓
DomainDatabaseService.fetchOrders()
    ↓
FirestoreDatabaseService.read()
    ↓
[FIROrderModel] —map—> [OrderModel]
    ↓
ViewModel update —> View update
```

## Залежності між модулями

```
View Layer
    ↓ (uses)
Services Layer
    ↓ (uses)
Data Layer

View Layer
    ↓ (observes)
NotificationCenter
    ↓ (notifies)
View Layer
```

## Безпека

- **Keychain** — зберігання сесійних даних
- **Biometric Auth** — Face ID / Touch ID для захисту
- **Firebase Auth** — аутентифікація користувачів
- **User-scoped data** — дані ізольовані за користувачем у Firestore

## Firebase Collections

| Collection | Description |
|------------|-------------|
| `users` | Користувачі та їх налаштування |
| `roles` | Ролі та доступи (адмін, технік) |
| `orders` | Замовлення |
| `productOfOrders` | Продукти у замовленнях |
| `productsPrice` | Меню та ціни |
| `ingredients` | Інгредієнти |
| `purchases` | Закупівлі інгредієнтів |
| `opexExpenses` | Операційні витрати |
| `inventoryAdjustments` | Коригування запасів |
| `productCategories` | Категорії продуктів |
