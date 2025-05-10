//
//  StaffCategoriesController.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import UIKit

class StaffCategoriesController: UITableViewController {
    
    enum Category: CaseIterable {
        case waiter
        case seniorWaiter
        
        var name: String {
            switch self {
                case .waiter: return R.string.global.staff_sectionWaiter()
                case .seniorWaiter: return R.string.global.staff_sectionSeniorWaiter()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.global.menuStaff()
        
        tableView.backgroundColor = UIColor.Main.background
        tableView.separatorStyle = .none
        
        tableView.register(baseCell: PersonTableViewCell.self)
        tableView.tableFooterView = UIView()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Category.allCases.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueBaseCell(PersonTableViewCell.self, for: indexPath)
        if indexPath.item == 0 {
            cell.setup(RequestManager.shared.admin)
            return cell
        }
        cell.textLabel?.text = Category.allCases[indexPath.row - 1].name
        cell.textLabel?.textColor = UIColor.Main.text
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            let controller = AdminDetailsController()
            navigationController?.pushViewController(controller, animated: true)
            return
        }
        switch Category.allCases[indexPath.row - 1] {
            case .waiter:
                let controller = TechniciansListController()
                navigationController?.pushViewController(controller, animated: true)
            case .seniorWaiter:
                let controller = ModeratorListController()
                navigationController?.pushViewController(controller, animated: true)
        }
    }
}

