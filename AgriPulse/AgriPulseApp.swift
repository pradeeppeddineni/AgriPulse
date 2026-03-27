import SwiftUI
import SwiftData

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
                }
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

    /// Add any commodities from CommoditySeeds.all that don't exist in the database yet.
    private static func syncNewCommodities(context: ModelContext) {
        let descriptor = FetchDescriptor<Commodity>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingNames = Set(existing.map(\.name))

        var added = 0
        for (index, seed) in CommoditySeeds.all.enumerated() {
            if !existingNames.contains(seed.name) {
                let commodity = Commodity(
                    name: seed.name,
                    searchQueries: seed.searchQueries,
                    sortOrder: index,
                    isSpecial: seed.isSpecial
                )
                context.insert(commodity)
                added += 1
            }
        }

        if added > 0 {
            try? context.save()
        }
    }

    /// One-time migration: strip HTML tags from all existing news snippets.
    private static func migrateSnippets(context: ModelContext) {
        let migrationKey = "snippetHTMLMigrationDone_v1"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let descriptor = FetchDescriptor<NewsItem>()
        let items = (try? context.fetch(descriptor)) ?? []

        var cleaned = 0
        for item in items {
            if item.snippet.contains("<") && item.snippet.contains(">") {
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
