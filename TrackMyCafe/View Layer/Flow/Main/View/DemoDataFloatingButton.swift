
//
//  DemoDataFloatingButton.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 24.02.2026.
//

import UIKit
import TinyConstraints

final class DemoDataFloatingButton: UIButton {

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "trash.fill")?.withRenderingMode(.alwaysTemplate)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemRed
        return imageView
    }()

    private let titleLabelView: UILabel = {
        let label = UILabel()
        label.text = R.string.global.deleteDemoData()
        label.font = Typography.bodyMedium
        label.textColor = UIColor.Main.text
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = UIColor.Main.background // Assuming main background is contrasting or specific color
        // For floating button usually a distinct background like white on dark or vice versa
        // Let's use specific colors to match "monobank style" (usually light/white pill on dark bg, or distinct)
        if #available(iOS 13.0, *) {
            backgroundColor = UIColor { trait in
                return trait.userInterfaceStyle == .dark ? UIColor(white: 0.2, alpha: 1.0) : UIColor.white
            }
        } else {
            backgroundColor = .white
        }
        
        layer.cornerRadius = 24 // Pill shape
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        
        // Horizontal Stack
        let stackView = UIStackView(arrangedSubviews: [iconImageView, titleLabelView])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.isUserInteractionEnabled = false // Let button handle touch
        
        addSubview(stackView)
        stackView.centerInSuperview()
        
        // Constraints for button size (pill)
        height(48)
        width(200, relation: .equalOrGreater) // Minimum width
        stackView.leadingToSuperview(offset: 20)
        stackView.trailingToSuperview(offset: 20)
    }
    
    // Add touch feedback animation
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            }
        }
    }
}
