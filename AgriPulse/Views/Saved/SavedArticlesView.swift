import SwiftUI
import SwiftData

struct SavedArticlesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SavedArticlesViewModel()
    @State private var showingExport = false
    @State private var pdfData: Data?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.filteredItems.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(viewModel.filteredItems.enumerated()), id: \.element.link) { index, item in
                        NewsCardView(
                            item: item,
                            commodityName: item.commodity?.name,
                            index: index,
                            onToggleSave: {
                                viewModel.unsave(item, context: modelContext)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(AgriPulseTheme.background)
        .navigationTitle("Saved Articles")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, prompt: "Search saved articles...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.savedItems.isEmpty {
                    Button {
                        pdfData = viewModel.generatePDF()
                        showingExport = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AgriPulseTheme.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingExport) {
            if let pdfData {
                PDFExportView(pdfData: pdfData, articleCount: viewModel.filteredItems.count)
            }
        }
        .onAppear {
            viewModel.load(context: modelContext)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 48))
                .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.3))

            Text("No saved articles")
                .font(.headline)
                .foregroundStyle(AgriPulseTheme.mutedForeground)

            Text("Tap the bookmark icon on any article to save it here")
                .font(.subheadline)
                .foregroundStyle(AgriPulseTheme.mutedForeground.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}
