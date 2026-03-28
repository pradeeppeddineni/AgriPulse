import SwiftUI
import SwiftData

struct SavedArticlesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SavedArticlesViewModel()
    @State private var showingDatePicker = false
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
                    Text("Export Saved Articles")
                        .font(.headline)
                        .foregroundStyle(AgriPulseTheme.foreground)
                        .padding(.top, 8)

                    DatePicker("From", selection: $exportStartDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    DatePicker("To", selection: $exportEndDate, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    let articlesInRange = viewModel.savedItems.filter {
                        $0.publishedAt >= exportStartDate && $0.publishedAt <= exportEndDate
                    }

                    Text("\(articlesInRange.count) articles in range")
                        .font(.subheadline)
                        .foregroundStyle(AgriPulseTheme.mutedForeground)

                    Button {
                        viewModel.exportDateRange = (exportStartDate, exportEndDate)
                        let pdfData = viewModel.generatePDF()
                        showingDatePicker = false
                        sharePDF(data: pdfData)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share PDF (\(articlesInRange.count) articles)")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AgriPulseTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(articlesInRange.isEmpty)

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
        .onAppear {
            viewModel.load(context: modelContext)
        }
    }

    private func sharePDF(data: Data) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "AgriPulse_Articles_\(dateFormatter.string(from: Date())).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)
        } catch {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                var presenter = rootVC
                while let presented = presenter.presentedViewController {
                    presenter = presented
                }
                activityVC.popoverPresentationController?.sourceView = presenter.view
                presenter.present(activityVC, animated: true)
            }
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
