//
//  TypeDetailsViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import UIKit
import RealmSwift

class IncomeTypeDetailsViewController: UIViewController {
    
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

    var incomeType: IncomeTypeModel
    
    init(incomeType: IncomeTypeModel) {
        self.incomeType = incomeType
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.Main.background
        title = "Type"
        
        typeTextfield.text = incomeType.name

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
        
        guard let name = typeTextfield.text else { //, !type.isEmpty
            // Handle case when type is empty
            return
        }
        
        DomainDatabaseService.shared.saveIncomeType(incomeType: IncomeTypeModel(id: "", name: name)) { success in
            if success {
                print("IncomeType saved successfully")
            } else {
                print("Failed to save IncomeType")
            }
        }
        
//        let incomeType = FIRIncomeTypeModel(dataModel: IncomeTypeModel(id: "", name: type))
//        
//        if let documentId = FirestoreDatabaseService.shared.createIncomeType(incomeType: incomeType) {
//                print("Income type created with document ID: \(documentId)")
//                navigationController?.popViewController(animated: true)
//            } else {
//                print("Failed to create income type")
//                // Handle error if necessary
//            }
        
        navigationController?.popViewController(animated: true)
    }

    @objc func cancelAction(param: UIButton) {
        navigationController?.popViewController(animated: true)
    }

}

