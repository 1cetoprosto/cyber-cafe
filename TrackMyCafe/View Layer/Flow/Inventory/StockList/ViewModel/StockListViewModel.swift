//
//  StockListViewModel.swift
//  TrackMyCafe
//
//  Created by AI Assistant on 20.02.2026.
//

import Foundation

protocol StockListViewModelProtocol {
    var onDataUpdated: (() -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var isLoading: ((Bool) -> Void)? { get set }
    
    var ingredients: [IngredientModel] { get }
    
    func fetchStock()
    func applyAdjustment(for ingredient: IngredientModel, delta: Double, reason: String)
}

final class StockListViewModel: StockListViewModelProtocol {
    
    // MARK: - Properties
    
    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    var isLoading: ((Bool) -> Void)?
    
    private(set) var ingredients: [IngredientModel] = [] {
        didSet {
            onDataUpdated?()
        }
    }
    
    private let dataService: IngredientDataServiceProtocol
    private let inventoryService: InventoryServiceProtocol
    
    // MARK: - Init
    
    init(
        dataService: IngredientDataServiceProtocol = DomainIngredientDataService.shared,
        inventoryService: InventoryServiceProtocol = InventoryService.shared
    ) {
        self.dataService = dataService
        self.inventoryService = inventoryService
    }
    
    // MARK: - Methods
    
    func fetchStock() {
        isLoading?(true)
        Task {
            do {
                let fetchedIngredients = try await dataService.fetchIngredients()
                await MainActor.run {
                    self.ingredients = fetchedIngredients.sorted(by: { $0.name < $1.name })
                    self.isLoading?(false)
                }
            } catch {
                await MainActor.run {
                    self.onError?(error.localizedDescription)
                    self.isLoading?(false)
                }
            }
        }
    }
    
    func applyAdjustment(for ingredient: IngredientModel, delta: Double, reason: String) {
        guard delta != 0 else { return }
        
        let adjustment = InventoryAdjustmentModel(
            ingredientId: ingredient.id,
            quantityDelta: delta,
            reason: reason
        )
        
        isLoading?(true)
        
        // Wrap legacy completion handler in async
        Task {
            do {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    inventoryService.processStockAdjustment(adjustment: adjustment) { result in
                        switch result {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                // Refresh list after update
                fetchStock()
                
            } catch {
                await MainActor.run {
                    self.onError?("Failed to update stock: \(error.localizedDescription)")
                    self.isLoading?(false)
                }
            }
        }
    }
}
