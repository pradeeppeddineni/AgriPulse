import Foundation
import FeedKit

struct RSSArticle {
    let title: String
    let link: String
    let source: String
    let snippet: String
    let publishedAt: Date
}

func stripHTML(_ html: String) -> String {
    // Remove HTML tags
    var text = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    // Remove bare Google News redirect URLs that remain after stripping <a> tags
    text = text.replacingOccurrences(of: "https?://news\\.google\\.com/rss/articles/[^\\s]*", with: "", options: .regularExpression)
    // Remove any other bare URLs left behind (e.g. https://... that aren't useful snippet text)
    text = text.replacingOccurrences(of: "https?://\\S+", with: "", options: .regularExpression)
    // Decode common HTML entities
    let entities: [(String, String)] = [
        ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
        ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"),
        ("&nbsp;", " "), ("&#x27;", "'"), ("&#x2F;", "/"),
        ("&rsquo;", "\u{2019}"), ("&lsquo;", "\u{2018}"),
        ("&rdquo;", "\u{201C}"), ("&ldquo;", "\u{201D}"),
        ("&mdash;", "\u{2014}"), ("&ndash;", "\u{2013}"),
        ("&hellip;", "\u{2026}"),
    ]
    for (entity, replacement) in entities {
        text = text.replacingOccurrences(of: entity, with: replacement)
    }
    // Decode numeric entities (&#NNN;)
    if let regex = try? NSRegularExpression(pattern: "&#(\\d+);") {
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, range: range).reversed()
        for match in matches {
            if let numRange = Range(match.range(at: 1), in: text),
               let code = UInt32(text[numRange]),
               let scalar = Unicode.Scalar(code) {
                let charRange = Range(match.range, in: text)!
                text.replaceSubrange(charRange, with: String(Character(scalar)))
            }
        }
    }
    // Collapse whitespace and trim
    text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    return text.trimmingCharacters(in: .whitespacesAndNewlines)
}

actor RSSFetcher {
    static let shared = RSSFetcher()

    private init() {}

    func fetch(query: String, isGlobal: Bool = false) async -> [RSSArticle] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let queryLower = query.lowercased()
        let isWeather = queryLower.contains("monsoon") || queryLower.contains("imd") || queryLower.contains("skymet")

        let baseURL: String
        if isGlobal && !isWeather {
            baseURL = "https://news.google.com/rss/search?q=\(encoded)&hl=en-US&gl=US&ceid=US:en"
        } else {
            baseURL = "https://news.google.com/rss/search?q=\(encoded)&hl=en-IN&gl=IN&ceid=IN:en"
        }

        let urlString = "\(baseURL)&tbs=qdr:d7"
        guard let url = URL(string: urlString) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let parser = FeedParser(data: data)
            let result = parser.parse()

            switch result {
            case .success(let feed):
                guard let rssFeed = feed.rssFeed else { return [] }
                return (rssFeed.items ?? []).compactMap { item -> RSSArticle? in
                    guard let link = item.link, !link.isEmpty else { return nil }
                    let title = item.title ?? "No Title"
                    var snippet = stripHTML(item.description ?? "")
                    if snippet.count > 500 { snippet = String(snippet.prefix(500)) + "..." }
                    let pubDate = item.pubDate ?? Date()
                    let source = item.source?.value ?? item.dublinCore?.dcCreator ?? "Google News"

                    return RSSArticle(
                        title: title,
                        link: link,
                        source: source,
                        snippet: snippet,
                        publishedAt: pubDate
                    )
                }
            case .failure:
                return []
            }
        } catch {
            return []
        }
    }

    func fetchMultipleQueries(_ queries: [String], isGlobal: Bool = false) async -> [RSSArticle] {
        var articles: [RSSArticle] = []
        var seenLinks = Set<String>()

        await withTaskGroup(of: [RSSArticle].self) { group in
            for query in queries {
                group.addTask {
                    await self.fetch(query: query, isGlobal: isGlobal)
                }
            }
            for await batch in group {
                for article in batch {
                    if !seenLinks.contains(article.link) {
                        seenLinks.insert(article.link)
                        articles.append(article)
                    }
                }
            }
        }

        return articles.sorted { $0.publishedAt > $1.publishedAt }
    }
}
