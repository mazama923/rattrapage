import XCTest
@testable import Rattrapage

final class XMLTVParserTests: XCTestCase {
    func testParseReturnsCurrentAndNextProgramsForEachChannel() throws {
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2024-01-01T12:30:00Z"))
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tv>
          <programme start="20240101110000 +0000" stop="20240101120000 +0000" channel="news">
            <title>Old news</title>
          </programme>
          <programme start="20240101120000 +0000" stop="20240101130000 +0000" channel="news">
            <title>Midday &amp; news</title>
            <desc>Current headlines</desc>
          </programme>
          <programme start="20240101130000 +0000" stop="20240101140000 +0000" channel="news">
            <title>Afternoon news</title>
          </programme>
          <programme start="20240101140000 +0000" stop="20240101150000 +0000" channel="news">
            <title>Later news</title>
          </programme>
        </tv>
        """

        let programs = try XMLTVParser().parse(Data(xml.utf8), now: now)

        XCTAssertEqual(programs["news"]?.map(\.title), ["Midday & news", "Afternoon news"])
        XCTAssertEqual(programs["news"]?.first?.summary, "Current headlines")
    }

    func testParseRejectsMalformedXML() {
        XCTAssertThrowsError(try XMLTVParser().parse(Data("<tv>".utf8)))
    }
}
