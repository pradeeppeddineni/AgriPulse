import Foundation
import SwiftData
@preconcurrency import FoundationIntelligence

@MainActor
final class SummarizationService {
    static let shared = SummarizationService()
    private init() {}

    var isAvailable: Bool {
        if #available(iOS 18.1, *) {
            return true
        }
        return false
    }

    func summarize(_ item: NewsItem, context: ModelContext) async {
        guard item.summary == nil else { return }

        if #available(iOS 18.1, *) {
            await summarizeWithAppleIntelligence(item, context: context)
        }
    }

    @available(iOS 18.1, *)
    private func summarizeWithAppleIntelligence(_ item: NewsItem, context: ModelContext) async {
        // Fetch the full article text from the webpage
        let articleText = await fetchArticleText(from: item.link)

        // Fall back to title + snippet if fetch fails
        let textToSummarize = articleText ?? "\(item.title). \(item.snippet)"
        guard textToSummarize.trimmingCharacters(in: .whitespaces).count > 20 else { return }

        do {
            let session = FoundationIntelligence.Summarizer(
                format: .paragraph,
                style: .concise
            )
            let result = try await session.summarize(textToSummarize)
            item.summary = result
            try? context.save()
        } catch {
            print("Summarization failed: \(error.localizedDescription)")
        }
    }

    /// Fetches a webpage and extracts the main article body text.
    private func fetchArticleText(from urlString: String) async -> String? {
        guard let url = URL(string: urlString) else { return nil }

        do {
            var request = URLRequest(url: url, timeoutInterval: 15)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii)
            else { return nil }

            let text = extractArticleBody(from: html)
            // Only return if we got meaningful content (at least ~100 chars)
            return text.count >= 100 ? text : nil
        } catch {
            print("Article fetch failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Extracts article body text from HTML.
    /// Tries <article> tag first, then falls back to <p> tags.
    private func extractArticleBody(from html: String) -> String {
        // Strategy 1: Extract content from <article> tag
        if let articleContent = extractTag("article", from: html) {
            let text = extractParagraphs(from: articleContent)
            if text.count >= 100 { return text }
        }

        // Strategy 2: Look for common article container classes/IDs
        for pattern in ["class=\"article-body", "class=\"story-body", "class=\"post-content", "class=\"entry-content", "id=\"article-body"] {
            if html.contains(pattern) {
                // Find the div/section containing this class
                if let range = html.range(of: pattern) {
                    let startSearch = html[..<range.lowerBound]
                    // Find the opening tag
                    if let tagStart = startSearch.lastIndex(of: "<") {
                        let remainder = String(html[tagStart...])
                        // Extract content from this container
                        let text = extractParagraphs(from: remainder)
                        if text.count >= 100 { return text }
                    }
                }
            }
        }

        // Strategy 3: Extract all <p> tags from the whole page
        let text = extractParagraphs(from: html)
        return text
    }

    /// Extracts content between opening and closing tags of the given tag name.
    private func extractTag(_ tag: String, from html: String) -> String? {
        guard let openRange = html.range(of: "<\(tag)", options: .caseInsensitive) else { return nil }
        // Find the end of the opening tag
        guard let openEnd = html[openRange.upperBound...].range(of: ">") else { return nil }
        let contentStart = openEnd.upperBound
        // Find the closing tag
        guard let closeRange = html.range(of: "</\(tag)>", options: .caseInsensitive, range: contentStart..<html.endIndex) else { return nil }
        return String(html[contentStart..<closeRange.lowerBound])
    }

    /// Extracts text from all <p> tags in the given HTML string.
    private func extractParagraphs(from html: String) -> String {
        var paragraphs: [String] = []
        var searchRange = html.startIndex..<html.endIndex

        while let openRange = html.range(of: "<p", options: .caseInsensitive, range: searchRange) {
            // Find end of opening <p> tag
            guard let openEnd = html.range(of: ">", range: openRange.upperBound..<html.endIndex) else { break }
            let contentStart = openEnd.upperBound

            // Find closing </p>
            guard let closeRange = html.range(of: "</p>", options: .caseInsensitive, range: contentStart..<html.endIndex) else { break }

            let rawContent = String(html[contentStart..<closeRange.lowerBound])
            let cleaned = stripHTML(rawContent).trimmingCharacters(in: .whitespacesAndNewlines)

            // Only keep paragraphs with meaningful text (skip nav items, short labels)
            if cleaned.count > 30 {
                paragraphs.append(cleaned)
            }

            searchRange = closeRange.upperBound..<html.endIndex
        }

        // Cap at ~3000 chars to keep summarization fast
        var result = ""
        for p in paragraphs {
            if result.count + p.count > 3000 { break }
            result += p + " "
        }
        return result.trimmingCharacters(in: .whitespaces)
    }
}
