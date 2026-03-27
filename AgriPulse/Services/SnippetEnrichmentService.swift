import Foundation
import SwiftData

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Progressively enriches articles with real snippets and AI summaries in the background.
/// Phase 1: Extract first paragraph from article page (replaces duplicate title-as-snippet).
/// Phase 2: Generate AI summary via Apple Intelligence (iOS 26+ only).
/// Runs in small batches so UI stays responsive.
@MainActor
final class SnippetEnrichmentService {
    static let shared = SnippetEnrichmentService()
    private init() {}

    private var isRunning = false
    private let batchSize = 3
    private let delayBetweenBatches: UInt64 = 500_000_000 // 0.5s

    /// Kick off background enrichment for articles that need it.
    func enrichInBackground(context: ModelContext) {
        guard !isRunning else { return }
        isRunning = true

        Task { @MainActor in
            defer { isRunning = false }
            await enrichSnippets(context: context)
            await enrichSummaries(context: context)
        }
    }

    // MARK: - Phase 1: Real snippets from article pages

    /// Find articles where snippet is empty or matches title, fetch real snippet.
    private func enrichSnippets(context: ModelContext) async {
        let descriptor = FetchDescriptor<NewsItem>(
            sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
        )
        guard let items = try? context.fetch(descriptor) else { return }

        // Filter to articles that need snippet enrichment
        let needsSnippet = items.filter { item in
            let snippet = item.snippet.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if snippet.isEmpty { return true }
            // Snippet is basically the title repeated (with or without source suffix)
            let normalizedSnippet = snippet.lowercased()
                .replacingOccurrences(of: item.source.lowercased(), with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            let normalizedTitle = title.lowercased()
                .replacingOccurrences(of: " - \(item.source.lowercased())", with: "")
                .replacingOccurrences(of: " | \(item.source.lowercased())", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            // If snippet is ≥80% similar to title, it needs enrichment
            if normalizedSnippet.count < 20 { return true }
            return normalizedSnippet == normalizedTitle
                || normalizedTitle.hasPrefix(normalizedSnippet)
                || normalizedSnippet.hasPrefix(normalizedTitle)
        }

        // Process in batches
        for batchStart in stride(from: 0, to: needsSnippet.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, needsSnippet.count)
            let batch = Array(needsSnippet[batchStart..<batchEnd])

            await withTaskGroup(of: Void.self) { group in
                for item in batch {
                    group.addTask { @MainActor in
                        await self.fetchRealSnippet(for: item)
                    }
                }
            }

            try? context.save()
            try? await Task.sleep(nanoseconds: self.delayBetweenBatches)
        }
    }

    /// Fetch the article page and extract the first paragraph as the snippet.
    private func fetchRealSnippet(for item: NewsItem) async {
        guard let url = URL(string: item.link) else { return }

        do {
            var request = URLRequest(url: url, timeoutInterval: 10)
            request.setValue(
                "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)",
                forHTTPHeaderField: "User-Agent"
            )

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii)
            else { return }

            let text = extractFirstParagraphs(from: html, maxLength: 300)
            if text.count >= 50 {
                item.snippet = text
            }
        } catch {
            // Silently skip — article page may be behind paywall or unavailable
        }
    }

    /// Extract first 1-2 meaningful paragraphs from HTML.
    private func extractFirstParagraphs(from html: String, maxLength: Int) -> String {
        // Try <article> tag first
        if let articleContent = extractTag("article", from: html) {
            let text = extractParagraphText(from: articleContent, maxLength: maxLength)
            if text.count >= 50 { return text }
        }

        // Try <main> tag
        if let mainContent = extractTag("main", from: html) {
            let text = extractParagraphText(from: mainContent, maxLength: maxLength)
            if text.count >= 50 { return text }
        }

        // Try common content class patterns
        let patterns = [
            "class=\"article-body", "class=\"story-body", "class=\"post-content",
            "class=\"entry-content", "class=\"article-content", "class=\"story-content",
            "class=\"td-post-content", "class=\"main-content", "class=\"post-body",
            "itemprop=\"articleBody",
        ]
        for pattern in patterns {
            if let range = html.range(of: pattern) {
                let startSearch = html[..<range.lowerBound]
                if let tagStart = startSearch.lastIndex(of: "<") {
                    let remainder = String(html[tagStart...])
                    let text = extractParagraphText(from: remainder, maxLength: maxLength)
                    if text.count >= 50 { return text }
                }
            }
        }

        // Fallback: extract from full HTML
        return extractParagraphText(from: html, maxLength: maxLength)
    }

    private func extractTag(_ tag: String, from html: String) -> String? {
        guard let openRange = html.range(of: "<\(tag)", options: .caseInsensitive) else { return nil }
        guard let openEnd = html[openRange.upperBound...].range(of: ">") else { return nil }
        let contentStart = openEnd.upperBound
        guard let closeRange = html.range(of: "</\(tag)>", options: .caseInsensitive, range: contentStart..<html.endIndex) else { return nil }
        return String(html[contentStart..<closeRange.lowerBound])
    }

    private func extractParagraphText(from html: String, maxLength: Int) -> String {
        var result = ""
        var searchRange = html.startIndex..<html.endIndex

        while let openRange = html.range(of: "<p", options: .caseInsensitive, range: searchRange) {
            guard let openEnd = html.range(of: ">", range: openRange.upperBound..<html.endIndex) else { break }
            let contentStart = openEnd.upperBound
            guard let closeRange = html.range(of: "</p>", options: .caseInsensitive, range: contentStart..<html.endIndex) else { break }

            let rawContent = String(html[contentStart..<closeRange.lowerBound])
            let cleaned = stripHTML(rawContent).trimmingCharacters(in: .whitespacesAndNewlines)

            if cleaned.count > 30 {
                if !result.isEmpty { result += " " }
                result += cleaned
                if result.count >= maxLength { break }
            }

            searchRange = closeRange.upperBound..<html.endIndex
        }

        if result.count > maxLength {
            result = String(result.prefix(maxLength)) + "..."
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Phase 2: AI summaries (iOS 26+ only)

    /// Generate AI summaries for articles that don't have one yet.
    private func enrichSummaries(context: ModelContext) async {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard SystemLanguageModel.default.isAvailable else { return }

            let descriptor = FetchDescriptor<NewsItem>(
                sortBy: [SortDescriptor(\.publishedAt, order: .reverse)]
            )
            guard let items = try? context.fetch(descriptor) else { return }

            let needsSummary = items.filter { $0.summary == nil }

            // Process newest articles first, in batches
            for batchStart in stride(from: 0, to: min(needsSummary.count, 50), by: batchSize) {
                let batchEnd = min(batchStart + batchSize, needsSummary.count)
                let batch = Array(needsSummary[batchStart..<batchEnd])

                for item in batch {
                    await generateSummary(for: item)
                }

                try? context.save()
                try? await Task.sleep(nanoseconds: self.delayBetweenBatches)
            }
        }
        #endif
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func generateSummary(for item: NewsItem) async {
        guard SystemLanguageModel.default.isAvailable else { return }

        // Use snippet (already enriched in Phase 1) or title as input
        let textToSummarize: String
        if item.snippet.count >= 100 {
            textToSummarize = item.snippet
        } else {
            textToSummarize = "\(item.title). \(item.snippet)"
        }
        guard textToSummarize.trimmingCharacters(in: .whitespaces).count > 50 else { return }

        do {
            let session = LanguageModelSession(
                instructions: "You are a concise news summarizer. Summarize in 2-3 sentences. Focus on key facts and impact."
            )
            let response = try await session.respond(to: textToSummarize)
            let summary = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !summary.isEmpty {
                item.summary = summary
            }
        } catch {
            // Silently skip
        }
    }
    #endif
}
