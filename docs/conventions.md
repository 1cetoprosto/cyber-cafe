# Code Style & Conventions

## Загальні правила

### Мова та локалізація

- **Код та коментарі**: англійська мова
- **Пояснення для користувача**: українська мова
- **Підтримувані мови**: українська, англійська (Localizable.strings)

### Swift Style Guide

Використовуйте [Apple Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

#### Іменування

```swift
// Типи — PascalCase
struct OrderModel { }
class OrderListViewModel { }
protocol OrderListViewModelType { }
enum OrderStatus { case pending, completed }

// Змінні та функції — camelCase
let orderCount = 0
func fetchOrders() { }
func saveOrder(order: OrderModel) { }

// Константи — camelCase або UPPER_SNAKE_CASE
let maxRetryCount = 3
let API_BASE_URL = "https://..."
```

#### Класи та структури

```swift
// Використовуйте final для класів, які не плануються успадковувати
final class OrderListViewController: UIViewController {
    // ...
}

// Протоколи з суфіксом Type
protocol ViewModelType { }
protocol CellViewModelType { }

// Для ViewModel використовуйте суфікс ViewModel
class OrderListViewModel: OrderListViewModelType { }
```

## Структура проєкту

### Організація файлів

```
TrackMyCafe/
├── Application/              # AppDelegate, SceneDelegate
├── Configuration/            # Конфігурації середовищ
├── Data Layer/               # Моделі та робота з даними
│   ├── Models/
│   │   ├── Domain/           # Domain моделі
│   │   ├── Firestore/        # Firebase DTO
│   │   └── Realm/            # Realm моделі
│   ├── Service/              # Сервіси зберігання
│   └── Utils/                # Утиліти
├── Services/                 # Бізнес-логіка
│   ├── Domain/               # Domain сервіси
│   ├── FIR/                  # Firebase сервіси
│   └── Realm/                # Realm сервіси
├── View Layer/               # UI шар
│   ├── Flow/                 # Екрани
│   │   └── {Feature}/
│   │       ├── View/         # ViewControllers
│   │       ├── ViewModel/    # ViewModels
│   │       └── Model/        # Feature-specific models
│   └── UI/                   # Універсальні UI компоненти
├── Extensions/               # Swift extensions
├── Utilities/                # Допоміжні утиліти
└── Resources/                # Ресурси
```

### Наймінг файлів

```
OrderListViewController.swift      # View Controller
OrderListViewModel.swift           # ViewModel
OrderListViewModelType.swift       # ViewModel Protocol
OrderListItemViewModel.swift       # Cell ViewModel
OrdersTableViewCell.swift          # UITableViewCell
OrderModel.swift                   # Domain Model
FIROrderModel.swift                # Firestore Model
RealmOrderModel.swift              # Realm Model
```

## UIKit правила

### Програмна верстка

**Заборонено**: Storyboard, XIB. Все UI створюється кодом.

```swift
final class OrderListViewController: UIViewController {
    
    // MARK: - UI Components
    
    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(OrdersTableViewCell.self, forCellReuseIdentifier: OrdersTableViewCell.identifier)
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorColor = UIColor.TableView.separator
        return tableView
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.addTarget(self, action: #selector(performAdd), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setConstraints()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.Main.background
        view.addSubview(tableView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addButton)
    }
    
    private func setConstraints() {
        tableView.edgesToSuperview()
    }
}
```

### Auto Layout

Використовуйте **TinyConstraints** для спрощення коду:

```swift
// Добре
view.edgesToSuperview()
button.centerInSuperview()
label.topToSuperview(offset: 16)
label.leadingToSuperview(offset: 16)
label.trailingToSuperview(offset: -16)

// Або NSLayoutAnchor
label.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    label.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
    label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
])
```

### Кольори та теми

```swift
// Використовуйте обгорнуті кольори
view.backgroundColor = UIColor.Main.background
tableView.separatorColor = UIColor.TableView.separator
button.tintColor = UIColor.Button.primary

// Не хардкодьте кольори
view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0) // Погано
```

## Асинхронний код

### Completion Handlers

```swift
func fetchOrders(completion: @escaping ([OrderModel]) -> Void) {
    FirestoreDatabaseService.shared.read(...) { result in
        switch result {
        case .success(let orders):
            completion(orders)
        case .failure(let error):
            self.logger.error("Error: \(error)")
            completion([])
        }
    }
}

// Виклик
fetchOrders { [weak self] orders in
    self?.orders = orders
    self?.tableView.reloadData()
}
```

### async/await

```swift
// Для нового коду віддайте перевагу async/await
func fetchOrders() async throws -> [OrderModel] {
    try await withCheckedThrowingContinuation { continuation in
        fetchOrders { orders in
            continuation.resume(returning: orders)
        }
    }
}

// Виклик
Task {
    do {
        let orders = try await fetchOrders()
        self.orders = orders
    } catch {
        logger.error("Error: \(error)")
    }
}
```

## Безпека та надійність

### Optional Handling

```swift
// Уникайте force unwrap
// Погано:
let id = order.id! 

// Добре:
let id = order.id ?? ""

// Або guard
 guard let id = order.id else { return }
```

### Слабкі посилання

```swift
// Завди все замикання слабкі посилання
fetchOrders { [weak self] orders in
    self?.orders = orders
}

// У класах з замиканнями використовуйте weak self
class OrderListViewController: UIViewController {
    private var viewModel: OrderListViewModelType?
}
```

## Логування

```swift
import os.log

class OrderListViewModel: Loggable {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!, 
        category: "OrderListViewModel"
    )
    
    func fetchOrders() {
        logger.info("Fetching orders...")
        logger.error("Failed to fetch: \(error.localizedDescription)")
    }
}
```

## Коментарі

```swift
// MARK: - Заголовок розділу

// MARK: - Properties

// MARK: - UI Components

// MARK: - Lifecycle

// MARK: - Setup

// MARK: - Actions

// MARK: - Private Methods

// MARK: - UITableViewDataSource
```

## Тестування

### Підход до тестування

- Тестуйте business logic у ViewModel
- Тестуйте data transformation
- Мокайте залежності через протоколи

### Приклад тесту

```swift
import XCTest
@testable import TrackMyCafe

final class OrderListViewModelTests: XCTestCase {
    
    var sut: OrderListViewModel!
    var mockService: MockDomainDatabaseService!
    
    override func setUp() {
        super.setUp()
        mockService = MockDomainDatabaseService()
        sut = OrderListViewModel(service: mockService)
    }
    
    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }
    
    func testFetchOrders() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch orders")
        mockService.stubOrders = [OrderModel.mock]
        
        // When
        sut.getOrders {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.numberOfSections(), 1)
    }
}
```

## Заборонені речі

- **Не використовуйте** Storyboard/XIB
- **Не використовуйте** SwiftUI для нових екранів
- **Не використовуйте** force unwrap (`!`)
- **Не використовуйте** implicitly unwrapped optionals
- **Не додавайте** залежностей без погодження з власником проєкту

## Перевірка якості коду

### Перед комітом

1. Код компілюється без попереждень
2. Відсутні попереждення в консолі
3. Код відповідає цьому style guide
4. Автотести проходять (if applicable)
