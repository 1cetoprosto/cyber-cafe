//
//  CreateEditTechnicianController.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 02.07.2024.
//

import PhotosUI
import SVProgressHUD
import TinyConstraints
import UIKit

final class CreateEditTechnicianController: UIViewController, Loggable {

    // MARK: - Properties

    private var profileImageView: UIImageView!
    private var newImage: UIImage?

    private let viewModel: StaffCreateEditViewModel

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
            isEditable: viewModel.isEmailEditable,
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
        button.addTarget(self, action: #selector(saveTechnician), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    init(_ employee: Employee, moderType: Bool) {
        self.viewModel = StaffCreateEditViewModel(employee: employee, isModerator: moderType)
        super.init(nibName: nil, bundle: nil)
    }

    init(moderType: Bool) {
        self.viewModel = StaffCreateEditViewModel(isModerator: moderType)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title

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
        lastNameInput.text = viewModel.lastName
        firstNameInput.text = viewModel.firstName
        middleNameInput.text = viewModel.middleName
        phoneInput.text = viewModel.phone
        emailInput.text = viewModel.email
        addressInput.text = viewModel.address
        noteInput.text = viewModel.note

        if let url = viewModel.avatarUrl {
            profileImageView.setImage(url, placeholder: R.image.profilePlaceholder())
        } else {
            profileImageView.image = R.image.profilePlaceholder()
        }
    }

    private func setupCallbacks() {
        lastNameInput.onTextChange = { [weak self] in self?.viewModel.updateLastName($0) }
        firstNameInput.onTextChange = { [weak self] in self?.viewModel.updateFirstName($0) }
        middleNameInput.onTextChange = { [weak self] in self?.viewModel.updateMiddleName($0) }
        phoneInput.onTextChange = { [weak self] in self?.viewModel.updatePhone($0) }
        emailInput.onTextChange = { [weak self] in self?.viewModel.updateEmail($0) }
        addressInput.onTextChange = { [weak self] in self?.viewModel.updateAddress($0) }
        noteInput.onTextChange = { [weak self] in self?.viewModel.updateNote($0) }
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

    @objc private func saveTechnician() {
        view.endEditing(true)

        if let errorMessage = viewModel.validate() {
            showAlert(R.string.global.error(), body: errorMessage)
            return
        }

        SVProgressHUD.show()

        if let image = newImage {
            let fileName = [viewModel.firstName, viewModel.lastName, Date().interval.string]
                .compactMap { $0 }.joined(separator: "_")
            StorageService.uploadAvatar(image, name: fileName) {
                [weak self] (success, filePath, thumbnailPath) in
                guard let self = self else { return }
                if success {
                    self.newImage = nil
                    self.viewModel.updateAvatar(filePath: filePath, thumbnailPath: thumbnailPath)
                    self.viewModel.logAvatarUpload(filePath: filePath ?? "")
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
            let errorMessage = await self.viewModel.save()
            await MainActor.run {
                if let errorMessage {
                    SVProgressHUD.dismiss()
                    self.showAlert(R.string.global.error(), body: errorMessage)
                } else {
                    self.afterSave()
                }
            }
        }
    }

    private func afterSave() {
        if viewModel.isEditing {
            SVProgressHUD.dismiss()
            navigationController?.popViewController(animated: true)
        } else {
            sendInviteEmail()
        }
    }

    private func sendInviteEmail() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.viewModel.sendInviteEmail()
                await MainActor.run {
                    SVProgressHUD.dismiss()
                    self.showAlert(
                        R.string.global.success(),
                        body: R.string.global.successSentEmployeeEmail(self.viewModel.email)
                    ) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    SVProgressHUD.dismiss()
                    self.showAlert(
                        R.string.global.error(), body: R.string.global.failedSentEmployeeEmail()
                    ) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
}

// MARK: - PHPickerViewControllerDelegate

extension CreateEditTechnicianController: PHPickerViewControllerDelegate {

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

// MARK: - Multiline Input Container

/// A card-styled multiline text input matching `InputContainerView`'s visual style.
final class MultilineInputContainerView: UIView {

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.apply(.footnote)
        label.textColor = UIColor.Main.secondaryText
        label.numberOfLines = 1
        return label
    }()

    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.font = Typography.title3
        textView.textColor = UIColor.Main.text
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        return textView
    }()

    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.title3
        label.textColor = UIColor.Main.secondaryText.alpha(0.5)
        label.numberOfLines = 0
        return label
    }()

    var text: String {
        get { textView.text }
        set {
            textView.text = newValue
            placeholderLabel.isHidden = !newValue.isEmpty
        }
    }

    var onTextChange: ((String) -> Void)?

    init(labelText: String, placeholder: String?, height: CGFloat) {
        super.init(frame: .zero)
        titleLabel.text = labelText
        placeholderLabel.text = placeholder
        setupUI(height: height)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(height: CGFloat) {
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(textView)
        containerView.addSubview(placeholderLabel)

        containerView.edgesToSuperview()

        titleLabel.topToSuperview(offset: UIConstants.mediumSpacing)
        titleLabel.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))

        textView.topToBottom(of: titleLabel, offset: UIConstants.smallSpacing)
        textView.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
        textView.bottomToSuperview(offset: -UIConstants.mediumSpacing)
        textView.height(height)

        placeholderLabel.top(to: textView, offset: 0)
        placeholderLabel.leading(to: textView)
        placeholderLabel.trailing(to: textView)
    }
}

extension MultilineInputContainerView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        onTextChange?(textView.text)
    }
}
