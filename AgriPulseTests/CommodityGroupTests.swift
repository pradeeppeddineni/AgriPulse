import XCTest
@testable import AgriPulse

final class CommodityGroupTests: XCTestCase {

    // MARK: - Market groups defined correctly

    func testSevenMarketGroupsExist() {
        XCTAssertEqual(CommoditySeeds.marketGroups.count, 7)
    }

    func testGrainsGroupContainsFiveCommodities() {
        let grains = CommoditySeeds.marketGroups.first { $0.slug == "grains" }
        XCTAssertNotNil(grains)
        XCTAssertEqual(grains?.commodities.count, 5)
        XCTAssertTrue(grains!.commodities.contains("Wheat"))
        XCTAssertTrue(grains!.commodities.contains("Maize"))
        XCTAssertTrue(grains!.commodities.contains("Paddy"))
        XCTAssertTrue(grains!.commodities.contains("Chana"))
        XCTAssertTrue(grains!.commodities.contains("Ethanol / DDGS"))
    }

    func testOthersGroupContainsCurrency() {
        let others = CommoditySeeds.marketGroups.first { $0.slug == "others" }
        XCTAssertNotNil(others)
        XCTAssertTrue(others!.commodities.contains("Currency"))
        XCTAssertTrue(others!.commodities.contains("Crude"))
        XCTAssertTrue(others!.commodities.contains("Precious Metals"))
    }

    func testAllGroupSlugsAreUnique() {
        let slugs = CommoditySeeds.marketGroups.map(\.slug)
        XCTAssertEqual(Set(slugs).count, slugs.count)
    }

    func testMarketGroupLookup() {
        let grains = CommoditySeeds.marketGroup(forSlug: "grains")
        XCTAssertNotNil(grains)
        XCTAssertEqual(grains?.label, "Grains")

        let missing = CommoditySeeds.marketGroup(forSlug: "nonexistent")
        XCTAssertNil(missing)
    }

    // MARK: - Commodity seeding

    func testTotalCommodityCount() {
        // Should be 40+ (regular + special + market + equity)
        XCTAssertGreaterThanOrEqual(CommoditySeeds.all.count, 40)
    }

    func testCurrencyCommodityExists() {
        XCTAssertTrue(CommoditySeeds.all.contains { $0.name == "Currency" })
    }

    func testAllCommoditiesHaveSearchQueries() {
        for seed in CommoditySeeds.all {
            XCTAssertFalse(seed.searchQueries.isEmpty, "\(seed.name) has no search queries")
        }
    }

    // MARK: - Group assignment

    func testWheatMapsToGrains() {
        XCTAssertEqual(CommoditySeeds.group(for: "Wheat"), .grains)
    }

    func testPalmOilMapsToEdibleOils() {
        XCTAssertEqual(CommoditySeeds.group(for: "Palm Oil"), .edibleOils)
    }

    func testCurrencyMapsToOthers() {
        XCTAssertEqual(CommoditySeeds.group(for: "Currency"), .others)
    }

    func testCryptoMapsToEquity() {
        XCTAssertEqual(CommoditySeeds.group(for: "Crypto"), .equity)
    }

    func testPIBMapsToRegulatory() {
        XCTAssertEqual(CommoditySeeds.group(for: "PIB Updates"), .regulatory)
    }

    func testAgriWeatherMapsToCommand() {
        XCTAssertEqual(CommoditySeeds.group(for: "Agri Weather"), .command)
    }

    // MARK: - Every commodity in a market group maps correctly

    func testAllGroupCommoditiesMapToCorrectGroup() {
        let expectedMapping: [(slug: String, group: CommoditySeeds.Group)] = [
            ("grains", .grains),
            ("edible-oils", .edibleOils),
            ("others", .others),
            ("fresh", .fresh),
            ("dry-fruits", .dryFruits),
            ("spices", .spices),
            ("others-1", .others1),
        ]

        for (slug, expectedGroup) in expectedMapping {
            guard let mg = CommoditySeeds.marketGroup(forSlug: slug) else {
                XCTFail("Market group \(slug) not found")
                continue
            }
            for commodityName in mg.commodities {
                XCTAssertEqual(
                    CommoditySeeds.group(for: commodityName), expectedGroup,
                    "\(commodityName) should map to \(expectedGroup) but got \(CommoditySeeds.group(for: commodityName))"
                )
            }
        }
    }

    // MARK: - Keywords exist for all commodities

    func testAllRegularCommoditiesHaveKeywords() {
        for seed in CommoditySeeds.regular {
            XCTAssertNotNil(
                KeywordLists.commodityTitleKeywords[seed.name],
                "\(seed.name) has no title keywords defined"
            )
        }
    }

    func testCurrencyKeywordsExist() {
        let keywords = KeywordLists.commodityTitleKeywords["Currency"]
        XCTAssertNotNil(keywords)
        XCTAssertTrue(keywords!.contains("rupee"))
        XCTAssertTrue(keywords!.contains("forex"))
    }
}
