import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.scenePhase) private var scenePhase
    @State private var sidebarVM = SidebarViewModel()
    @State private var selectedTab: AppTab = .latest
    @State private var showMoreSidebar = false

    enum AppTab: String, CaseIterable {
        case latest = "Latest"
        case saved = "Saved"
        case weather = "Weather"
        case wheat = "Wheat"
        case equity = "Equity"
    }

    var body: some View {
        Group {
            if sizeClass == .regular {
                // iPad: NavigationSplitView
                NavigationSplitView {
                    SidebarView(viewModel: sidebarVM)
                } detail: {
                    NavigationStack {
                        switch selectedTab {
                        case .latest:
                            NewsFeedView(commodity: sidebarVM.selectedCommodity)
                        case .saved:
                            SavedArticlesView()
                        case .weather:
                            NewsFeedView(commodity: sidebarVM.commodity(named: "Agri Weather"))
                        case .wheat:
                            NewsFeedView(commodity: sidebarVM.commodity(named: "Wheat"))
                        case .equity:
                            EquityMarketView()
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        tabPicker
                    }
                }
            } else {
                // iPhone: TabView
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        NewsFeedView(commodity: sidebarVM.selectedCommodity)
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    hamburgerMenu
                                }
                            }
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
                        NewsFeedView(commodity: sidebarVM.commodity(named: "Wheat"))
                    }
                    .tabItem {
                        Label("Wheat", systemImage: "leaf.fill")
                    }
                    .tag(AppTab.wheat)
                    .badge(sidebarVM.wheatFreshCount)

                    NavigationStack {
                        EquityMarketView()
                    }
                    .tabItem {
                        Label("Equity", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(AppTab.equity)
                    .badge(sidebarVM.equityFreshCount)
                }
                .tint(AgriPulseTheme.primary)
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
        .sheet(isPresented: $showMoreSidebar) {
            NavigationStack {
                moreSidebarContent
                    .navigationTitle("Commodities")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showMoreSidebar = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var tabPicker: some View {
        Picker("Tab", selection: $selectedTab) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    private var hamburgerMenu: some View {
        Menu {
            Button("Latest Updates") {
                sidebarVM.selectedCommodity = nil
            }

            Button {
                showMoreSidebar = true
            } label: {
                Label("All Commodities", systemImage: "square.grid.2x2")
            }

            Section("Quick Access") {
                Button("Calendar") {
                    showMoreSidebar = false
                    // Present calendar as sheet
                    showCalendarSheet = true
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal")
                Text(sidebarVM.selectedCommodity?.name ?? "Latest")
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    @State private var showCalendarSheet = false

    private var moreSidebarContent: some View {
        List {
            Section("Calendar") {
                Button {
                    showMoreSidebar = false
                    showCalendarSheet = true
                } label: {
                    Label("Commodity Calendar", systemImage: "calendar")
                }
            }

            ForEach(sidebarVM.grouped, id: \.group) { section in
                Section(section.group.rawValue) {
                    ForEach(section.items, id: \.name) { commodity in
                        Button {
                            sidebarVM.selectedCommodity = commodity
                            // Route to the right tab
                            if commodity.name == "Agri Weather" {
                                selectedTab = .weather
                            } else if commodity.name == "Wheat" {
                                selectedTab = .wheat
                            } else if ["Indian Equity", "Global Equity", "Crypto", "Mutual Funds"].contains(commodity.name) {
                                selectedTab = .equity
                            } else {
                                selectedTab = .latest
                            }
                            showMoreSidebar = false
                        } label: {
                            HStack {
                                Text(commodity.name)
                                    .foregroundStyle(AgriPulseTheme.foreground)
                                Spacer()
                                if let count = sidebarVM.freshCounts[commodity.name], count > 0 {
                                    Text("\(count)")
                                        .font(.caption2.weight(.semibold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AgriPulseTheme.primary.opacity(0.2))
                                        .clipShape(Capsule())
                                        .foregroundStyle(AgriPulseTheme.primary)
                                }
                            }
                        }
                    }
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
}
