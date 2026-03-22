import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var sidebarVM = SidebarViewModel()
    @State private var selectedTab: AppTab = .news

    enum AppTab: String, CaseIterable {
        case news = "News"
        case calendar = "Calendar"
        case saved = "Saved"
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
                        case .news:
                            NewsFeedView(commodity: sidebarVM.selectedCommodity)
                        case .calendar:
                            CommodityCalendarView()
                        case .saved:
                            SavedArticlesView()
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
                                    commodityMenu
                                }
                            }
                    }
                    .tabItem {
                        Label("News", systemImage: "newspaper.fill")
                    }
                    .tag(AppTab.news)

                    NavigationStack {
                        CommodityCalendarView()
                    }
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(AppTab.calendar)

                    NavigationStack {
                        SavedArticlesView()
                    }
                    .tabItem {
                        Label("Saved", systemImage: "bookmark.fill")
                    }
                    .tag(AppTab.saved)
                }
                .tint(AgriPulseTheme.primary)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            sidebarVM.load(context: modelContext)
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

    private var commodityMenu: some View {
        Menu {
            Button("Latest Updates") {
                sidebarVM.selectedCommodity = nil
            }

            ForEach(sidebarVM.grouped, id: \.group) { section in
                Section(section.group.rawValue) {
                    ForEach(section.items, id: \.name) { commodity in
                        Button {
                            sidebarVM.selectedCommodity = commodity
                        } label: {
                            HStack {
                                Text(commodity.name)
                                if let count = sidebarVM.freshCounts[commodity.name], count > 0 {
                                    Text("\(count)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease")
                Text(sidebarVM.selectedCommodity?.name ?? "Latest")
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}
