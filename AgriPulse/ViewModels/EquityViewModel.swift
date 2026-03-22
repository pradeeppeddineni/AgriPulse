import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class EquityViewModel {
    var commodities: [Commodity] = []
    var freshCounts: [String: Int] = [:]
    var isRefreshing = false

    private static let equityNames: Set<String> = ["Indian Equity", "Global Equity", "Crypto", "Mutual Funds"]

    func load(context: ModelContext) {
        let descriptor = FetchDescriptor<Commodity>(sortBy: [SortDescriptor(\.sortOrder)])
        let all = (try? context.fetch(descriptor)) ?? []
        commodities = all.filter { Self.equityNames.contains($0.name) }

        let cutoff = Date().addingTimeInterval(-8 * 3600)
        for commodity in commodities {
            let items = commodity.newsItems ?? []
            freshCounts[commodity.name] = items.filter { $0.publishedAt > cutoff }.count
        }
    }

    func commodity(named name: String) -> Commodity? {
        commodities.first { $0.name == name }
    }

    func freshCount(for name: String) -> Int {
        freshCounts[name] ?? 0
    }

    func refresh(commodity: Commodity, context: ModelContext) async -> Int {
        isRefreshing = true
        defer { isRefreshing = false }
        let count = await NewsService.shared.refreshNews(for: commodity, context: context)
        load(context: context)
        return count
    }
}
