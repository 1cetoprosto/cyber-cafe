//
//  SalesViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 03.11.2021.
//

import UIKit

class SalesViewController: UIViewController {

    let idSalesCell = "idSalesCell"
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(SalesTableViewCell.self, forCellReuseIdentifier: idSalesCell)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = "Продажи"
        
        
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
    @objc func performAdd(param: UIBarButtonItem) {
        let saleVC = SaleViewController()
        navigationController?.pushViewController(saleVC, animated: true)
    }
    
}

//MARK: - UITableViewDelegate, UITableViewDataSource
extension SalesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 25
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idSalesCell, for: indexPath) as! SalesTableViewCell
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //let selectedDay = days[indexPath.row]
        
        let saleVC = SaleViewController()
        self.navigationController?.pushViewController(saleVC, animated: true)
    }
}
