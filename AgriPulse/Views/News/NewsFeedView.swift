import SwiftUI
import SwiftData

struct NewsFeedView: View {
    let commodity: Commodity?
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = NewsFeedViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.filteredItems.isEmpty && !viewModel.isRefreshing {
                    emptyState
                } else {
                    ForEach(Array(viewModel.filteredItems.enumerated()), id: \.element.link) { index, item in
                        NewsCardView(
                            item: item,
                            commodityName: commodity == nil ? item.commodity?.name : nil,
                            index: index,
                            onToggleSave: {
                                viewModel.toggleSave(item, context: modelContext)
                            }
                        )
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
            // Auto-refresh if this view has no articles yet
            viewModel.load(commodity: commodity, context: modelContext)
            if viewModel.newsItems.isEmpty && !viewModel.isRefreshing {
                await viewModel.refresh(context: modelContext)
            }
        }
        .onChange(of: commodity?.name) {
            viewModel.load(commodity: commodity, context: modelContext)
        }
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
