//
//  ProductDetailsViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.11.2021.
//

import RealmSwift
import UIKit

class ProductDetailsViewController: UIViewController {

  let productLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.text = R.string.global.productName()
    label.textColor = UIColor.Main.text
    label.font = UIFont.systemFont(ofSize: 20)
    label.translatesAutoresizingMaskIntoConstraints = false

    return label
  }()

  let productTextfield: UITextField = {
    let textField = UITextField()
    textField.textAlignment = .left
    textField.placeholder = R.string.global.enterProductName()
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
    label.text = R.string.global.price()
    label.textColor = UIColor.Main.text
    label.font = UIFont.systemFont(ofSize: 20)
    label.translatesAutoresizingMaskIntoConstraints = false

    return label
  }()

  let priceTextfield: UITextField = {
    let textField = UITextField()
    textField.textAlignment = .left
    textField.placeholder = R.string.global.enterPrice()
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
    button.setTitle(R.string.global.save(), for: .normal)
    button.addTarget(self, action: #selector(saveAction(param:)), for: .touchUpInside)

    return button
  }()

  lazy var cancelButton: UIButton = {
    let button = DefaultButton()
    button.setTitle(R.string.global.cancel(), for: .normal)
    button.addTarget(self, action: #selector(cancelAction(param:)), for: .touchUpInside)

    return button
  }()

  //    var product: String = ""
  //    var price: Double = 0.0
  var productPrice: ProductsPriceModel

  //    let localRealm = try! Realm()
  //    var productsModel = RealmProductsPriceModel()
  //    var newModel = true

  init(productPrice: ProductsPriceModel) {
    self.productPrice = productPrice
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = UIColor.Main.background
    title = R.string.global.product()

    productTextfield.text = productPrice.name
    if productPrice.price != 0 {
      priceTextfield.text = productPrice.price.string
    }

    navigationController?.view.backgroundColor = UIColor.NavBar.background

    setConstraints()
  }

  func setConstraints() {

    let buttonStackView = UIStackView(
      arrangedSubviews: [saveButton, cancelButton],
      axis: .horizontal,
      spacing: 20,
      distribution: .fillEqually)

    let productStackView = UIStackView(
      arrangedSubviews: [
        productLabel,
        productTextfield,
        priceLabel,
        priceTextfield,
        buttonStackView,
      ],
      axis: .vertical,
      spacing: 5,
      distribution: .fillEqually)
    view.addSubview(productStackView)

    NSLayoutConstraint.activate([
      productStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
      productStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      productStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      productStackView.heightAnchor.constraint(equalToConstant: 200),
    ])

  }

  // MARK: - Method
  @objc func saveAction(param: UIButton) {
    guard let name = productTextfield.text, !name.isEmpty else {
      PopupFactory.showPopup(
        title: R.string.global.error(), description: R.string.global.pleaseEnterProductName()
      ) {}
      return
    }

    let price = priceTextfield.text?.double ?? 0.0

    productPrice.name = name
    productPrice.price = price

    if productPrice.id.isEmpty {
      productPrice.id = UUID().uuidString
      DomainDatabaseService.shared.saveProductsPrice(productPrice: productPrice) { success in
        if !success {
          PopupFactory.showPopup(
            title: R.string.global.error(), description: R.string.global.failedToSaveProductPrice()
          ) {}
        }
      }
    } else {
      DomainDatabaseService.shared.updateProductsPrice(
        model: productPrice, name: name, price: price)
    }

    navigationController?.popViewController(animated: true)
  }

  @objc func cancelAction(param: UIButton) {
    navigationController?.popViewController(animated: true)
  }

}
