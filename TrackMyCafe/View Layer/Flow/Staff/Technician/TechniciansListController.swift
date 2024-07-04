//
//  TechniciansListController.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import UIKit

enum TechniciansListControllerState {
    case simple
    //case forCalculation
}

class TechniciansListController: PersonsListViewController<Technician> {
    
    let currentState: TechniciansListControllerState
    
    init(state: TechniciansListControllerState = .simple) {
            self.currentState = state
            super.init(nibName: nil, bundle: nil)
        }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var rightBarButtons: [UIBarButtonItem]? {
        switch currentState {
        case .simple:
            return [UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTechnician(_:)))]
//        case .forCalculation:
//            return nil
        }
    }
    
    override var updateNotification: Notification.Name {
        return .techniciansInfoReload
    }
    
    override var items: [Technician] {
        switch currentState {
        case .simple:
            return RequestManager.shared.technicians
                .filter { $0.role == .technician || $0.role == .techMod }
                .filter { $0.enabled }
//        case .forCalculation:
//            return RequestManager.shared.technicians
//                .filter { $0.role == .technician || $0.role == .techMod }
//                .filter { $0.enabled }
//                .filter { $0.isAllowedCalculationsForAdministrator }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.global.staff_sectionTech()
    }
    
    override func didSelect(item: Technician) {
        switch currentState {
        case .simple:
            let controller = TechnicianDetailsController(item, fromMod: false)
            show(controller, sender: self)
//        case .forCalculation:
//            let controller = TechnicianDebtOrdersController(ordersOwner: item.firebaseRef)
//            show(controller, sender: self)
        }
    }
    
    // MARK: - Actions
    @objc func addTechnician(_ sender: UIBarButtonItem) {
        let staffCount = RequestManager.shared.technicians.filter { $0.enabled }.count
        if staffCount >= IAPManager.shared.currentSubscription.staffCount {
            PopupFactory.showPopup(title: R.string.global.warning(),
                                   description: R.string.global.technicianLimitReached(),
                                   buttonTitle: R.string.global.changeSub()) {[weak self] in
                let controller = SubscriptionController.makeReached()
                self?.navigationController?.pushViewController(controller, animated: true)
            }
        } else {
            let controller = CreateEditTechnicianController(moderType: false)
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}

