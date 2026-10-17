//
//  CreateEditAdminController.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 01.07.2024.
//

import PhotosUI
import SVProgressHUD
import TinyConstraints
import UIKit

final class CreateEditAdminController: UIViewController, Loggable {

    // MARK: - Properties

    private var profileImageView: UIImageView!
    private var newImage: UIImage?

    private let admin: Admin

    // Container to center the avatar in the stack view (which uses .fill alignment)
    private lazy var avatarContainer: UIView = {
        let view = UIView()
        return view
    }()

    // MARK: - UI Elements

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag
        return scrollView
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = UIConstants.standardPadding
        stackView.alignment = .fill
        return stackView
    }()

    private lazy var lastNameInput: InputContainerView = {
        InputContainerView(
            labelText: R.string.global.lastName(),
            inputType: .text(keyboardType: .default),
            placeholder: R.string.global.noRequired()
        )
    }()

    private lazy var firstNameInput: InputContainerView = {
        InputContainerView(
            labelText: R.string.global.firstName(),
            inputType: .text(keyboardType: .default),
            placeholder: R.string.global.required()
        )
    }()

    private lazy var middleNameInput: InputContainerView = {
        InputContainerView(
            labelText: R.string.global.middleName(),
            inputType: .text(keyboardType: .default),
            placeholder: R.string.global.noRequired()
        )
    }()

    private lazy var phoneInput: InputContainerView = {
        InputContainerView(
            labelText: R.string.global.phone(),
            inputType: .text(keyboardType: .phonePad),
            placeholder: R.string.global.noRequired()
        )
    }()

    private lazy var emailInput: InputContainerView = {
        InputContainerView(
            labelText: R.string.global.email(),
            inputType: .text(keyboardType: .emailAddress),
            isEditable: false,
            placeholder: R.string.global.required()
        )
    }()

    private lazy var addressInput: MultilineInputContainerView = {
        MultilineInputContainerView(
            labelText: R.string.global.address(),
            placeholder: R.string.global.noRequired(),
            height: 70
        )
    }()

    private lazy var noteInput: MultilineInputContainerView = {
        MultilineInputContainerView(
            labelText: R.string.global.note(),
            placeholder: R.string.global.noRequired(),
            height: 110
        )
    }()

    private lazy var saveButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(R.string.global.save(), for: .normal)
        button.addTarget(self, action: #selector(saveAdmin), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    init() {
        self.admin = RequestManager.shared.admin.copy()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = R.string.global.edit()

        setupUI()
        setupConstraints()
        populateFields()
        setupCallbacks()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor.Main.background

        // Profile image
        profileImageView = UIImageView()
        profileImageView.isUserInteractionEnabled = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = UIConstants.profileImageCornerRadius
        profileImageView.layer.borderWidth = UIConstants.standardBorderWidth
        profileImageView.layer.borderColor = UIColor.Main.secondaryText.alpha(0.3).cgColor
        profileImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(changeImage)))

        view.addSubview(scrollView)
        view.addSubview(saveButton)
        scrollView.addSubview(mainStackView)

        avatarContainer.addSubview(profileImageView)
        mainStackView.addArrangedSubview(avatarContainer)
        mainStackView.addArrangedSubview(lastNameInput)
        mainStackView.addArrangedSubview(firstNameInput)
        mainStackView.addArrangedSubview(middleNameInput)
        mainStackView.addArrangedSubview(phoneInput)
        mainStackView.addArrangedSubview(emailInput)
        mainStackView.addArrangedSubview(addressInput)
        mainStackView.addArrangedSubview(noteInput)
    }

    private func setupConstraints() {
        scrollView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        scrollView.bottomToTop(of: saveButton, offset: -UIConstants.standardPadding)

        let horizontalInset = UIConstants.standardPadding
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        let fillWidth = mainStackView.widthAnchor.constraint(
            equalTo: scrollView.frameLayoutGuide.widthAnchor,
            constant: -2 * horizontalInset
        )
        fillWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor,
                constant: UIConstants.standardPadding
            ),
            mainStackView.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                constant: -UIConstants.standardPadding
            ),
            mainStackView.centerXAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            mainStackView.leadingAnchor.constraint(
                greaterThanOrEqualTo: scrollView.frameLayoutGuide.leadingAnchor,
                constant: horizontalInset
            ),
            mainStackView.trailingAnchor.constraint(
                lessThanOrEqualTo: scrollView.frameLayoutGuide.trailingAnchor,
                constant: -horizontalInset
            ),
            fillWidth,
            mainStackView.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
        ])

        profileImageView.height(150)
        profileImageView.width(150)
        profileImageView.centerXToSuperview()
        profileImageView.centerYToSuperview()
        avatarContainer.height(150)

        saveButton.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
        saveButton.height(UIConstants.buttonHeight)
        saveButton.bottomToSuperview(
            offset: -UIConstants.standardPadding, usingSafeArea: true
        )
    }

    private func populateFields() {
        lastNameInput.text = admin.lastName
        firstNameInput.text = admin.firstName
        middleNameInput.text = admin.middleName
        phoneInput.text = admin.phone
        emailInput.text = admin.email
        addressInput.text = admin.address ?? ""
        noteInput.text = admin.comment ?? ""

        if let path = admin.avatarThumbnailUrl ?? admin.avatarUrl, let url = URL(string: path) {
            profileImageView.setImage(url, placeholder: R.image.profilePlaceholder())
        } else {
            profileImageView.image = R.image.profilePlaceholder()
        }
    }

    private func setupCallbacks() {
        lastNameInput.onTextChange = { [weak self] in self?.admin.lastName = $0 }
        firstNameInput.onTextChange = { [weak self] in self?.admin.firstName = $0 }
        middleNameInput.onTextChange = { [weak self] in self?.admin.middleName = $0 }
        phoneInput.onTextChange = { [weak self] in self?.admin.phone = $0 }
        emailInput.onTextChange = { [weak self] in self?.admin.email = $0 }
        addressInput.onTextChange = { [weak self] in self?.admin.address = $0 }
        noteInput.onTextChange = { [weak self] in self?.admin.comment = $0 }
    }

    // MARK: - Actions

    @objc private func changeImage(_ sender: UITapGestureRecognizer) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func saveAdmin() {
        view.endEditing(true)

        if admin.firstName.isEmpty {
            showAlert(
                R.string.global.error(),
                body: R.string.global.firstNameRequired())
            return
        }

        SVProgressHUD.show()

        if let image = newImage {
            let fileName = [admin.firstName, admin.lastName, Date().interval.string]
                .compactMap { $0 }.joined(separator: "_")
            StorageService.uploadAvatar(image, name: fileName) {
                [weak self] (success, filePath, thumbnailPath) in
                guard let self = self else { return }
                if success {
                    self.newImage = nil
                    self.admin.avatarUrl = filePath
                    self.admin.avatarThumbnailUrl = thumbnailPath
                    self.performSave()
                } else {
                    SVProgressHUD.dismiss()
                    self.showAlert(R.string.global.error(), body: R.string.global.wentWrong())
                }
            }
        } else {
            performSave()
        }
    }

    private func performSave() {
        Task { [weak self] in
            guard let self else { return }
            let success = await FirestoreDatabaseService.updateAdmin(self.admin)
            await MainActor.run {
                if success {
                    self.log()
                    SVProgressHUD.dismiss()
                    self.navigationController?.popViewController(animated: true)
                } else {
                    SVProgressHUD.dismiss()
                    self.showAlert(
                        R.string.global.error(),
                        body: R.string.global.wentWrong())
                }
            }
        }
    }

    private func log() {
        RequestManager.shared.log(
            date: Date(),
            object: FirebaseCollections.legacyTechnicians,
            action: .update,
            description: self.admin.description
        )
    }
}

// MARK: - PHPickerViewControllerDelegate

extension CreateEditAdminController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, _) in
            guard let self = self, let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self.newImage = image
                self.profileImageView.image = image
            }
        }
    }
}
