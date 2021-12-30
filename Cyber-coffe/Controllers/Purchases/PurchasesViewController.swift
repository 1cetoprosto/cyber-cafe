//
//  PurchasesViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 03.11.2021.
//

import UIKit
import RealmSwift

struct Purchase {
    let date: Date
    let good: String
    let sum: Double
    let handler: (() -> Void)
}

class PurchasesViewController: UIViewController {

    let localRealm = try! Realm()
    var purchases: Results<PurchaseModel>!
    var purchasesArray = [Purchase]()
    
    let idPurchasesCell = "idPurchasesCell"
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
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = "Purchases"
        
        tableView.register(PurchasesTableViewCell.self, forCellReuseIdentifier: idPurchasesCell)
        tableView.dataSource = self
        tableView.delegate = self
        
        //Кнопка справа
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(performAdd(param:)))
        
        setConstraints()
        
    }
    
    func configure() {
        purchasesArray = [Purchase]()
        purchases = localRealm.objects(PurchaseModel.self).sorted(byKeyPath: "purchaseDate")
        for purchase in purchases {
            purchasesArray.append(Purchase(date: purchase.purchaseDate, good: purchase.purchaseGood, sum: purchase.purchaseSum) { self.navigationController?.pushViewController(PurchaseViewController(), animated: true) })
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
    
    //MARK: - Method
    @objc func performAdd(param: UIBarButtonItem) {
        let purchaseVC = PurchaseViewController()
        navigationController?.pushViewController(purchaseVC, animated: true)
    }
    
}

//MARK: - UITableViewDelegate, UITableViewDataSource
extension PurchasesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return purchasesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idPurchasesCell, for: indexPath) as! PurchasesTableViewCell
        cell.configure(purchase: purchasesArray[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let purchaseVC = PurchaseViewController()
        
        let editingRow = purchasesArray[indexPath.row]
        purchaseVC.purchaseDate = editingRow.date
        purchaseVC.purchaseName = editingRow.good
        purchaseVC.purchaseSum = editingRow.sum
        
        self.navigationController?.pushViewController(purchaseVC, animated: true)
    }
}

