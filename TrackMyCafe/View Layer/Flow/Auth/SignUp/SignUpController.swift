//
//  SignUpController.swift
//  DTLab
//
//  Created by Alexander Momotiuk on 26.07.2020.
//  Copyright © 2020 DTLab. All rights reserved.
//

import UIKit
import SVProgressHUD
import AnimatedTextInput
import LocalAuthentication

class SignUpController: UIViewController {
    
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
        field.returnKeyType = .next
        field.inputAccessoryView = nil
        field.autocorrection = .no
        field.delegate = self
        return field
    }()
    
    private lazy var passwordField: AnimatedTextInput = {
        let field = AnimatedTextInput()
        field.style = AnimatedTextInputStyleLogin()
        field.type = .password(toggleable: true)
        field.placeHolderText = R.string.global.password()
        field.returnKeyType = .next
        field.inputAccessoryView = nil
        field.delegate = self
        return field
    }()
    
    private lazy var passwordRepeatField: AnimatedTextInput = {
        let field = AnimatedTextInput()
        field.style = AnimatedTextInputStyleLogin()
        field.type = .password(toggleable: true)
        field.placeHolderText = R.string.auth.repeatPassword()
        field.returnKeyType = .done
        field.inputAccessoryView = nil
        field.delegate = self
        return field
    }()
    
    private lazy var signUpButton: UIButton = {
        let button = UIButton()
        button.setTitle(R.string.auth.signUp(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        button.backgroundColor = UIColor.Button.background
        button.layer.cornerRadius = 4
        button.height(44)
        button.addTarget(self, action: #selector(signUpAction(_:)), for: .touchUpInside)
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
            case .error(let error):
                showAlert(R.string.global.error(), body: error?.localizedDescription)
            case .retry(let cancel, let retry):
                let alertVC = UIAlertController(title: R.string.global.error(),
                                                message: R.string.global.wentWrong(),
                                                preferredStyle: .alert)
                
                alertVC.addAction(UIAlertAction(title: R.string.global.cancel(), style: .destructive, handler: { (action) in
                    cancel()
                }))
                
                alertVC.addAction(UIAlertAction(title: R.string.global.retry(), style: .destructive, handler: { handler in
                    retry()
                }))
                
                present(alertVC, animated: true)
            case .chooseRole(let roles, let comletion):
                let chooseRoles = roles.sorted { $0.role.rawValue < $1.role.rawValue }
                PopupFactory.showChooseRoleAlert(chooseRoles) { role in
                    comletion(role)
                }
            case .alert(let title, let body, let completion):
                showAlert(title, body: body, action: completion)
            case .success:
                var authError: NSError?
                let context = LAContext()
                let canUseBio = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError)
                if canUseBio && authError == nil {
                    navigationController?.pushViewController(BioAuthController(context), animated: true)
                } else {
                    let controller = MainNavigationController(rootViewController: MainTabBarController())
                    //AppDelegate.shared.set(root: controller)
                    SceneDelegate.shared.set(root: controller)
                }
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
        
        let fieldsStack = UIStackView(arrangedSubviews: [emailField, passwordField, passwordRepeatField])
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 16
        
        contentView.addSubview(fieldsStack)
        fieldsStack.topToBottom(of: logoView, offset: 50)
        fieldsStack.centerXToSuperview()
        if UIDevice.current.userInterfaceIdiom == .phone {
            fieldsStack.horizontalToSuperview(insets: .horizontal(25))
        } else {
            fieldsStack.width(300)
        }
        
        contentView.addSubview(signUpButton)
        signUpButton.topToBottom(of: fieldsStack, offset: 40)
        signUpButton.centerXToSuperview()
        signUpButton.width(to: fieldsStack)
        signUpButton.bottomToSuperview(offset: -20, relation: .equalOrLess, usingSafeArea: true)
        
        view.addSubview(backButton)
        backButton.topToSuperview(offset: 10, usingSafeArea: true)
        backButton.leftToSuperview(offset: 10)
    }
    
    // MARK: - Actions
    @objc private func signUpAction(_ sender: UIButton) {
        guard validateFields() else { return }
        model.signUp(email: emailField.text!, password: passwordField.text!)
    }
    
    @objc private func backAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helpers
    
    private func validateFields() -> Bool {
        var isValid = true
        if emailField.text == nil || emailField.text!.isEmpty {
            emailField.show(error: R.string.global.fieldRequired(emailField.placeHolderText),
                            placeholderText: emailField.placeHolderText)
            isValid = false
        } else if let email = emailField.text, !email.isValid(regex: String.RegularExpressions.email) {
            emailField.show(error: R.string.global.enterCorrect(emailField.placeHolderText),
                            placeholderText: emailField.placeHolderText)
            isValid = false
        } else { emailField.clearError() }
        
        if passwordField.text == nil || passwordField.text!.isEmpty {
            passwordField.show(error: R.string.global.fieldRequired(passwordField.placeHolderText),
                               placeholderText: passwordField.placeHolderText)
            isValid = false
        } else if let password = passwordField.text, password.count < 6 {
            passwordField.show(error: R.string.global.passwordValidateDesc(),
                               placeholderText: passwordField.placeHolderText)
            isValid = false
        } else { passwordField.clearError() }
        
        if passwordRepeatField.text == nil || passwordRepeatField.text!.isEmpty {
            passwordRepeatField.show(error: R.string.global.fieldRequired(passwordRepeatField.placeHolderText),
                                     placeholderText: passwordRepeatField.placeHolderText)
            isValid = false
        } else if let password = passwordField.text, let passwordRepeat = passwordRepeatField.text, password != passwordRepeat {
            passwordRepeatField.show(error: R.string.global.passwordNotMatch(),
                                     placeholderText: passwordRepeatField.placeHolderText)
            isValid = false
        } else { passwordRepeatField.clearError() }
        return isValid
    }
}

extension SignUpController: AnimatedTextInputDelegate {
    
    func animatedTextInputShouldReturn(animatedTextInput: AnimatedTextInput) -> Bool {
        switch animatedTextInput {
            case emailField: passwordField.becomeFirstResponder()
            case passwordField: passwordRepeatField.becomeFirstResponder()
            default: animatedTextInput.resignFirstResponder()
        }
        return true
    }
}
