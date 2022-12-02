//
//  GoodListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 07.11.2021.
//

import UIKit
import RealmSwift

class GoodListViewController: UIViewController {

    let localRealm = try! Realm()
    var goodsArray: Results<GoodsPriceModel>!
    
    let idGoodsCell = "idGoodsCell"
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
        title = "Goods"
        
        tableView.register(GoodPriceTableViewCell.self, forCellReuseIdentifier: idGoodsCell)
        tableView.dataSource = self
        tableView.delegate = self
        
        // Кнопка справа
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(performAdd(param:)))
        
        setConstraints()
        
    }

    func configure() {
        goodsArray = localRealm.objects(GoodsPriceModel.self).sorted(byKeyPath: "good")
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
        let goodVC = GoodDetailsViewController()
        navigationController?.pushViewController(goodVC, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension GoodListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goodsArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idGoodsCell, for: indexPath) as! GoodPriceTableViewCell
        cell.configure(goodPrice: goodsArray[indexPath.row], indexPath: indexPath)

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = goodsArray[indexPath.row]
        
        let goodVC = GoodDetailsViewController()
        goodVC.goodsModel = model
        goodVC.newModel = false
        goodVC.good = model.good
        goodVC.price = model.price
        navigationController?.pushViewController(goodVC, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let model = goodsArray[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            DatabaseManager.shared.delete(model: model)

            self.configure()

            tableView.reloadData()
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
