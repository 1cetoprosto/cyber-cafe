//
//  PersonsListViewController.swift
//  TrackMyCafe Prod
//
//  Created by Леонід Квіт on 15.06.2024.
//

import UIKit

class PersonsListViewController<ItemType: PersonListModelProtocol>: UITableViewController, UISearchResultsUpdating {
    
    var mutableItems: [ItemType] = []
    var isReorderingEnabled = false
    
    internal var rightBarButtons: [UIBarButtonItem]? {
        return nil
    }
    
    internal var updateNotification: Notification.Name {
        return Notification.Name("")
    }
    
    internal var items: [ItemType] {
        return []
    }
    
    internal var filteredItems = [ItemType]()
    internal var searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: updateNotification, object: nil)
        tableView.register(PersonTableViewCell.self, forCellReuseIdentifier: "PersonTableViewCell")
        tableView.tableFooterView = UIView()
        
        navigationItem.rightBarButtonItems = rightBarButtons
        searchController = UIKitFactory.setupSearch(searchController, base: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.hidesSearchBarWhenScrolling = true
        reload()
    }
    
    func didSelect(item: ItemType) {
        
    }
    
    @objc func reload() {
        tableView.setEditing(isReorderingEnabled, animated: true)
        tableView.reloadData()
    }
    
    private func item(at indexPath: IndexPath) -> ItemType {
        if isFiltering() {
            return filteredItems[indexPath.row]
        }
        return items[indexPath.row]
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredItems.count
        }
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueBaseCell(PersonTableViewCell.self, for: indexPath)
        cell.setup(item(at: indexPath))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        didSelect(item: item(at: indexPath))
    }
    
    // MARK: - Search
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String) {
        filteredItems = items.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }

    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return isReorderingEnabled
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedObject = mutableItems[sourceIndexPath.row]
        mutableItems.remove(at: sourceIndexPath.row)
        mutableItems.insert(movedObject, at: destinationIndexPath.row)
        
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
}
