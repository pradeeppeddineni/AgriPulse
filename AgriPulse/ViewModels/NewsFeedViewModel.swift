import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class NewsFeedViewModel {
    var newsItems: [NewsItem] = []
    var isRefreshing = false
    var searchText = ""
    var currentPage = 1

    var lastSyncedText: String? {
        guard let date = UserDefaults.standard.object(forKey: "lastSyncedAt") as? Date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy 'at' hh:mm a"
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        formatter.locale = Locale(identifier: "en_IN")
        return "Synced \(formatter.string(from: date)) IST"
    }

    private var commodity: Commodity?

    // Pagination config per commodity
    private var pageSize: Int {
        guard let name = commodity?.name else { return 0 }
        switch name {
        case "Wheat": return 50
        case "PIB Updates": return 25
        default: return 0  // 0 means no pagination
        }
    }

    var isPaginated: Bool { pageSize > 0 }

    var totalItems: Int { filteredItems.count }

    var totalPages: Int {
        guard isPaginated, pageSize > 0 else { return 1 }
        return max(1, Int(ceil(Double(filteredItems.count) / Double(pageSize))))
    }

    var paginatedItems: [NewsItem] {
        guard isPaginated, pageSize > 0 else { return filteredItems }
        let start = (currentPage - 1) * pageSize
        let end = min(start + pageSize, filteredItems.count)
        guard start < filteredItems.count else { return [] }
        return Array(filteredItems[start..<end])
    }

    var statusText: String {
        if isRefreshing { return "Fetching latest..." }
        let total = filteredItems.count
        if isPaginated {
            let start = (currentPage - 1) * pageSize + 1
            let end = min(currentPage * pageSize, total)
            return "\(start)-\(end) of \(total) updates · page \(currentPage) of \(totalPages)"
        }
        return "\(total) updates"
    }

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
        "Agri Weather", "Indian Equity", "Global Equity", "Crypto", "Mutual Funds",
        "PIB Updates", "Packaging", "DGFT Updates", "IMD / Advisories"
    ]

    func load(commodity: Commodity?, context: ModelContext) {
        self.commodity = commodity
        currentPage = 1

        if let commodity {
            let commodityName = commodity.name
            let predicate = #Predicate<NewsItem> { item in
                item.commodity?.name == commodityName
            }
            var descriptor = FetchDescriptor<NewsItem>(predicate: predicate, sortBy: [SortDescriptor(\.publishedAt, order: .reverse)])

            // Wheat: 365-day window
            if commodity.name == "Wheat" {
                descriptor.fetchLimit = 5000
            } else {
                descriptor.fetchLimit = 200
            }

            newsItems = (try? context.fetch(descriptor)) ?? []
        } else {
            // Latest Updates: exclude equity, weather, grains
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

    func goToPage(_ page: Int) {
        currentPage = max(1, min(page, totalPages))
    }

    func nextPage() { goToPage(currentPage + 1) }
    func previousPage() { goToPage(currentPage - 1) }

    func toggleSave(_ item: NewsItem, context: ModelContext) {
        item.isSaved.toggle()
        try? context.save()
    }
}
