import SwiftUI
import SwiftData

struct EquityMarketView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = EquityViewModel()
    @State private var activeTab = "Indian Equity"

    private struct TabInfo: Identifiable {
        let id: String
        let label: String
        let icon: String
        let color: Color
    }

    private let tabs: [TabInfo] = [
        TabInfo(id: "Indian Equity",  label: "Indian Equity",  icon: "chart.line.uptrend.xyaxis", color: .green),
        TabInfo(id: "Global Equity",  label: "Global Equity",  icon: "globe",                     color: .blue),
        TabInfo(id: "Crypto",         label: "Crypto",         icon: "bitcoinsign.circle",        color: .orange),
        TabInfo(id: "Mutual Funds",   label: "Mutual Funds",   icon: "chart.pie",                 color: .purple),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AgriPulseTheme.primary)
                            .padding(6)
                            .background(AgriPulseTheme.primary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Equity Market")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AgriPulseTheme.foreground)
                            Text("Indian · Global · Crypto · Mutual Funds")
                                .font(.system(size: 11))
                                .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.8))
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
                        ForEach(tabs) { tab in
                            tabButton(tab)
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
                    EquityTabContent(commodity: commodity)
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
            viewModel.load(context: modelContext)
        }
        .task {
            // Auto-refresh equity commodities if no articles exist
            viewModel.load(context: modelContext)
            for tab in tabs {
                if let commodity = viewModel.commodity(named: tab.id),
                   (commodity.newsItems ?? []).isEmpty {
                    _ = await viewModel.refresh(commodity: commodity, context: modelContext)
                }
            }
        }
    }

    private func tabButton(_ tab: TabInfo) -> some View {
        let isActive = activeTab == tab.id
        let fresh = viewModel.freshCount(for: tab.id)

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                activeTab = tab.id
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(isActive ? AgriPulseTheme.primary : tab.color.opacity(0.6))

                // Show short label on compact, full on regular
                Text(tab.label)
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
            .foregroundStyle(isActive ? AgriPulseTheme.primary : AgriPulseTheme.mutedForeground)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Content (news list for a single equity commodity)

private struct EquityTabContent: View {
    let commodity: Commodity
    @Environment(\.modelContext) private var modelContext

    var sortedNews: [NewsItem] {
        (commodity.newsItems ?? []).sorted { $0.publishedAt > $1.publishedAt }
    }

    var body: some View {
        if sortedNews.isEmpty {
            ContentUnavailableView {
                Image(systemName: "chart.line.uptrend.xyaxis")
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
                        .animation(.easeOut(duration: 0.2).delay(Double(index) * 0.03), value: sortedNews.count)
                }
            }
            .padding(.vertical, 8)
        }
    }
}
