//
//  TypeDetailsViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import RealmSwift
import UIKit

class TypeDetailsViewController: UIViewController {

  let typeLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .left
    label.text = R.string.global.type()
    label.textColor = UIColor.Main.text
    label.applyDynamic(Typography.footnote)
    label.translatesAutoresizingMaskIntoConstraints = false

    return label
  }()

  let typeTextfield: UITextField = {
    let textField = UITextField()
    textField.textAlignment = .left
    textField.placeholder = R.string.global.enterTypeName()
      textField.layer.borderWidth = UIConstants.standardBorderWidth
      textField.layer.borderColor = UIColor.TableView.cellBackground.cgColor
    textField.layer.cornerRadius = UIConstants.smallCornerRadius
    textField.backgroundColor = UIColor.TableView.cellBackground
    textField.font = Typography.title3
    textField.textColor = UIColor.TableView.cellLabel
    if #available(iOS 11.0, *) { textField.adjustsFontForContentSizeCategory = true }
    textField.translatesAutoresizingMaskIntoConstraints = false

    return textField
  }()

  lazy var saveButton: UIButton = {
    let button = DefaultButton()
    button.setTitle(R.string.global.save(), for: .normal)
    button.addTarget(self, action: #selector(saveAction(param:)), for: .touchUpInside)

    return button
  }()

  var type: TypeModel

  init(type: TypeModel) {
    self.type = type
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = UIColor.Main.background
    title = R.string.global.type()

    typeTextfield.text = type.name

    navigationController?.view.backgroundColor = UIColor.NavBar.background

    setConstraints()
  }

  func setConstraints() {

    let buttonStackView = UIStackView(
      arrangedSubviews: [saveButton],
      axis: .horizontal,
      spacing: 20,
      distribution: .fillEqually)

    let productStackView = UIStackView(
      arrangedSubviews: [
        typeLabel,
        typeTextfield,
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
      productStackView.heightAnchor.constraint(equalToConstant: 120),
    ])

  }

  // MARK: - Method
  @objc func saveAction(param: UIButton) {
    guard let name = typeTextfield.text, !name.isEmpty else {
      PopupFactory.showPopup(
        title: R.string.global.error(), description: R.string.global.pleaseEnterTypeName()
      ) {}
      return
    }

    type.name = name
    if type.id.isEmpty {
      type.id = UUID().uuidString
      DomainDatabaseService.shared.saveType(model: type) { success in
        if !success {
          PopupFactory.showPopup(
            title: R.string.global.error(), description: R.string.global.failedToSaveType()
          ) {}
        }
      }
    } else {
      DomainDatabaseService.shared.updateType(model: type, type: name)
    }

    navigationController?.popViewController(animated: true)
  }

  @objc func cancelAction(param: UIButton) {
    navigationController?.popViewController(animated: true)
  }

}
