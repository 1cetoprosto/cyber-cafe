//
//  UIKitFactory.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import UIKit

//NEED REFACTORING
class UIKitFactory {
    
    static func setupSearch(_ searchController: UISearchController, base: UIViewController) -> UISearchController {
        searchController.searchResultsUpdater = base as? UISearchResultsUpdating
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = R.string.global.search()
        base.navigationItem.searchController = searchController
        base.definesPresentationContext = true
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self, MainNavigationController.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self, MainNavigationController.self]).backgroundColor = UIColor.NavBar.background
        return searchController
    }
}
