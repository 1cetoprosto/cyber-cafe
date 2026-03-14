import TinyConstraints
import UIKit

final class HomeHeaderView: UIView {
    var onAddIncome: (() -> Void)?
    var onAddExpense: (() -> Void)?
    var onPeriodChanged: ((Int) -> Void)?
    var onDeleteDemoData: (() -> Void)?

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
        let l = UILabel()
        l.applyDynamic(Typography.title2DemiBold)
        l.text = R.string.global.appName()
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.applyDynamic(Typography.footnote)
        return l
    }()

    private let actionsStack = UIStackView()
    private let incomeButton = DefaultButton()
    private let expenseButton = DefaultButton()

    private let summaryCard = TodayCardView()
    private let expensesCard = SimpleKpiCard(
        iconSystemName: "arrow.down.right",
        tint: UIColor.systemRed.withAlphaComponent(0.15),
        iconTint: UIColor.systemRed
    )
    private let profitCard = ProfitCard()
    private let balanceCard = BalanceCard()
    private let periodControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [
            R.string.global.today(), R.string.global.week(), R.string.global.month(),
        ])
        control.selectedSegmentIndex = 2
        return control
    }()
    private let kpiRow1 = UIStackView()
    private let kpiRow2 = UIStackView()
    private var isThreeInRow = true

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
        cash: Double,
        card: Double,
        showDeleteDemoData: Bool = false
    ) {
        // Redundant delete button hidden as per request (replaced by floating button)
        deleteDemoDataButton.isHidden = true // !showDeleteDemoData
        deleteDemoDataButton.addTarget(self, action: #selector(deleteDemoDataTap), for: .touchUpInside)

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
            title: R.string.global.costs() + " " + periodTitle.lowercased(),
            value: NumberFormatter.currencyInteger.string(expenses)
        )
        profitCard.configure(
            periodTitle: periodTitle.lowercased(), expenses: expenses, profit: profit)
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

        kpiRow1.axis = .horizontal
        kpiRow1.spacing = UIConstants.standardPadding
        kpiRow1.distribution = .fillEqually
        kpiRow2.axis = .horizontal
        kpiRow2.spacing = UIConstants.standardPadding
        kpiRow2.distribution = .fillEqually

        kpiRow1.addArrangedSubview(summaryCard)
        kpiRow1.addArrangedSubview(expensesCard)
        kpiRow1.addArrangedSubview(profitCard)

        deleteDemoDataButton.height(UIConstants.buttonHeight)

        let contentStack = UIStackView(
            arrangedSubviews: [
                deleteDemoDataButton, headerStack, actionsStack, periodControl, kpiRow1, kpiRow2, balanceCard,
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
            expenseButton.layer.borderColor = UIColor.Main.text.resolvedColor(with: traitCollection).alpha(0.15).cgColor
        } else {
            expenseButton.layer.borderColor = UIColor.Main.text.alpha(0.15).cgColor
        }
    }
}

// MARK: - Small UI Components
// Summary mini-cards now use InputContainerView for consistent styling

private final class ProfitCard: UIView {
    private let iconView = UIImageView()
    private let badgeView = UIView()
    private let titleLabel = AppLabel(style: .kpiTitle)
    private let valueLabel = AppLabel(style: .kpiValue)
    private let divider = UIView()
    private let footerLabel = AppLabel(style: .kpiFooter)

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.TableView.cellBackground
        layer.cornerRadius = UIConstants.extraLargeCornerRadius

        badgeView.backgroundColor = UIColor.systemPink.withAlphaComponent(0.2)
        badgeView.layer.cornerRadius = UIConstants.badgeCornerRadius
        iconView.image = UIImage(systemName: "arrow.down.right")
        iconView.tintColor = UIColor.systemPink
        iconView.contentMode = .scaleAspectFit
        titleLabel.apply(.kpiTitle)
        valueLabel.apply(.kpiValue)
        valueLabel.textColor = UIColor.systemRed
        divider.backgroundColor = UIColor.Main.text.alpha(0.1)
        footerLabel.apply(.kpiFooter)

        badgeView.addSubview(iconView)
        iconView.size(CGSize(width: UIConstants.largeIconSize, height: UIConstants.largeIconSize))
        iconView.centerInSuperview()
        badgeView.size(CGSize(width: UIConstants.badgeSize, height: UIConstants.badgeSize))

        let vStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        vStack.axis = .vertical
        vStack.spacing = UIConstants.smallSpacing

        let hStack = UIStackView(arrangedSubviews: [badgeView, vStack])
        hStack.axis = .horizontal
        hStack.spacing = UIConstants.smallSpacing
        hStack.alignment = .center

        //    let header = UIStackView(arrangedSubviews: [badgeView, titleLabel])
        //    header.axis = .horizontal
        //    header.spacing = UIConstants.smallSpacing

        let stack = UIStackView(arrangedSubviews: [hStack, footerLabel])
        stack.axis = .vertical
        stack.spacing = UIConstants.standardSpacing

        addSubview(stack)
        stack.edgesToSuperview(
            insets: .init(
                top: UIConstants.standardPadding,
                left: UIConstants.standardPadding,
                bottom: UIConstants.standardPadding,
                right: UIConstants.standardPadding
            )
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(periodTitle: String, expenses: Double, profit: Double) {
        titleLabel.text = R.string.global.monthlyProfit(periodTitle.lowercased())
        let profitText = NumberFormatter.currencyInteger.string(profit)
        valueLabel.text = profitText
        if profit >= 0 {
            iconView.image = UIImage(systemName: "arrow.up.right")
            iconView.tintColor = UIColor.systemGreen
            badgeView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
            valueLabel.textColor = UIColor.systemGreen
        } else {
            iconView.image = UIImage(systemName: "arrow.down.right")
            iconView.tintColor = UIColor.systemRed
            badgeView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
            valueLabel.textColor = UIColor.systemRed
        }
        let expensesText = NumberFormatter.currencyInteger.string(expenses)
        footerLabel.text = R.string.global.expensesPrefix() + expensesText
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
        layer.cornerRadius = UIConstants.extraLargeCornerRadius

        iconBadge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        iconBadge.layer.cornerRadius = UIConstants.badgeCornerRadius
        iconView.image = UIImage(systemName: "arrow.up.right")
        iconView.tintColor = UIColor.systemGreen
        iconView.contentMode = .scaleAspectFit
        titleLabel.apply(.kpiTitle)
        titleLabel.text = R.string.global.today()
        valueLabel.apply(.kpiValue)
        valueLabel.textColor = UIColor.Main.text

        iconBadge.addSubview(iconView)
        iconView.size(CGSize(width: UIConstants.largeIconSize, height: UIConstants.largeIconSize))
        iconView.centerInSuperview()
        iconBadge.size(CGSize(width: UIConstants.badgeSize, height: UIConstants.badgeSize))

        let header = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        header.axis = .vertical
        header.spacing = UIConstants.smallSpacing

        let stack = UIStackView(arrangedSubviews: [iconBadge, header])
        stack.axis = .horizontal
        stack.spacing = UIConstants.smallSpacing
        stack.alignment = .center

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
        layer.cornerRadius = UIConstants.extraLargeCornerRadius

        iconBadge.backgroundColor = tint
        iconBadge.layer.cornerRadius = UIConstants.badgeCornerRadius
        iconView.image = UIImage(systemName: iconSystemName)
        iconView.tintColor = iconTint
        iconView.contentMode = .scaleAspectFit
        titleLabel.apply(.kpiTitle)
        valueLabel.apply(.kpiValue)

        iconBadge.addSubview(iconView)
        iconView.size(CGSize(width: UIConstants.largeIconSize, height: UIConstants.largeIconSize))
        iconView.centerInSuperview()
        iconBadge.size(CGSize(width: UIConstants.badgeSize, height: UIConstants.badgeSize))

        let header = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        header.axis = .vertical
        header.spacing = UIConstants.smallSpacing

        let stack = UIStackView(arrangedSubviews: [iconBadge, header])
        stack.axis = .horizontal
        stack.spacing = UIConstants.smallSpacing
        stack.alignment = .center

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
        // Ensure color is set initially if not already
        if expenseButton.layer.borderColor == nil {
            updateExpenseButtonBorder()
        }

        let width = bounds.width
        let spacing = UIConstants.standardPadding
        let cardWidth = (width - 2 * spacing) / 3
        let shouldBeThree = cardWidth >= 140
        if shouldBeThree != isThreeInRow {
            isThreeInRow = shouldBeThree

            // Clear existing views
            kpiRow1.arrangedSubviews.forEach {
                kpiRow1.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            kpiRow2.arrangedSubviews.forEach {
                kpiRow2.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }

            if shouldBeThree {
                kpiRow1.addArrangedSubview(summaryCard)
                kpiRow1.addArrangedSubview(expensesCard)
                kpiRow1.addArrangedSubview(profitCard)
            } else {
                kpiRow1.addArrangedSubview(summaryCard)
                kpiRow1.addArrangedSubview(expensesCard)
                kpiRow2.addArrangedSubview(profitCard)
            }
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

    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.TableView.cellBackground
        layer.cornerRadius = UIConstants.extraLargeCornerRadius

        iconCash.image = UIImage(systemName: SystemImages.banknoteFill)
        iconCash.tintColor = UIColor.systemGreen
        iconCash.contentMode = .scaleAspectFit
        iconCard.image = UIImage(systemName: SystemImages.creditCardCircleFill)
        iconCard.tintColor = UIColor.systemBlue
        iconCard.contentMode = .scaleAspectFit

        cashLabel.apply(.balanceTitle)
        cashLabel.text = R.string.global.receivedInCash()
        cardLabel.apply(.balanceTitle)
        cardLabel.text = R.string.global.receivedByCard()

        cashValue.apply(.balanceValue)
        cardValue.apply(.balanceValue)

        let cashRow = UIStackView(arrangedSubviews: [iconCash, cashLabel, UIView(), cashValue])
        cashRow.axis = .horizontal
        cashRow.spacing = UIConstants.smallSpacing
        iconCash.size(
            CGSize(width: UIConstants.iconContainerSize, height: UIConstants.iconContainerSize))
        cashLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        cashValue.setContentCompressionResistancePriority(.required, for: .horizontal)

        let cardRow = UIStackView(arrangedSubviews: [iconCard, cardLabel, UIView(), cardValue])
        cardRow.axis = .horizontal
        cardRow.spacing = UIConstants.smallSpacing
        iconCard.size(
            CGSize(width: UIConstants.iconContainerSize, height: UIConstants.iconContainerSize))
        cardLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        cardValue.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [cashRow, cardRow])
        stack.axis = .vertical
        stack.spacing = UIConstants.standardSpacing

        addSubview(stack)
        stack.edgesToSuperview(
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
}
