import TinyConstraints
import UIKit

final class TransactionTableViewCell: UITableViewCell {
  static let identifier = "TransactionTableViewCell"
  private static let df = DateFormatter.appFullDate

  private let cardView: UIView = {
    let v = UIView()
    v.backgroundColor = UIColor.TableView.cellBackground
    v.layer.cornerRadius = UIConstants.extraLargeCornerRadius
    return v
  }()

  private let titleLabel: UILabel = {
    let l = UILabel()
    l.applyDynamic(Typography.body)
    l.textColor = UIColor.Main.text
    return l
  }()

  private let dateLabel: UILabel = {
    let l = UILabel()
    l.applyDynamic(Typography.footnote)
    l.textColor = UIColor.Main.text.alpha(0.6)
    return l
  }()

  private let amountLabel: UILabel = {
    let l = UILabel()
      l.applyDynamic(Typography.body)
    l.textAlignment = .right
    return l
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = UIColor.Main.background
    contentView.backgroundColor = UIColor.Main.background
    setupLayout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String, date: Date, amount: Double, isIncome: Bool) {
    titleLabel.text = title
    dateLabel.text = Self.df.string(from: date)

    let prefix = isIncome ? "+" : "-"
    let formatted = NumberFormatter.currencyInteger.string(amount)
    amountLabel.text = "\(prefix)\(formatted)"
      amountLabel.textColor = Theme.current.primaryText
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    titleLabel.text = nil
    dateLabel.text = nil
    amountLabel.text = nil
    amountLabel.textColor = Theme.current.primaryText
  }

  private func setupLayout() {
    contentView.addSubview(cardView)
    cardView.edgesToSuperview(
      insets: .init(
        top: UIConstants.smallSpacing, left: 0, bottom: UIConstants.smallSpacing, right: 0))

    cardView.addSubview(titleLabel)
    cardView.addSubview(dateLabel)
    cardView.addSubview(amountLabel)

    titleLabel.topToSuperview(offset: UIConstants.standardPadding)
    titleLabel.leadingToSuperview(offset: UIConstants.standardPadding)
    titleLabel.trailingToLeading(
      of: amountLabel, offset: -UIConstants.smallSpacing, relation: .equalOrLess)

    dateLabel.topToBottom(of: titleLabel, offset: 2)
    dateLabel.leading(to: titleLabel)
    dateLabel.bottomToSuperview(offset: -UIConstants.standardPadding)

    amountLabel.centerYToSuperview()
    amountLabel.trailingToSuperview(offset: UIConstants.standardPadding)
  }
}
