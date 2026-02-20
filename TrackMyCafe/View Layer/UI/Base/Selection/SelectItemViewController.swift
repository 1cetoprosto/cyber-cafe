import UIKit

/// A concrete implementation for simple String selection or simple models
class SelectItemViewController: SelectionViewController<String> {
    
    // MARK: - Init
    
    /// Convenience init for simple string lists
    init(title: String, items: [String], onSelect: @escaping (String) -> Void) {
        super.init(items: items, configureCell: { cell, item in
            cell.textLabel?.text = item
        }, filterHandler: { item, query in
            return item.lowercased().contains(query.lowercased())
        })
        
        self.title = title
        self.onSelect = onSelect
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add specific UI customization for simple selection if needed
    }
}
