import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class SidebarViewModel {
    var commodities: [Commodity] = []
    var freshCounts: [String: Int] = [:]
    var selectedCommodity: Commodity?

    func load(context: ModelContext) {
        let descriptor = FetchDescriptor<Commodity>(sortBy: [SortDescriptor(\.sortOrder)])
        commodities = (try? context.fetch(descriptor)) ?? []

        // Compute fresh counts (articles in last 8 hours)
        let cutoff = Date().addingTimeInterval(-8 * 3600)
        for commodity in commodities {
            let name = commodity.name
            let items = commodity.newsItems ?? []
            freshCounts[name] = items.filter { $0.publishedAt > cutoff }.count
        }
    }

    var grouped: [(group: CommoditySeeds.Group, items: [Commodity])] {
        var result: [(CommoditySeeds.Group, [Commodity])] = []
        for group in CommoditySeeds.Group.allCases {
            let items = commodities.filter { CommoditySeeds.group(for: $0.name) == group }
            if !items.isEmpty {
                result.append((group, items))
            }
        }
        return result
    }
}
