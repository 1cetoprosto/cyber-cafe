import TinyConstraints
import UIKit

final class ManualMovementEditViewController: UIViewController {
    private let viewModel: ManualMovementEditViewModelType
    private var saveButtonBottomConstraint: NSLayoutConstraint!

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag
        return scrollView
    }()

    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = UIConstants.standardSpacing
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()

    private lazy var kindControl: DefaultSegmentedControl = {
        let items = [
            R.string.global.manualMovementDeposit(),
            R.string.global.manualMovementWithdrawal(),
            R.string.global.manualMovementTransfer(),
            R.string.global.manualMovementAdjustment(),
        ]
        let control = DefaultSegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(kindChanged), for: .valueChanged)
        return control
    }()

    private lazy var kindContainerView: UIView = {
        makeSegmentedContainer(
            title: R.string.global.manualMovementType(),
            control: kindControl
        )
    }()

    private lazy var dateInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: R.string.global.costDate(),
            inputType: .date(mode: .date),
            isEditable: true
        )
        return container
    }()

    private lazy var amountInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: R.string.global.costSum(),
            inputType: .text(keyboardType: .decimalPad),
            isEditable: true,
            placeholder: R.string.global.costSumPlaceholder()
        )
        return container
    }()

    private let accountLabel = AppLabel(style: .footnote)

    private lazy var accountControl: DefaultSegmentedControl = {
        makeAccountControl()
    }()

    private lazy var accountContainerView: UIView = {
        configureTitleLabel(accountLabel)
        return makeSegmentedContainer(label: accountLabel, control: accountControl)
    }()

    private lazy var fromAccountControl: DefaultSegmentedControl = {
        makeAccountControl()
    }()

    private lazy var fromAccountContainerView: UIView = {
        makeSegmentedContainer(
            title: R.string.global.manualMovementFromAccount(),
            control: fromAccountControl
        )
    }()

    private lazy var toAccountControl: DefaultSegmentedControl = {
        makeAccountControl()
    }()

    private lazy var toAccountContainerView: UIView = {
        makeSegmentedContainer(
            title: R.string.global.manualMovementToAccount(),
            control: toAccountControl
        )
    }()

    private lazy var signControl: DefaultSegmentedControl = {
        let control = DefaultSegmentedControl(items: ["+", "-"])
        control.selectedSegmentIndex = 0
        return control
    }()

    private lazy var signContainerView: UIView = {
        makeSegmentedContainer(
            title: R.string.global.manualMovementSign(),
            control: signControl
        )
    }()

    private lazy var noteInputContainer: InputContainerView = {
        let container = InputContainerView(
            labelText: R.string.global.note(),
            inputType: .text(keyboardType: .default),
            isEditable: true
        )
        return container
    }()

    private lazy var saveButton: DefaultButton = {
        let button = DefaultButton()
        button.setTitle(R.string.global.save(), for: .normal)
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.height(UIConstants.buttonHeight)
        return button
    }()

    init(viewModel: ManualMovementEditViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Main.background
        title =
            viewModel.isEditing
            ? R.string.global.edit()
            : R.string.global.add()

        view.addSubview(scrollView)
        view.addSubview(saveButton)
        scrollView.addSubview(mainStackView)

        setupUI()
        setupKeyboardHandling()
        applyInitialValues()
        kindChanged()
    }

    private func setupUI() {
        scrollView.topToSuperview(usingSafeArea: true)
        scrollView.leadingToSuperview()
        scrollView.trailingToSuperview()
        scrollView.bottomToTop(of: saveButton, offset: -UIConstants.standardSpacing)

        mainStackView.topToSuperview(offset: UIConstants.standardSpacing)
        mainStackView.leadingToSuperview(offset: UIConstants.standardSpacing)
        mainStackView.trailingToSuperview(offset: -UIConstants.standardSpacing)
        mainStackView.bottomToSuperview(offset: -UIConstants.standardSpacing)
        mainStackView.width(to: scrollView, offset: -UIConstants.standardSpacing * 2)

        saveButton.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
        saveButtonBottomConstraint = saveButton.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: -UIConstants.standardSpacing
        )
        saveButtonBottomConstraint.isActive = true

        mainStackView.addArrangedSubview(kindContainerView)
        mainStackView.addArrangedSubview(dateInputContainer)
        mainStackView.addArrangedSubview(amountInputContainer)
        mainStackView.addArrangedSubview(accountContainerView)
        mainStackView.addArrangedSubview(fromAccountContainerView)
        mainStackView.addArrangedSubview(toAccountContainerView)
        mainStackView.addArrangedSubview(signContainerView)
        mainStackView.addArrangedSubview(noteInputContainer)

        amountInputContainer.enableNumericInput(maxFractionDigits: 2)
        let currencySymbol =
            RequestManager.shared.settings?.currencySymbol
            ?? ((Locale.current.languageCode == "uk")
                ? DefaultValues.currencySymbol : DefaultValues.dollarSymbol)
        amountInputContainer.enableCurrencySuffix(symbol: currencySymbol)
    }

    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func configureTitleLabel(_ label: UILabel) {
        label.apply(.footnote)
        label.textColor = UIColor.Main.text
        label.numberOfLines = 0
    }

    private func makeAccountControl() -> DefaultSegmentedControl {
        let control = DefaultSegmentedControl(items: [
            R.string.global.cash(),
            R.string.global.card(),
        ])
        control.selectedSegmentIndex = UISegmentedControl.noSegment
        return control
    }

    private func makeSegmentedContainer(title: String, control: DefaultSegmentedControl) -> UIView {
        let label = AppLabel(style: .footnote)
        configureTitleLabel(label)
        label.text = title
        return makeSegmentedContainer(label: label, control: control)
    }

    private func makeSegmentedContainer(label: UILabel, control: DefaultSegmentedControl) -> UIView
    {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.layer.cornerRadius = UIConstants.mediumCornerRadius

        view.addSubview(label)
        view.addSubview(control)

        label.topToSuperview(offset: UIConstants.mediumSpacing)
        label.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))

        control.topToBottom(of: label, offset: UIConstants.smallSpacing)
        control.horizontalToSuperview(insets: .horizontal(UIConstants.standardPadding))
        control.bottomToSuperview(offset: -UIConstants.mediumSpacing)

        return view
    }

    private func applyInitialValues() {
        dateInputContainer.date = viewModel.initialDate
        amountInputContainer.text = viewModel.initialAmountText
        noteInputContainer.text = viewModel.initialNote

        kindControl.selectedSegmentIndex = segmentIndex(for: viewModel.initialKind)

        selectAccount(viewModel.initialFromAccount, in: fromAccountControl)
        selectAccount(viewModel.initialToAccount, in: toAccountControl)
        selectAccount(
            viewModel.initialFromAccount ?? viewModel.initialToAccount, in: accountControl)

        signControl.selectedSegmentIndex = viewModel.initialAdjustmentIsNegative ? 1 : 0
    }

    @objc private func kindChanged() {
        let kind = selectedKind
        accountContainerView.isHidden = kind == .transfer
        fromAccountContainerView.isHidden = kind != .transfer
        toAccountContainerView.isHidden = kind != .transfer
        signContainerView.isHidden = kind != .adjustment

        switch kind {
        case .deposit:
            accountLabel.text = R.string.global.manualMovementToAccount()
        case .withdrawal:
            accountLabel.text = R.string.global.manualMovementFromAccount()
        case .adjustment:
            accountLabel.text = R.string.global.account()
        case .transfer:
            accountLabel.text = ""
        }
    }

    @objc private func saveTapped() {
        saveButton.isEnabled = false

        let kind = selectedKind
        let date = dateInputContainer.date ?? Date()
        let amountText = amountInputContainer.text
        let note = noteInputContainer.text
        let adjustmentIsNegative = signControl.selectedSegmentIndex == 1

        let from: PaymentAccount?
        let to: PaymentAccount?
        switch kind {
        case .transfer:
            from = selectedAccount(fromAccountControl)
            to = selectedAccount(toAccountControl)
        case .deposit:
            from = nil
            to = selectedAccount(accountControl)
        case .withdrawal, .adjustment:
            from = selectedAccount(accountControl)
            to = nil
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.viewModel.save(
                    kind: kind,
                    date: date,
                    amountText: amountText,
                    fromAccount: from,
                    toAccount: to,
                    note: note,
                    adjustmentIsNegative: adjustmentIsNegative
                )
                await MainActor.run {
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                await MainActor.run {
                    PopupFactory.showPopup(
                        title: R.string.global.error(),
                        description: error.localizedDescription
                    ) {}
                }
            }
            await MainActor.run { self.saveButton.isEnabled = true }
        }
    }

    private var selectedKind: ManualMovementKind {
        switch kindControl.selectedSegmentIndex {
        case 0:
            return .deposit
        case 1:
            return .withdrawal
        case 2:
            return .transfer
        default:
            return .adjustment
        }
    }

    private func segmentIndex(for kind: ManualMovementKind) -> Int {
        switch kind {
        case .deposit: return 0
        case .withdrawal: return 1
        case .transfer: return 2
        case .adjustment: return 3
        }
    }

    private func selectedAccount(_ control: DefaultSegmentedControl) -> PaymentAccount? {
        switch control.selectedSegmentIndex {
        case 0:
            return .cash
        case 1:
            return .card
        default:
            return nil
        }
    }

    private func selectAccount(_ account: PaymentAccount?, in control: DefaultSegmentedControl) {
        switch account {
        case .cash:
            control.selectedSegmentIndex = 0
        case .card:
            control.selectedSegmentIndex = 1
        case .none:
            control.selectedSegmentIndex = UISegmentedControl.noSegment
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else {
            return
        }
        let keyboardFrame = frameValue.cgRectValue
        let keyboardHeight = keyboardFrame.height
        saveButtonBottomConstraint.constant = -keyboardHeight - UIConstants.standardSpacing
        view.layoutIfNeeded()
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        saveButtonBottomConstraint.constant = -UIConstants.standardSpacing
        view.layoutIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
