import XCTest
@testable import Rattrapage

@MainActor
final class FavoritesStoreTests: XCTestCase {
    private var suiteName = ""
    private var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        suiteName = "FavoritesStoreTests.\(UUID().uuidString)"
        userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
    }

    func testFavoritesPersistForTheirPlaylist() throws {
        let source = PlaylistSource(name: "Test", url: "https://example.com/list.m3u")
        let channel = Channel(
            name: "Example",
            streamURL: URL(string: "https://example.com/live.m3u8")!
        )
        let store = FavoritesStore(userDefaults: userDefaults)
        store.load(for: source)
        store.toggle(channel)

        let restoredStore = FavoritesStore(userDefaults: userDefaults)
        restoredStore.load(for: source)

        XCTAssertTrue(restoredStore.isFavorite(channel))
    }

    func testFavoritesAreSeparatedByPlaylist() throws {
        let firstSource = PlaylistSource(name: "First", url: "https://example.com/first.m3u")
        let secondSource = PlaylistSource(name: "Second", url: "https://example.com/second.m3u")
        let channel = Channel(
            name: "Example",
            streamURL: URL(string: "https://example.com/live.m3u8")!
        )
        let store = FavoritesStore(userDefaults: userDefaults)
        store.load(for: firstSource)
        store.toggle(channel)
        store.load(for: secondSource)

        XCTAssertFalse(store.isFavorite(channel))
    }
}
