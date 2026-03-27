import SwiftUI
import SwiftData

struct NewsFeedView: View {
    let commodity: Commodity?
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = NewsFeedViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Sync time + status bar
                VStack(spacing: 4) {
                    if let syncText = viewModel.lastSyncedText {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(syncText)
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Status bar with fetching indicator
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
                                    : AgriPulseTheme.mutedForeground.opacity(0.5)
                            )

                        Spacer()
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
                            }
                        )
                    }

                    // Pagination controls
                    if viewModel.isPaginated && viewModel.totalPages > 1 {
                        paginationControls
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AgriPulseTheme.background)
        .navigationTitle(commodity?.name ?? "Latest Updates")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, prompt: "Search articles...")
        .refreshable {
            await viewModel.refresh(context: modelContext)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                RefreshButton(isRefreshing: viewModel.isRefreshing) {
                    Task {
                        await viewModel.refresh(context: modelContext)
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

    private var paginationControls: some View {
        HStack(spacing: 8) {
            // Previous
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

            // Page numbers
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

            // Next
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

        if total <= maxVisible {
            return Array(1...total)
        }

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
