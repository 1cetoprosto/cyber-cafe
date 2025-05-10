//
//  ModeratorListController.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import UIKit

class ModeratorListController: PersonsListViewController<Technician> {
    
    override var rightBarButtons: [UIBarButtonItem]? {
        return [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTechnician(_:)))]
    }
    
    override var updateNotification: Notification.Name {
        return .techniciansInfoReload
    }

    override var items: [Technician] {
        return RequestManager.shared.technicians.filter { $0.role == .techMod || $0.role == .moderator }.filter { $0.enabled }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.global.staff_sectionSeniorWaiter()
        view.backgroundColor = UIColor.Main.background
    }
    
    override func didSelect(item: Technician) {
        let controller = TechnicianDetailsController(item, fromMod: true)
        show(controller, sender: self)
    }
    
    // MARK: - Actions
    @objc func addTechnician(_ sender: UIBarButtonItem) {
        let staffCount = RequestManager.shared.technicians.filter { $0.enabled }.count
//        if staffCount >= IAPManager.shared.currentSubscription.staffCount {
//            PopupFactory.showPopup(title: R.string.global.warning(),
//                                   description: R.string.global.technicianLimitReached(),
//                                   buttonTitle: R.string.global.changeSub()) {[weak self] in
//                let controller = SubscriptionController.makeReached()
//                self?.navigationController?.pushViewController(controller, animated: true)
//            }
//        } else {
            let controller = CreateEditTechnicianController(moderType: true)
            navigationController?.pushViewController(controller, animated: true)
        //}
    }
}

