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

    var type: String = ""

    let localRealm = try! Realm()
    var typesModel = TypeOfDonationModel()
    var newModel = true

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = "Type"
        
        typeTextfield.text = type

        navigationController?.view.backgroundColor = UIColor.NavBar.background

        setConstraints()
    }

    func setConstraints() {

        let buttonStackView = UIStackView(arrangedSubviews: [saveButton, cancelButton],
                                          axis: .horizontal,
                                          spacing: 20,
                                          distribution: .fillEqually)

        let goodStackView = UIStackView(arrangedSubviews: [typeLabel,
                                                           typeTextfield,
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
        
        type = typeTextfield.text ?? ""
        
        if newModel {
            typesModel.type = type
            
            if let id = FIRFirestoreService
                .shared
                .create(firModel: FIRTypeOfDonationModel(typeOfDonationModel: typesModel),
                        collection: "typesOfDonation") {
                typesModel.id = id
                typesModel.synchronized = true
            }
            
            DatabaseManager.shared.saveTypeOfDonationModel(model: typesModel)
            typesModel = TypeOfDonationModel()
        } else {
            
            let typeOfDonationSynchronized = FIRFirestoreService
                .shared
                .update(firModel: FIRTypeOfDonationModel(id: typesModel.id,
                                                         type: type),
                        collection: "typesOfDonation",
                        documentId: typesModel.id)
            
            DatabaseManager
                .shared
                .updateTypeOfDonationModel(model: typesModel,
                                           type: type,
                                           typeOfDonationSynchronized: typeOfDonationSynchronized)
        }
        
        navigationController?.popViewController(animated: true)
    }

    @objc func cancelAction(param: UIButton) {
        navigationController?.popViewController(animated: true)
    }

}

