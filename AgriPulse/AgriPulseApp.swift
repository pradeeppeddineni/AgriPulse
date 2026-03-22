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

            // Seed commodities synchronously so they're available before UI appears
            let context = container.mainContext
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
}
