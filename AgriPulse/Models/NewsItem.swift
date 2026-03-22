import Foundation
import SwiftData

@Model
final class NewsItem {
    #Unique<NewsItem>([\.link])

    var title: String
    @Attribute(.unique) var link: String
    var source: String
    var snippet: String
    var publishedAt: Date
    var isSaved: Bool
    var isGlobal: Bool

    var commodity: Commodity?

    init(
        title: String,
        link: String,
        source: String,
        snippet: String,
        publishedAt: Date,
        isSaved: Bool = false,
        isGlobal: Bool = false,
        commodity: Commodity? = nil
    ) {
        self.title = title
        self.link = link
        self.source = source
        self.snippet = snippet
        self.publishedAt = publishedAt
        self.isSaved = isSaved
        self.isGlobal = isGlobal
        self.commodity = commodity
    }
}
