import SwiftUI
import SwiftData

@main
struct AgriPulseApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([Commodity.self, NewsItem.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .task {
                    await seedCommoditiesIfNeeded(context: modelContainer.mainContext)
                }
        }
    }

    @MainActor
    private func seedCommoditiesIfNeeded(context: ModelContext) async {
        let descriptor = FetchDescriptor<Commodity>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

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
}
