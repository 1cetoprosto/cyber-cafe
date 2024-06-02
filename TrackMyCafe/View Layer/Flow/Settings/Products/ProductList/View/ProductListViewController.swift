//
//  ProductListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 07.11.2021.
//

import UIKit
import RealmSwift

class ProductListViewController: UIViewController {

    //let localRealm = try! Realm()
    //var productsArray: Results<RealmProductsPriceModel>!
    var productsPrice = [ProductsPriceModel]()
    
    let idProductsCell = "idProductsCell"
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
        title = "Products"
        
        tableView.register(ProductPriceTableViewCell.self, forCellReuseIdentifier: idProductsCell)
        tableView.dataSource = self
        tableView.delegate = self
        
        // Кнопка справа
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
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
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])

    }
    
    // MARK: - Method
    @objc func performAdd(param: UIBarButtonItem) {
        let productVC = ProductDetailsViewController(productPrice: ProductsPriceModel(id: "", name: "", price: 0.0))
        navigationController?.pushViewController(productVC, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ProductListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productsPrice.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idProductsCell, for: indexPath) as! ProductPriceTableViewCell
        cell.configure(productPrice: productsPrice[indexPath.row], indexPath: indexPath)

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = productsPrice[indexPath.row]
        
        let productVC = ProductDetailsViewController(productPrice: model)
        productVC.productPrice = model
        navigationController?.pushViewController(productVC, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let model = productsPrice[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            DomainDatabaseService.shared.deleteProductsPrice(model: model) { success in
                if success {
                    print("productsPrice type deleted successfully")
                    self.configure()
                    
                    tableView.reloadData()
                } else {
                    print("Failed to delete productsPrice")
                }
            }
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
