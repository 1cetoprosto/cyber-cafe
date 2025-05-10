final class SubscriptionLinkButton: UIButton {
    
    init(title: String, fontSize: CGFloat = 14) {
        super.init(frame: .zero)
        setupButton(title: title, fontSize: fontSize)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton(title: String, fontSize: CGFloat) {
        setTitle(title, for: .normal)
        setTitleColor(.systemBlue, for: .normal)
        setTitleColor(UIColor.systemBlue.alpha(0.5), for: .highlighted)
        titleLabel?.font = .systemFont(ofSize: fontSize)
        translatesAutoresizingMaskIntoConstraints = false
    }
}