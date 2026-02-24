import UIKit

final class SettingsSwitchTableViewCell: BaseSettingsCell {
    
    private let switchView: UISwitch = {
        let switchView = UISwitch()
        switchView.onTintColor = .systemGreen
        switchView.thumbTintColor = UIColor.Main.background
        switchView.translatesAutoresizingMaskIntoConstraints = false
        return switchView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        accessoryType = .none
        self.addSubview(switchView)
        
        // Deactivate the trailing constraint from BaseSettingsCell to prevent overlap
        if let existingConstraint = contentView.constraints.first(where: {
            ($0.firstItem as? UILabel) == label && $0.firstAttribute == .trailing
        }) {
            existingConstraint.isActive = false
        }
        
        NSLayoutConstraint.activate([
            switchView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            switchView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            
            // Constrain label to stop before switchView
            label.trailingAnchor.constraint(equalTo: switchView.leadingAnchor, constant: -10)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with option: SettingsSwitchOption) {
        label.text = option.title
        iconImageView.image = option.icon
        iconContainer.backgroundColor = option.iconBackgroundColor
        switchView.isOn = option.isOn
        switchView.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }
    
    private var handler: ((Bool) -> Void)?
    
    @objc private func switchChanged(_ sender: UISwitch) {
        handler?(sender.isOn)
    }
}
