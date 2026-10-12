import AVFoundation
import XCTest
@testable import Rattrapage

@MainActor
final class PlayerManagerTests: XCTestCase {
    private let seekableRange = CMTimeRange(
        start: CMTime(seconds: 100, preferredTimescale: 600),
        duration: CMTime(seconds: 120, preferredTimescale: 600)
    )

    func testSeekIsClampedToStartOfDVRWindow() throws {
        let target = try XCTUnwrap(
            PlayerManager.clampedSeekTime(
                currentTime: CMTime(seconds: 110, preferredTimescale: 600),
                offset: -30,
                in: seekableRange
            )
        )

        XCTAssertEqual(target.seconds, 100, accuracy: 0.01)
    }

    func testSeekStopsOneSecondBeforeLiveEdge() throws {
        let target = try XCTUnwrap(
            PlayerManager.clampedSeekTime(
                currentTime: CMTime(seconds: 210, preferredTimescale: 600),
                offset: 30,
                in: seekableRange
            )
        )

        XCTAssertEqual(target.seconds, 219, accuracy: 0.01)
    }

    func testSeekRejectsInvalidTimes() {
        let target = PlayerManager.clampedSeekTime(
            currentTime: .invalid,
            offset: -30,
            in: seekableRange
        )

        XCTAssertNil(target)
    }
}
