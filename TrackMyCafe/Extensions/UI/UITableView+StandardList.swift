import UIKit

extension UITableView {
    static func standardList(style: UITableView.Style = .insetGrouped) -> UITableView {
        let tableView = UITableView(frame: .zero, style: style)
        tableView.applyStandardListAppearance()
        return tableView
    }

    func applyStandardListAppearance() {
        backgroundColor = UIColor.Main.background
        separatorStyle = .singleLine
        separatorColor = UIColor.TableView.separator
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 56
        sectionHeaderHeight = UITableView.automaticDimension
        estimatedSectionHeaderHeight = 28

        if #available(iOS 15.0, *) {
            sectionHeaderTopPadding = 0
        }
    }
}
