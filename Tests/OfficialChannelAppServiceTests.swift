import XCTest
@testable import Rattrapage

final class OfficialChannelAppServiceTests: XCTestCase {
    func testTF1FamilyRequiresTF1Plus() {
        for channelName in ["TF1", "TF1 HD", "TMC", "TFX"] {
            XCTAssertEqual(
                OfficialChannelAppService.officialApp(for: channelName),
                .tf1Plus,
                channelName
            )
        }
    }

    func testM6FamilyRequiresM6Plus() {
        for channelName in ["M6", "M6 HD", "W9", "6ter", "6 TER HD"] {
            XCTAssertEqual(
                OfficialChannelAppService.officialApp(for: channelName),
                .m6Plus,
                channelName
            )
        }
    }

    func testUnmappedChannelDoesNotRequireAnOfficialApp() {
        XCTAssertNil(OfficialChannelAppService.officialApp(for: "France 2 HD"))
    }
}
