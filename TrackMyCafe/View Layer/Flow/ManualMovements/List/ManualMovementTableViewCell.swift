import TinyConstraints
import UIKit

final class ManualMovementTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ManualMovementTableViewCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.applyDynamic(Typography.title3DemiBold)
        label.textColor = UIColor.Main.text
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.applyDynamic(Typography.footnote)
        label.textColor = UIColor.Main.text.alpha(0.6)
        label.numberOfLines = 2
        return label
    }()

    private let amountLabel: UILabel = {
        let label = UILabel()
        label.applyDynamic(Typography.title3DemiBold)
        label.textAlignment = .right
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private let vStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = UIConstants.smallSpacing
        return stack
    }()

    private let hStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = UIConstants.standardSpacing
        stack.alignment = .top
        return stack
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UIColor.TableView.cellBackground
        selectionStyle = .default

        vStack.addArrangedSubview(titleLabel)
        vStack.addArrangedSubview(subtitleLabel)

        hStack.addArrangedSubview(vStack)
        hStack.addArrangedSubview(amountLabel)

        contentView.addSubview(hStack)
        hStack.edgesToSuperview(insets: .uniform(UIConstants.standardPadding))
    }

    func configure(with operation: ManualMovementOperation) {
        titleLabel.text = operationTitle(kind: operation.kind)
        subtitleLabel.text = subtitleText(for: operation)

        let amountText = formattedAmountText(for: operation)
        amountLabel.text = amountText.text
        amountLabel.textColor = amountText.color
    }

    private func operationTitle(kind: ManualMovementKind) -> String {
        switch kind {
        case .deposit:
            return NSLocalizedString("manualMovementDeposit", tableName: "Global", comment: "")
        case .withdrawal:
            return NSLocalizedString("manualMovementWithdrawal", tableName: "Global", comment: "")
        case .transfer:
            return NSLocalizedString("manualMovementTransfer", tableName: "Global", comment: "")
        case .adjustment:
            return NSLocalizedString("manualMovementAdjustment", tableName: "Global", comment: "")
        }
    }

    private func subtitleText(for operation: ManualMovementOperation) -> String? {
        let accountText: String?
        switch operation.kind {
        case .transfer:
            if let from = operation.fromAccount, let to = operation.toAccount {
                accountText = "\(accountTitle(from)) → \(accountTitle(to))"
            } else {
                accountText = nil
            }
        case .deposit:
            accountText = operation.toAccount.map { accountTitle($0) }
        case .withdrawal, .adjustment:
            accountText = operation.fromAccount.map { accountTitle($0) }
        }

        let note = operation.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteText = (note?.isEmpty == false) ? note : nil

        switch (accountText, noteText) {
        case (nil, nil):
            return nil
        case (let a?, nil):
            return a
        case (nil, let n?):
            return n
        case (let a?, let n?):
            return "\(a) • \(n)"
        }
    }

    private func accountTitle(_ account: PaymentAccount) -> String {
        switch account {
        case .cash:
            return NSLocalizedString("cash", tableName: "Global", comment: "")
        case .card:
            return NSLocalizedString("card", tableName: "Global", comment: "")
        }
    }

    private func formattedAmountText(
        for operation: ManualMovementOperation
    ) -> (text: String, color: UIColor) {
        let currency: String
        let prefix: String
        let color: UIColor

        switch operation.kind {
        case .deposit:
            prefix = "+"
            currency = NumberFormatter.currencyInteger.string(abs(operation.amount))
            color = UIColor.systemGreen
        case .withdrawal:
            prefix = "-"
            currency = NumberFormatter.currencyInteger.string(abs(operation.amount))
            color = UIColor.systemRed
        case .transfer:
            prefix = ""
            currency = NumberFormatter.currencyInteger.string(abs(operation.amount))
            color = UIColor.Main.text
        case .adjustment:
            let raw = operation.amount
            prefix = raw >= 0 ? "+" : "-"
            currency = NumberFormatter.currencyInteger.string(abs(raw))
            color = raw >= 0 ? UIColor.systemGreen : UIColor.systemRed
        }

        return ("\(prefix)\(currency)", color)
    }
}

