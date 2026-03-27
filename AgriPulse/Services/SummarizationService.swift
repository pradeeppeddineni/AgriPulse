import Foundation
import SwiftData

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
final class SummarizationService {
    static let shared = SummarizationService()
    private init() {}

    var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    func summarize(_ item: NewsItem, context: ModelContext) async {
        guard item.summary == nil else { return }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            await summarizeWithAppleIntelligence(item, context: context)
        }
        #endif
    }

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private func summarizeWithAppleIntelligence(_ item: NewsItem, context: ModelContext) async {
        guard SystemLanguageModel.default.isAvailable else { return }

        // Fetch the full article text from the webpage
        let articleText = await fetchArticleText(from: item.link)

        // Fall back to title + snippet if fetch fails or body is too short
        let textToSummarize: String
        if let body = articleText, body.count >= 100 {
            textToSummarize = body
        } else {
            let fallback = "\(item.title). \(item.snippet)"
            guard fallback.trimmingCharacters(in: .whitespaces).count > 50 else { return }
            textToSummarize = fallback
        }

        do {
            let session = LanguageModelSession(
                instructions: "You are a concise news summarizer. Summarize the following article in 2-3 sentences. Focus on the key facts and impact."
            )
            let response = try await session.respond(to: textToSummarize)
            let summary = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if !summary.isEmpty {
                item.summary = summary
                try? context.save()
            }
        } catch {
            print("Summarization failed: \(error.localizedDescription)")
        }
    }
    #endif

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
            return text.count >= 100 ? text : nil
        } catch {
            print("Article fetch failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Extracts article body text from HTML.
    private func extractArticleBody(from html: String) -> String {
        if let articleContent = extractTag("article", from: html) {
            let text = extractParagraphs(from: articleContent)
            if text.count >= 100 { return text }
        }

        // Try <main> tag
        if let mainContent = extractTag("main", from: html) {
            let text = extractParagraphs(from: mainContent)
            if text.count >= 100 { return text }
        }

        // Try common CSS class/id patterns for article content
        let patterns = [
            "class=\"article-body", "class=\"story-body", "class=\"post-content",
            "class=\"entry-content", "id=\"article-body", "class=\"article-content",
            "class=\"story-content", "class=\"td-post-content", "class=\"article_content",
            "class=\"content-area", "class=\"article__body", "class=\"field-item",
            "class=\"story_details", "class=\"article-text", "class=\"news-detail",
            "class=\"main-content", "class=\"post-body", "class=\"node-content",
            "itemprop=\"articleBody",
        ]
        for pattern in patterns {
            if html.contains(pattern) {
                if let range = html.range(of: pattern) {
                    let startSearch = html[..<range.lowerBound]
                    if let tagStart = startSearch.lastIndex(of: "<") {
                        let remainder = String(html[tagStart...])
                        let text = extractParagraphs(from: remainder)
                        if text.count >= 100 { return text }
                    }
                }
            }
        }

        return extractParagraphs(from: html)
    }

    private func extractTag(_ tag: String, from html: String) -> String? {
        guard let openRange = html.range(of: "<\(tag)", options: .caseInsensitive) else { return nil }
        guard let openEnd = html[openRange.upperBound...].range(of: ">") else { return nil }
        let contentStart = openEnd.upperBound
        guard let closeRange = html.range(of: "</\(tag)>", options: .caseInsensitive, range: contentStart..<html.endIndex) else { return nil }
        return String(html[contentStart..<closeRange.lowerBound])
    }

    private func extractParagraphs(from html: String) -> String {
        var paragraphs: [String] = []
        var searchRange = html.startIndex..<html.endIndex

        while let openRange = html.range(of: "<p", options: .caseInsensitive, range: searchRange) {
            guard let openEnd = html.range(of: ">", range: openRange.upperBound..<html.endIndex) else { break }
            let contentStart = openEnd.upperBound
            guard let closeRange = html.range(of: "</p>", options: .caseInsensitive, range: contentStart..<html.endIndex) else { break }

            let rawContent = String(html[contentStart..<closeRange.lowerBound])
            let cleaned = stripHTML(rawContent).trimmingCharacters(in: .whitespacesAndNewlines)

            if cleaned.count > 30 {
                paragraphs.append(cleaned)
            }

            searchRange = closeRange.upperBound..<html.endIndex
        }

        var result = ""
        for p in paragraphs {
            if result.count + p.count > 16000 { break }
            result += p + " "
        }
        return result.trimmingCharacters(in: .whitespaces)
    }
}
