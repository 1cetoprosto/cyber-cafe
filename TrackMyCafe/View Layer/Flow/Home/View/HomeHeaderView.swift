import TinyConstraints
import UIKit

final class HomeHeaderView: UIView {
    var onAddIncome: (() -> Void)?
    var onAddExpense: (() -> Void)?
    var onPeriodChanged: ((Int) -> Void)?
    var onDeleteDemoData: (() -> Void)?
    var onProfitTap: (() -> Void)?
    var onProfitInfoTap: (() -> Void)?
    var onManualOperations: (() -> Void)? {
        didSet { balanceCard.onManualOperations = onManualOperations }
    }

    private let deleteDemoDataButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(R.string.global.deleteDemoData(), for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.isHidden = true
        return button
    }()

    private let titleLabel: UILabel = {
        let l = AppLabel(style: .title2DemiBold)
        l.apply(.title2DemiBold)
        l.text = R.string.global.appName()
        return l
    }()

    private let dateLabel: UILabel = {
        let l = AppLabel(style: .footnote)
        l.apply(.footnote)
        return l
    }()

    private let actionsStack = UIStackView()
    private let incomeButton = DefaultButton()
    private let expenseButton = DefaultButton()

    private let summaryCard = TodayCardView()
    private let expensesCard = SimpleKpiCard(
        iconSystemName: "arrow.down.right",
        tint: UIColor.Semantic.negativeFill,
        iconTint: UIColor.Semantic.negative
    )
    private let profitCard = ProfitCard()
    private let balanceCard = BalanceCard()
    private let periodControl: DefaultSegmentedControl = {
        let control = DefaultSegmentedControl(items: [
            R.string.global.today(), R.string.global.week(), R.string.global.month(),
        ])
        control.selectedSegmentIndex = 2
        return control
    }()
    private let kpiRow = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func configure(
        date: Date,
        period: DashboardPeriod,
        sales: Double,
        expenses: Double,
        profit: Double,
        profitDeltaPercent: Double?,
        cash: Double,
        card: Double,
        showDeleteDemoData: Bool = false
    ) {
        // Redundant delete button hidden as per request (replaced by floating button)
        deleteDemoDataButton.isHidden = true  // !showDeleteDemoData
        deleteDemoDataButton.addTarget(
            self, action: #selector(deleteDemoDataTap), for: .touchUpInside)

        dateLabel.text = DateFormatter.appFullDate.string(from: date)
        periodControl.selectedSegmentIndex = period.rawValue

        let periodTitle: String
        switch period {
        case .day:
            periodTitle = R.string.global.today()
        case .week:
            periodTitle = R.string.global.week()
        case .month:
            periodTitle = R.string.global.month()
        }

        let salesText = NumberFormatter.currencyInteger.string(sales)
        let incomeTitle = R.string.global.incomeFor(periodTitle.lowercased())
        summaryCard.configure(title: incomeTitle, value: salesText)
        expensesCard.configure(
            title: R.string.global.expensesFor(periodTitle.lowercased()),
            value: NumberFormatter.currencyInteger.string(expenses)
        )
        profitCard.configure(
            period: period,
            profit: profit,
            deltaPercent: profitDeltaPercent
        )
        balanceCard.configure(
            cash: NumberFormatter.currencyInteger.string(cash),
            card: NumberFormatter.currencyInteger.string(card)
        )
    }

    private func setupUI() {
        backgroundColor = UIColor.Main.background
        titleLabel.textColor = UIColor.Main.text
        dateLabel.textColor = UIColor.Main.text.alpha(0.7)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        headerStack.axis = .vertical
        headerStack.spacing = UIConstants.smallSpacing

        actionsStack.axis = .horizontal
        actionsStack.spacing = UIConstants.standardPadding
        actionsStack.distribution = .fillEqually

        incomeButton.setTitle("+ " + R.string.global.income(), for: .normal)
        incomeButton.addTarget(self, action: #selector(incomeTap), for: .touchUpInside)
        incomeButton.height(UIConstants.buttonHeight)
        incomeButton.accessibilityIdentifier = "homeAddIncome"

        expenseButton.setTitle("+ " + R.string.global.cost(), for: .normal)
        expenseButton.setTitleColor(UIColor.Main.text, for: .normal)
        expenseButton.layer.borderWidth = UIConstants.standardBorderWidth
        // Moved borderColor setup to traitCollectionDidChange
        expenseButton.backgroundColor = UIColor.Main.background
        if #available(iOS 11.0, *) {
            expenseButton.titleLabel?.adjustsFontForContentSizeCategory = true
        }
        expenseButton.addTarget(self, action: #selector(expenseTap), for: .touchUpInside)
        expenseButton.height(UIConstants.buttonHeight)
        expenseButton.accessibilityIdentifier = "homeAddExpense"

        actionsStack.addArrangedSubview(incomeButton)
        actionsStack.addArrangedSubview(expenseButton)

        periodControl.addTarget(self, action: #selector(periodChanged), for: .valueChanged)

        profitCard.onTap = { [weak self] in self?.onProfitTap?() }
        profitCard.onInfoTap = { [weak self] in self?.onProfitInfoTap?() }

        kpiRow.axis = .horizontal
        kpiRow.spacing = UIConstants.standardPadding
        kpiRow.distribution = .fillEqually
        kpiRow.addArrangedSubview(summaryCard)
        kpiRow.addArrangedSubview(expensesCard)

        deleteDemoDataButton.height(UIConstants.buttonHeight)

        let contentStack = UIStackView(
            arrangedSubviews: [
                deleteDemoDataButton, headerStack, actionsStack, periodControl, profitCard, kpiRow,
                balanceCard,
            ]
        )
        contentStack.axis = NSLayoutConstraint.Axis.vertical
        contentStack.spacing = UIConstants.largeSpacing

        addSubview(contentStack)
        contentStack.edgesToSuperview(
            insets: UIEdgeInsets(
                top: UIConstants.largeSpacing,
                left: 0,
                bottom: UIConstants.largeSpacing,
                right: 0
            )
        )
    }

    @objc private func incomeTap() { onAddIncome?() }
    @objc private func expenseTap() { onAddExpense?() }
    @objc private func periodChanged() { onPeriodChanged?(periodControl.selectedSegmentIndex) }
    @objc private func deleteDemoDataTap() { onDeleteDemoData?() }

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateExpenseButtonBorder()
            }
        }
    }

    private func updateExpenseButtonBorder() {
        if #available(iOS 13.0, *) {
            expenseButton.layer.borderColor =
                UIColor.Main.text.resolvedColor(with: traitCollection).alpha(0.15).cgColor
        } else {
            expenseButton.layer.borderColor = UIColor.Main.text.alpha(0.15).cgColor
        }
    }
}

// MARK: - Small UI Components
// Summary mini-cards now use InputContainerView for consistent styling

private final class ProfitCard: UIView {
    var onTap: (() -> Void)?
    var onInfoTap: (() -> Void)?

    private let titleLabel = AppLabel(style: .kpiTitle)
    private let valueLabel = AppLabel(style: .footnote)
    private let compareLabel = AppLabel(style: .kpiFooter)
    private let infoButton = UIButton(type: .system)
    private let chevronView = UIImageView()
    private let deltaFont = Typography.calloutDemi

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.TableView.cellBackground
        applyCafeSoftCardStyle()
        isAccessibilityElement = false

        titleLabel.apply(.kpiTitle)
        titleLabel.text = R.string.global.homeProfitTitle()
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        valueLabel.font = Typography.largeTitleBold
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.textColor = Theme.current.primaryText
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.6
        valueLabel.numberOfLines = 1

        compareLabel.apply(.kpiFooter)
        compareLabel.numberOfLines = 2

        let infoImage = UIImage(
            systemName: "info.circle",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        )
        infoButton.setImage(infoImage, for: .normal)
        infoButton.tintColor = Theme.current.secondaryText
        infoButton.accessibilityLabel = R.string.global.homeProfitInfoAccessibility()
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)
        infoButton.setContentHuggingPriority(.required, for: .horizontal)
        infoButton.width(28)
        infoButton.height(28)

        chevronView.image = UIImage(systemName: SystemImages.chevronRight)
        chevronView.tintColor = Theme.current.secondaryText
        chevronView.contentMode = .scaleAspectFit
        chevronView.setContentHuggingPriority(.required, for: .horizontal)
        chevronView.width(14)
        chevronView.height(18)

        let titleRow = UIStackView(arrangedSubviews: [titleLabel, infoButton, UIView(), chevronView])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = UIConstants.smallSpacing

        let stack = UIStackView(arrangedSubviews: [titleRow, valueLabel, compareLabel])
        stack.axis = .vertical
        stack.spacing = UIConstants.smallSpacing
        stack.alignment = .fill

        addSubview(stack)
        stack.edgesToSuperview(
            insets: .init(
                top: UIConstants.standardPadding,
                left: UIConstants.standardPadding,
                bottom: UIConstants.standardPadding,
                right: UIConstants.standardPadding
            )
        )

        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        addGestureRecognizer(tap)
        accessibilityTraits = .button
        accessibilityLabel = R.string.global.homeProfitCardAccessibility()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(period: DashboardPeriod, profit: Double, deltaPercent: Double?) {
        valueLabel.text = NumberFormatter.currencyInteger.string(profit)
        valueLabel.textColor = UIColor.Semantic.profit(profit)

        let compareBase: String
        switch period {
        case .day:
            compareBase = R.string.global.homeProfitCompareDay()
        case .week:
            compareBase = R.string.global.homeProfitCompareWeek()
        case .month:
            compareBase = R.string.global.homeProfitCompareMonth()
        }

        if let deltaPercent {
            let arrow = deltaPercent >= 0 ? "↑" : "↓"
            let deltaText = R.string.global.homeProfitDeltaFormat(arrow, abs(deltaPercent))
            let full = "\(compareBase)  \(deltaText)"
            let attributed = NSMutableAttributedString(
                string: full,
                attributes: [
                    .font: Typography.callout,
                    .foregroundColor: UIColor.Semantic.kpiLabel,
                ]
            )
            if let range = full.range(of: deltaText) {
                let nsRange = NSRange(range, in: full)
                attributed.addAttributes(
                    [
                        .foregroundColor: UIColor.Semantic.profit(deltaPercent),
                        .font: deltaFont,
                    ],
                    range: nsRange
                )
            }
            compareLabel.attributedText = attributed
        } else {
            compareLabel.attributedText = nil
            compareLabel.text = "\(compareBase)  ·  \(R.string.global.homeProfitDeltaUnavailable())"
            compareLabel.textColor = UIColor.Semantic.kpiLabel
        }
    }

    @objc private func cardTapped() { onTap?() }
    @objc private func infoTapped() { onInfoTap?() }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCafeSoftCardShadowPath()
    }
}

extension ProfitCard: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch)
        -> Bool
    {
        if touch.view is UIControl { return false }
        if let view = touch.view, view.isDescendant(of: infoButton) { return false }
        return true
    }
}

// MARK: - Today Card View
private final class TodayCardView: UIView {
    private let iconView = UIImageView()
    private let iconBadge = UIView()
    private let titleLabel = AppLabel(style: .kpiTitle)
    private let valueLabel = AppLabel(style: .kpiValue)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.TableView.cellBackground
        applyCafeSoftCardStyle()

        iconBadge.backgroundColor = UIColor.Semantic.positiveFill
        iconBadge.layer.cornerRadius = UIConstants.badgeCornerRadius
        iconView.image = UIColor.Semantic.kpiSymbol("arrow.up.right")
        iconView.tintColor = UIColor.Semantic.positive
        iconView.contentMode = .scaleAspectFit
        titleLabel.apply(.kpiTitle)
        titleLabel.text = R.string.global.today()
        valueLabel.apply(.kpiValue)
        valueLabel.textColor = UIColor.Main.text

        iconBadge.addSubview(iconView)
        iconView.size(CGSize(width: UIConstants.kpiIconSize, height: UIConstants.kpiIconSize))
        iconView.centerInSuperview()
        iconBadge.size(CGSize(width: UIConstants.kpiBadgeSize, height: UIConstants.kpiBadgeSize))

        let header = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        header.axis = .vertical
        header.spacing = UIConstants.smallSpacing

        let stack = UIStackView(arrangedSubviews: [iconBadge, header])
        stack.axis = .horizontal
        stack.spacing = UIConstants.smallSpacing
        stack.alignment = .top

        addSubview(stack)
        stack.edgesToSuperview(
            insets: .init(
                top: UIConstants.standardPadding, left: UIConstants.standardPadding,
                bottom: UIConstants.standardPadding, right: UIConstants.standardPadding))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

// MARK: - Simple KPI Card
private final class SimpleKpiCard: UIView {
    private let iconView = UIImageView()
    private let iconBadge = UIView()
    private let titleLabel = AppLabel(style: .kpiTitle)
    private let valueLabel = AppLabel(style: .kpiValue)

    init(iconSystemName: String, tint: UIColor, iconTint: UIColor) {
        super.init(frame: .zero)
        backgroundColor = UIColor.TableView.cellBackground
        applyCafeSoftCardStyle()

        iconBadge.backgroundColor = tint
        iconBadge.layer.cornerRadius = UIConstants.badgeCornerRadius
        iconView.image = UIColor.Semantic.kpiSymbol(iconSystemName)
        iconView.tintColor = iconTint
        iconView.contentMode = .scaleAspectFit
        titleLabel.apply(.kpiTitle)
        valueLabel.apply(.kpiValue)

        iconBadge.addSubview(iconView)
        iconView.size(CGSize(width: UIConstants.kpiIconSize, height: UIConstants.kpiIconSize))
        iconView.centerInSuperview()
        iconBadge.size(CGSize(width: UIConstants.kpiBadgeSize, height: UIConstants.kpiBadgeSize))

        let header = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        header.axis = .vertical
        header.spacing = UIConstants.smallSpacing

        let stack = UIStackView(arrangedSubviews: [iconBadge, header])
        stack.axis = .horizontal
        stack.spacing = UIConstants.smallSpacing
        stack.alignment = .top

        addSubview(stack)
        stack.edgesToSuperview(
            insets: .init(
                top: UIConstants.standardPadding, left: UIConstants.standardPadding,
                bottom: UIConstants.standardPadding, right: UIConstants.standardPadding))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}

extension HomeHeaderView {
    override func layoutSubviews() {
        super.layoutSubviews()
        if expenseButton.layer.borderColor == nil {
            updateExpenseButtonBorder()
        }

        [summaryCard, expensesCard, profitCard, balanceCard].forEach {
            $0.updateCafeSoftCardShadowPath()
        }
    }
}

// MARK: - Localization helper

private final class BalanceCard: UIView {
    private let iconCash = UIImageView()
    private let iconCard = UIImageView()
    private let cashLabel = AppLabel(style: .balanceTitle)
    private let cashValue = AppLabel(style: .balanceValue)
    private let cardLabel = AppLabel(style: .balanceTitle)
    private let cardValue = AppLabel(style: .balanceValue)
    var onManualOperations: (() -> Void)?
    private let manualOperationsControl = UIControl()
    private let manualOperationsLabel = AppLabel(style: .footnote)
    private let manualOperationsChevron = UIImageView()

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.TableView.cellBackground
        applyCafeSoftCardStyle()

        iconCash.image = UIColor.Semantic.kpiSymbol(SystemImages.banknoteFill)
            ?? UIImage(systemName: SystemImages.banknoteFill)
        iconCash.tintColor = Theme.current.secondaryText
        iconCash.contentMode = .scaleAspectFit
        iconCard.image = UIColor.Semantic.kpiSymbol(SystemImages.creditCardCircleFill)
            ?? UIImage(systemName: SystemImages.creditCardCircleFill)
        iconCard.tintColor = Theme.current.secondaryText
        iconCard.contentMode = .scaleAspectFit

        cashLabel.apply(.balanceTitle)
        cashLabel.text = R.string.global.cashBalance()
        cardLabel.apply(.balanceTitle)
        cardLabel.text = R.string.global.cardBalance()

        cashValue.apply(.balanceValue)
        cardValue.apply(.balanceValue)

        manualOperationsLabel.apply(.footnote)
        manualOperationsLabel.textColor = UIColor.Main.text.alpha(0.75)
        manualOperationsLabel.text = R.string.global.manualOperations()
        manualOperationsLabel.numberOfLines = 1
        manualOperationsLabel.adjustsFontSizeToFitWidth = true
        manualOperationsLabel.minimumScaleFactor = 0.85

        manualOperationsChevron.image = UIImage(systemName: "chevron.right")
        manualOperationsChevron.tintColor = UIColor.Main.text.alpha(0.45)
        manualOperationsChevron.contentMode = .scaleAspectFit
        manualOperationsChevron.setContentHuggingPriority(.required, for: .horizontal)
        manualOperationsChevron.setContentCompressionResistancePriority(.required, for: .horizontal)

        let manualRow = UIStackView(arrangedSubviews: [
            manualOperationsLabel, UIView(), manualOperationsChevron,
        ])
        manualRow.axis = .horizontal
        manualRow.spacing = UIConstants.smallSpacing
        manualRow.isUserInteractionEnabled = false
        manualRow.arrangedSubviews.forEach { $0.isUserInteractionEnabled = false }

        manualOperationsControl.addSubview(manualRow)
        manualRow.edgesToSuperview()
        manualOperationsControl.addTarget(
            self,
            action: #selector(manualOperationsTap),
            for: .touchUpInside
        )
        manualOperationsControl.isAccessibilityElement = true
        manualOperationsControl.accessibilityLabel = R.string.global.manualOperations()
        manualOperationsControl.accessibilityTraits = [.button]

        let divider = UIView()
        divider.backgroundColor = UIColor.Main.text.alpha(0.06)
        divider.height(1)

        let cashHeaderRow = UIStackView(arrangedSubviews: [
            iconCash, cashLabel, UIView(), cashValue,
        ])
        cashHeaderRow.axis = .horizontal
        cashHeaderRow.spacing = UIConstants.smallSpacing
        iconCash.size(
            CGSize(width: UIConstants.iconContainerSize, height: UIConstants.iconContainerSize))
        cashLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        cashValue.setContentCompressionResistancePriority(.required, for: .horizontal)

        let cardHeaderRow = UIStackView(arrangedSubviews: [
            iconCard, cardLabel, UIView(), cardValue,
        ])
        cardHeaderRow.axis = .horizontal
        cardHeaderRow.spacing = UIConstants.smallSpacing
        iconCard.size(
            CGSize(width: UIConstants.iconContainerSize, height: UIConstants.iconContainerSize))
        cardLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        cardValue.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [cashHeaderRow, cardHeaderRow])
        stack.axis = .vertical
        stack.spacing = UIConstants.standardSpacing

        let contentStack = UIStackView(arrangedSubviews: [stack, divider, manualOperationsControl])
        contentStack.axis = .vertical
        contentStack.spacing = UIConstants.standardSpacing

        addSubview(contentStack)
        contentStack.edgesToSuperview(
            insets: .init(
                top: UIConstants.standardPadding,
                left: UIConstants.standardPadding,
                bottom: UIConstants.standardPadding,
                right: UIConstants.standardPadding
            )
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(cash: String, card: String) {
        cashValue.text = cash
        cardValue.text = card
    }

    @objc private func manualOperationsTap() {
        onManualOperations?()
    }
}
