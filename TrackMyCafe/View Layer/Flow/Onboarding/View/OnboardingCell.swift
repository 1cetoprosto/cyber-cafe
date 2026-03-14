import UIKit
import TinyConstraints

final class OnboardingCell: UICollectionViewCell {

    static let reuseId = "OnboardingCell"

    // MARK: - UI Elements

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = UIColor.Button.background
        return iv
    }()

    private let titleLabel: AppLabel = {
        let label = AppLabel(style: .largeTitle)
        label.textColor = UIColor.Main.text
        label.textAlignment = .center
        return label
    }()

    private let descriptionLabel: AppLabel = {
        let label = AppLabel(style: .bodyMultiline)
        label.textColor = UIColor.Main.secondaryText
        label.textAlignment = .center
        return label
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.alignment = .center
        return sv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.addSubview(stackView)

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionLabel)

        stackView.centerInSuperview()
        stackView.widthToSuperview(multiplier: 0.8)

        imageView.height(150)
        imageView.width(150)
    }

    // MARK: - Configure

    func configure(with slide: OnboardingSlide) {
        titleLabel.text = slide.title
        descriptionLabel.text = slide.description

        if let image = UIImage(systemName: slide.imageName) {
            imageView.image = image
        } else {
            // Fallback if system name not found (shouldn't happen with valid SF Symbols)
            imageView.image = UIImage(systemName: "star.fill")
        }
    }
}
