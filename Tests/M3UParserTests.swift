import XCTest
@testable import Rattrapage

final class M3UParserTests: XCTestCase {
    func testParseExtractsChannelMetadata() throws {
        let playlist = """
        #EXTM3U
        #EXTINF:-1 tvg-id="example.news" tvg-logo="https://images.example/news.png" group-title="News",Example News
        https://streams.example/news/index.m3u8
        """

        let channels = try M3UParser().parse(playlist)

        XCTAssertEqual(channels.count, 1)
        XCTAssertEqual(channels[0].name, "Example News")
        XCTAssertEqual(channels[0].streamURL, URL(string: "https://streams.example/news/index.m3u8"))
        XCTAssertEqual(channels[0].logoURL, URL(string: "https://images.example/news.png"))
        XCTAssertEqual(channels[0].group, "News")
        XCTAssertEqual(channels[0].guideID, "example.news")
    }

    func testParseResolvesRelativeStreamAndLogoURLs() throws {
        let playlist = """
        #EXTM3U
        #EXTINF:-1 tvg-logo="logos/example.png",Example Channel
        streams/example.m3u8
        """
        let baseURL = URL(string: "https://playlist.example/catalog/playlist.m3u8")!

        let channels = try M3UParser().parse(playlist, relativeTo: baseURL.deletingLastPathComponent())

        XCTAssertEqual(channels[0].streamURL, URL(string: "https://playlist.example/catalog/streams/example.m3u8"))
        XCTAssertEqual(channels[0].logoURL, URL(string: "https://playlist.example/catalog/logos/example.png"))
    }

    func testParseRejectsPlaylistWithoutChannels() {
        XCTAssertThrowsError(try M3UParser().parse("#EXTM3U\n# A comment")) { error in
            XCTAssertEqual(error as? M3UParserError, .noPlayableChannels)
        }
    }
}
