//
//  SaleViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 08.11.2021.
//

import UIKit

class SaleViewController: UIViewController {
    
    let datePiker: UIDatePicker = {
        let datePiker = UIDatePicker(frame: CGRect(x: 0, y: 70, width: 100, height: 50))
        //datePiker.backgroundColor = .red
        datePiker.datePickerMode = .date
        datePiker.contentHorizontalAlignment = .center
        
        return datePiker
    }()
    
    let idSaleCell = "idSaleCell"
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(SaleTableViewCell.self, forCellReuseIdentifier: idSaleCell)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        
        return tableView
    }()
    
    let moneyLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.text = "Money:"
        label.textColor = UIColor.Main.text
        //label.backgroundColor = .red
        label.font = UIFont.systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    let moneyTextfield: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .left
        textField.placeholder = "0"
        //textField.layer.borderWidth = 1
        //textField.text = "0"
        //textField.backgroundColor = .orange
        textField.font = UIFont.systemFont(ofSize: 28)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        return textField
    }()
    
    let saleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.text = "240"
        label.textColor = UIColor.Main.text
        //label.backgroundColor = .green
        label.font = UIFont.systemFont(ofSize: 28)
        label.translatesAutoresizingMaskIntoConstraints = false
        //label.sizeToFit()//If required
        
        return label
    }()
    
    let saveButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: .normal)
        button.titleLabel?.textColor = .red //UIColor.Button.title
        button.backgroundColor = UIColor.Button.background
        button.layer.cornerRadius = 10

        button.addTarget(self, action: #selector(saveAction(param:)), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Продажа"
        view.backgroundColor = UIColor.Main.background
        
        setConstraints()
        
    }
    
    func setConstraints() {
        
        let cashStackView = UIStackView(arrangedSubviews: [moneyLabel, moneyTextfield], axis: .horizontal, spacing: 5, distribution: .fillEqually)
        view.addSubview(cashStackView)
        
//        NSLayoutConstraint.activate([
//            cashStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            cashStackView.widthAnchor.constraint(equalToConstant: view.frame.width/2),
//            cashStackView.heightAnchor.constraint(equalToConstant: 44),
//        ])
        
        let moneyStackView = UIStackView(arrangedSubviews: [cashStackView, saleLabel], axis: .horizontal, spacing: 10, distribution: .fillEqually)
        view.addSubview(moneyStackView)
        
//        NSLayoutConstraint.activate([
//            moneyStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            moneyStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20),
//            moneyStackView.heightAnchor.constraint(equalToConstant: 44),
//        ])
        
        NSLayoutConstraint.activate([
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        let mainStackView = UIStackView(arrangedSubviews: [datePiker, tableView, moneyStackView, saveButton], axis: .vertical, spacing: 10, distribution: .fill)
        view.addSubview(mainStackView)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            mainStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            mainStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        ])
    }
    
    //MARK: - Method
    @objc func saveAction(param: UIButton) {
        print("save")
    }
    
    @objc func cancelAction(param: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
}

//MARK: - UITableViewDelegate, UITableViewDataSource
extension SaleViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: idSaleCell, for: indexPath) as! SaleTableViewCell
        cell.configure(indexPath: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
}
