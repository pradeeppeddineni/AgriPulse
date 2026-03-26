import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class NewsFeedViewModel {
    var newsItems: [NewsItem] = []
    var isRefreshing = false
    var searchText = ""

    var lastSyncedText: String? {
        guard let date = UserDefaults.standard.object(forKey: "lastSyncedAt") as? Date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy 'at' hh:mm a"
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        formatter.locale = Locale(identifier: "en_IN")
        return "Synced \(formatter.string(from: date)) IST"
    }

    private var commodity: Commodity?

    var filteredItems: [NewsItem] {
        if searchText.isEmpty { return newsItems }
        let lower = searchText.lowercased()
        return newsItems.filter {
            $0.title.lowercased().contains(lower)
            || $0.snippet.lowercased().contains(lower)
            || $0.source.lowercased().contains(lower)
        }
    }

    private static let excludedFromLatest: Set<String> = [
        "Agri Weather",
        "Indian Equity",
        "Global Equity",
        "Crypto",
        "Mutual Funds"
    ]

    func load(commodity: Commodity?, context: ModelContext) {
        self.commodity = commodity

        if let commodity {
            // Load news for specific commodity
            let commodityName = commodity.name
            let predicate = #Predicate<NewsItem> { item in
                item.commodity?.name == commodityName
            }
            var descriptor = FetchDescriptor<NewsItem>(predicate: predicate, sortBy: [SortDescriptor(\.publishedAt, order: .reverse)])
            descriptor.fetchLimit = 200
            newsItems = (try? context.fetch(descriptor)) ?? []
        } else {
            // Latest Updates: commodity news only (exclude equity and weather)
            var descriptor = FetchDescriptor<NewsItem>(sortBy: [SortDescriptor(\.publishedAt, order: .reverse)])
            descriptor.fetchLimit = 200
            let allItems = (try? context.fetch(descriptor)) ?? []
            newsItems = allItems.filter { item in
                guard let name = item.commodity?.name else { return true }
                return !Self.excludedFromLatest.contains(name)
            }
        }
    }

    func refresh(context: ModelContext) async {
        isRefreshing = true
        defer { isRefreshing = false }

        if let commodity {
            if commodity.name == "PIB Updates" {
                _ = await PIBService.shared.refreshPIBNews(for: commodity, context: context)
            } else {
                _ = await NewsService.shared.refreshNews(for: commodity, context: context)
            }
        } else {
            _ = await NewsService.shared.refreshAll(context: context)
        }

        load(commodity: commodity, context: context)
    }

    func toggleSave(_ item: NewsItem, context: ModelContext) {
        item.isSaved.toggle()
        try? context.save()
    }
}
