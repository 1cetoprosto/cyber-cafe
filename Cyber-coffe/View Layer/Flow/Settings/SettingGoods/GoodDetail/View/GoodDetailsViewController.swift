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
        let button = DefaultButton()
        button.setTitle("Save", for: .normal)
        button.addTarget(self, action: #selector(saveAction(param:)), for: .touchUpInside)

        return button
    }()

    lazy var cancelButton: UIButton = {
        let button = DefaultButton()
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(cancelAction(param:)), for: .touchUpInside)

        return button
    }()

//    var good: String = ""
//    var price: Double = 0.0
    var goodPrice: GoodsPriceModel

//    let localRealm = try! Realm()
//    var goodsModel = RealmGoodsPriceModel()
//    var newModel = true

    init(goodPrice: GoodsPriceModel) {
        self.goodPrice = goodPrice
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = "Good"
        
        goodTextfield.text = goodPrice.name
        if goodPrice.price != 0 {
            priceTextfield.text = goodPrice.price.string
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
        guard let name = goodTextfield.text, !name.isEmpty else {
            PopupFactory.showPopup(title: "Помилка", description: "Будь ласка, введіть назву товару") { }
            return
        }
        
        let price = priceTextfield.text?.double ?? 0.0
        
        goodPrice.name = name
        goodPrice.price = price
        
        if goodPrice.id.isEmpty {
            goodPrice.id = UUID().uuidString
            DomainDatabaseService.shared.saveGoodsPrice(goodPrice: goodPrice) { success in
                if !success {
                    PopupFactory.showPopup(title: "Помилка", description: "Не вдалось записати goodPrice") { }
                }
            }
        } else {
            DomainDatabaseService.shared.updateGoodsPrice(model: goodPrice, name: name, price: price)
        }
        
        navigationController?.popViewController(animated: true)
    }

    @objc func cancelAction(param: UIButton) {
        navigationController?.popViewController(animated: true)
    }

}