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

    func commodity(named name: String) -> Commodity? {
        commodities.first { $0.name == name }
    }

    // Tab-level fresh counts
    private static let equityNames: Set<String> = ["Indian Equity", "Global Equity", "Crypto", "Mutual Funds"]

    private static let grainsNames: Set<String> = Set(
        CommoditySeeds.marketGroups.first { $0.slug == "grains" }?.commodities ?? []
    )

    private static var excludedFromLatest: Set<String> {
        var excluded: Set<String> = ["Agri Weather"]
        excluded.formUnion(equityNames)
        excluded.formUnion(grainsNames)
        return excluded
    }

    var latestFreshCount: Int {
        freshCounts.filter { !Self.excludedFromLatest.contains($0.key) }.values.reduce(0, +)
    }

    var weatherFreshCount: Int {
        freshCounts["Agri Weather"] ?? 0
    }

    var grainsFreshCount: Int {
        freshCounts.filter { Self.grainsNames.contains($0.key) }.values.reduce(0, +)
    }

    var equityFreshCount: Int {
        freshCounts.filter { Self.equityNames.contains($0.key) }.values.reduce(0, +)
    }

    func freshCountForGroup(_ group: CommoditySeeds.MarketGroup) -> Int {
        let nameSet = Set(group.commodities)
        return freshCounts.filter { nameSet.contains($0.key) }.values.reduce(0, +)
    }

    // Sidebar grouping for Command/Markets/Regulatory sections
    var commandItems: [Commodity] {
        commodities.filter { $0.name == "Agri Weather" }
    }

    var regulatoryItems: [Commodity] {
        let names: Set<String> = ["Packaging", "PIB Updates", "DGFT Updates", "IMD / Advisories"]
        return commodities.filter { names.contains($0.name) }
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
