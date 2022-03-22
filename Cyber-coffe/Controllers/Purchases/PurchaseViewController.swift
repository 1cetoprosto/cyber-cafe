//
//  PurchaseViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 04.12.2021.
//

import UIKit
import RealmSwift

class PurchaseViewController: UIViewController {
    
    let purchaseDateLabel: UILabel = {
        let label = UILabel(text: "Date:", font: UIFont.systemFont(ofSize: 20), aligment: .left)
        
        return label
    }()
    
    let purchasedatePiker: UIDatePicker = {
        let datePiker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        //datePiker.backgroundColor = .red
        datePiker.datePickerMode = .date
        datePiker.contentHorizontalAlignment = .left
        datePiker.preferredDatePickerStyle = .automatic
        
        return datePiker
    }()
    
    let purchaseNameLabel: UILabel = {
        let label = UILabel(text: "Purchase:", font: UIFont.systemFont(ofSize: 20), aligment: .left)
        
        return label
    }()
    
    let purchaseNameTextfield: UITextField = {
        let textField = UITextField(placeholder: "Enter purchase name", font: UIFont.systemFont(ofSize: 28))
        
        return textField
    }()
    
    let purchaseSumLabel: UILabel = {
        let label = UILabel(text: "Sum:", font: UIFont.systemFont(ofSize: 20), aligment: .left)
        
        return label
    }()
    
    let purchaseSumTextfield: UITextField = {
        let textField = UITextField(placeholder: "Enter purchase sum", font: UIFont.systemFont(ofSize: 28))
        
        return textField
    }()
    
    let saveButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: .normal)
        button.setTitleColor(UIColor.Button.title, for: .normal)
        button.backgroundColor = UIColor.Button.background
        button.layer.cornerRadius = 10
        
        button.addTarget(PurchaseViewController.self, action: #selector(saveAction(param:)), for: .touchUpInside)
        return button
    }()
    
    let cancelButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(UIColor.Button.title, for: .normal)
        button.backgroundColor = UIColor.Button.background
        button.layer.cornerRadius = 10
        
        button.addTarget(PurchaseViewController.self, action: #selector(cancelAction(param:)), for: .touchUpInside)
        return button
    }()
    
    let localRealm = try! Realm()
    var purchaseModel = PurchaseModel()
    var newModel = true
    
    var purchaseDate: Date = NSDate() as Date
    var purchaseName: String = ""
    var purchaseSum: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Purchase"
        view.backgroundColor = UIColor.Main.background
        navigationController?.view.backgroundColor = UIColor.NavBar.background
        
        if purchaseName != "" {
            purchaseNameTextfield.text = String(purchaseName)
        }
        if purchaseSum != 0 {
            purchaseSumTextfield.text = String(purchaseSum)
        }
        
        purchasedatePiker.date = purchaseDate
        
        setConstraints()
        
    }
    
    //MARK: - Method
    @objc func saveAction(param: UIButton) {
        purchaseDate = purchasedatePiker.date
        purchaseName = purchaseNameTextfield.text ?? ""
        purchaseSum = Double(purchaseSumTextfield.text ?? "0.0") ?? 0.0
        
        if newModel {
            //запишем наименование и цену
            purchaseModel.purchaseDate = purchaseDate
            purchaseModel.purchaseGood = purchaseName
            purchaseModel.purchaseSum = purchaseSum
            
            RealmManager.shared.savePurchaseModel(model: purchaseModel)
            purchaseModel = PurchaseModel()
        } else {
            RealmManager.shared.updatePurchaseModel(model: purchaseModel, purchaseDate: purchaseDate, purchaseName: purchaseName, purchaseSum: purchaseSum)
        }
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func cancelAction(param: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
}

extension PurchaseViewController {
    func setConstraints() {
        let buttonStackView = UIStackView(arrangedSubviews: [saveButton, cancelButton], axis: .horizontal, spacing: 20, distribution: .fillEqually)
        
        let dateStackView = UIStackView(arrangedSubviews: [purchaseDateLabel, purchasedatePiker], axis: .horizontal, spacing: 20, distribution: .fill)
        
        let purchaseStackView = UIStackView(arrangedSubviews: [dateStackView, purchaseNameLabel, purchaseNameTextfield, purchaseSumLabel, purchaseSumTextfield, buttonStackView], axis: .vertical, spacing: 10, distribution: .fillEqually)
        view.addSubview(purchaseStackView)
        
        NSLayoutConstraint.activate([
            purchaseStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            purchaseStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            purchaseStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            purchaseStackView.heightAnchor.constraint(equalToConstant: 270)
        ])
    }
}
