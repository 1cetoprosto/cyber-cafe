//
//  BioAuthViewController.swift
//  Cyber-coffe
//
//  Created by Alexander Momotiuk on 27.07.2020.
//

import UIKit
import LocalAuthentication

class BioAuthViewController: UIViewController {
    
    private lazy var iconView = UIImageView()
    private lazy var titleLabel: UILabel = {
        let label = AppLabel(style: .footnote)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var settingsButton: UIButton = {
        let button = DefaultButton()
        button.setTitle(R.string.auth.enableBioLater(), for: .normal)
        button.height(44)
        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var enableButton: UIButton = {
        let button = DefaultButton()
        button.height(44)
        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        return button
    }()
    
    private let context: LAContext
    private var viewModel: BioAuthViewModelType?

    init(_ context: LAContext) {
        self.context = context
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        setupData()
    }

    private func bindViewModel() {
        viewModel = BioAuthViewModel(context: context)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.Main.background
        iconView.tintColor = UIColor.Main.text
        
        iconView.size(.init(width: 90, height: 90))
        
        let contentView = UIView()
        view.addSubview(contentView)
        contentView.addSubview(iconView)
        iconView.topToSuperview()
        iconView.centerXToSuperview()
        
        contentView.addSubview(titleLabel)
        titleLabel.topToBottom(of: iconView, offset: 12)
        titleLabel.horizontalToSuperview()
        titleLabel.bottomToSuperview()
        
        contentView.centerInSuperview()
        if UIDevice.current.userInterfaceIdiom == .pad {
            contentView.width(300)
        } else {
            contentView.horizontalToSuperview(insets: .horizontal(20))
        }
        
        let buttonsStack = UIStackView(arrangedSubviews: [settingsButton, enableButton])
        buttonsStack.axis = .vertical
        buttonsStack.spacing = UIConstants.mediumSpacing
        view.addSubview(buttonsStack)
        buttonsStack.centerXToSuperview()
        buttonsStack.bottomToSuperview(offset: -20, usingSafeArea: true)
        if UIDevice.current.userInterfaceIdiom == .pad {
            buttonsStack.width(300)
        } else {
            buttonsStack.horizontalToSuperview(insets: .horizontal(20))
        }
    }
    
    private func setupData() {
        guard let viewModel else { return }
        let typeString = viewModel.biometryDisplayName
        if viewModel.iconUsesTouchID, let touchImage = R.image.touchId() {
            iconView.image = touchImage.tint(color: UIColor.Main.text)
        } else if viewModel.iconUsesFaceID, let faceImage = R.image.faceId() {
            iconView.image = faceImage.tint(color: UIColor.Main.text)
        }

        titleLabel.text = R.string.auth.useBioAuth(typeString)
        enableButton.setTitle(R.string.auth.enableBioAuth(typeString), for: .normal)
    }
    
    // MARK: - Actions
    @objc private func buttonAction(_ sender: UIButton) {
        viewModel?.enableBioAuth(sender == enableButton)
        let controller = MainTabBarController() // MenuController()
        // AppDelegate.shared.set(root: controller)
        SceneDelegate.shared.set(root: controller)
    }
}
