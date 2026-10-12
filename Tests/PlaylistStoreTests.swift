import XCTest
@testable import Rattrapage

@MainActor
final class PlaylistStoreTests: XCTestCase {
    private var suiteName = ""
    private var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        suiteName = "PlaylistStoreTests.\(UUID().uuidString)"
        userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
    }

    func testBuiltInSourceIsAvailableOnFirstLaunch() {
        let store = PlaylistStore(userDefaults: userDefaults)

        XCTAssertTrue(
            store.sources.contains {
                $0.url == "https://iptv-org.github.io/iptv/countries/fr.m3u"
                    && $0.isBuiltIn
            }
        )
    }

    func testAddPersistsSourceAndSelection() throws {
        let store = PlaylistStore(userDefaults: userDefaults)
        let source = try XCTUnwrap(
            store.add(name: "My playlist", url: "https://example.com/playlist.m3u8")
        )

        let restoredStore = PlaylistStore(userDefaults: userDefaults)

        XCTAssertTrue(restoredStore.sources.contains { $0.id == source.id })
        XCTAssertEqual(restoredStore.selectedSourceID, source.id)
        XCTAssertEqual(restoredStore.selectedSource?.name, "My playlist")
    }

    func testAddDoesNotDuplicateExistingURL() throws {
        let store = PlaylistStore(userDefaults: userDefaults)
        let firstSource = try XCTUnwrap(
            store.add(name: "First name", url: "https://example.com/playlist.m3u8")
        )
        let secondSource = try XCTUnwrap(
            store.add(name: "Second name", url: "https://example.com/playlist.m3u8")
        )

        XCTAssertEqual(firstSource.id, secondSource.id)
        XCTAssertEqual(
            store.sources.filter { $0.url == "https://example.com/playlist.m3u8" }.count,
            1
        )
    }

    func testBuiltInSourceCannotBeRemoved() throws {
        let store = PlaylistStore(userDefaults: userDefaults)
        let builtInSource = try XCTUnwrap(store.sources.first { $0.isBuiltIn })

        store.remove(builtInSource)

        XCTAssertTrue(store.sources.contains { $0.id == builtInSource.id })
    }
}
