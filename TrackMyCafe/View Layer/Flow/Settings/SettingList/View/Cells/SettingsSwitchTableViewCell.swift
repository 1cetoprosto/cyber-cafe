import UIKit

final class SettingsSwitchTableViewCell: BaseSettingsCell {

    private let switchView: UISwitch = {
        let switchView = UISwitch()
        switchView.onTintColor = .systemGreen
        switchView.thumbTintColor = UIColor.Main.background
        switchView.translatesAutoresizingMaskIntoConstraints = false
        return switchView
    }()

    private lazy var infoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "info.circle"), for: .normal)
        button.tintColor = UIColor.Main.secondaryText
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        return button
    }()

    private var handler: ((Bool) -> Void)?
    private var infoHandler: (() -> Void)?
    private var labelTrailingToSwitch: NSLayoutConstraint?
    private var labelTrailingToInfo: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .none
        contentView.addSubview(switchView)
        contentView.addSubview(infoButton)

        labelTrailingConstraint?.isActive = false

        labelTrailingToSwitch = label.trailingAnchor.constraint(
            equalTo: switchView.leadingAnchor, constant: -10)
        labelTrailingToInfo = label.trailingAnchor.constraint(
            equalTo: infoButton.leadingAnchor, constant: -8)

        NSLayoutConstraint.activate([
            switchView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            switchView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),

            infoButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            infoButton.trailingAnchor.constraint(
                equalTo: switchView.leadingAnchor, constant: -8),
            infoButton.widthAnchor.constraint(equalToConstant: 24),
            infoButton.heightAnchor.constraint(equalToConstant: 24),
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
        infoHandler = option.infoHandler

        let showInfo = option.infoHandler != nil
        infoButton.isHidden = !showInfo
        labelTrailingToSwitch?.isActive = !showInfo
        labelTrailingToInfo?.isActive = showInfo

        switchView.removeTarget(nil, action: nil, for: .valueChanged)
        switchView.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        handler = nil
        infoHandler = nil
        infoButton.isHidden = true
        switchView.removeTarget(nil, action: nil, for: .valueChanged)
    }

    @objc private func switchChanged(_ sender: UISwitch) {
        handler?(sender.isOn)
    }

    @objc private func infoButtonTapped() {
        infoHandler?()
    }
}
