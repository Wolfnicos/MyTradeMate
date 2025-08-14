import Foundation

@MainActor
final class TradeHistoryVM: ObservableObject {
    @Published var fills: [OrderFill] = []
    private var page = 0
    private let pageSize = 50
    
    func onAppear() { reload() }
    
    func reload() {
        Task {
            let all = await TradeManager.shared.fills
            await MainActor.run {
                self.page = 0
                self.fills = Array(all.prefix(pageSize))
            }
        }
    }
    
    func loadMoreIfNeeded(current item: OrderFill?) {
        guard let item, let last = fills.last, item.id == last.id else { return }
        Task {
            let all = await TradeManager.shared.fills
            page += 1
            let end = min(all.count, (page + 1) * pageSize)
            let next = Array(all.prefix(end))
            await MainActor.run { self.fills = next }
        }
    }
}