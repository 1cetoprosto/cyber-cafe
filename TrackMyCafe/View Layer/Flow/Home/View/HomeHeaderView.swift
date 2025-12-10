import TinyConstraints
import UIKit

final class HomeHeaderView: UIView {
  var onAddIncome: (() -> Void)?
  var onAddExpense: (() -> Void)?

  private let titleLabel: UILabel = {
    let l = UILabel()
    l.applyDynamic(Typography.title2DemiBold)
    l.textColor = UIColor.Main.text
    l.text = "TrackMyCafe"
    return l
  }()

  private let dateLabel: UILabel = {
    let l = UILabel()
    l.applyDynamic(Typography.footnote)
    l.textColor = UIColor.Main.text.alpha(0.7)
    return l
  }()

  private let actionsStack = UIStackView()
  private let incomeButton = DefaultButton()
  private let expenseButton = UIButton(type: .system)

  private let todayCard = TodayCardView()
  private let weekContainer = InputContainerView(
    labelText: R.string.global.week(), inputType: .text(keyboardType: .decimalPad),
    isEditable: false
  )
  private let monthContainer = InputContainerView(
    labelText: R.string.global.month(), inputType: .text(keyboardType: .decimalPad),
    isEditable: false
  )
  private let profitCard = ProfitCard()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  func configure(
    date: Date, today: Double, week: Double, month: Double, expenses: Double, profit: Double
  ) {
    let df = DateFormatter()
    df.locale = .autoupdatingCurrent
    df.dateFormat = "d MMMM yyyy"
    dateLabel.text = df.string(from: date)

    todayCard.valueText = NumberFormatter.currencyInteger.string(today)
    weekContainer.text = NumberFormatter.currencyInteger.string(week)
    monthContainer.text = NumberFormatter.currencyInteger.string(month)
    profitCard.configure(expenses: expenses, profit: profit)
  }

  private func setupUI() {
    backgroundColor = UIColor.Main.background

    let headerStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
    headerStack.axis = .vertical
    headerStack.spacing = 2

    actionsStack.axis = .horizontal
    actionsStack.spacing = UIConstants.standardPadding
    actionsStack.distribution = .fillEqually

    incomeButton.setTitle("+ " + R.string.global.income(), for: .normal)
    incomeButton.addTarget(self, action: #selector(incomeTap), for: .touchUpInside)
    incomeButton.translatesAutoresizingMaskIntoConstraints = false
    incomeButton.heightAnchor.constraint(equalToConstant: UIConstants.buttonHeight).isActive = true

    expenseButton.setTitle("+ " + R.string.global.cost(), for: .normal)
    expenseButton.setTitleColor(UIColor.Main.text, for: .normal)
    expenseButton.layer.cornerRadius = UIConstants.largeCornerRadius
    expenseButton.layer.borderWidth = UIConstants.standardBorderWidth
    expenseButton.layer.borderColor = UIColor.Main.text.alpha(0.15).cgColor
    expenseButton.backgroundColor = UIColor.Main.background
    expenseButton.titleLabel?.font = Typography.title3
    if #available(iOS 11.0, *) {
      expenseButton.titleLabel?.adjustsFontForContentSizeCategory = true
    }
    expenseButton.addTarget(self, action: #selector(expenseTap), for: .touchUpInside)
    expenseButton.translatesAutoresizingMaskIntoConstraints = false
    expenseButton.heightAnchor.constraint(equalToConstant: UIConstants.buttonHeight).isActive = true

    actionsStack.addArrangedSubview(incomeButton)
    actionsStack.addArrangedSubview(expenseButton)

    weekContainer.configure(labelText: R.string.global.week())
    monthContainer.configure(labelText: R.string.global.month())
    let miniStack = UIStackView(arrangedSubviews: [weekContainer, monthContainer])
    miniStack.axis = .horizontal
    miniStack.spacing = UIConstants.standardPadding
    miniStack.distribution = .fillEqually

    let contentStack = UIStackView(arrangedSubviews: [
      headerStack, actionsStack, todayCard, miniStack, profitCard,
    ])
    contentStack.axis = .vertical
    contentStack.spacing = UIConstants.largeSpacing

    addSubview(contentStack)
    contentStack.edgesToSuperview(
      insets: .init(
        top: UIConstants.largeSpacing,
        left: UIConstants.standardPadding,
        bottom: UIConstants.largeSpacing,
        right: UIConstants.standardPadding
      )
    )

    let containerHeight =
      UIConstants.cellHeight + UIConstants.largeSpacing + UIConstants.standardPadding
    todayCard.height(containerHeight)
    weekContainer.height(containerHeight)
    monthContainer.height(containerHeight)
  }

  @objc private func incomeTap() { onAddIncome?() }
  @objc private func expenseTap() { onAddExpense?() }
}

// MARK: - Small UI Components
// Summary mini-cards now use InputContainerView for consistent styling

private final class ProfitCard: UIView {
  private let iconView = UIImageView()
  private let badgeView = UIView()
  private let titleLabel = UILabel()
  private let valueLabel = UILabel()
  private let divider = UIView()
  private let footerLabel = UILabel()

  init() {
    super.init(frame: .zero)
    backgroundColor = UIColor.TableView.cellBackground
    layer.cornerRadius = UIConstants.extraLargeCornerRadius

    badgeView.backgroundColor = UIColor.systemPink.withAlphaComponent(0.2)
    badgeView.layer.cornerRadius = 12
    iconView.image = UIImage(systemName: "arrow.down.right")
    iconView.tintColor = UIColor.systemPink
    iconView.contentMode = .scaleAspectFit
    titleLabel.applyDynamic(Typography.footnote)
    titleLabel.textColor = UIColor.Main.text.alpha(0.7)
    titleLabel.text = R.string.global.monthlyProfit()
    valueLabel.applyDynamic(Typography.title3DemiBold)
    valueLabel.textColor = UIColor.systemRed
    divider.backgroundColor = UIColor.Main.text.alpha(0.1)
    footerLabel.applyDynamic(Typography.footnote)
    footerLabel.textColor = UIColor.Main.text.alpha(0.7)

    badgeView.addSubview(iconView)
    iconView.size(CGSize(width: 40, height: 40))
    iconView.centerInSuperview()
    badgeView.size(CGSize(width: 44, height: 44))

      
      let vStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
      vStack.axis = .vertical
      vStack.spacing = UIConstants.smallSpacing
      
      let hStack = UIStackView(arrangedSubviews: [badgeView, vStack])
      hStack.axis = .horizontal
      hStack.spacing = UIConstants.smallSpacing
      
      //    let header = UIStackView(arrangedSubviews: [badgeView, titleLabel])
      //    header.axis = .horizontal
      //    header.spacing = UIConstants.smallSpacing
      
      let stack = UIStackView(arrangedSubviews: [hStack, divider, footerLabel])
      stack.axis = .vertical
      stack.spacing = UIConstants.smallSpacing
      
      addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: topAnchor, constant: UIConstants.standardPadding),
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UIConstants.standardPadding),
      stack.trailingAnchor.constraint(
        equalTo: trailingAnchor, constant: -UIConstants.standardPadding),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UIConstants.standardPadding),
    ])
    divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  func configure(expenses: Double, profit: Double) {
    let profitText = NumberFormatter.currencyInteger.string(profit)
    valueLabel.text = profitText
    valueLabel.textColor = profit >= 0 ? UIColor.systemGreen : UIColor.systemRed
    let expensesText = NumberFormatter.currencyInteger.string(expenses)
    footerLabel.text = R.string.global.expensesPrefix() + expensesText
  }
}

// MARK: - Today Card View
private final class TodayCardView: UIView {
  private let iconView = UIImageView()
  private let iconBadge = UIView()
  private let titleLabel = UILabel()
  private let valueLabel = UILabel()

  var valueText: String? { didSet { valueLabel.text = valueText } }

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.TableView.cellBackground
    layer.cornerRadius = UIConstants.extraLargeCornerRadius

    iconBadge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
    iconBadge.layer.cornerRadius = 12
    iconView.image = UIImage(systemName: "calendar")
      iconView.tintColor = UIColor.Button.background
    iconView.contentMode = .scaleAspectFit
    titleLabel.applyDynamic(Typography.footnote)
    titleLabel.textColor = UIColor.Main.text.alpha(0.7)
    titleLabel.text = R.string.global.today()
    valueLabel.applyDynamic(Typography.title3DemiBold)
    valueLabel.textColor = UIColor.Main.text

    iconBadge.addSubview(iconView)
    iconView.size(CGSize(width: 40, height: 40))
    iconView.centerInSuperview()
    iconBadge.size(CGSize(width: 44, height: 44))

      let header = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
      header.axis = .vertical
      header.spacing = UIConstants.smallSpacing
      
    let stack = UIStackView(arrangedSubviews: [iconBadge, header])
      stack.axis = .horizontal
      stack.spacing = UIConstants.smallSpacing


    addSubview(stack)
    stack.edgesToSuperview(
      insets: .init(
        top: UIConstants.standardPadding, left: UIConstants.standardPadding,
        bottom: UIConstants.standardPadding, right: UIConstants.standardPadding))
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Localization helper
