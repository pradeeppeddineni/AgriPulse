import SwiftUI

struct PDFExportView: View {
    let pdfData: Data
    let articleCount: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 56))
                    .foregroundStyle(AgriPulseTheme.primary)

                VStack(spacing: 8) {
                    Text("PDF Ready")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AgriPulseTheme.foreground)

                    Text("\(articleCount) saved article\(articleCount == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(AgriPulseTheme.mutedForeground)
                }

                Button {
                    sharePDF()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share PDF")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AgriPulseTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AgriPulseTheme.background)
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sharePDF() {
        // Write to temp file so it shares as a proper PDF
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "AgriPulse_Articles_\(dateFormatter.string(from: Date())).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try pdfData.write(to: tempURL)
        } catch {
            return
        }

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
