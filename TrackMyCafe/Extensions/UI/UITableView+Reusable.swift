//
//  UITableView+Reusable.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import UIKit

extension UITableView {
    func register(baseCell cellType: UITableViewCell.Type) {
        if let cellNib = cellType.nib {
            self.register(cellNib, forCellReuseIdentifier: cellType.identifier)
        } else {
            self.register(cellType, forCellReuseIdentifier: cellType.identifier)
        }
    }
    
    func register(baseHeaderFooter viewType: UITableViewHeaderFooterView.Type) {
        if let nib = viewType.nib {
            self.register(nib, forHeaderFooterViewReuseIdentifier: viewType.identifier)
        } else {
            self.register(viewType, forHeaderFooterViewReuseIdentifier: viewType.identifier)
        }
    }
    
    func dequeueBaseCell<Cell: UITableViewCell>(_ cell: Cell.Type, for indexPath: IndexPath) -> Cell {
        let dequeuedCell = self.dequeueReusableCell(withIdentifier: cell.identifier, for: indexPath)
        guard let typedCell = dequeuedCell as? Cell else {
            fatalError("Wrong cell type \(String(describing: dequeuedCell.self))")
        }
        return typedCell
    }
    
    func dequeueBaseHeaderFooterView<View: UITableViewHeaderFooterView>(_ view: View.Type) -> View {
        let dequeuedView = self.dequeueReusableHeaderFooterView(withIdentifier: view.identifier)
        guard let typedView = dequeuedView as? View else {
            fatalError("Wrong view type \(String(describing: dequeuedView.self))")
        }
        return typedView
    }
    
    func sizeToFitComponent(_ view: UIView?) -> UIView? {
        guard let view = view else { return nil }
        let height = view.systemLayoutSizeFitting(.init(width: bounds.size.width, height: .greatestFiniteMagnitude),
                                                  withHorizontalFittingPriority: .required,
                                                  verticalFittingPriority: .fittingSizeLevel).height
        var viewFrame = view.frame
        
        if height != viewFrame.size.height {
            viewFrame.size.height = height
            view.frame = viewFrame
            return view
        }
        return nil
    }
}

