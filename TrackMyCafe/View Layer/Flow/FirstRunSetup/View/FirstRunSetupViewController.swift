//
//  FirstRunSetupViewController.swift
//  TrackMyCafe
//
//  Created on 23.11.2026.
//

import TinyConstraints
import UIKit

// MARK: - FirstRunSetupViewControllerDelegate

protocol FirstRunSetupViewControllerDelegate: AnyObject {
    func firstRunSetupDidFinish(_ controller: FirstRunSetupViewController)
}

// MARK: - FirstRunSetupViewController

final class FirstRunSetupViewController: UIViewController, Loggable {

    // MARK: - Properties

    weak var delegate: FirstRunSetupViewControllerDelegate?
    private let viewModel: FirstRunSetupViewModelType

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag
        return scrollView
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        return stack
    }()

    private let stepLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.footnote
        label.textColor = Theme.current.secondaryText
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.title2DemiBold
        label.textColor = UIColor.Main.text
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.body
        label.textColor = Theme.current.secondaryText
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var productNameField: InputContainerView = {
        InputContainerView(
            labelText: R.string.global.productName(),
            inputType: .text(keyboardType: .default),
            placeholder: R.string.global.firstRunProductNamePlaceholder()
        )
    }()

    private lazy var productPriceField: InputContainerView = {
        InputContainerView(
            labelText: R.string.global.price(),
            inputType: .text(keyboardType: .decimalPad),
            placeholder: "0"
        )
    }()

    private lazy var addProductButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(R.string.global.firstRunAddProduct(), for: .normal)
        button.titleLabel?.font = Typography.bodyMedium
        button.addTarget(self, action: #selector(addProductTapped), for: .touchUpInside)
        return button
    }()

    private let productsListStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()

    private let saleListStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()

    private lazy var expenseNameField: InputContainerView = {
        InputContainerView(
            labelText: R.string.global.costName(),
            inputType: .text(keyboardType: .default),
            placeholder: R.string.global.firstRunExpenseNamePlaceholderFinance()
        )
    }()

    private lazy var expenseAmountField: InputContainerView = {
        InputContainerView(
            labelText: R.string.global.costSum(),
            inputType: .text(keyboardType: .decimalPad),
            placeholder: "0"
        )
    }()

    private let summaryCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.TableView.cellBackground
        view.applyCafeSoftCardStyle()
        return view
    }()

    private let summaryStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private let leftoverScaleTipLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.apply(.footnote)
        label.textColor = UIColor.Main.text.withAlphaComponent(0.7)
        label.numberOfLines = 0
        label.text = R.string.global.firstRunLeftoverScaleTip()
        return label
    }()

    private lazy var primaryButton: DefaultButton = {
        let button = DefaultButton()
        button.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)
        return button
    }()

    private lazy var skipStepButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(R.string.global.firstRunSkipStep(), for: .normal)
        button.titleLabel?.font = Typography.body
        button.setTitleColor(Theme.current.secondaryText, for: .normal)
        button.addTarget(self, action: #selector(skipStepTapped), for: .touchUpInside)
        return button
    }()

    private lazy var skipAllButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(R.string.global.firstRunSkipAll(), for: .normal)
        button.titleLabel?.font = Typography.footnote
        button.setTitleColor(Theme.current.secondaryText, for: .normal)
        button.addTarget(self, action: #selector(skipAllTapped), for: .touchUpInside)
        return button
    }()

    private let preferencesSection = UIStackView()
    private let menuSection = UIStackView()
    private let saleSection = UIStackView()
    private let expenseSection = UIStackView()
    private let leftoverSection = UIStackView()

    private lazy var stockNoCard = makePreferenceCard(
        title: R.string.global.firstRunPreferencesStockNoTitle(),
        body: R.string.global.firstRunPreferencesStockNoBody(),
        action: #selector(stockNoTapped)
    )
    private lazy var stockYesCard = makePreferenceCard(
        title: R.string.global.firstRunPreferencesStockYesTitle(),
        body: R.string.global.firstRunPreferencesStockYesBody(),
        action: #selector(stockYesTapped)
    )
    private lazy var classicCard = makePreferenceCard(
        title: R.string.global.firstRunPreferencesClassicTitle(),
        body: R.string.global.firstRunPreferencesClassicBody(),
        action: #selector(classicReceiptTapped)
    )
    private lazy var simplifiedCard = makePreferenceCard(
        title: R.string.global.firstRunPreferencesSimplifiedTitle(),
        body: R.string.global.firstRunPreferencesSimplifiedBody(),
        action: #selector(simplifiedReceiptTapped)
    )

    private lazy var categoryFirstSwitch: UISwitch = {
        let control = UISwitch()
        control.onTintColor = .systemGreen
        control.addTarget(self, action: #selector(categoryFirstChanged(_:)), for: .valueChanged)
        return control
    }()

    private let categoryFirstRow = UIStackView()
    private let categoryFirstHintLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.apply(.footnote)
        label.textColor = Theme.current.secondaryText
        label.numberOfLines = 0
        label.text = R.string.global.firstRunPreferencesCategoryFirstHint()
        return label
    }()

    // MARK: - Init

    init(viewModel: FirstRunSetupViewModelType = FirstRunSetupViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setConstraints()
        bindViewModel()
        renderStep()
        renderPreferencesSelection()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = UIColor.Main.background
        title = R.string.global.firstRunTitle()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: R.string.global.firstRunSkipAll(),
            style: .plain,
            target: self,
            action: #selector(skipAllTapped)
        )

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(primaryButton)
        view.addSubview(skipStepButton)
        view.addSubview(skipAllButton)

        configureSectionStacks()

        contentStack.addArrangedSubview(stepLabel)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.addArrangedSubview(preferencesSection)
        contentStack.addArrangedSubview(menuSection)
        contentStack.addArrangedSubview(saleSection)
        contentStack.addArrangedSubview(expenseSection)
        contentStack.addArrangedSubview(leftoverSection)

        summaryCard.addSubview(summaryStack)
        leftoverSection.addArrangedSubview(summaryCard)
        leftoverSection.addArrangedSubview(leftoverScaleTipLabel)
    }

    private func configureSectionStacks() {
        [preferencesSection, menuSection, saleSection, expenseSection, leftoverSection].forEach {
            stack in
            stack.axis = .vertical
            stack.spacing = 12
        }

        let stockHeader = sectionHeader(R.string.global.firstRunPreferencesStockSection())
        let receiptHeader = sectionHeader(R.string.global.firstRunPreferencesReceiptSection())

        let categoryTitle = AppLabel(style: .body)
        categoryTitle.apply(.body)
        categoryTitle.text = R.string.global.firstRunPreferencesCategoryFirst()
        categoryTitle.numberOfLines = 0
        categoryTitle.textColor = UIColor.Main.text

        categoryFirstRow.axis = .horizontal
        categoryFirstRow.alignment = .center
        categoryFirstRow.spacing = 12
        categoryFirstRow.addArrangedSubview(categoryTitle)
        categoryFirstRow.addArrangedSubview(categoryFirstSwitch)

        preferencesSection.addArrangedSubview(stockHeader)
        preferencesSection.addArrangedSubview(stockNoCard)
        preferencesSection.addArrangedSubview(stockYesCard)
        preferencesSection.addArrangedSubview(receiptHeader)
        preferencesSection.addArrangedSubview(classicCard)
        preferencesSection.addArrangedSubview(simplifiedCard)
        preferencesSection.addArrangedSubview(categoryFirstRow)
        preferencesSection.addArrangedSubview(categoryFirstHintLabel)

        menuSection.addArrangedSubview(productNameField)
        menuSection.addArrangedSubview(productPriceField)
        menuSection.addArrangedSubview(addProductButton)
        menuSection.addArrangedSubview(productsListStack)

        saleSection.addArrangedSubview(saleListStack)

        expenseSection.addArrangedSubview(expenseNameField)
        expenseSection.addArrangedSubview(expenseAmountField)
    }

    private func setConstraints() {
        scrollView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        scrollView.bottomToTop(of: primaryButton, offset: -UIConstants.standardPadding)

        contentStack.edgesToSuperview(
            insets: UIEdgeInsets(
                top: UIConstants.standardPadding,
                left: UIConstants.standardPadding,
                bottom: UIConstants.standardPadding,
                right: UIConstants.standardPadding
            )
        )
        contentStack.widthToSuperview(
            offset: -(UIConstants.standardPadding * 2)
        )

        primaryButton.leftToSuperview(offset: UIConstants.standardPadding)
        primaryButton.rightToSuperview(offset: -UIConstants.standardPadding)
        primaryButton.height(UIConstants.buttonHeight)
        primaryButton.bottomToTop(of: skipStepButton, offset: -8)

        skipStepButton.centerXToSuperview()
        skipStepButton.bottomToTop(of: skipAllButton, offset: -4)

        skipAllButton.centerXToSuperview()
        skipAllButton.bottomToSuperview(offset: -UIConstants.standardPadding, usingSafeArea: true)

        summaryStack.edgesToSuperview(
            insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        )
    }

    private func bindViewModel() {
        viewModel.onStepChanged = { [weak self] in
            self?.renderStep()
        }
        viewModel.onProductsChanged = { [weak self] in
            self?.renderProductsList()
            self?.updatePrimaryEnabled()
        }
        viewModel.onSaleChanged = { [weak self] in
            self?.renderSaleList()
            self?.updatePrimaryEnabled()
        }
        viewModel.onSummaryReady = { [weak self] in
            self?.renderSummary()
        }
        viewModel.onPreferencesChanged = { [weak self] in
            self?.renderPreferencesSelection()
        }
        viewModel.onCompleted = { [weak self] in
            guard let self else { return }
            self.delegate?.firstRunSetupDidFinish(self)
        }
        viewModel.onError = { [weak self] message in
            self?.presentSimpleAlert(message: message)
        }
    }

    // MARK: - Render

    private func renderStep() {
        let step = viewModel.currentStep
        stepLabel.text = R.string.global.firstRunStepProgress(
            String(step.displayNumber),
            String(FirstRunSetupStep.totalCount)
        )

        preferencesSection.isHidden = step != .preferences
        menuSection.isHidden = step != .menu
        saleSection.isHidden = step != .firstSale
        expenseSection.isHidden = step != .expense
        leftoverSection.isHidden = step != .leftover
        skipStepButton.isHidden = step == .leftover
        skipAllButton.isHidden = step == .leftover
        navigationItem.rightBarButtonItem?.isEnabled = step != .leftover

        switch step {
        case .preferences:
            titleLabel.text = R.string.global.firstRunPreferencesTitle()
            subtitleLabel.text = R.string.global.firstRunPreferencesSubtitle()
            primaryButton.setTitle(R.string.global.firstRunContinue(), for: .normal)
            renderPreferencesSelection()
        case .menu:
            titleLabel.text = R.string.global.firstRunMenuTitle()
            subtitleLabel.text =
                viewModel.tracksIngredients
                ? R.string.global.firstRunMenuSubtitleStock()
                : R.string.global.firstRunMenuSubtitleFinance()
            primaryButton.setTitle(R.string.global.firstRunContinue(), for: .normal)
            renderProductsList()
        case .firstSale:
            titleLabel.text = R.string.global.firstRunSaleTitle()
            subtitleLabel.text = R.string.global.firstRunSaleSubtitle()
            primaryButton.setTitle(R.string.global.firstRunSaveSale(), for: .normal)
            renderSaleList()
        case .expense:
            titleLabel.text = R.string.global.firstRunExpenseTitle()
            applyExpenseCopyForMode()
            primaryButton.setTitle(R.string.global.firstRunSaveExpense(), for: .normal)
        case .leftover:
            titleLabel.text = R.string.global.firstRunLeftoverTitle()
            subtitleLabel.text = R.string.global.firstRunLeftoverSubtitle()
            primaryButton.setTitle(R.string.global.firstRunGoToDashboard(), for: .normal)
            viewModel.refreshSummary()
            renderSummary()
        }

        updatePrimaryEnabled()
        view.endEditing(true)
    }

    private func applyExpenseCopyForMode() {
        if viewModel.tracksIngredients {
            subtitleLabel.text = R.string.global.firstRunExpenseSubtitleStock()
            expenseNameField.setPlaceholder(
                R.string.global.firstRunExpenseNamePlaceholderStock()
            )
        } else {
            subtitleLabel.text = R.string.global.firstRunExpenseSubtitleFinance()
            expenseNameField.setPlaceholder(
                R.string.global.firstRunExpenseNamePlaceholderFinance()
            )
        }
    }

    private func renderPreferencesSelection() {
        stylePreferenceCard(stockNoCard, selected: !viewModel.tracksIngredients)
        stylePreferenceCard(stockYesCard, selected: viewModel.tracksIngredients)
        stylePreferenceCard(classicCard, selected: viewModel.orderEntryMode == .perOrder)
        stylePreferenceCard(simplifiedCard, selected: viewModel.orderEntryMode == .openTab)

        let showCategory = viewModel.orderEntryMode == .perOrder
        categoryFirstRow.isHidden = !showCategory
        categoryFirstHintLabel.isHidden = !showCategory
        categoryFirstSwitch.isOn = viewModel.chooseCategoryFirst
    }

    private func renderProductsList() {
        productsListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for product in viewModel.addedProducts {
            let row = makeInfoRow(
                title: product.name,
                detail: product.price.currency
            )
            productsListStack.addArrangedSubview(row)
        }
    }

    private func renderSaleList() {
        saleListStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for line in viewModel.saleLines {
            let row = makeSaleRow(line: line)
            saleListStack.addArrangedSubview(row)
        }
    }

    private func renderSummary() {
        summaryStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        summaryStack.addArrangedSubview(
            makeInfoRow(
                title: R.string.global.hubBigSalesLabel(),
                detail: viewModel.salesTotal.currency
            )
        )
        summaryStack.addArrangedSubview(
            makeInfoRow(
                title: R.string.global.hubBigCostsLabel(),
                detail: viewModel.costsTotal.currency
            )
        )

        let leftoverRow = makeInfoRow(
            title: R.string.global.hubBigNetLabel(),
            detail: viewModel.leftoverTotal.currency
        )
        leftoverRow.titleLabel.font = Typography.title3DemiBold
        leftoverRow.detailLabel.font = Typography.title3DemiBold
        summaryStack.addArrangedSubview(leftoverRow)
    }

    private func updatePrimaryEnabled() {
        switch viewModel.currentStep {
        case .preferences, .expense, .leftover:
            primaryButton.isEnabled = true
            primaryButton.alpha = 1
        case .menu, .firstSale:
            primaryButton.isEnabled = viewModel.canContinueFromCurrentStep()
            primaryButton.alpha = primaryButton.isEnabled ? 1 : 0.5
        }
    }

    // MARK: - Preference UI helpers

    private func sectionHeader(_ text: String) -> UILabel {
        let label = AppLabel(style: .bodyDemiBold)
        label.apply(.bodyDemiBold)
        label.text = text
        label.textColor = UIColor.Main.text
        label.numberOfLines = 0
        return label
    }

    private func makePreferenceCard(title: String, body: String, action: Selector) -> UIControl {
        let control = UIControl()
        control.backgroundColor = UIColor.TableView.cellBackground
        control.applyCafeSoftCardStyle()
        control.addTarget(self, action: action, for: .touchUpInside)

        let titleLabel = AppLabel(style: .bodyDemiBold)
        titleLabel.apply(.bodyDemiBold)
        titleLabel.text = title
        titleLabel.textColor = UIColor.Main.text
        titleLabel.numberOfLines = 0
        titleLabel.isUserInteractionEnabled = false

        let bodyLabel = AppLabel(style: .footnote)
        bodyLabel.apply(.footnote)
        bodyLabel.text = body
        bodyLabel.textColor = Theme.current.secondaryText
        bodyLabel.numberOfLines = 0
        bodyLabel.isUserInteractionEnabled = false

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.isUserInteractionEnabled = false

        control.addSubview(stack)
        stack.edgesToSuperview(
            insets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        )
        return control
    }

    private func stylePreferenceCard(_ card: UIControl, selected: Bool) {
        card.layer.borderWidth = selected ? 2 : 1
        card.layer.borderColor =
            selected
            ? UIColor.Button.background.cgColor
            : UIColor.Main.text.withAlphaComponent(0.12).cgColor
        card.alpha = selected ? 1 : 0.92
    }

    // MARK: - Row builders

    private func makeInfoRow(title: String, detail: String) -> InfoRowView {
        InfoRowView(title: title, detail: detail)
    }

    private func makeSaleRow(line: FirstRunSetupSaleLine) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.TableView.cellBackground
        container.applyCafeSoftCardStyle()

        let nameLabel = UILabel()
        nameLabel.text = line.product.name
        nameLabel.font = Typography.body
        nameLabel.textColor = UIColor.Main.text
        nameLabel.numberOfLines = 0
        nameLabel.adjustsFontForContentSizeCategory = true

        let priceLabel = UILabel()
        priceLabel.text = line.product.price.currency
        priceLabel.font = Typography.footnote
        priceLabel.textColor = Theme.current.secondaryText

        let minusButton = UIButton(type: .system)
        minusButton.setTitle("−", for: .normal)
        minusButton.titleLabel?.font = Typography.title3
        minusButton.accessibilityIdentifier = "firstRunSaleMinus_\(line.product.id)"

        let qtyLabel = UILabel()
        qtyLabel.text = "\(line.quantity)"
        qtyLabel.font = Typography.bodyMedium
        qtyLabel.textAlignment = .center
        qtyLabel.width(28)

        let plusButton = UIButton(type: .system)
        plusButton.setTitle("+", for: .normal)
        plusButton.titleLabel?.font = Typography.title3

        let productId = line.product.id
        minusButton.addAction(
            UIAction { [weak self] _ in
                let current = self?.viewModel.saleLines.first(where: { $0.product.id == productId })?
                    .quantity ?? 0
                self?.viewModel.setSaleQuantity(productId: productId, quantity: current - 1)
            },
            for: .touchUpInside
        )
        plusButton.addAction(
            UIAction { [weak self] _ in
                let current = self?.viewModel.saleLines.first(where: { $0.product.id == productId })?
                    .quantity ?? 0
                self?.viewModel.setSaleQuantity(productId: productId, quantity: current + 1)
            },
            for: .touchUpInside
        )

        let qtyStack = UIStackView(arrangedSubviews: [minusButton, qtyLabel, plusButton])
        qtyStack.axis = .horizontal
        qtyStack.spacing = 4
        qtyStack.alignment = .center

        let textStack = UIStackView(arrangedSubviews: [nameLabel, priceLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        container.addSubview(textStack)
        container.addSubview(qtyStack)

        textStack.leftToSuperview(offset: 12)
        textStack.topToSuperview(offset: 12)
        textStack.bottomToSuperview(offset: -12)
        textStack.rightToLeft(of: qtyStack, offset: -8)

        qtyStack.rightToSuperview(offset: -12)
        qtyStack.centerYToSuperview()

        return container
    }

    // MARK: - Actions

    @objc private func stockNoTapped() {
        viewModel.setTracksIngredients(false)
    }

    @objc private func stockYesTapped() {
        viewModel.setTracksIngredients(true)
    }

    @objc private func classicReceiptTapped() {
        viewModel.setOrderEntryMode(.perOrder)
    }

    @objc private func simplifiedReceiptTapped() {
        viewModel.setOrderEntryMode(.openTab)
    }

    @objc private func categoryFirstChanged(_ sender: UISwitch) {
        viewModel.setChooseCategoryFirst(sender.isOn)
    }

    @objc private func addProductTapped() {
        Task { [weak self] in
            guard let self else { return }
            let ok = await self.viewModel.addProduct(
                name: self.productNameField.text ?? "",
                priceText: self.productPriceField.text ?? ""
            )
            if ok {
                self.productNameField.text = ""
                self.productPriceField.text = ""
            }
        }
    }

    @objc private func primaryTapped() {
        switch viewModel.currentStep {
        case .preferences:
            viewModel.commitOperatingPreferences()
            viewModel.advanceAfterSuccessfulAction()
        case .menu:
            guard viewModel.canContinueFromCurrentStep() else { return }
            viewModel.advanceAfterSuccessfulAction()
        case .firstSale:
            Task { [weak self] in
                guard let self else { return }
                let ok = await self.viewModel.saveFirstSale()
                if ok {
                    self.viewModel.advanceAfterSuccessfulAction()
                }
            }
        case .expense:
            Task { [weak self] in
                guard let self else { return }
                let ok = await self.viewModel.saveExpense(
                    name: self.expenseNameField.text ?? "",
                    amountText: self.expenseAmountField.text ?? ""
                )
                if ok {
                    self.viewModel.advanceAfterSuccessfulAction()
                }
            }
        case .leftover:
            viewModel.finishSetup()
        }
    }

    @objc private func skipStepTapped() {
        PopupFactory.showPopup(
            title: R.string.global.firstRunSkipStepTitle(),
            description: R.string.global.firstRunSkipStepMessage(),
            buttonTitle: R.string.global.firstRunSkipStepConfirm(),
            buttonAction: { [weak self] in
                self?.viewModel.skipCurrentStep()
            }
        )
    }

    @objc private func skipAllTapped() {
        PopupFactory.showPopup(
            title: R.string.global.firstRunSkipAllTitle(),
            description: R.string.global.firstRunSkipAllMessage(),
            buttonTitle: R.string.global.firstRunSkipAllConfirm(),
            buttonAction: { [weak self] in
                self?.viewModel.skipEntireSetup()
            }
        )
    }

    private func presentSimpleAlert(message: String) {
        PopupFactory.showPopup(
            title: R.string.global.error(),
            description: message
        )
    }
}

// MARK: - InfoRowView

private final class InfoRowView: UIView {
    let titleLabel = UILabel()
    let detailLabel = UILabel()

    init(title: String, detail: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = Typography.body
        titleLabel.textColor = UIColor.Main.text
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true

        detailLabel.text = detail
        detailLabel.font = Typography.bodyMedium
        detailLabel.textColor = UIColor.Main.text
        detailLabel.textAlignment = .right
        detailLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .firstBaseline
        addSubview(stack)
        stack.edgesToSuperview()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
