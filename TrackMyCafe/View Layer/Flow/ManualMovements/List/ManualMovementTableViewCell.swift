import TinyConstraints
import UIKit

final class ManualMovementTableViewCell: BaseListTableViewCell {
    static let reuseIdentifier = "ManualMovementTableViewCell"

    private let titleLabel: AppLabel = {
        let label = AppLabel(style: .body)
        label.textColor = UIColor.TableView.cellLabel
        return label
    }()

    private let subtitleLabel: AppLabel = {
        let label = AppLabel(style: .footnote)
        label.textColor = UIColor.Main.secondaryText
        label.numberOfLines = 2
        return label
    }()

    private let amountLabel: AppLabel = {
        let label = AppLabel(style: .bodyValue)
        label.textAlignment = .right
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
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func setupUI() {
        accessoryType = .disclosureIndicator

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
            color = UIColor.TableView.cellLabel
        case .adjustment:
            let raw = operation.amount
            prefix = raw >= 0 ? "+" : "-"
            currency = NumberFormatter.currencyInteger.string(abs(raw))
            color = raw >= 0 ? UIColor.systemGreen : UIColor.systemRed
        }

        return ("\(prefix)\(currency)", color)
    }
}
