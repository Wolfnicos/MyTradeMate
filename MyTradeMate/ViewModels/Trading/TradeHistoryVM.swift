import Foundation

@MainActor
final class TradeHistoryVM: ObservableObject {
    @Published var fills: [OrderFill] = []
    @Published var sortOption: TradeSortOption = .dateNewest
    @Published var filterOption: TradeFilterOption = .all
    @Published var searchText: String = ""
    
    private var allFills: [OrderFill] = []
    private var page = 0
    private let pageSize = 50
    
    func onAppear() { reload() }
    
    func reload() {
        Task {
            let all = await TradeManager.shared.fills
            await MainActor.run {
                self.allFills = all
                self.page = 0
                self.applyFiltersAndSorting()
            }
        }
    }
    
    func applyFiltersAndSorting() {
        var filtered = allFills
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { fill in
                fill.symbol.display.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply side filter
        switch filterOption {
        case .all:
            break
        case .buyOnly:
            filtered = filtered.filter { $0.side == .buy }
        case .sellOnly:
            filtered = filtered.filter { $0.side == .sell }
        }
        
        // Apply sorting
        switch sortOption {
        case .dateNewest:
            filtered.sort { $0.timestamp > $1.timestamp }
        case .dateOldest:
            filtered.sort { $0.timestamp < $1.timestamp }
        case .priceHighest:
            filtered.sort { $0.price > $1.price }
        case .priceLowest:
            filtered.sort { $0.price < $1.price }
        case .quantityLargest:
            filtered.sort { $0.quantity > $1.quantity }
        case .quantitySmallest:
            filtered.sort { $0.quantity < $1.quantity }
        }
        
        // Apply pagination
        self.fills = Array(filtered.prefix(pageSize))
    }
    
    func loadMoreIfNeeded(current item: OrderFill?) {
        guard let item, let last = fills.last, item.id == last.id else { return }
        
        var filtered = allFills
        
        // Apply same filters as in applyFiltersAndSorting
        if !searchText.isEmpty {
            filtered = filtered.filter { fill in
                fill.symbol.display.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch filterOption {
        case .all:
            break
        case .buyOnly:
            filtered = filtered.filter { $0.side == .buy }
        case .sellOnly:
            filtered = filtered.filter { $0.side == .sell }
        }
        
        switch sortOption {
        case .dateNewest:
            filtered.sort { $0.timestamp > $1.timestamp }
        case .dateOldest:
            filtered.sort { $0.timestamp < $1.timestamp }
        case .priceHighest:
            filtered.sort { $0.price > $1.price }
        case .priceLowest:
            filtered.sort { $0.price < $1.price }
        case .quantityLargest:
            filtered.sort { $0.quantity > $1.quantity }
        case .quantitySmallest:
            filtered.sort { $0.quantity < $1.quantity }
        }
        
        page += 1
        let end = min(filtered.count, (page + 1) * pageSize)
        let next = Array(filtered.prefix(end))
        self.fills = next
    }
    
    func updateSort(_ newSort: TradeSortOption) {
        sortOption = newSort
        page = 0
        applyFiltersAndSorting()
    }
    
    func updateFilter(_ newFilter: TradeFilterOption) {
        filterOption = newFilter
        page = 0
        applyFiltersAndSorting()
    }
    
    func updateSearch(_ newSearch: String) {
        searchText = newSearch
        page = 0
        applyFiltersAndSorting()
    }
}