//
//  SignInController.swift
//  DTLab
//
//  Created by Alexander Momotiuk on 24.07.2020.
//  Copyright © 2020 DTLab. All rights reserved.
//

import FirebaseAuth
import LocalAuthentication
import SVProgressHUD
import TinyConstraints
import UIKit

class SignInController: UIViewController {

    var completionHandler: ((Bool) -> Void)?

    private lazy var logoView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = R.image.appLogo()
        view.size(CGSize(width: 115, height: 115))
        view.isUserInteractionEnabled = true
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        return view
    }()

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
        passwordField.isSecureTextEntry = !sender.isSelected
    }

    private lazy var rememberButton = RememberMeButton()

    private lazy var loginButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(R.string.auth.signIn(), for: .normal)
        button.height(44)
        button.addTarget(self, action: #selector(loginAction(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var bioAuthButton: UIButton = {
        let button = UIButton()
        button.size(CGSize(width: 60, height: 60))
        button.addTarget(self, action: #selector(checkByBio), for: .touchUpInside)
        return button
    }()

    private lazy var signUpButton: UIButton = {
        let button = UIButton()
        button.setTitle(R.string.auth.signUp(), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitleColor(UIColor.Main.text, for: .normal)
        button.setTitleColor(UIColor.Main.text.withAlphaComponent(0.5), for: .highlighted)
        button.addTarget(self, action: #selector(signUpAction(_:)), for: .touchUpInside)
        button.height(44)
        return button
    }()

    private lazy var forgotButton: UIButton = {
        let button = UIButton()
        button.setTitle(R.string.auth.forgotPass(), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitleColor(UIColor.Main.text, for: .normal)
        button.setTitleColor(UIColor.Main.text.withAlphaComponent(0.5), for: .highlighted)
        button.addTarget(self, action: #selector(forgotAction(_:)), for: .touchUpInside)
        return button
    }()

    var waitEmailConfirmation = false
    private let model = AuthModel()
    private var authLink: String?

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()

    init() {
        self.authLink = nil
        super.init(nibName: nil, bundle: nil)
    }

    init(link: String) {
        self.authLink = link
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        model.actionHandler = handleModel(_:)

        setupBio()

        if authLink != nil { return }

        if UserSession.current.rememberUser {
            emailField.text = UserSession.current.userEmail
            rememberButton.isCheck = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let link = authLink {
            model.signInWithLink(link)
            authLink = nil
            return
        }

        if authLink == nil,
            UserSession.current.isAuth
                && UserSession.current.useBioAuthUser == UserSession.current.userEmail
                && (UserSession.current.useBioAuth ?? false)
        {
            checkByBio()
        }
    }

    private func setupBio() {
        var authError: NSError?
        let context = LAContext()
        let canUseBio = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: &authError)
        if canUseBio && UserSession.current.rememberUser
            && (UserSession.current.useBioAuth ?? false)
            && authLink == nil
        {
            switch context.biometryType {
            case .touchID:
                bioAuthButton.setImage(
                    R.image.touchId()!.tint(color: UIColor.Button.title), for: .normal)
                bioAuthButton.setImage(
                    R.image.touchId()!.tint(color: UIColor.Button.title.withAlphaComponent(0.5)),
                    for: .highlighted)
            case .faceID:
                bioAuthButton.setImage(
                    R.image.faceId()!.tint(color: UIColor.Button.title), for: .normal)
                bioAuthButton.setImage(
                    R.image.faceId()!.tint(color: UIColor.Button.title.withAlphaComponent(0.5)),
                    for: .highlighted)
            case .none: break
            case .opticID: break
            @unknown default: break
            }
        } else {
            bioAuthButton.superview?.isHidden = true
        }
    }

    @objc private func checkByBio() {
        var authError: NSError?
        let context = LAContext()
        let canUseBio = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics, error: &authError)
        if canUseBio && authError == nil {
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: R.string.auth.bioAuthReason()
            ) { [weak self] (success, error) in
                DispatchQueue.main.async {
                    if success {
                        self?.model.signInWithBio()
                    } else {
                        if error?.localizedDescription != "Canceled by user." {
                            self?.showAlert(
                                R.string.global.error(), body: R.string.global.repeatAgain())
                        }
                    }
                }
            }
        }
    }

    private func handleModel(_ action: AuthModel.AuthModelAction) {
        switch action {
        case .loading(let show):
            SVProgressHUD.show(show)
        case .error(let error):
            showAlert(R.string.global.error(), body: error?.localizedDescription)
        case .retry(let cancel, let retry):
            let alertVC = UIAlertController(
                title: R.string.global.error(),
                message: R.string.global.wentWrong(),
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
        case .success(let setPassword):
            var authError: NSError?
            let context = LAContext()
            let canUseBio = context.canEvaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics, error: &authError)
            let askUser =
                UserSession.current.useBioAuth == nil
                || UserSession.current.userEmail != UserSession.current.useBioAuthUser
            if setPassword {
                let askBio =
                    canUseBio && authError == nil && UserSession.current.rememberUser && askUser
                navigationController?.pushViewController(
                    SetPasswordController(askBio ? context : nil), animated: true)
            } else if canUseBio && authError == nil && UserSession.current.rememberUser && askUser {
                navigationController?.pushViewController(BioAuthController(context), animated: true)
            } else {
                let controller = MainTabBarController()
                //AppDelegate.shared.set(root: controller)
                SceneDelegate.shared.set(root: controller)
            }
            completionHandler?(true)
        case .confirmEmail(let completion):
            showConfirmEmail(completion)
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor.Main.background

        view.addSubview(scrollView)
        scrollView.edgesToSuperview()

        let contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.edgesToSuperview()

        contentView.width(to: view)

        contentView.addSubview(logoView)
        logoView.topToSuperview(offset: 90)
        logoView.centerXToSuperview()

        let fieldsStack = UIStackView(arrangedSubviews: [emailField, passwordField])
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

        contentView.addSubview(rememberButton)
        rememberButton.topToBottom(of: fieldsStack, offset: 12)
        rememberButton.left(to: fieldsStack)

        let buttonsStack = UIStackView.VStack(
            [loginButton, bioAuthButton.wrapH(), signUpButton, forgotButton], spacing: 20)
        contentView.addSubview(buttonsStack)
        buttonsStack.topToBottom(of: fieldsStack, offset: 60)
        buttonsStack.centerXToSuperview()
        buttonsStack.width(to: fieldsStack)
        buttonsStack.bottomToSuperview(offset: -20, relation: .equalOrLess, usingSafeArea: true)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
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

        guard let password = passwordField.text, !password.isEmpty else {
            showAlert(
                R.string.global.error(),
                body: R.string.global.fieldRequired(passwordField.placeholder ?? ""))
            return false
        }

        return true
    }

    // MARK: - Actions
    @objc private func loginAction(_ sender: UIButton) {

        #if DEV
            guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                let configDict = NSDictionary(contentsOfFile: path),
                let firebaseConfig = configDict["FirebaseDev"] as? [String: String],
                let email = firebaseConfig["Email"],
                let password = firebaseConfig["Password"]
            else {
                fatalError("Error reading Firebase configuration")
            }
            emailField.text = email
            passwordField.text = password
        #elseif BETA
            //        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
            //              let configDict = NSDictionary(contentsOfFile: path),
            //              let firebaseConfig = configDict["FirebaseBeta"] as? [String: String],
            //              let email = firebaseConfig["Email"],
            //              let password = firebaseConfig["Password"] else {
            //            fatalError("Error reading Firebase configuration")
            //        }
            //
            //        emailField.text = email
            //        passwordField.text = password
        #elseif PROD

        #else
            guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
                let configDict = NSDictionary(contentsOfFile: path),
                let firebaseConfig = configDict["FirebaseDev"] as? [String: String],
                let email = firebaseConfig["Email"],
                let password = firebaseConfig["Password"]
            else {
                fatalError("Error reading Firebase configuration")
            }
            emailField.text = email
            passwordField.text = password
        #endif

        guard validateFields() else { return }
        model.signIn(
            email: emailField.text!,
            password: passwordField.text!,
            rememberUser: rememberButton.isCheck)
    }

    @objc private func signUpAction(_ sender: UIButton) {
        let controller = SignUpController()
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func forgotAction(_ sender: UIButton) {
        let controller = ForgotPassController()
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - Public
    func showConfirmEmail(_ completion: @escaping (String) -> Void) {
        let alertVC = UIAlertController(
            title: R.string.auth.signIn(),
            message: R.string.auth.confirmEmail(),
            preferredStyle: .alert)

        alertVC.addTextField { (textField) in
            textField.placeholder = R.string.auth.enterEmail()
            textField.autocapitalizationType = .none
            textField.keyboardType = .emailAddress
        }

        alertVC.addAction(
            UIAlertAction(
                title: R.string.global.cancel(), style: .destructive,
                handler: { [weak self] (_) in
                    self?.waitEmailConfirmation = false
                }))

        alertVC.addAction(
            UIAlertAction(
                title: R.string.auth.signIn(), style: .default,
                handler: { [weak self] action in
                    self?.waitEmailConfirmation = false
                    if let email = alertVC.textFields?.first?.text, email.isValid(regex: .email) {
                        completion(email)
                    } else {
                        self?.showAlert(
                            R.string.global.error(), body: R.string.global.emailInvalid(),
                            action: {
                                self?.showConfirmEmail(completion)
                            })
                    }

                }))

        waitEmailConfirmation = true
        present(alertVC, animated: true, completion: nil)
    }

    // MARK: - Keyboard Handling

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }

    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil)

        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }

    @objc private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }

        let contentInset = UIEdgeInsets(
            top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }

    @objc private func keyboardWillHide(notification: Notification) {
        let contentInset = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }
}

extension SignInController: UITextFieldDelegate {

    func textFieldDidChangeSelection(_ textField: UITextField) {
        bioAuthButton.superview?.isHidden = true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else {
            loginAction(loginButton)
        }
        return true
    }
}

extension SignInController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch)
        -> Bool
    {
        if touch.view is UIControl { return false }
        if let view = touch.view,
            view.isDescendant(of: emailField) || view.isDescendant(of: passwordField)
        {
            return false
        }
        return true
    }
}
