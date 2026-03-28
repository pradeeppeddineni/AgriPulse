import SwiftUI
import SwiftData

struct SavedArticlesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SavedArticlesViewModel()
    @State private var showingExport = false
    @State private var showingDatePicker = false
    @State private var pdfData: Data?
    @State private var exportStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var exportEndDate = Date()

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
                            },
                            onSummarize: {
                                Task { await SummarizationService.shared.summarize(item, context: modelContext) }
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
                        showingDatePicker = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AgriPulseTheme.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Select Date Range")
                        .font(.headline)
                        .foregroundStyle(AgriPulseTheme.foreground)
                        .padding(.top, 8)

                    DatePicker("From", selection: $exportStartDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    DatePicker("To", selection: $exportEndDate, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    let filteredCount = viewModel.savedItems.filter {
                        $0.publishedAt >= exportStartDate && $0.publishedAt <= exportEndDate
                    }.count

                    Text("\(filteredCount) articles in range")
                        .font(.subheadline)
                        .foregroundStyle(AgriPulseTheme.mutedForeground)

                    Button {
                        viewModel.exportDateRange = (exportStartDate, exportEndDate)
                        pdfData = viewModel.generatePDF()
                        showingDatePicker = false
                        showingExport = true
                    } label: {
                        Text("Export PDF")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AgriPulseTheme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(filteredCount == 0)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .background(AgriPulseTheme.background)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") { showingDatePicker = false }
                    }
                }
            }
            .preferredColorScheme(.dark)
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
