//
//  StaffCategoriesController.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import UIKit

class StaffCategoriesController: UITableViewController {
    
    enum Category: CaseIterable {
        case tech
        case moder
        
        var name: String {
            switch self {
                case .tech: return R.string.global.staff_sectionTech()
                case .moder: return R.string.global.staff_sectionMod()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.global.menuStaff()
        
        tableView.register(baseCell: PersonTableViewCell.self)
        tableView.tableFooterView = UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Category.allCases.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.item == 0 {
            let cell = tableView.dequeueBaseCell(PersonTableViewCell.self, for: indexPath)
            cell.setup(RequestManager.shared.admin)
            return cell
        }
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = Category.allCases[indexPath.row - 1].name
        cell.textLabel?.font = .systemFont(ofSize: 19, weight: .medium)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            let controller = AdminDetailsController()
            navigationController?.pushViewController(controller, animated: true)
            return
        }
        switch Category.allCases[indexPath.row - 1] {
            case .tech:
                let controller = TechniciansListController()
                navigationController?.pushViewController(controller, animated: true)
            case .moder:
                let controller = ModeratorListController()
                navigationController?.pushViewController(controller, animated: true)
        }
    }
}

