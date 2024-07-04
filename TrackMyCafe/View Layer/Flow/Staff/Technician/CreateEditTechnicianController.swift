//
//  CreateEditTechnicianController.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 02.07.2024.
//

import UIKit
import FirebaseAuth
import SVProgressHUD
import FirebaseFirestore
import FirebaseFirestoreSwift

class CreateEditTechnicianController: UIViewController {
    
    private var profileImageView: UIImageView!
    private var newImage: UIImage?
    
    private lazy var imagePicker = ImagePicker()
    
    private let technician: Technician
    private let moderType: Bool
    
    init(_ technician: Technician, moderType: Bool) {
        self.technician = technician.copy()
        self.moderType = moderType
        super.init(nibName: nil, bundle: nil)
    }
    
    init(moderType: Bool) {
        self.technician = Technician()
        if moderType {
            self.technician.role = .moderator
        }
        self.moderType = moderType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        
        if technician.firebaseRef.nilIfEmpty != nil {
            title = R.string.global.edit()
        } else {
            title = moderType ? R.string.global.newModerator() : R.string.global.newTechnician()
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTechnician))
        
        setupUI()
        populateFields()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Profile Image
        profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.isUserInteractionEnabled = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 75
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.borderColor = UIColor.lightGray.cgColor
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changeImage)))
        view.addSubview(profileImageView)
        
        // Other fields and sections
        let fieldsStackView = UIStackView()
        fieldsStackView.translatesAutoresizingMaskIntoConstraints = false
        fieldsStackView.axis = .vertical
        fieldsStackView.spacing = 10
        view.addSubview(fieldsStackView)
        
        // Add subviews for fields
        let fields = [
            makeField(label: R.string.global.lastName(), placeholder: R.string.global.noRequired(), value: technician.lastName ?? "") { self.technician.lastName = $0 },
            makeField(label: R.string.global.firstName(), placeholder: R.string.global.required(), value: technician.firstName) { self.technician.firstName = $0 },
            makeField(label: R.string.global.middleName(), placeholder: R.string.global.noRequired(), value: technician.middleName ?? "") { self.technician.middleName = $0 },
            makeField(label: R.string.global.phone(), placeholder: R.string.global.noRequired(), value: technician.phone ?? "", keyboardType: .phonePad) { self.technician.phone = $0 },
            makeField(label: R.string.global.email(), placeholder: R.string.global.required(), value: technician.email, keyboardType: .emailAddress, isEditing: technician.firebaseRef.nilIfEmpty == nil) { self.technician.email = $0 },
            makeTextViewField(label: R.string.global.address(), placeholder: R.string.global.noRequired(), value: technician.address ?? "", height: 70) { self.technician.address = $0 }
        ]
        
        fields.forEach { fieldsStackView.addArrangedSubview($0) }
        
        // Add switches
        let techModSwitch = makeSwitch(label: moderType ? R.string.global.addTechnicianPrivilege() : R.string.global.addModerationPrivilege(), isOn: technician.role == .techMod) { isOn in
            if self.moderType {
                self.technician.role = isOn ? .techMod : .moderator
            } else {
                self.technician.role = isOn ? .techMod : .technician
            }
        }
        
        let calcSwitch = makeSwitch(label: R.string.global.isAllowCalculationForAdministrator(), isOn: technician.isAllowedCalculationsForAdministrator) { isOn in
            self.technician.isAllowedCalculationsForAdministrator = isOn
        }
        
        fieldsStackView.addArrangedSubview(techModSwitch)
        fieldsStackView.addArrangedSubview(calcSwitch)
        
        // Add note
        let noteField = makeTextViewField(label: R.string.global.note(), placeholder: R.string.global.noRequired(), value: technician.comment ?? "", height: 110) { self.technician.comment = $0 }
        fieldsStackView.addArrangedSubview(noteField)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 150),
            profileImageView.heightAnchor.constraint(equalToConstant: 150),
            
            fieldsStackView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 20),
            fieldsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            fieldsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }
    
    private func makeField(label: String, placeholder: String, value: String, keyboardType: UIKeyboardType = .default, isEditing: Bool = true, onChange: @escaping (String) -> Void) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.text = value
        textField.keyboardType = keyboardType
        textField.borderStyle = .roundedRect
        textField.isUserInteractionEnabled = isEditing
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        textField.onChange = onChange
        
        container.addSubview(titleLabel)
        container.addSubview(textField)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            textField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            textField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func makeTextViewField(label: String?, placeholder: String, value: String, height: CGFloat, onChange: @escaping (String) -> Void) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let textView = UITextView()
        textView.text = value
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 5
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.heightAnchor.constraint(equalToConstant: height).isActive = true
        textView.delegate = self
        textView.onChange = onChange
        
        container.addSubview(titleLabel)
        container.addSubview(textView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func makeSwitch(label: String, isOn: Bool, onChange: @escaping (Bool) -> Void) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let switchControl = UISwitch()
        switchControl.isOn = isOn
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        switchControl.onChange = onChange
        
        container.addSubview(titleLabel)
        container.addSubview(switchControl)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            switchControl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            switchControl.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 10),
            switchControl.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        return container
    }
    
    private func populateFields() {
        if let url = technician.avatarThumbnailUrl?.url {
            profileImageView.setImage(url, placeholder: R.image.profilePlaceholder())
        }
    }
    
    @objc private func changeImage(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }
        imagePicker.showPickerOptions(in: self, sender: view)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        textField.onChange?(textField.text ?? "")
    }
    
    @objc private func switchChanged(_ switchControl: UISwitch) {
        switchControl.onChange?(switchControl.isOn)
    }
    
    private func validate() -> Bool {
        if technician.firstName.isEmpty {
            showAlert(R.string.global.error(), body: R.string.global.firstNameRequired())
            return false
        }
        
        if technician.email.nilIfEmpty == nil {
            showAlert(R.string.global.error(), body: R.string.global.emailRequired())
            return false
        }
        
        if let email = technician.email.nilIfEmpty, !email.isValid(regex: .email) {
            showAlert(R.string.global.error(), body: R.string.global.emailNotValid())
            return false
        }
        
        return true
    }
    
    @objc private func saveTechnician() {
        view.endEditing(true)
        guard validate() else { return }
        SVProgressHUD.show()
        
        if let image = newImage {
            let fileName = [technician.firstName, technician.lastName, Date().interval.string].compactMap { $0 }.joined(separator: "_")
            StorageService.uploadAvatar(image, name: fileName) {[weak self] (success, filePath, thumbnailPath) in
                guard let self = self else { return }
                if success {
                    self.newImage = nil
                    self.technician.avatarUrl = filePath
                    self.technician.avatarThumbnailUrl = thumbnailPath
                    RequestManager.shared.log(date: Date(), object: .technicians, action: .add, description: "Uploaded new technician image at \(filePath.emptyIfNil)")
                    self.saveTechnicianToDatabase()
                } else {
                    SVProgressHUD.dismiss()
                    self.showAlert(R.string.global.error(), body: R.string.global.wentWrong())
                }
            }
        } else {
            saveTechnicianToDatabase()
        }
    }
    
    private func saveTechnicianToDatabase() {
        let isNew = self.technician.firebaseRef.nilIfEmpty == nil

        if isNew {
            FirestoreDatabaseService.getRoles(self.technician.email.trimmed.lowercased()) { roles in
                if (roles ?? []).isEmpty {
                    var roles = [RoleConfig]()
                    let userRef = Firestore.firestore().collection("users").document()
                    if self.technician.role == .technician || self.technician.role == .techMod {
                        let techRole = RoleConfig(ref: userRef.documentID, email: self.technician.email, dataRef: UserSession.current.masterUserRef, userRef: userRef.documentID, role: .technician, onlineVersion: true)
                        roles.append(techRole)
                    }
                    if self.technician.role == .moderator || self.technician.role == .techMod {
                        let modeRole = RoleConfig(ref: userRef.documentID, email: self.technician.email, dataRef: UserSession.current.masterUserRef, userRef: userRef.documentID, role: .moderator, onlineVersion: true)
                        roles.append(modeRole)
                    }

                    var updateData = [String: Any]()
                    roles.forEach {
                        let key = "roles/\($0.firebaseRef)"
                        updateData[key] = $0.forDatabase()
                    }

                    let newTechRef = Firestore.firestore().collection("technicians").document()
                    self.technician.firebaseRef = newTechRef.documentID
                    let newTechKey = "users/\(String(describing: UserSession.current.masterUserRef))/technicians/\(newTechRef.documentID)"
                    updateData[newTechKey] = self.technician.forDatabase()

                    let batch = Firestore.firestore().batch()
                    updateData.forEach { key, value in
                        let ref = Firestore.firestore().document(key)
                        batch.setData(value as! [String : Any], forDocument: ref)
                    }

                    batch.commit { error in
                        let success = error == nil
                        if success {
                            self.log(isNew)
                            self.sendInviteEmail()
                        } else {
                            SVProgressHUD.dismiss()
                            self.showAlert(R.string.global.error(), body: R.string.global.wentWrong())
                        }
                    }
                } else {
                    SVProgressHUD.dismiss()
                    self.showAlert(R.string.global.error(), body: "Ви не можете створити техніка з таким e-mail, тому що користувач з таким e-mail вже зареєстрований в системі")
                }
            }
        } else {
            FirestoreDatabaseService.getTechRoles(self.technician.email) { items in
                guard let roles = items,
                    let userDataKey = roles.first?.userRef else { return }

                var removeRoles = [RoleConfig]()
                var addRoles = [RoleConfig]()
                if let role = roles.first(where: { $0.role == .technician }), self.technician.role == .moderator {
                    removeRoles.append(role)
                }
                if let role = roles.first(where: { $0.role == .moderator }), self.technician.role == .technician {
                    removeRoles.append(role)
                }

                if (self.technician.role == .technician || self.technician.role == .techMod) && !(roles.contains { $0.role == .technician }) {
                    let techRole = RoleConfig(ref: Firestore.firestore().collection("users").document().documentID, email: self.technician.email, dataRef: UserSession.current.masterUserRef, userRef: userDataKey, role: .technician, onlineVersion: true)
                    addRoles.append(techRole)
                }

                if (self.technician.role == .moderator || self.technician.role == .techMod) && !(roles.contains { $0.role == .moderator }) {
                    let techRole = RoleConfig(ref: Firestore.firestore().collection("users").document().documentID, email: self.technician.email, dataRef: UserSession.current.masterUserRef, userRef: userDataKey, role: .moderator, onlineVersion: true)
                    addRoles.append(techRole)
                }

                var updateData = [String: Any?]()
                addRoles.forEach {
                    let key = "roles/\($0.firebaseRef)"
                    updateData[key] = $0.forDatabase()
                }
                removeRoles.forEach {
                    let key = "roles/\($0.firebaseRef)"
                    updateData[key] = nil
                }

                let techKey = "users/\(String(describing: UserSession.current.masterUserRef))/technicians/\(String(describing: self.technician.firebaseRef))"
                updateData[techKey] = self.technician.forDatabase()

                let batch = Firestore.firestore().batch()
                updateData.forEach { key, value in
                    let ref = Firestore.firestore().document(key)
                    if let value = value {
                        batch.setData(value as! [String : Any], forDocument: ref)
                    } else {
                        ref.delete()
                    }
                }

                batch.commit { error in
                    let success = error == nil
                    if success {
                        self.log(isNew)
                        SVProgressHUD.dismiss()
                        self.navigationController?.popViewController(animated: true)
                    } else {
                        SVProgressHUD.dismiss()
                        self.showAlert(R.string.global.error(), body: R.string.global.wentWrong())
                    }
                }
            }
        }
    }


    
    private func sendInviteEmail() {
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: Config.associatedDomain)
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        actionCodeSettings.setAndroidPackageName(Config.androidBundle, installIfNotAvailable: true, minimumVersion: Config.androidVersion)
        
        Auth.auth().sendSignInLink(toEmail: self.technician.email, actionCodeSettings: actionCodeSettings) { (error) in
            SVProgressHUD.dismiss()
            if error != nil {
                self.showAlert(R.string.global.error(), body: R.string.global.failedSentTechnicianEmail()) {
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                self.showAlert(R.string.global.success(), body: R.string.global.successSentTechnicianEmail(self.technician.email)) {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    private func log(_ isNew: Bool) {
        RequestManager.shared.log(date: Date(), object: .technicians, action: isNew ? .add : .update, description: self.technician.description)
    }
}

extension CreateEditTechnicianController: ImagePickerDelegate {
    
    func imagePicker(_ picker: ImagePicker, didSelect image: UIImage) {
        imagePicker.dismiss()
        newImage = image
        profileImageView.image = image
    }
    
    func imagePickerDidCancel(_ picker: ImagePicker) {
        imagePicker.dismiss()
    }
}

// MARK: - UITextField Extension
extension UITextField {
    private struct AssociatedKeys {
        static var onChangeKey = "onChangeKey"
    }
    
    var onChange: ((String) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.onChangeKey) as? ((String) -> Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.onChangeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - UITextView Extension
extension UITextView {
    private struct AssociatedKeys {
        static var onChangeKey = "onChangeKey"
    }
    
    var onChange: ((String) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.onChangeKey) as? ((String) -> Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.onChangeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension CreateEditTechnicianController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textView.onChange?(textView.text)
    }
}

extension UISwitch {
    private struct AssociatedKeys {
        static var onChangeKey = "onChangeKey"
    }
    
    var onChange: ((Bool) -> Void)? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.onChangeKey) as? ((Bool) -> Void)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.onChangeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
