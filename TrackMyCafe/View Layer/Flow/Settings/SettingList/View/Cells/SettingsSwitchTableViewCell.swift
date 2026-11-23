import UIKit

final class SettingsSwitchTableViewCell: BaseSettingsCell {

    private let switchView: UISwitch = {
        let switchView = UISwitch()
        switchView.onTintColor = .systemGreen
        switchView.thumbTintColor = UIColor.Main.background
        switchView.translatesAutoresizingMaskIntoConstraints = false
        return switchView
    }()

    private var handler: ((Bool) -> Void)?
    private var labelTrailingToSwitch: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .none
        contentView.addSubview(switchView)

        labelTrailingConstraint?.isActive = false
        labelTrailingToSwitch = label.trailingAnchor.constraint(
            lessThanOrEqualTo: switchView.leadingAnchor, constant: -10)

        NSLayoutConstraint.activate([
            switchView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            switchView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
        ])
        labelTrailingToSwitch?.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with option: SettingsSwitchOption) {
        label.text = option.title
        iconImageView.image = option.icon
        iconContainer.backgroundColor = option.iconBackgroundColor
        switchView.isOn = option.isOn
        handler = option.handler

        switchView.removeTarget(nil, action: nil, for: .valueChanged)
        switchView.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        handler = nil
        switchView.removeTarget(nil, action: nil, for: .valueChanged)
    }

    @objc private func switchChanged(_ sender: UISwitch) {
        handler?(sender.isOn)
    }
}
