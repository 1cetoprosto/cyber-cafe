//
//  ProductListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 07.11.2021.
//

import RealmSwift
import UIKit

enum ProductSortOrder: String {
    case none = "none"
    case nameAscending = "name_asc"
    case nameDescending = "name_desc"
}

class ProductListViewController: UIViewController, Loggable {

    //let localRealm = try! Realm()
    //var productsArray: Results<RealmProductsPriceModel>!
    var productsPrice = [ProductsPriceModel]()
    private var currentSortOrder: ProductSortOrder = .none
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        tableView.rowHeight = 44
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.addTarget(self, action: #selector(performAdd(param:)), for: .touchUpInside)
        button.accessibilityIdentifier = "navBarAddProduct"
        return button
    }()

    private lazy var sortButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.up.arrow.down"), for: .normal)
        button.addTarget(self, action: #selector(showSortOptions), for: .touchUpInside)
        button.accessibilityIdentifier = "navBarSortProduct"
        return button
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configure()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = R.string.global.products()

        tableView.register(ProductPriceTableViewCell.self, forCellReuseIdentifier: CellIdentifiers.productsCell)
        tableView.dataSource = self
        tableView.delegate = self

        let addBarButton = UIBarButtonItem(customView: addButton)
        let sortBarButton = UIBarButtonItem(customView: sortButton)
        navigationItem.rightBarButtonItems = [addBarButton, sortBarButton]

        loadSavedSortOrder()
        setConstraints()

    }
    
    func configure() {
        DomainDatabaseService.shared.fetchProductsPrice { productsPrice in
            self.productsPrice = productsPrice
            self.applySort()
            self.tableView.reloadData()
        }
    }

    private func loadSavedSortOrder() {
        if let savedOrder = UserDefaults.standard.string(forKey: "productSortOrder"),
           let order = ProductSortOrder(rawValue: savedOrder) {
            currentSortOrder = order
        }
    }

    private func saveSortOrder() {
        UserDefaults.standard.set(currentSortOrder.rawValue, forKey: "productSortOrder")
    }

    private func applySort() {
        switch currentSortOrder {
        case .nameAscending:
            productsPrice.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            productsPrice.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .none:
            break
        }
    }

    private func updateSortIcon() {
        let iconName: String
        switch currentSortOrder {
        case .nameAscending:
            iconName = "arrow.up"
        case .nameDescending:
            iconName = "arrow.down"
        case .none:
            iconName = "arrow.up.arrow.down"
        }
        sortButton.setImage(UIImage(systemName: iconName), for: .normal)
    }

    @objc private func showSortOptions() {
        let alert = UIAlertController(title: R.string.global.sortBy(), message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: R.string.global.nameAZ(), style: .default) { [weak self] _ in
            self?.currentSortOrder = .nameAscending
            self?.saveSortOrder()
            self?.applySort()
            self?.updateSortIcon()
            self?.tableView.reloadData()
        })

        alert.addAction(UIAlertAction(title: R.string.global.nameZA(), style: .default) { [weak self] _ in
            self?.currentSortOrder = .nameDescending
            self?.saveSortOrder()
            self?.applySort()
            self?.updateSortIcon()
            self?.tableView.reloadData()
        })

        alert.addAction(UIAlertAction(title: R.string.global.cancel(), style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.last
        }

        present(alert, animated: true)
    }
    
    func setConstraints() {
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])
        
    }
    
    // MARK: - Method
    @objc func performAdd(param: UIBarButtonItem) {
        let model = ProductsPriceModel(id: "", name: "", price: 0.0)
        let vm = ProductDetailsViewModel(model: model, dataService: DomainProductPriceDataService())
        let productVC = ProductDetailsViewController(viewModel: vm)
        navigationController?.pushViewController(productVC, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ProductListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productsPrice.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.productsCell, for: indexPath)
        as! ProductPriceTableViewCell
        cell.configure(productPrice: productsPrice[indexPath.row], indexPath: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = productsPrice[indexPath.row]
        
        let vm = ProductDetailsViewModel(model: model, dataService: DomainProductPriceDataService())
        let productVC = ProductDetailsViewController(viewModel: vm)
        navigationController?.pushViewController(productVC, animated: true)
    }
    
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let model = productsPrice[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: R.string.global.delete()) {
            _, _, _ in
            DomainDatabaseService.shared.deleteProductsPrice(model: model) { [self] success in
                if success {
                    logger.notice("productsPrice type \(model.id) deleted successfully")
                    self.configure()
                    
                    tableView.reloadData()
                } else {
                    logger.error("Failed to delete productsPrice \(model.id)")
                }
            }
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
