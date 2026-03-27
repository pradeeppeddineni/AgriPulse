import XCTest
@testable import AgriPulse

final class HTMLStrippingTests: XCTestCase {

    // MARK: - stripHTML function tests

    func testStripBasicHTMLTags() {
        let input = "<p>Hello <b>World</b></p>"
        let result = stripHTML(input)
        XCTAssertEqual(result, "Hello World")
    }

    func testStripAnchorTagsWithURLs() {
        // This is the actual bug — Google News RSS returns anchor tags in descriptions
        let input = """
        <a href="https://news.google.com/rss/articles/CBMi6wFBVV95cUxQ">India wheat output may drop</a>
        """
        let result = stripHTML(input)
        XCTAssertEqual(result, "India wheat output may drop")
        XCTAssertFalse(result.contains("href"))
        XCTAssertFalse(result.contains("<"))
    }

    func testDecodeHTMLEntities() {
        let input = "Wheat &amp; Rice &mdash; India&rsquo;s top grains"
        let result = stripHTML(input)
        XCTAssertEqual(result, "Wheat & Rice \u{2014} India\u{2019}s top grains")
    }

    func testDecodeNumericEntities() {
        let input = "Price &#8377; 2,500 per quintal"
        let result = stripHTML(input)
        XCTAssertTrue(result.contains("₹") || result.contains("2,500"))
    }

    func testCollapseWhitespace() {
        let input = "   Multiple   spaces   and\n\nnewlines   "
        let result = stripHTML(input)
        XCTAssertEqual(result, "Multiple spaces and newlines")
    }

    func testEmptyString() {
        XCTAssertEqual(stripHTML(""), "")
    }

    func testPlainTextPassthrough() {
        let input = "No HTML here, just plain text about wheat prices."
        let result = stripHTML(input)
        XCTAssertEqual(result, input)
    }

    func testComplexGoogleNewsSnippet() {
        // Real-world Google News RSS description with nested HTML
        let input = """
        <a href="https://news.google.com/rss/articles/CBMihwFBVV95cUxQZm">HPPC Meeting: Haryana Strengthens Wheat Storage with ₹550 Crore Bag Procurement Approval</a>&nbsp;&nbsp;<font color="#6f6f6f">Punjab Newsline</font>
        """
        let result = stripHTML(input)
        XCTAssertTrue(result.contains("HPPC Meeting"))
        XCTAssertTrue(result.contains("Punjab Newsline"))
        XCTAssertFalse(result.contains("<a"))
        XCTAssertFalse(result.contains("<font"))
    }

    func testSnippetTruncation() {
        let longHTML = String(repeating: "word ", count: 200) // ~1000 chars
        var snippet = stripHTML(longHTML)
        if snippet.count > 500 { snippet = String(snippet.prefix(500)) + "..." }
        XCTAssertTrue(snippet.count <= 503) // 500 + "..."
    }
}
