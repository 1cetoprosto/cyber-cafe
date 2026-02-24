//
//  SetPasswordController.swift
//  DTLab
//
//  Created by Alexander Momotiuk on 13.04.2021.
//  Copyright © 2021 DTLab. All rights reserved.
//

import FirebaseAuth
import LocalAuthentication
import SVProgressHUD
import UIKit

class SetPasswordController: UIViewController {

    private lazy var passwordField: UITextField = {
        let field = PaddedTextField()
        field.isSecureTextEntry = true
        field.placeholder = R.string.auth.setPasswordPlaceholder()
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

    private lazy var repasswordField: UITextField = {
        let field = PaddedTextField()
        field.isSecureTextEntry = true
        field.placeholder = R.string.auth.setPasswordRePlaceholder()
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
        } else if sender == repasswordField.rightView {
            repasswordField.isSecureTextEntry = !sender.isSelected
        }
    }

    private lazy var saveButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(R.string.auth.signIn(), for: .normal)
        button.height(44)
        button.addTarget(self, action: #selector(savePasswordAction(_:)), for: .touchUpInside)
        return button
    }()

    private let context: LAContext?

    init(_ context: LAContext?) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }

    private func setupLayout() {
        view.backgroundColor = UIColor.Main.background

        let scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.edgesToSuperview(usingSafeArea: true)

        let imageView = UIImageView(image: R.image.setPassword()?.tint(color: UIColor.NavBar.text))
        imageView.size(CGSize(width: 120, height: 120))
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.text = R.string.auth.setPasswordTitle()

        let contentStack = UIStackView.VStack([
            imageView.wrapH(),
            titleLabel,
            passwordField,
            repasswordField,
            saveButton,
        ])
        contentStack.setCustomSpacing(24, after: imageView.superview!)
        contentStack.setCustomSpacing(32, after: titleLabel)
        contentStack.setCustomSpacing(24, after: passwordField)
        contentStack.setCustomSpacing(32, after: repasswordField)

        scrollView.addSubview(contentStack)

        contentStack.centerInSuperview()
        contentStack.topToSuperview(relation: .equalOrGreater)
        contentStack.bottomToSuperview(relation: .equalOrLess)
        if UIDevice.current.userInterfaceIdiom == .phone {
            contentStack.horizontalToSuperview(insets: .horizontal(25))
            contentStack.left(to: view, offset: 25)
            contentStack.right(to: view, offset: -25)
        } else {
            contentStack.width(300)
            contentStack.centerXToSuperview()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        passwordField.becomeFirstResponder()
    }

    // MARK: - Actions
    @objc private func savePasswordAction(_ sender: UIButton) {
        guard let password = passwordField.text?.nilIfEmpty else {
            showAlert(R.string.global.error(), body: R.string.auth.setPasswordEnterPassword())
            return
        }
        guard password.count >= 6 else {
            showAlert(R.string.global.error(), body: R.string.auth.setPasswordValidLength())
            return
        }
        guard let repassword = repasswordField.text?.nilIfEmpty else {
            showAlert(R.string.global.error(), body: R.string.auth.setPasswordReEnterPassword())
            return
        }
        guard password == repassword else {
            showAlert(R.string.global.error(), body: R.string.auth.setPasswordEqualPasswords())
            return
        }
        sender.isEnabled = false

        view.endEditing(true)
        SVProgressHUD.show()
        Auth.auth().currentUser?.updatePassword(
            to: password,
            completion: { [weak self] (error) in
                SVProgressHUD.dismiss()
                self?.saveButton.isEnabled = error != nil
                if error != nil {
                    self?.showAlert(
                        R.string.global.error(), body: R.string.global.wentWrongTryAgain())
                } else {
                    if let bioContext = self?.context {
                        self?.navigationController?.pushViewController(
                            BioAuthController(bioContext), animated: true)
                    } else {
                        let controller = MainTabBarController()
                        //AppDelegate.shared.set(root: controller)
                        SceneDelegate.shared.set(root: controller)
                    }
                }
            })
    }
}

extension SetPasswordController: UITextFieldDelegate {

    func textFieldDidChangeSelection(_ textField: UITextField) {
        saveButton.isEnabled =
            passwordField.text?.nilIfEmpty != nil && repasswordField.text?.nilIfEmpty != nil
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == passwordField {
            repasswordField.becomeFirstResponder()
        } else {
            savePasswordAction(saveButton)
        }
        return true
    }
}
