import Foundation
import SwiftData
import SwiftUI
import PDFKit

@MainActor
@Observable
final class SavedArticlesViewModel {
    var savedItems: [NewsItem] = []
    var searchText = ""
    var exportDateRange: (start: Date, end: Date)?

    var filteredItems: [NewsItem] {
        if searchText.isEmpty { return savedItems }
        let lower = searchText.lowercased()
        return savedItems.filter {
            $0.title.lowercased().contains(lower)
            || $0.snippet.lowercased().contains(lower)
            || $0.source.lowercased().contains(lower)
        }
    }

    func load(context: ModelContext) {
        let predicate = #Predicate<NewsItem> { $0.isSaved == true }
        let descriptor = FetchDescriptor<NewsItem>(predicate: predicate, sortBy: [SortDescriptor(\.publishedAt, order: .reverse)])
        savedItems = (try? context.fetch(descriptor)) ?? []
    }

    func unsave(_ item: NewsItem, context: ModelContext) {
        item.isSaved = false
        try? context.save()
        load(context: context)
    }

    var exportItems: [NewsItem] {
        if let range = exportDateRange {
            return filteredItems.filter { $0.publishedAt >= range.start && $0.publishedAt <= range.end }
        }
        return filteredItems
    }

    func generatePDF() -> Data {
        let pageWidth: CGFloat = 595 // A4
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = renderer.pdfData { context in
            var y: CGFloat = 0

            func newPage() {
                context.beginPage()
                y = margin
            }

            func checkSpace(_ needed: CGFloat) {
                if y + needed > pageHeight - margin {
                    newPage()
                }
            }

            newPage()

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: UIColor.label,
            ]
            let title = "AgriPulse — Saved Articles"
            let titleSize = (title as NSString).size(withAttributes: titleAttrs)
            (title as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
            y += titleSize.height + 4

            // Date range
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d MMM yyyy"
            let dates = exportItems.compactMap { $0.publishedAt }
            let dateRange: String
            if let earliest = dates.min(), let latest = dates.max() {
                dateRange = "\(dateFormatter.string(from: earliest)) — \(dateFormatter.string(from: latest)) · \(exportItems.count) articles"
            } else {
                dateRange = "\(exportItems.count) articles"
            }

            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel,
            ]
            (dateRange as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttrs)
            y += 24

            // Divider
            UIColor.separator.setStroke()
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: margin, y: y))
            dividerPath.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            dividerPath.lineWidth = 0.5
            dividerPath.stroke()
            y += 16

            // Articles
            let articleTitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor.label,
            ]
            let metaAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel,
            ]
            let snippetAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.tertiaryLabel,
            ]

            for item in exportItems {
                let titleRect = (item.title as NSString).boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: articleTitleAttrs,
                    context: nil
                )

                let snippetText = item.snippet.isEmpty ? "" : item.snippet
                let snippetRect = snippetText.isEmpty ? CGRect.zero : (snippetText as NSString).boundingRect(
                    with: CGSize(width: contentWidth, height: 40),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: snippetAttrs,
                    context: nil
                )

                let neededHeight = titleRect.height + 16 + snippetRect.height + 30
                checkSpace(neededHeight)

                // Source + date
                let meta = "\(item.source) · \(dateFormatter.string(from: item.publishedAt)) · \(item.commodity?.name ?? "General")"
                (meta as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: metaAttrs)
                y += 14

                // Title
                (item.title as NSString).draw(
                    in: CGRect(x: margin, y: y, width: contentWidth, height: titleRect.height),
                    withAttributes: articleTitleAttrs
                )
                y += titleRect.height + 4

                // Snippet
                if !snippetText.isEmpty {
                    (snippetText as NSString).draw(
                        in: CGRect(x: margin, y: y, width: contentWidth, height: snippetRect.height),
                        withAttributes: snippetAttrs
                    )
                    y += snippetRect.height + 4
                }

                // Link
                let linkAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8, weight: .regular),
                    .foregroundColor: UIColor.systemBlue,
                ]
                (item.link as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: linkAttrs)
                y += 20

                // Separator
                UIColor.separator.setStroke()
                let sepPath = UIBezierPath()
                sepPath.move(to: CGPoint(x: margin, y: y))
                sepPath.addLine(to: CGPoint(x: pageWidth - margin, y: y))
                sepPath.lineWidth = 0.25
                sepPath.stroke()
                y += 12
            }
        }

        return data
    }
}
