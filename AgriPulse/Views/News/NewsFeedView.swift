import SwiftUI
import SwiftData

struct NewsFeedView: View {
    let commodity: Commodity?
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = NewsFeedViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var showSearchBar = false
    @FocusState private var searchFocused: Bool

    private var isLatestTab: Bool { commodity == nil }

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        return formatter.string(from: Date())
    }

    // Category pills for Latest tab
    private let categories: [(label: String, icon: String, filter: String)] = [
        ("All", "newspaper", ""),
        ("Grains", "leaf", "grains"),
        ("Oils", "drop", "oils"),
        ("Others 1", "shippingbox", "others1"),
        ("Dry Fruits", "leaf.circle", "dryfruits"),
        ("Markets", "chart.bar", "markets"),
    ]

    @State private var activeCategory = ""

    var body: some View {
        VStack(spacing: 0) {
            if isLatestTab {
                latestHeader
            }

            ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    Color.clear.frame(height: 0).id("feedTop")

                    if !isLatestTab {
                        standardStatusBar
                    } else {
                        // Compact status for latest tab
                        VStack(spacing: 4) {
                            if let syncText = viewModel.lastSyncedText {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 10))
                                    Text(syncText)
                                        .font(.system(size: 11))
                                }
                                .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(viewModel.isRefreshing ? AgriPulseTheme.hotAmber : AgriPulseTheme.freshEmerald)
                                    .frame(width: 6, height: 6)
                                    .opacity(viewModel.isRefreshing ? 1 : 0.7)
                                    .animation(
                                        viewModel.isRefreshing
                                            ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                                            : .default,
                                        value: viewModel.isRefreshing
                                    )

                                Text(viewModel.statusText)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(
                                        viewModel.isRefreshing
                                            ? AgriPulseTheme.hotAmber.opacity(0.8)
                                            : AgriPulseTheme.mutedForeground.opacity(0.7)
                                    )

                                Spacer()
                            }
                        }
                    }

                    if viewModel.paginatedItems.isEmpty && !viewModel.isRefreshing {
                        emptyState
                    } else {
                        ForEach(Array(viewModel.paginatedItems.enumerated()), id: \.element.link) { index, item in
                            NewsCardView(
                                item: item,
                                commodityName: commodity == nil ? item.commodity?.name : nil,
                                index: index,
                                onToggleSave: {
                                    viewModel.toggleSave(item, context: modelContext)
                                },
                                onSummarize: {
                                    Task { await SummarizationService.shared.summarize(item, context: modelContext) }
                                }
                            )
                        }

                        if viewModel.isPaginated && viewModel.totalPages > 1 {
                            paginationControls
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .refreshable {
                await viewModel.refresh(context: modelContext)
            }
            .agriPulseRefresh(isRefreshing: viewModel.isRefreshing)
            .onChange(of: viewModel.currentPage) {
                withAnimation { proxy.scrollTo("feedTop", anchor: .top) }
            }
            } // ScrollViewReader
        }
        .background(AgriPulseTheme.background)
        .navigationTitle(isLatestTab ? "" : (commodity?.name ?? ""))
        .navigationBarTitleDisplayMode(isLatestTab ? .inline : .large)
        .toolbar(isLatestTab ? .hidden : .visible, for: .navigationBar)
        .searchable(text: $viewModel.searchText, prompt: "Search articles...")
        .toolbar {
            if !isLatestTab {
                ToolbarItem(placement: .topBarTrailing) {
                    RefreshButton(isRefreshing: viewModel.isRefreshing) {
                        Task { await viewModel.refresh(context: modelContext) }
                    }
                }
            }
        }
        .onAppear {
            viewModel.load(commodity: commodity, context: modelContext)
        }
        .task(id: commodity?.name) {
            viewModel.load(commodity: commodity, context: modelContext)
            if viewModel.newsItems.isEmpty && !viewModel.isRefreshing {
                await viewModel.refresh(context: modelContext)
            }
        }
        .onChange(of: commodity?.name) {
            viewModel.load(commodity: commodity, context: modelContext)
        }
    }

    // MARK: - Apple News-style Header

    private var latestHeader: some View {
        VStack(spacing: 0) {
            // Top row: Logo + date | search + refresh
            HStack(alignment: .center) {
                // Left: Logo + date
                HStack(spacing: 10) {
                    Image("AgriPulseLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 9))

                    VStack(alignment: .leading, spacing: 1) {
                        Text("AgriPulse")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(AgriPulseTheme.foreground)
                        Text(todayDateString)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.5))
                    }
                }

                Spacer()

                // Right: Search + Theme Toggle + Refresh
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSearchBar.toggle()
                            if showSearchBar {
                                searchFocused = true
                            } else {
                                viewModel.searchText = ""
                                searchFocused = false
                            }
                        }
                    } label: {
                        Image(systemName: showSearchBar ? "xmark" : "magnifyingglass")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AgriPulseTheme.primary)
                            .frame(width: 38, height: 38)
                            .background(AgriPulseTheme.card)
                            .clipShape(Circle())
                    }

                    // Theme toggle
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            isDarkMode.toggle()
                        }
                    } label: {
                        ZStack {
                            // Sun (light mode indicator)
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .yellow],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .rotationEffect(.degrees(isDarkMode ? -90 : 0))
                                .scaleEffect(isDarkMode ? 0.0 : 1.0)
                                .opacity(isDarkMode ? 0 : 1)

                            // Moon (dark mode indicator)
                            Image(systemName: "moon.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.6, green: 0.6, blue: 1.0), Color(red: 0.4, green: 0.4, blue: 0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .rotationEffect(.degrees(isDarkMode ? 0 : 90))
                                .scaleEffect(isDarkMode ? 1.0 : 0.0)
                                .opacity(isDarkMode ? 1 : 0)
                        }
                        .frame(width: 38, height: 38)
                        .background(AgriPulseTheme.card)
                        .clipShape(Circle())
                    }

                    Button {
                        Task { await viewModel.refresh(context: modelContext) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AgriPulseTheme.primary)
                            .frame(width: 38, height: 38)
                            .background(AgriPulseTheme.card)
                            .clipShape(Circle())
                            .rotationEffect(.degrees(viewModel.isRefreshing ? 360 : 0))
                            .animation(viewModel.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isRefreshing)
                    }
                    .disabled(viewModel.isRefreshing)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, showSearchBar ? 8 : 12)

            // Search bar (expandable)
            if showSearchBar {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.5))

                    TextField("Search articles...", text: $viewModel.searchText)
                        .font(.system(size: 14))
                        .foregroundStyle(AgriPulseTheme.foreground)
                        .focused($searchFocused)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AgriPulseTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Category pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.filter) { cat in
                        categoryPill(label: cat.label, icon: cat.icon, isActive: activeCategory == cat.filter) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                activeCategory = cat.filter
                                viewModel.categoryFilter = cat.filter
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 10)

            // Divider
            Rectangle()
                .fill(AgriPulseTheme.border.opacity(0.3))
                .frame(height: 0.5)
        }
        .background(AgriPulseTheme.background)
    }

    private func categoryPill(label: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(isActive ? AgriPulseTheme.primaryForeground : AgriPulseTheme.mutedForeground.opacity(0.7))
            .background(
                isActive
                    ? AgriPulseTheme.primary
                    : AgriPulseTheme.card
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Standard status bar (for commodity views)

    private var standardStatusBar: some View {
        VStack(spacing: 4) {
            if let syncText = viewModel.lastSyncedText {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(syncText)
                        .font(.system(size: 11))
                }
                .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.isRefreshing ? AgriPulseTheme.hotAmber : AgriPulseTheme.freshEmerald)
                    .frame(width: 6, height: 6)
                    .opacity(viewModel.isRefreshing ? 1 : 0.7)
                    .animation(
                        viewModel.isRefreshing
                            ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                            : .default,
                        value: viewModel.isRefreshing
                    )

                Text(viewModel.statusText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(
                        viewModel.isRefreshing
                            ? AgriPulseTheme.hotAmber.opacity(0.8)
                            : AgriPulseTheme.mutedForeground.opacity(0.7)
                    )

                Spacer()
            }
        }
    }

    // MARK: - Pagination

    private var paginationControls: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.previousPage()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(viewModel.currentPage > 1 ? AgriPulseTheme.primary : AgriPulseTheme.mutedForeground.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .background(AgriPulseTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(viewModel.currentPage <= 1)

            ForEach(pageNumbers, id: \.self) { page in
                Button {
                    viewModel.goToPage(page)
                } label: {
                    Text("\(page)")
                        .font(.system(size: 12, weight: viewModel.currentPage == page ? .bold : .medium))
                        .foregroundStyle(viewModel.currentPage == page ? AgriPulseTheme.primaryForeground : AgriPulseTheme.mutedForeground)
                        .frame(width: 32, height: 32)
                        .background(
                            viewModel.currentPage == page
                                ? AgriPulseTheme.primary
                                : AgriPulseTheme.card
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            Button {
                viewModel.nextPage()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(viewModel.currentPage < viewModel.totalPages ? AgriPulseTheme.primary : AgriPulseTheme.mutedForeground.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .background(AgriPulseTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(viewModel.currentPage >= viewModel.totalPages)
        }
        .padding(.vertical, 16)
    }

    private var pageNumbers: [Int] {
        let total = viewModel.totalPages
        let current = viewModel.currentPage
        let maxVisible = 7
        if total <= maxVisible { return Array(1...total) }
        let half = maxVisible / 2
        var start = max(1, current - half)
        var end = start + maxVisible - 1
        if end > total {
            end = total
            start = max(1, end - maxVisible + 1)
        }
        return Array(start...end)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "newspaper")
                .font(.system(size: 48))
                .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.3))

            Text("No articles yet")
                .font(.headline)
                .foregroundStyle(AgriPulseTheme.mutedForeground)

            Text("Pull down to refresh and fetch the latest news")
                .font(.subheadline)
                .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}
