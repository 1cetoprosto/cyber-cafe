import UIKit

class SearchTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    let searchController = UISearchController(searchResultsController: nil)
    
    var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool {
        return searchController.isActive && !isSearchBarEmpty
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearch()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.Main.background
        tableView.tableFooterView = UIView()
    }
    
    private func setupSearch() {
        _ = UIKitFactory.setupSearch(searchController, base: self)
    }
    
    // MARK: - Search Logic
    
    /// Override this method to filter your data
    func filterContentForSearchText(_ searchText: String) {
        // Implementation in subclass
    }
}

// MARK: - UISearchResultsUpdating
extension SearchTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
}
