//
//  SignUpController.swift
//  DTLab
//
//  Created by Alexander Momotiuk on 26.07.2020.
//  Copyright © 2020 DTLab. All rights reserved.
//

import LocalAuthentication
import SVProgressHUD
import UIKit

class SignUpController: UIViewController {

    private lazy var logoView = AuthLogoView()

    private lazy var emailField: UITextField = {
        let field = PaddedTextField()
        field.keyboardType = .emailAddress
        field.placeholder = R.string.global.email()
        field.returnKeyType = .next
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.delegate = self
        field.height(50)
        return field
    }()

    private lazy var passwordField: UITextField = {
        let field = PaddedTextField()
        field.isSecureTextEntry = true
        field.placeholder = R.string.global.password()
        field.returnKeyType = .next
        field.delegate = self
        field.height(50)

        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "eye"), for: .normal)
        button.setImage(UIImage(systemName: "eye.slash"), for: .selected)
        button.tintColor = UIColor.lightGray
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        button.addTarget(self, action: #selector(togglePasswordVisibility(_:)), for: .touchUpInside)
        field.rightView = button
        field.rightViewMode = .always

        return field
    }()

    private lazy var passwordRepeatField: UITextField = {
        let field = PaddedTextField()
        field.isSecureTextEntry = true
        field.placeholder = R.string.auth.repeatPassword()
        field.returnKeyType = .done
        field.delegate = self
        field.height(50)

        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "eye"), for: .normal)
        button.setImage(UIImage(systemName: "eye.slash"), for: .selected)
        button.tintColor = UIColor.lightGray
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        button.addTarget(self, action: #selector(togglePasswordVisibility(_:)), for: .touchUpInside)
        field.rightView = button
        field.rightViewMode = .always

        return field
    }()

    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        sender.isSelected.toggle()
        if sender == passwordField.rightView {
            passwordField.isSecureTextEntry = !sender.isSelected
        } else if sender == passwordRepeatField.rightView {
            passwordRepeatField.isSecureTextEntry = !sender.isSelected
        }
    }

    private lazy var signUpButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(R.string.auth.signUp(), for: .normal)
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
        case .retry(let error, let cancel, let retry):
            let alertVC = UIAlertController(
                title: R.string.global.error(),
                message: error ?? R.string.global.wentWrong(),
                preferredStyle: .alert)

            alertVC.addAction(
                UIAlertAction(
                    title: R.string.global.cancel(), style: .destructive,
                    handler: { (action) in
                        cancel()
                    }))

            alertVC.addAction(
                UIAlertAction(
                    title: R.string.global.retry(), style: .destructive,
                    handler: { handler in
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
            let canUseBio = context.canEvaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics, error: &authError)
            if canUseBio && authError == nil {
                navigationController?.pushViewController(BioAuthController(context), animated: true)
            } else {
                let controller = MainNavigationController(
                    rootViewController: MainTabBarController())
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

        let fieldsStack = UIStackView(arrangedSubviews: [
            emailField, passwordField, passwordRepeatField,
        ])
        fieldsStack.axis = .vertical
        fieldsStack.spacing = UIConstants.standardPadding

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
        guard let email = emailField.text, !email.isEmpty else {
            showAlert(
                R.string.global.error(),
                body: R.string.global.fieldRequired(emailField.placeholder ?? ""))
            return false
        }

        if !email.isValid(regex: String.RegularExpressions.email) {
            showAlert(
                R.string.global.error(),
                body: R.string.global.enterCorrect(emailField.placeholder ?? ""))
            return false
        }

        guard let password = passwordField.text, !password.isEmpty else {
            showAlert(
                R.string.global.error(),
                body: R.string.global.fieldRequired(passwordField.placeholder ?? ""))
            return false
        }

        if password.count < 6 {
            showAlert(R.string.global.error(), body: R.string.global.passwordValidateDesc())
            return false
        }

        guard let passwordRepeat = passwordRepeatField.text, !passwordRepeat.isEmpty else {
            showAlert(
                R.string.global.error(),
                body: R.string.global.fieldRequired(passwordRepeatField.placeholder ?? ""))
            return false
        }

        if password != passwordRepeat {
            showAlert(R.string.global.error(), body: R.string.global.passwordNotMatch())
            return false
        }

        return true
    }
}

extension SignUpController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailField: passwordField.becomeFirstResponder()
        case passwordField: passwordRepeatField.becomeFirstResponder()
        default: textField.resignFirstResponder()
        }
        return true
    }
}
