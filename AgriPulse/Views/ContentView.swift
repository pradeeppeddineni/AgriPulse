import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.scenePhase) private var scenePhase
    @State private var sidebarVM = SidebarViewModel()
    @State private var selectedTab: AppTab = .latest
    @State private var showSidePanel = false
    @State private var showCalendarSheet = false
    @State private var navigatedGroup: CommoditySeeds.MarketGroup?
    @State private var navigatedCommodity: Commodity?

    enum AppTab: String, CaseIterable {
        case latest = "Latest"
        case saved = "Saved"
        case weather = "Weather"
        case grains = "Grains"
        case equity = "Equity"
        case more = "More"
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                // iPad: NavigationSplitView
                NavigationSplitView {
                    SidebarView(viewModel: sidebarVM)
                } detail: {
                    NavigationStack {
                        tabContent(for: selectedTab)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        tabPicker
                    }
                }
            } else {
                // iPhone: TabView with 6 tabs
                ZStack {
                    TabView(selection: $selectedTab) {
                        NavigationStack {
                            NewsFeedView(commodity: sidebarVM.selectedCommodity)
                        }
                        .tabItem {
                            Label("Latest", systemImage: "newspaper.fill")
                        }
                        .tag(AppTab.latest)
                        .badge(sidebarVM.latestFreshCount)

                        NavigationStack {
                            SavedArticlesView()
                        }
                        .tabItem {
                            Label("Saved", systemImage: "bookmark.fill")
                        }
                        .tag(AppTab.saved)

                        NavigationStack {
                            NewsFeedView(commodity: sidebarVM.commodity(named: "Agri Weather"))
                        }
                        .tabItem {
                            Label("Weather", systemImage: "cloud.sun.fill")
                        }
                        .tag(AppTab.weather)
                        .badge(sidebarVM.weatherFreshCount)

                        NavigationStack {
                            if let grainsGroup = CommoditySeeds.marketGroups.first(where: { $0.slug == "grains" }) {
                                CommodityGroupView(group: grainsGroup)
                            }
                        }
                        .tabItem {
                            Label("Grains", systemImage: "leaf.fill")
                        }
                        .tag(AppTab.grains)
                        .badge(sidebarVM.grainsFreshCount)

                        NavigationStack {
                            EquityMarketView()
                        }
                        .tabItem {
                            Label("Equity", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .tag(AppTab.equity)
                        .badge(sidebarVM.equityFreshCount)

                        // More tab — placeholder content, side panel shown as overlay
                        NavigationStack {
                            moreTabContent
                        }
                        .tabItem {
                            Label("More", systemImage: "line.3.horizontal")
                        }
                        .tag(AppTab.more)
                    }
                    .tint(AgriPulseTheme.primary)

                    // Side panel overlay
                    if showSidePanel {
                        SidePanelView(
                            isPresented: $showSidePanel,
                            viewModel: sidebarVM,
                            onSelectTab: { tab in
                                selectedTab = tab
                            },
                            onSelectGroup: { group in
                                navigatedGroup = group
                                selectedTab = .more
                            },
                            onSelectCommodity: { commodity in
                                navigatedCommodity = commodity
                                selectedTab = .more
                            },
                            onShowCalendar: {
                                showCalendarSheet = true
                            }
                        )
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            sidebarVM.load(context: modelContext)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                sidebarVM.load(context: modelContext)
            }
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            if newTab == .more {
                showSidePanel = true
            } else {
                showSidePanel = false
                // Clear navigation state when leaving More tab
                if oldTab == .more {
                    navigatedGroup = nil
                    navigatedCommodity = nil
                }
            }
        }
        .sheet(isPresented: $showCalendarSheet) {
            NavigationStack {
                CommodityCalendarView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showCalendarSheet = false }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .latest:
            NewsFeedView(commodity: sidebarVM.selectedCommodity)
        case .saved:
            SavedArticlesView()
        case .weather:
            NewsFeedView(commodity: sidebarVM.commodity(named: "Agri Weather"))
        case .grains:
            if let grainsGroup = CommoditySeeds.marketGroups.first(where: { $0.slug == "grains" }) {
                CommodityGroupView(group: grainsGroup)
            }
        case .equity:
            EquityMarketView()
        case .more:
            moreTabContent
        }
    }

    private var tabPicker: some View {
        Picker("Tab", selection: $selectedTab) {
            ForEach(AppTab.allCases.filter({ $0 != .more }), id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    // More tab content — shows navigated group/commodity or a landing page
    private var moreTabContent: some View {
        Group {
            if let group = navigatedGroup {
                CommodityGroupView(group: group)
            } else if let commodity = navigatedCommodity {
                NewsFeedView(commodity: commodity)
            } else {
                // Landing content when side panel dismissed without selection
                VStack(spacing: 16) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 40))
                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.3))
                    Text("All Commodities")
                        .font(.headline)
                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.6))
                    Text("Tap More to browse all commodity groups")
                        .font(.caption)
                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AgriPulseTheme.background)
            }
        }
    }
}
