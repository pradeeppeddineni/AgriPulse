import Foundation
import SwiftData

@Model
final class Commodity {
    var name: String
    var searchQueries: String
    var sortOrder: Int
    var isSpecial: Bool

    @Relationship(deleteRule: .cascade, inverse: \NewsItem.commodity)
    var newsItems: [NewsItem]?

    init(name: String, searchQueries: String, sortOrder: Int = 0, isSpecial: Bool = false) {
        self.name = name
        self.searchQueries = searchQueries
        self.sortOrder = sortOrder
        self.isSpecial = isSpecial
    }
}
