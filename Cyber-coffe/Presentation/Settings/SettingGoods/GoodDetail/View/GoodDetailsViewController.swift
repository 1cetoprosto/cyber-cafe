//
//  GoodDetailsViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.11.2021.
//

import UIKit
import RealmSwift

class GoodDetailsViewController: UIViewController {
    
    let goodLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.text = "Good name:"
        label.textColor = UIColor.Main.text
        label.font = UIFont.systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    let goodTextfield: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .left
        textField.placeholder = "Enter good's name"
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray.cgColor
        textField.layer.cornerRadius = 5
        textField.backgroundColor = UIColor.TableView.cellBackground
        textField.font = UIFont.systemFont(ofSize: 20)
        textField.textColor = UIColor.TableView.cellLabel
        textField.translatesAutoresizingMaskIntoConstraints = false

        return textField
    }()
    
    let priceLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.text = "Price:"
        label.textColor = UIColor.Main.text
        label.font = UIFont.systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()

    let priceTextfield: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .left
        textField.placeholder = "Enter price"
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray.cgColor
        textField.layer.cornerRadius = 5
        textField.backgroundColor = UIColor.TableView.cellBackground
        textField.font = UIFont.systemFont(ofSize: 20)
        textField.textColor = UIColor.TableView.cellLabel
        textField.translatesAutoresizingMaskIntoConstraints = false

        return textField
    }()

    lazy var saveButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: .normal)
        button.setTitleColor(UIColor.Button.title, for: .normal)
        button.backgroundColor = UIColor.Button.background
        button.layer.cornerRadius = 10

        button.addTarget(self, action: #selector(saveAction(param:)), for: .touchUpInside)
        return button
    }()

    lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(UIColor.Button.title, for: .normal)
        button.backgroundColor = UIColor.Button.background
        button.layer.cornerRadius = 10

        button.addTarget(self, action: #selector(cancelAction(param:)), for: .touchUpInside)
        return button
    }()

    var good: String = ""
    var price: Double = 0.0

    let localRealm = try! Realm()
    var goodsModel = GoodsPriceModel()
    var newModel = true

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = "Good"
        
        goodTextfield.text = good
        if price != 0 {
            priceTextfield.text = String(price)
        }

        navigationController?.view.backgroundColor = UIColor.NavBar.background

        setConstraints()
    }

    func setConstraints() {

        let buttonStackView = UIStackView(arrangedSubviews: [saveButton, cancelButton],
                                          axis: .horizontal,
                                          spacing: 20,
                                          distribution: .fillEqually)

        let goodStackView = UIStackView(arrangedSubviews: [goodLabel,
                                                           goodTextfield,
                                                           priceLabel,
                                                           priceTextfield,
                                                           buttonStackView],
                                        axis: .vertical,
                                        spacing: 5,
                                        distribution: .fillEqually)
        view.addSubview(goodStackView)

        NSLayoutConstraint.activate([
            goodStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            goodStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            goodStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            goodStackView.heightAnchor.constraint(equalToConstant: 200)
        ])

    }

    // MARK: - Method
    @objc func saveAction(param: UIButton) {

        good = goodTextfield.text ?? ""
        price = Double(priceTextfield.text ?? "0.0") ?? 0.0

        if newModel {
            goodsModel.good = good
            goodsModel.price = price
            
            if let id = FirestoreDatabase
                .shared
                .create(firModel: FIRGoodsPriceModel(goodsPriceModel: goodsModel), collection: "goodsPrice") {
                goodsModel.id = id
                goodsModel.synchronized = true
            }

            DatabaseManager.shared.saveGoodsPriceModel(model: goodsModel)
            goodsModel = GoodsPriceModel()
        } else {
            
            let synchronized = FirestoreDatabase
                .shared
                .update(firModel: FIRGoodsPriceModel(id: goodsModel.id, good: good, price: price),
                        collection: "goodsPrice", documentId: goodsModel.id)
            
            DatabaseManager.shared.updateGoodsPriceModel(model: goodsModel, good: good, price: price, synchronized: synchronized)
        }

        navigationController?.popViewController(animated: true)
    }

    @objc func cancelAction(param: UIButton) {
        navigationController?.popViewController(animated: true)
    }

}
