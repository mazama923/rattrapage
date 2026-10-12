import Foundation

/// Un programme TV diffusé maintenant ou prévu ensuite pour une chaîne.
struct TVProgram: Identifiable, Hashable {
    let channelID: String
    let title: String
    let start: Date
    let end: Date
    let summary: String?

    var id: String {
        "\(channelID)-\(start.timeIntervalSince1970)"
    }
}
