//
//  SubscriptionReuseView.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 02.07.2024.
//

import UIKit

class SubscriptionReuseView: UIView {
    
    // MARK: - Public Properties
    
    var text: String? {
        get { return titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    var textColor: UIColor {
        get { return titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }
    
    var font: UIFont {
        get { return titleLabel.font }
        set { titleLabel.font = newValue }
    }
    
    // MARK: - Private Properties
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.Main.text // Змінюємо на загальний колір тексту
        label.font = .systemFont(ofSize: 17) // Використовуємо стандартний розмір шрифту
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    
    private func setupLayout() {
        addSubview(titleLabel)
        titleLabel.edgesToSuperview(insets: .init(top: 8, left: 15, bottom: 8, right: 15))
    }
}

