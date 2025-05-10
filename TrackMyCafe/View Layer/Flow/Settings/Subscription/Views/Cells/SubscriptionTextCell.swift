//
//  SubscriptionTextCell.swift
//  TrackMyCafe
//
//  Created by Леонід Квіт on 10.05.2025.
//

import UIKit

final class SubscriptionTextCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .clear
        textLabel?.numberOfLines = 0
        textLabel?.font = .systemFont(ofSize: 14, weight: .light)
        textLabel?.textColor = UIColor.TableView.cellLabel
        selectionStyle = .none
    }
    
    func configure(text: String) {
        textLabel?.text = text
    }
}
