import Foundation
import SwiftSoup
import SwiftData

// Ported from server/pib.ts

@MainActor
final class PIBService {
    static let shared = PIBService()

    private let pibBase = "https://www.pib.gov.in"

    private init() {}

    /// Main entry point: scrape PIB + Google News RSS fallback
    func refreshPIBNews(for commodity: Commodity, context: ModelContext) async -> Int {
        // Strategy 1: Direct PIB allRel page scraping
        var toInsert: [(title: String, link: String, publishedAt: Date)] = []
        var seenPRIDs = Set<String>()

        // Today (no date param) + past 6 days
        var datesToScrape = [""]
        for i in 1...6 {
            if let d = Calendar.current.date(byAdding: .day, value: -i, to: Date()) {
                datesToScrape.append(formatDatePIB(d))
            }
        }

        for dateStr in datesToScrape {
            let found = await scrapeAllRelPage(dateStr: dateStr)
            for (prid, title) in found {
                if seenPRIDs.contains(prid) { continue }
                seenPRIDs.insert(prid)

                var approxDate = Date()
                if !dateStr.isEmpty {
                    let parts = dateStr.split(separator: "/")
                    if parts.count == 3,
                       let dd = Int(parts[0]), let mm = Int(parts[1]), let yyyy = Int(parts[2]) {
                        var comps = DateComponents()
                        comps.year = yyyy; comps.month = mm; comps.day = dd
                        comps.hour = 12
                        approxDate = Calendar.current.date(from: comps) ?? Date()
                    }
                }

                let exactDate = await getPressReleaseDate(prid: prid, fallback: approxDate)
                toInsert.append((title: title, link: "\(pibBase)/PressReleasePage.aspx?PRID=\(prid)", publishedAt: exactDate))
            }

            try? await Task.sleep(for: .milliseconds(800))
        }

        // Strategy 2: Google News RSS fallback if direct scraping got nothing
        if toInsert.isEmpty {
            let fallback = await fetchPIBViaGoogleNews()
            toInsert.append(contentsOf: fallback)
        }

        // Insert into SwiftData
        var count = 0
        for item in toInsert {
            let link = item.link
            let predicate = #Predicate<NewsItem> { $0.link == link }
            let descriptor = FetchDescriptor<NewsItem>(predicate: predicate)
            let existing = (try? context.fetchCount(descriptor)) ?? 0
            if existing > 0 { continue }

            let newsItem = NewsItem(
                title: item.title,
                link: item.link,
                source: "PIB - Press Information Bureau",
                snippet: "",
                publishedAt: item.publishedAt,
                isGlobal: false,
                commodity: commodity
            )
            context.insert(newsItem)
            count += 1
        }

        try? context.save()
        return count
    }

    // MARK: - Strategy 1: Direct PIB allRel scraping

    private func scrapeAllRelPage(dateStr: String) async -> [(prid: String, title: String)] {
        var urlString = "\(pibBase)/allRel.aspx?reg=3&lang=1"
        if !dateStr.isEmpty {
            urlString += "&dt=\(dateStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? dateStr)"
        }

        guard let url = URL(string: urlString) else { return [] }

        do {
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8) else { return [] }

            let doc = try SwiftSoup.parse(html)
            let links = try doc.select("a[href*=PressReleasePage.aspx?PRID=]")

            var results: [(String, String)] = []
            for link in links {
                let href = try link.attr("href")
                let title = try link.attr("title").isEmpty ? try link.text() : try link.attr("title")

                // Extract PRID from href
                if let range = href.range(of: "PRID=") {
                    let prid = String(href[range.upperBound...]).components(separatedBy: CharacterSet.decimalDigits.inverted).first ?? ""
                    if !prid.isEmpty && !title.isEmpty && NewsFilterEngine.isPIBCommodityRelated(title) {
                        results.append((prid, title.trimmingCharacters(in: .whitespacesAndNewlines)))
                    }
                }
            }
            return results
        } catch {
            return []
        }
    }

    private func getPressReleaseDate(prid: String, fallback: Date) async -> Date {
        guard let url = URL(string: "\(pibBase)/PressReleasePage.aspx?PRID=\(prid)") else { return fallback }

        do {
            try await Task.sleep(for: .milliseconds(300))
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8) else { return fallback }

            // Match pattern: "15 JAN 2026 10:30AM"
            let pattern = #"(\d{1,2})\s+(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\s+(\d{4})\s+(\d{1,2}):(\d{2})(AM|PM)"#
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)) else {
                return fallback
            }

            let months = ["JAN": 1, "FEB": 2, "MAR": 3, "APR": 4, "MAY": 5, "JUN": 6,
                          "JUL": 7, "AUG": 8, "SEP": 9, "OCT": 10, "NOV": 11, "DEC": 12]

            let nsHtml = html as NSString
            let day = Int(nsHtml.substring(with: match.range(at: 1))) ?? 1
            let monthStr = nsHtml.substring(with: match.range(at: 2)).uppercased()
            let year = Int(nsHtml.substring(with: match.range(at: 3))) ?? 2026
            var hour = Int(nsHtml.substring(with: match.range(at: 4))) ?? 12
            let minute = Int(nsHtml.substring(with: match.range(at: 5))) ?? 0
            let ampm = nsHtml.substring(with: match.range(at: 6)).uppercased()

            if ampm == "PM" && hour != 12 { hour += 12 }
            if ampm == "AM" && hour == 12 { hour = 0 }

            var comps = DateComponents()
            comps.year = year
            comps.month = months[monthStr] ?? 1
            comps.day = day
            comps.hour = hour
            comps.minute = minute
            comps.timeZone = TimeZone(identifier: "Asia/Kolkata")

            return Calendar.current.date(from: comps) ?? fallback
        } catch {
            return fallback
        }
    }

    // MARK: - Strategy 2: Google News RSS fallback

    private func fetchPIBViaGoogleNews() async -> [(title: String, link: String, publishedAt: Date)] {
        let searchTerms = [
            "\"pib.gov.in\" agriculture farmers India",
            "\"press information bureau\" (wheat OR rice OR sugar OR MSP OR procurement) India",
            "\"press information bureau\" (pulses OR oilseed OR crop OR kisan) India",
            "\"pib.gov.in\" (food grain OR horticulture OR fertilizer) India",
            "site:pib.gov.in agriculture crop farmer",
        ]

        var results: [(title: String, link: String, publishedAt: Date)] = []
        var seen = Set<String>()

        for term in searchTerms {
            let articles = await RSSFetcher.shared.fetch(query: term)
            for article in articles {
                if seen.contains(article.link) { continue }
                let title = article.title
                    .replacingOccurrences(of: " - PIB", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: " - Press Information Bureau", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                guard NewsFilterEngine.isPIBCommodityRelated(title) || NewsFilterEngine.isPIBCommodityRelated(article.snippet) else { continue }

                seen.insert(article.link)
                results.append((title: title, link: article.link, publishedAt: article.publishedAt))
            }

            try? await Task.sleep(for: .milliseconds(500))
        }

        return results
    }

    // MARK: - Helpers

    private func formatDatePIB(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.day, .month, .year], from: date)
        return String(format: "%02d/%02d/%04d", comps.day ?? 1, comps.month ?? 1, comps.year ?? 2026)
    }
}
