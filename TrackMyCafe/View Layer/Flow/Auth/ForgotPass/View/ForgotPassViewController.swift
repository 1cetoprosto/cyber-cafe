//
//  ForgotPassViewController.swift
//  Cyber-coffe
//
//  Created by Alexander Momotiuk on 26.07.2020.
//

import LocalAuthentication
import SVProgressHUD
import UIKit

class ForgotPassViewController: UIViewController {

    private lazy var logoView = AuthLogoView()

    private lazy var emailField: UITextField = {
        let field = PaddedTextField()
        field.keyboardType = .emailAddress
        field.placeholder = R.string.global.email()
        field.returnKeyType = .done
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.delegate = self
        field.height(50)
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

    private var viewModel: ForgotPassViewModelType?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    private func bindViewModel() {
        let viewModel = ForgotPassViewModel()
        viewModel.actionHandler = { [weak self] action in
            self?.handleModel(action)
        }
        self.viewModel = viewModel
    }

    private func handleModel(_ action: ForgotPassViewModelType.Action) {
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
        let email = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel?.sendPasswordReset(email)
    }

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
        return true
    }

    @objc private func backAction(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}

extension ForgotPassViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            sendAction(sendButton)
        }
        return true
    }
}
