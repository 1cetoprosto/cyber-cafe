//
//  SalesViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 03.11.2021.
//

import UIKit
import RealmSwift

class SalesViewController: UIViewController {

    let localRealm = try! Realm()
    var sales: Results<SalesModel>!
    
    let idSalesCell = "idSalesCell"
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = "Sales"
        
        tableView.register(SalesTableViewCell.self, forCellReuseIdentifier: idSalesCell)
        tableView.dataSource = self
        tableView.delegate = self
        
        configure()
        
        //Кнопка справа
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(performAdd(param:)))
        
        setConstraints()
        
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
    func configure() {
        //sales = localRealm.objects(SalesModel.self).filter(predicateDate).sorted(byKeyPath: "salesDate")
        sales = localRealm.objects(SalesModel.self).sorted(byKeyPath: "salesDate")
        tableView.reloadData()
    }
    
    @objc func performAdd(param: UIBarButtonItem) {
        let saleVC = SaleViewController()
        navigationController?.pushViewController(saleVC, animated: true)
    }
    
}

//MARK: - UITableViewDelegate, UITableViewDataSource
extension SalesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sales.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idSalesCell, for: indexPath) as! SalesTableViewCell
        cell.configure(sale: sales[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let selectedDay = days[indexPath.row]
        
        let saleVC = SaleViewController()
        saleVC.forDate = sales[indexPath.row].salesDate
        self.navigationController?.pushViewController(saleVC, animated: true)
    }
}
