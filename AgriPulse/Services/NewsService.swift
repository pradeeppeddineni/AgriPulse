import Foundation
import SwiftData

@MainActor
final class NewsService {
    static let shared = NewsService()

    private init() {}

    /// Fetch and filter news for a single commodity, inserting new items into SwiftData
    func refreshNews(for commodity: Commodity, context: ModelContext) async -> Int {
        let queries = commodity.searchQueries
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let indiaOnly = NewsFilterEngine.isIndiaOnly(commodity.name)
        let isGlobal = queries.contains { NewsFilterEngine.isGlobalQuery($0) }

        let articles = await RSSFetcher.shared.fetchMultipleQueries(queries, isGlobal: isGlobal)

        var insertedCount = 0
        for article in articles {
            let fullText = "\(article.title) \(article.snippet)"
            let articleIsGlobal = !NewsFilterEngine.mentionsIndia(fullText)

            // India-only filter
            if indiaOnly && articleIsGlobal { continue }

            // Relevance filter
            if !NewsFilterEngine.isRelevant(commodityName: commodity.name, title: article.title) {
                continue
            }

            // Dedup by link
            let linkPredicate = #Predicate<NewsItem> { $0.link == article.link }
            let descriptor = FetchDescriptor<NewsItem>(predicate: linkPredicate)
            let existing = (try? context.fetchCount(descriptor)) ?? 0
            if existing > 0 { continue }

            let newsItem = NewsItem(
                title: article.title,
                link: article.link,
                source: article.source,
                snippet: article.snippet,
                publishedAt: article.publishedAt,
                isGlobal: articleIsGlobal,
                commodity: commodity
            )
            context.insert(newsItem)
            insertedCount += 1
        }

        try? context.save()
        return insertedCount
    }

    /// Refresh news for all commodities
    func refreshAll(context: ModelContext) async -> Int {
        let descriptor = FetchDescriptor<Commodity>(sortBy: [SortDescriptor(\.sortOrder)])
        guard let commodities = try? context.fetch(descriptor) else { return 0 }

        var total = 0
        // Process in batches of 5 to avoid rate-limiting
        let batchSize = 5
        for startIndex in stride(from: 0, to: commodities.count, by: batchSize) {
            let end = min(startIndex + batchSize, commodities.count)
            let batch = Array(commodities[startIndex..<end])

            // Run batch commodities concurrently
            await withTaskGroup(of: Int.self) { group in
                for commodity in batch {
                    group.addTask { @MainActor in
                        if commodity.name == "PIB Updates" {
                            return await PIBService.shared.refreshPIBNews(for: commodity, context: context)
                        }
                        return await self.refreshNews(for: commodity, context: context)
                    }
                }
                for await count in group {
                    total += count
                }
            }
        }

        return total
    }

    /// Clean up news older than N days
    func cleanupOldNews(days: Int, context: ModelContext) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<NewsItem> { $0.publishedAt < cutoff && !$0.isSaved }
        let descriptor = FetchDescriptor<NewsItem>(predicate: predicate)
        guard let old = try? context.fetch(descriptor) else { return }
        for item in old {
            context.delete(item)
        }
        try? context.save()
    }

    /// Un-save saved articles older than N days
    func unsaveOldArticles(days: Int, context: ModelContext) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<NewsItem> { $0.publishedAt < cutoff && $0.isSaved }
        let descriptor = FetchDescriptor<NewsItem>(predicate: predicate)
        guard let old = try? context.fetch(descriptor) else { return }
        for item in old {
            item.isSaved = false
        }
        try? context.save()
    }
}
