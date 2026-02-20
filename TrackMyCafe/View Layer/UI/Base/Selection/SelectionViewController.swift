import UIKit

/// A generic cell configuration closure
typealias CellConfiguration<T> = (UITableViewCell, T) -> Void

class SelectionViewController<T>: SearchTableViewController {
    
    // MARK: - Properties
    
    var items: [T] = [] {
        didSet {
            if !isFiltering { tableView.reloadData() }
        }
    }
    
    var filteredItems: [T] = [] {
        didSet {
            if isFiltering { tableView.reloadData() }
        }
    }
    
    // Callback when an item is selected
    var onSelect: ((T) -> Void)?
    
    // Closure to configure the cell
    private let configureCell: CellConfiguration<T>
    // Closure to filter items
    private let filterHandler: ((T, String) -> Bool)?
    
    private let cellIdentifier = "SelectionCell"
    
    // MARK: - Init
    
    init(items: [T], 
         configureCell: @escaping CellConfiguration<T>, 
         filterHandler: ((T, String) -> Bool)? = nil) {
        self.items = items
        self.configureCell = configureCell
        self.filterHandler = filterHandler
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    // MARK: - Search Logic
    
    override func filterContentForSearchText(_ searchText: String) {
        guard let filterHandler = filterHandler else { return }
        filteredItems = items.filter { filterHandler($0, searchText) }
        tableView.reloadData()
    }
    
    // MARK: - TableView DataSource & Delegate
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering ? filteredItems.count : items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let item = isFiltering ? filteredItems[indexPath.row] : items[indexPath.row]
        
        configureCell(cell, item)
        
        // Default styling
        cell.backgroundColor = UIColor.Main.background
        cell.textLabel?.textColor = UIColor.Main.text
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = isFiltering ? filteredItems[indexPath.row] : items[indexPath.row]
        
        onSelect?(item)
        
        // Dismiss if presented modally or pop if pushed
        if navigationController?.viewControllers.first == self {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
}
