//
//  ForgotPassController.swift
//  DTLab
//
//  Created by Alexander Momotiuk on 26.07.2020.
//  Copyright © 2020 DTLab. All rights reserved.
//

import UIKit
import LocalAuthentication
import AnimatedTextInput
import SVProgressHUD

class ForgotPassController: UIViewController {
    
    private lazy var logoView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = R.image.appLogo()
        view.size(CGSize(width: 115, height: 115))
        return view
    }()
    
    private lazy var emailField: AnimatedTextInput = {
        let field = AnimatedTextInput()
        field.style = AnimatedTextInputStyleLogin()
        field.type = .email
        field.placeHolderText = R.string.global.email()
        field.returnKeyType = .done
        field.inputAccessoryView = nil
        field.autocorrection = .no
        return field
    }()
    
    private lazy var sendButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(R.string.auth.resetPassword(), for: .normal)
        button.height(44)
        button.addTarget(self, action: #selector(sendAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var backButton: UIButton = {
        let backButtonImage = R.image.back()?.withRenderingMode(.alwaysTemplate)
        let button = UIButton(type: .custom)
        button.setImage(backButtonImage, for: .normal)
        button.tintColor = UIColor.NavBar.text
        button.setTitle(" \(R.string.global.back())", for: .normal)
        button.setTitleColor(UIColor.NavBar.text, for: .normal)
        button.setTitleColor(UIColor.NavBar.text.withAlphaComponent(0.5), for: .highlighted)
        button.addTarget(self, action: #selector(backAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private let model = AuthModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    
        model.actionHandler = handleModel(_:)
    }
    
    private func handleModel(_ action: AuthModel.AuthModelAction) {
        switch action {
            case .loading(let show):
                SVProgressHUD.show(show)
            case .alert(let title, let descr, let completion):
                sendButton.isEnabled = true
                showAlert(title, body: descr, action: completion)
            case .success:
                navigationController?.popViewController(animated: true)
            default:
                break
        }
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.Main.background
        
        let scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.edgesToSuperview()
        
        let contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.topToSuperview()
        contentView.leftToSuperview()
        contentView.rightToSuperview()
        contentView.bottomToSuperview()
        
        contentView.width(to: view)
        
        contentView.addSubview(logoView)
        logoView.topToSuperview(offset: 90)
        logoView.centerXToSuperview()
        
        contentView.addSubview(emailField)
        emailField.topToBottom(of: logoView, offset: 50)
        emailField.centerXToSuperview()
        if UIDevice.current.userInterfaceIdiom == .phone {
            emailField.horizontalToSuperview(insets: .horizontal(25))
        } else {
            emailField.width(300)
        }
        
        contentView.addSubview(sendButton)
        sendButton.topToBottom(of: emailField, offset: 60)
        sendButton.centerXToSuperview()
        sendButton.width(to: emailField)
        sendButton.bottomToSuperview(offset: -20, relation: .equalOrLess, usingSafeArea: true)
        
        view.addSubview(backButton)
        backButton.topToSuperview(offset: 10, usingSafeArea: true)
        backButton.leftToSuperview(offset: 10)
    }
    
    // MARK: - Actions
    @objc private func sendAction(_ sender: UIButton) {
        guard validateFields() else { return }
        sender.isEnabled = false
        view.endEditing(true)
        model.sendSignInLink(emailField.text!)
    }
    
    private func validateFields() -> Bool {
        var isValid = true
        if emailField.text == nil || emailField.text!.isEmpty {
            emailField.show(error: R.string.global.fieldRequired(emailField.placeHolderText), placeholderText: emailField.placeHolderText)
            isValid = false
        } else if let email = emailField.text, !email.isValid(regex: String.RegularExpressions.email) {
            emailField.show(error: R.string.global.enterCorrect(emailField.placeHolderText), placeholderText: emailField.placeHolderText)
            isValid = false
        } else { emailField.clearError() }
        return isValid
    }
    
    @objc private func backAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}
