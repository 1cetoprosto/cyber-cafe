//
//  ProductListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 07.11.2021.
//

import RealmSwift
import UIKit

class ProductListViewController: UIViewController, Loggable {

  //let localRealm = try! Realm()
  //var productsArray: Results<RealmProductsPriceModel>!
  var productsPrice = [ProductsPriceModel]()

  let tableView: UITableView = {
    let tableView = UITableView()
    tableView.backgroundColor = UIColor.Main.background
    tableView.separatorStyle = .none
    tableView.translatesAutoresizingMaskIntoConstraints = false

    return tableView
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

    // Кнопка справа
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .add,
      target: self,
      action: #selector(performAdd(param:)))

    setConstraints()

  }

  func configure() {
    DomainDatabaseService.shared.fetchProductsPrice { productsPrice in
      self.productsPrice = productsPrice
      self.tableView.reloadData()
    }
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

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 50
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
