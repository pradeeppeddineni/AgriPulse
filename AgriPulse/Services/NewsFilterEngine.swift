import Foundation

// Ported from server/news.ts — isArticleRelevant, indiaKeywords, NOISE_PATTERNS

enum NewsFilterEngine {
    /// Returns true if the article's full text mentions India-related keywords
    static func mentionsIndia(_ text: String) -> Bool {
        let lower = text.lowercased()
        return KeywordLists.indiaKeywords.contains { lower.contains($0) }
    }

    /// Returns true if the article title is relevant for the given commodity
    static func isRelevant(commodityName: String, title: String) -> Bool {
        let lowerTitle = title.lowercased()

        // 1. Reject universal noise
        if KeywordLists.noisePatterns.contains(where: { lowerTitle.contains($0) }) {
            return false
        }

        // 2. Commodity-specific exclusions
        if commodityName == "Chana" {
            if KeywordLists.chanaMetalExclusions.contains(where: { lowerTitle.contains($0) }) {
                return false
            }
        }

        // 3. Commodity keyword must appear in title
        guard let keywords = KeywordLists.commodityTitleKeywords[commodityName] else {
            return true // No filter defined — allow everything
        }

        return keywords.contains { lowerTitle.contains($0) }
    }

    /// Returns true if this commodity should only keep India-focused articles
    static func isIndiaOnly(_ commodityName: String) -> Bool {
        KeywordLists.indiaOnlyNames.contains(commodityName)
    }

    /// Determine if a query string targets global markets (used for RSS locale)
    static func isGlobalQuery(_ query: String) -> Bool {
        let lower = query.lowercased()
        return lower.contains("palm") || lower.contains("soy") || lower.contains("pea")
            || lower.contains("pulse") || lower.contains("cocoa") || lower.contains("almond")
            || lower.contains("vietnam") || lower.contains("ivory coast")
    }

    /// PIB-specific: check if title is commodity-related
    static func isPIBCommodityRelated(_ text: String) -> Bool {
        let lower = text.lowercased()
        return KeywordLists.pibCommodityKeywords.contains { lower.contains($0) }
    }
}
