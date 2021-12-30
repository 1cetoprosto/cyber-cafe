//
//  GoodsViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 07.11.2021.
//

import UIKit
import RealmSwift

struct GoodPrice {
    let good: String
    let price: Double
    let handler: (() -> Void)
}

class GoodsViewController: UIViewController {

    let localRealm = try! Realm()
    var goods: Results<GoodsPriceModel>!
    var goodsArray = [GoodPrice]()
    
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
        
        //configure()
        //Кнопка справа
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(performAdd(param:)))
        
        setConstraints()
        
    }
    
    func configure() {
        goodsArray = [GoodPrice]()
        goods = localRealm.objects(GoodsPriceModel.self).sorted(byKeyPath: "good")
        for good in goods {
            goodsArray.append(GoodPrice(good: good.good, price: good.price) { self.navigationController?.pushViewController(GoodViewController(), animated: true) })
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
        let goodVC = GoodViewController()
        navigationController?.pushViewController(goodVC, animated: true)
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource
extension GoodsViewController: UITableViewDelegate, UITableViewDataSource {
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
        let goodPrice = goodsArray[indexPath.row]
        
        let goodVC = GoodViewController()
        goodVC.good = goodPrice.good
        goodVC.price = goodPrice.price
        navigationController?.pushViewController(goodVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editingRow = goods[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completionHandler in
            RealmManager.shared.deleteGoodsPriceModel(model: editingRow)
            
            self.configure()
            
            tableView.reloadData()
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
