//
//  PurchasesViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 03.11.2021.
//

import UIKit
import RealmSwift

class PurchasesViewController: UIViewController {

    let idPurchasesCell = "idPurchasesCell"
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()

    let localRealm = try! Realm()
    var purchasesArray: Results<PurchaseModel>!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configure()
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = "Purchases"
        
        tableView.register(PurchasesTableViewCell.self, forCellReuseIdentifier: idPurchasesCell)
        tableView.dataSource = self
        tableView.delegate = self
        
        // Кнопка справа
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(performAdd(param:)))
        
        setConstraints()
        
    }

    func configure() {
        purchasesArray = localRealm.objects(PurchaseModel.self).sorted(byKeyPath: "purchaseDate")
    }
    
    // MARK: - Method
    @objc func performAdd(param: UIBarButtonItem) {
        let purchaseVC = PurchaseViewController()
        navigationController?.pushViewController(purchaseVC, animated: true)
    }

}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension PurchasesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return purchasesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idPurchasesCell,
                                                 for: indexPath) as! PurchasesTableViewCell
        cell.configure(purchase: purchasesArray[indexPath.row])

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let purchaseVC = PurchaseViewController()
        
        let model = purchasesArray[indexPath.row]
        purchaseVC.purchaseModel = model
        purchaseVC.newModel = false
        purchaseVC.purchaseDate = model.purchaseDate
        purchaseVC.purchaseName = model.purchaseGood
        purchaseVC.purchaseSum = model.purchaseSum

        self.navigationController?.pushViewController(purchaseVC, animated: true)
    }
}

// MARK: setConstraints
extension PurchasesViewController {
    func setConstraints() {

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])

    }
}
