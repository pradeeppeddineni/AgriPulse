import SwiftUI
import SwiftData

struct CommodityGroupView: View {
    let group: CommoditySeeds.MarketGroup
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = GroupViewModel()
    @State private var activeTab: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: group.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AgriPulseTheme.primary)
                            .padding(6)
                            .background(AgriPulseTheme.primary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(group.label)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AgriPulseTheme.foreground)
                            Text(group.subtitle)
                                .font(.system(size: 11))
                                .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.5))
                        }
                    }

                    Spacer()

                    RefreshButton(isRefreshing: viewModel.isRefreshing) {
                        if let commodity = viewModel.commodity(named: activeTab) {
                            Task {
                                _ = await viewModel.refresh(commodity: commodity, context: modelContext)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

                // Sub-tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(group.commodities, id: \.self) { name in
                            subTabButton(name: name)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 12)
            }
            .background(AgriPulseTheme.background)
            .overlay(alignment: .bottom) {
                Divider().opacity(0.3)
            }

            // News feed
            ScrollView {
                if let commodity = viewModel.commodity(named: activeTab) {
                    GroupTabContent(commodity: commodity)
                } else {
                    ContentUnavailableView {
                        ProgressView()
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .refreshable {
                if let commodity = viewModel.commodity(named: activeTab) {
                    _ = await viewModel.refresh(commodity: commodity, context: modelContext)
                }
            }
        }
        .background(AgriPulseTheme.background)
        .onAppear {
            viewModel.load(context: modelContext, commodityNames: group.commodities)
            if activeTab.isEmpty, let first = group.commodities.first {
                activeTab = first
            }
        }
        .task {
            viewModel.load(context: modelContext, commodityNames: group.commodities)
            // Auto-refresh commodities with no articles
            for name in group.commodities {
                if let commodity = viewModel.commodity(named: name),
                   (commodity.newsItems ?? []).isEmpty {
                    _ = await viewModel.refresh(commodity: commodity, context: modelContext)
                }
            }
        }
    }

    private func subTabButton(name: String) -> some View {
        let isActive = activeTab == name
        let fresh = viewModel.freshCount(for: name)

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                activeTab = name
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: group.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(isActive ? AgriPulseTheme.primary : AgriPulseTheme.mutedForeground.opacity(0.4))

                Text(name)
                    .font(.system(size: 12, weight: .semibold))

                if fresh > 0 {
                    Text("\(fresh)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AgriPulseTheme.primaryForeground)
                        .padding(.horizontal, 6)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(AgriPulseTheme.primary)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isActive
                    ? AgriPulseTheme.primary.opacity(0.15)
                    : Color.clear
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? AgriPulseTheme.primary.opacity(0.25) : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(isActive ? AgriPulseTheme.primary : AgriPulseTheme.mutedForeground.opacity(0.55))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Content

private struct GroupTabContent: View {
    let commodity: Commodity
    @Environment(\.modelContext) private var modelContext

    var sortedNews: [NewsItem] {
        (commodity.newsItems ?? []).sorted { $0.publishedAt > $1.publishedAt }
    }

    var body: some View {
        if sortedNews.isEmpty {
            ContentUnavailableView {
                Image(systemName: "newspaper")
                    .font(.largeTitle)
                    .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.3))
            } description: {
                Text("No articles yet")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.6))
                Text("Pull to refresh or wait for the next scheduled update")
                    .font(.caption)
                    .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.4))
            }
            .padding(.top, 60)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(Array(sortedNews.enumerated()), id: \.element.id) { index, item in
                    NewsCardView(item: item, commodityName: commodity.name, onToggleSave: {
                        item.isSaved.toggle()
                        try? modelContext.save()
                    }, onSummarize: {
                        Task { await SummarizationService.shared.summarize(item, context: modelContext) }
                    })
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .animation(.easeOut(duration: 0.2).delay(Double(min(index, 10)) * 0.03), value: sortedNews.count)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class GroupViewModel {
    var commodities: [Commodity] = []
    var freshCounts: [String: Int] = [:]
    var isRefreshing = false

    func load(context: ModelContext, commodityNames: [String]) {
        let nameSet = Set(commodityNames)
        let descriptor = FetchDescriptor<Commodity>(sortBy: [SortDescriptor(\.sortOrder)])
        let all = (try? context.fetch(descriptor)) ?? []
        commodities = all.filter { nameSet.contains($0.name) }

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
        load(context: context, commodityNames: commodities.map(\.name))
        return count
    }
}
