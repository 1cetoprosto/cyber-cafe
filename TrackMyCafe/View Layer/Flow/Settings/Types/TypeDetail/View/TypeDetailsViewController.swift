//
//  TypeDetailsViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import UIKit
import RealmSwift

class TypeDetailsViewController: UIViewController {
    
    let typeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.text = "Type:"
        label.textColor = UIColor.Main.text
        label.font = UIFont.systemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    let typeTextfield: UITextField = {
        let textField = UITextField()
        textField.textAlignment = .left
        textField.placeholder = "Enter type's name"
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
        title = "Type"
        
        typeTextfield.text = type.name

        navigationController?.view.backgroundColor = UIColor.NavBar.background

        setConstraints()
    }

    func setConstraints() {

        let buttonStackView = UIStackView(arrangedSubviews: [saveButton, cancelButton],
                                          axis: .horizontal,
                                          spacing: 20,
                                          distribution: .fillEqually)

        let productStackView = UIStackView(arrangedSubviews: [typeLabel,
                                                           typeTextfield,
                                                           buttonStackView],
                                        axis: .vertical,
                                        spacing: 5,
                                        distribution: .fillEqually)
        view.addSubview(productStackView)

        NSLayoutConstraint.activate([
            productStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            productStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            productStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            productStackView.heightAnchor.constraint(equalToConstant: 120)
        ])

    }

    // MARK: - Method
    @objc func saveAction(param: UIButton) {
        guard let name = typeTextfield.text, !name.isEmpty else {
            PopupFactory.showPopup(title: "Помилка", description: "Будь ласка, введіть назву надходження") { }
            return
        }
        
        type.name = name
        if type.id.isEmpty {
            type.id = UUID().uuidString
            DomainDatabaseService.shared.saveType(model: type) { success in
                if !success {
                    PopupFactory.showPopup(title: "Помилка", description: "Failed to save Type") { }
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

