import SwiftUI
import SwiftData
import StoreKit

@main
struct AgriPulseApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([Commodity.self, NewsItem.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [config])
            modelContainer = container

            let context = container.mainContext

            // Seed commodities on first launch
            let descriptor = FetchDescriptor<Commodity>()
            let count = (try? context.fetchCount(descriptor)) ?? 0
            if count == 0 {
                for (index, seed) in CommoditySeeds.all.enumerated() {
                    let commodity = Commodity(
                        name: seed.name,
                        searchQueries: seed.searchQueries,
                        sortOrder: index,
                        isSpecial: seed.isSpecial
                    )
                    context.insert(commodity)
                }
                try? context.save()
            } else {
                // Sync: add any new commodities that don't exist yet (e.g. Currency in v1.2)
                Self.syncNewCommodities(context: context)

                // One-time migration: strip HTML from existing snippets
                Self.migrateSnippets(context: context)
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .task {
                    await initialRefreshIfNeeded(context: modelContainer.mainContext)
                    requestReviewIfNeeded()
                    NotificationService.shared.requestPermission()
                }
        }
    }

    private func requestReviewIfNeeded() {
        let key = "appSessionCount"
        let lastReviewKey = "lastReviewRequestDate"
        let count = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(count, forKey: key)

        // Show after 5th session, max once per 90 days
        guard count >= 5 else { return }
        if let lastDate = UserDefaults.standard.object(forKey: lastReviewKey) as? Date,
           Date().timeIntervalSince(lastDate) < 90 * 86400 { return }

        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
            UserDefaults.standard.set(Date(), forKey: lastReviewKey)
        }
    }

    @MainActor
    private func initialRefreshIfNeeded(context: ModelContext) async {
        let descriptor = FetchDescriptor<NewsItem>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        // No news yet — fetch everything on first launch
        _ = await NewsService.shared.refreshAll(context: context)
    }

    /// Add any new commodities and update search queries for existing ones.
    private static func syncNewCommodities(context: ModelContext) {
        let descriptor = FetchDescriptor<Commodity>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingByName = Dictionary(uniqueKeysWithValues: existing.map { ($0.name, $0) })

        var changed = 0
        for (index, seed) in CommoditySeeds.all.enumerated() {
            if let commodity = existingByName[seed.name] {
                // Update search queries if they changed
                if commodity.searchQueries != seed.searchQueries {
                    commodity.searchQueries = seed.searchQueries
                    changed += 1
                }
            } else {
                let commodity = Commodity(
                    name: seed.name,
                    searchQueries: seed.searchQueries,
                    sortOrder: index,
                    isSpecial: seed.isSpecial
                )
                context.insert(commodity)
                changed += 1
            }
        }

        if changed > 0 {
            try? context.save()
        }
    }

    /// One-time migration: strip HTML tags and bare URLs from all existing news snippets.
    private static func migrateSnippets(context: ModelContext) {
        let migrationKey = "snippetHTMLMigrationDone_v2"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let descriptor = FetchDescriptor<NewsItem>()
        let items = (try? context.fetch(descriptor)) ?? []

        var cleaned = 0
        for item in items {
            let hasHTML = item.snippet.contains("<") && item.snippet.contains(">")
            let hasBareURL = item.snippet.contains("https://news.google.com/rss/articles/") || item.snippet.contains("https://")
            if hasHTML || hasBareURL {
                item.snippet = stripHTML(item.snippet)
                cleaned += 1
            }
        }

        if cleaned > 0 {
            try? context.save()
        }

        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
