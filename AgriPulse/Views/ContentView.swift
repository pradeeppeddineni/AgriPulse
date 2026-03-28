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
    @State private var moreDestination: MoreDestination?

    enum AppTab: String, CaseIterable {
        case latest = "Latest"
        case saved = "Saved"
        case equity = "Equity"
        case grains = "Grains"
        case more = "More"
    }

    enum MoreDestination: Equatable {
        case equity
        case group(String) // slug
        case commodity(String) // name

        static func == (lhs: MoreDestination, rhs: MoreDestination) -> Bool {
            switch (lhs, rhs) {
            case (.equity, .equity): return true
            case (.group(let a), .group(let b)): return a == b
            case (.commodity(let a), .commodity(let b)): return a == b
            default: return false
            }
        }
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                iPadLayout
            } else {
                iPhoneLayout
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

    // MARK: - iPad Layout

    private var iPadLayout: some View {
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
    }

    // MARK: - iPhone Layout (5 tabs — iOS max without auto-More)

    private var iPhoneLayout: some View {
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
                    EquityMarketView()
                }
                .tabItem {
                    Label("Equity", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(AppTab.equity)
                .badge(sidebarVM.equityFreshCount)

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

                // More tab — shows navigated content or opens side panel
                NavigationStack {
                    moreTabContent
                }
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
                .tag(AppTab.more)
                .badge(sidebarVM.equityFreshCount)
            }
            .tint(AgriPulseTheme.primary)
            .onChange(of: selectedTab) { _, newTab in
                if newTab == .more && moreDestination == nil {
                    // Only auto-open side panel if no destination is set
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        showSidePanel = true
                    }
                }
            }

            // Side panel overlay — on top of everything (swipe right from edge to open)
            SidePanelView(
                isPresented: $showSidePanel,
                viewModel: sidebarVM,
                onSelectTab: { tab in
                    moreDestination = nil
                    selectedTab = tab
                },
                onSelectGroup: { group in
                    moreDestination = .group(group.slug)
                    showSidePanel = false
                    selectedTab = .more
                },
                onSelectCommodity: { commodity in
                    moreDestination = .commodity(commodity.name)
                    showSidePanel = false
                    selectedTab = .more
                },
                onShowCalendar: {
                    showSidePanel = false
                    showCalendarSheet = true
                },
                onSelectEquity: {
                    showSidePanel = false
                    selectedTab = .equity
                }
            )
        }
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .global)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = abs(value.translation.height)
                    // Swipe right from left edge to open panel
                    if horizontalAmount > 60 && verticalAmount < 100 && value.startLocation.x < 50 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            showSidePanel = true
                        }
                    }
                }
        )
    }

    // MARK: - Tab Content

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .latest:
            NewsFeedView(commodity: sidebarVM.selectedCommodity)
        case .saved:
            SavedArticlesView()
        case .equity:
            EquityMarketView()
        case .grains:
            if let grainsGroup = CommoditySeeds.marketGroups.first(where: { $0.slug == "grains" }) {
                CommodityGroupView(group: grainsGroup)
            }
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

    // MARK: - More Tab Content

    @ViewBuilder
    private var moreTabContent: some View {
        switch moreDestination {
        case .equity:
            EquityMarketView()
                .toolbar { moreToolbarItems }
        case .group(let slug):
            if let group = CommoditySeeds.marketGroup(forSlug: slug) {
                CommodityGroupView(group: group)
                    .toolbar { moreToolbarItems }
            }
        case .commodity(let name):
            NewsFeedView(commodity: sidebarVM.commodity(named: name))
                .toolbar { moreToolbarItems }
        case nil:
            moreLandingPage
        }
    }

    // Toolbar buttons for navigated More content — back + menu
    @ToolbarContentBuilder
    private var moreToolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                moreDestination = nil
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    showSidePanel = true
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("More")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(AgriPulseTheme.primary)
            }
        }
    }

    private var moreLandingPage: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "square.grid.2x2")
                .font(.system(size: 44))
                .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.25))

            Text("All Commodities")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.6))

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    showSidePanel = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal")
                    Text("Browse Commodities")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AgriPulseTheme.primaryForeground)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AgriPulseTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AgriPulseTheme.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        showSidePanel = true
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AgriPulseTheme.primary)
                }
            }
        }
    }
}
