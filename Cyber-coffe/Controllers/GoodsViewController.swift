//
//  GoodsViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 07.11.2021.
//

import UIKit

struct GoodPrice {
    let good: String
    let price: Double
    let handler: (() -> Void)
}

class GoodsViewController: UIViewController {

    let idGoodsCell = "idGoodsCell"
    lazy private var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(GoodPriceTableViewCell.self, forCellReuseIdentifier: idGoodsCell)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        
        return tableView
    }()
    
    var goodsArray = [GoodPrice]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = "Goods"
        
        //Кнопка справа
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(performAdd(param:)))
        
        setConstraints()
        
    }
    
    func configure() {
        goodsArray.append(GoodPrice(good: "Espresso", price: 10) { self.navigationController?.pushViewController(GoodViewController(), animated: true) })
        goodsArray.append(GoodPrice(good: "Amerecano", price: 10) { self.navigationController?.pushViewController(GoodViewController(), animated: true) })
        goodsArray.append(GoodPrice(good: "Amerecano with milk", price: 10) { self.navigationController?.pushViewController(GoodViewController(), animated: true) })
        goodsArray.append(GoodPrice(good: "Capuchino", price: 10) { self.navigationController?.pushViewController(GoodViewController(), animated: true) })
        goodsArray.append(GoodPrice(good: "Ayrish", price: 10) { self.navigationController?.pushViewController(GoodViewController(), animated: true) })
        goodsArray.append(GoodPrice(good: "Latte", price: 20) { self.navigationController?.pushViewController(GoodViewController(), animated: true) })
        goodsArray.append(GoodPrice(good: "Cacao", price: 10) { self.navigationController?.pushViewController(GoodViewController(), animated: true) })
        goodsArray.append(GoodPrice(good: "Hot chocolad", price: 10) { self.navigationController?.pushViewController(GoodViewController(), animated: true) })
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
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idGoodsCell, for: indexPath) as! GoodPriceTableViewCell
        cell.configure(indexPath: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        <#code#>
//    }
    
}
