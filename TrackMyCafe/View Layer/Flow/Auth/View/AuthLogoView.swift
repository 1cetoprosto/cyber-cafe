//
//  AuthLogoView.swift
//  TrackMyCafe
//
//  Created by Trae on 24.02.2026.
//

import TinyConstraints
import UIKit

final class AuthLogoView: UIImageView {

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        contentMode = .scaleAspectFit
        isUserInteractionEnabled = true
        layer.cornerRadius = 24
        clipsToBounds = true
        backgroundColor = .clear
        size(CGSize(width: 115, height: 115))
        updateLogo()

        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) {
                [weak self] (_: AuthLogoView, _) in
                self?.updateLogo()
            }
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateLogo()
    }

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 17.0, *) {
            // Handled by trait change registration above.
        } else {
            updateLogo()
        }
    }

    private func updateLogo() {
        let isDark: Bool
        if Theme.currentSelection.appearance == .system {
            // Prefer window's trait collection if available, fallback to current
            let style =
                window?.traitCollection.userInterfaceStyle
                ?? UITraitCollection.current.userInterfaceStyle
            isDark = style == .dark
        } else {
            isDark = Theme.currentSelection.appearance == .dark
        }

        if isDark {
            // Try to fetch App Icon (Beige) from Bundle Info.plist
            if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
                let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
                let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
                let lastIcon = iconFiles.last,
                let appIcon = UIImage(named: lastIcon)
            {
                image = appIcon
            } else {
                // Fallback to appBigLogo if app icon not found
                image = R.image.appBigLogo()
            }
        } else {
            // Light theme -> appLogo (White background)
            image = R.image.appLogo()
        }
    }
}
