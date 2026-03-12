import UIKit

class BaseListTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        applyTheme()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func applyTheme() {
        backgroundColor = UIColor.TableView.cellBackground
        contentView.backgroundColor = UIColor.TableView.cellBackground
        selectionStyle = .default

        textLabel?.textColor = UIColor.TableView.cellLabel
        detailTextLabel?.textColor = UIColor.TableView.cellLabel

        let selected = UIView()
        selected.backgroundColor = UIColor.TableView.cellSelectionBackground
        selectedBackgroundView = selected
    }
}
