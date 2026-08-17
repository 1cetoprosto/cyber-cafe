import UIKit

class DefaultSegmentedControl: UISegmentedControl {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSegmented()
    }

    override init(items: [Any]?) {
        super.init(items: items)
        setupSegmented()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSegmented()
    }

    private func setupSegmented() {
        translatesAutoresizingMaskIntoConstraints = false
        selectedSegmentTintColor = Theme.current.tabBarTint
        setTitleTextAttributes(
            [
                .foregroundColor: Theme.current.primaryText,
                .font: Typography.bodyMedium
            ],
            for: .normal)
        setTitleTextAttributes(
            [
                .foregroundColor: UIColor.white,
                .font: Typography.headline
            ],
            for: .selected)
    }
}
