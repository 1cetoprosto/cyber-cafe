//
//  PurchaseDetailsListViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 04.12.2021.
//

import UIKit

class PurchaseDetailsListViewController: UIViewController {
    
    var viewModel: PurchaseDetailsViewModelType?
    
    let purchaseDateLabel: UILabel = {
        let label = UILabel(text: "Date:", font: UIFont.systemFont(ofSize: 20), aligment: .left)
        
        return label
    }()
    
    let purchasedatePiker: UIDatePicker = {
        let datePiker = UIDatePicker(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
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
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        setData()
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Purchase"
        view.backgroundColor = UIColor.Main.background
        navigationController?.view.backgroundColor = UIColor.NavBar.background
        
        setData()
        
        setConstraints()
        
    }

    // MARK: - Method
    fileprivate func setData() {
        if viewModel == nil {
            viewModel = PurchaseDetailsViewModel(purchase: PurchaseModel())
        }
        
        guard let viewModel = viewModel else { return }
        if viewModel.purchaseName != "" {
            purchaseNameTextfield.text = viewModel.purchaseName
        }
        if viewModel.purchaseSum != "" {
            purchaseSumTextfield.text = viewModel.purchaseSum
        }
        
        purchasedatePiker.date = viewModel.purchaseDate
    }
    
    @objc func saveAction(param: UIButton) {
        viewModel?.savePurchaseModel(purchaseDate: purchasedatePiker.date, purchaseName: purchaseNameTextfield.text, purchaseSum: purchaseSumTextfield.text)
        navigationController?.popToRootViewController(animated: true)
    }

    @objc func cancelAction(param: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - Constraints
extension PurchaseDetailsListViewController {
    func setConstraints() {
        let buttonStackView = UIStackView(arrangedSubviews: [saveButton, cancelButton],
                                          axis: .horizontal,
                                          spacing: 20,
                                          distribution: .fillEqually)

        let dateStackView = UIStackView(arrangedSubviews: [purchaseDateLabel, purchasedatePiker],
                                        axis: .horizontal,
                                        spacing: 20,
                                        distribution: .fill)

        let purchaseStackView = UIStackView(arrangedSubviews: [dateStackView,
                                                               purchaseNameLabel,
                                                               purchaseNameTextfield,
                                                               purchaseSumLabel,
                                                               purchaseSumTextfield,
                                                               buttonStackView],
                                            axis: .vertical,
                                            spacing: 10,
                                            distribution: .fillEqually)
        view.addSubview(purchaseStackView)

        NSLayoutConstraint.activate([
            purchaseStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            purchaseStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            purchaseStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            purchaseStackView.heightAnchor.constraint(equalToConstant: 270)
        ])
    }
}
