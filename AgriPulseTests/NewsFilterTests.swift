import XCTest
@testable import AgriPulse

final class NewsFilterTests: XCTestCase {

    // MARK: - Noise pattern filtering

    func testRejectsHoroscope() {
        XCTAssertFalse(NewsFilterEngine.isRelevant(commodityName: "Wheat", title: "Daily horoscope for March 26"))
    }

    func testRejectsRecipe() {
        XCTAssertFalse(NewsFilterEngine.isRelevant(commodityName: "Potato", title: "Best potato recipe for dinner"))
    }

    func testRejectsCricket() {
        XCTAssertFalse(NewsFilterEngine.isRelevant(commodityName: "Wheat", title: "IPL cricket match highlights today"))
    }

    func testRejectsPetFood() {
        XCTAssertFalse(NewsFilterEngine.isRelevant(commodityName: "Wheat", title: "Can dogs eat wheat? Vet-reviewed guide"))
    }

    // MARK: - Commodity-specific exclusions

    func testMaizeRejectsCornrow() {
        XCTAssertFalse(NewsFilterEngine.isRelevant(commodityName: "Maize", title: "Latest cornrow braiding styles for 2026"))
    }

    func testWheatRejectsGrainOfSalt() {
        XCTAssertFalse(NewsFilterEngine.isRelevant(commodityName: "Wheat", title: "Take this claim with a grain of salt"))
    }

    func testBlackPepperRejectsPepperSpray() {
        XCTAssertFalse(NewsFilterEngine.isRelevant(commodityName: "Black pepper", title: "Police use pepper spray on protesters"))
    }

    func testChilliRejectsRedHotChiliPeppers() {
        XCTAssertFalse(NewsFilterEngine.isRelevant(commodityName: "Chilli powder", title: "Red hot chili peppers announce new tour"))
    }

    func testChanaRejectsGoldArticles() {
        XCTAssertFalse(NewsFilterEngine.isRelevant(commodityName: "Chana", title: "Gold price today: Chana gold market update"))
    }

    // MARK: - Relevant articles pass through

    func testWheatRelevantArticle() {
        XCTAssertTrue(NewsFilterEngine.isRelevant(commodityName: "Wheat", title: "India wheat output may drop by over 1% from initial estimate"))
    }

    func testMaizeRelevantArticle() {
        XCTAssertTrue(NewsFilterEngine.isRelevant(commodityName: "Maize", title: "Maize prices rise in Bihar mandis as demand for poultry feed grows"))
    }

    func testCurrencyRelevantArticle() {
        XCTAssertTrue(NewsFilterEngine.isRelevant(commodityName: "Currency", title: "Indian rupee falls to 85.50 against dollar as RBI intervention slows"))
    }

    func testEquityRelevantArticle() {
        XCTAssertTrue(NewsFilterEngine.isRelevant(commodityName: "Indian Equity", title: "Sensex falls 500 points amid global selloff"))
    }

    // MARK: - India detection

    func testMentionsIndiaWithStateName() {
        XCTAssertTrue(NewsFilterEngine.mentionsIndia("Wheat procurement in Punjab reaches record levels"))
    }

    func testMentionsIndiaWithMandi() {
        XCTAssertTrue(NewsFilterEngine.mentionsIndia("Onion prices spike in mandi markets"))
    }

    func testNoIndiaMention() {
        XCTAssertFalse(NewsFilterEngine.mentionsIndia("US wheat export strength fading into new crop"))
    }

    // MARK: - India-only commodities

    func testAgriWeatherIsIndiaOnly() {
        XCTAssertTrue(NewsFilterEngine.isIndiaOnly("Agri Weather"))
    }

    func testWheatIsNotIndiaOnly() {
        XCTAssertFalse(NewsFilterEngine.isIndiaOnly("Wheat"))
    }

    // MARK: - PIB relevance

    func testPIBCommodityRelated() {
        XCTAssertTrue(NewsFilterEngine.isPIBCommodityRelated("Ministry announces MSP for wheat procurement"))
    }

    func testPIBNotCommodityRelated() {
        XCTAssertFalse(NewsFilterEngine.isPIBCommodityRelated("PM visits European Union for trade summit"))
    }
}
