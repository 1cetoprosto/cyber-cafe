//
//  TypeDetailsViewController.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 13.04.2022.
//

import RealmSwift
import TinyConstraints
import UIKit

final class TypeDetailsViewController: UIViewController {

  // MARK: - Properties
  private var saveButtonBottomConstraint: NSLayoutConstraint!
  var type: TypeModel

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
    stackView.distribution = .fill
    stackView.alignment = .fill
    return stackView
  }()

  private lazy var typeInputContainer: InputContainerView = {
    let container = InputContainerView(
      labelText: R.string.global.type(),
      inputType: .text(keyboardType: .default),
      isEditable: true,
      placeholder: R.string.global.enterTypeName()
    )
    return container
  }()

  private lazy var defaultToggleContainer: InputContainerView = {
    let container = InputContainerView(
      labelText: R.string.global.defaultType(),
      inputType: .toggle(isOn: false),
      isEditable: true
    )
    return container
  }()

  private lazy var saveButton: UIButton = {
    let button = DefaultButton()
    button.setTitle(R.string.global.save(), for: .normal)
    button.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
    return button
  }()

  // MARK: - Init
  init(type: TypeModel) {
    self.type = type
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupConstraints()
    setupData()
    setupKeyboardHandling()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setupNavigationBar()
  }

  // MARK: - Setup Methods
  private func setupUI() {
    view.backgroundColor = UIColor.Main.background
    view.addSubview(scrollView)
    view.addSubview(saveButton)
    scrollView.addSubview(mainStackView)

    typeInputContainer.setDelegate(self)
    typeInputContainer.setReturnKeyType(.done)

    mainStackView.addArrangedSubview(typeInputContainer)
    mainStackView.addArrangedSubview(defaultToggleContainer)
  }

  private func setupNavigationBar() {
    title = R.string.global.type()
    navigationController?.navigationBar.prefersLargeTitles = true
    navigationItem.largeTitleDisplayMode = .always
    navigationController?.navigationBar.largeTitleTextAttributes = [
      .foregroundColor: UIColor.NavBar.text
    ]
    navigationController?.navigationBar.titleTextAttributes = [
      .foregroundColor: UIColor.NavBar.text
    ]
    navigationController?.view.backgroundColor = UIColor.NavBar.background
  }

  private func setupConstraints() {
    // ScrollView constraints
    scrollView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
    scrollView.bottomToTop(of: saveButton, offset: -UIConstants.standardPadding)

    // Main StackView constraints
    mainStackView.edgesToSuperview(
      insets: .init(
        top: UIConstants.largeSpacing,
        left: UIConstants.standardPadding,
        bottom: UIConstants.largeSpacing,
        right: UIConstants.standardPadding
      )
    )
    mainStackView.width(to: scrollView, offset: -2 * UIConstants.standardPadding)

    // Single input container height
    let containerHeight =
      UIConstants.cellHeight + UIConstants.largeSpacing + UIConstants.standardPadding
    typeInputContainer.height(containerHeight)
    defaultToggleContainer.height(containerHeight)

    // Save Button constraints
    saveButton.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
    saveButton.height(UIConstants.buttonHeight)
    saveButtonBottomConstraint = saveButton.bottomAnchor.constraint(
      equalTo: view.keyboardLayoutGuide.topAnchor,
      constant: -UIConstants.standardPadding
    )
    saveButtonBottomConstraint.isActive = true
  }

  private func setupData() {
    typeInputContainer.text = type.name
    defaultToggleContainer.isOn = type.isDefault
  }

  private func setupKeyboardHandling() {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    tapGesture.cancelsTouchesInView = false
    view.addGestureRecognizer(tapGesture)
  }

  // MARK: - Actions
  @objc private func saveAction() {
    guard let name = typeInputContainer.text, !name.isEmpty else {
      PopupFactory.showPopup(
        title: R.string.global.error(),
        description: R.string.global.pleaseEnterTypeName()
      ) {}
      return
    }

    type.name = name
    let isDefault = defaultToggleContainer.isOn
    if type.id.isEmpty {
      type.id = UUID().uuidString
      DomainDatabaseService.shared.saveType(model: type) { success in
        if !success {
          PopupFactory.showPopup(
            title: R.string.global.error(),
            description: R.string.global.failedToSaveType()
          ) {}
        }
        if success {
          DomainDatabaseService.shared.setDefaultType(model: self.type, isDefault: isDefault)
        }
      }
    } else {
      DomainDatabaseService.shared.updateType(model: type, type: name)
      DomainDatabaseService.shared.setDefaultType(model: type, isDefault: isDefault)
    }

    navigationController?.popViewController(animated: true)
  }

  @objc private func dismissKeyboard() {
    view.endEditing(true)
  }
}

// MARK: - UITextFieldDelegate
extension TypeDetailsViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}
