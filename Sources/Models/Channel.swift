import Foundation

/// Une chaîne obtenue à partir d'une entrée `#EXTINF` suivie de son URL de flux.
struct Channel: Identifiable, Hashable {
    // L'URL du flux est stable dans une playlist et convient donc comme identifiant.
    let id: String
    let name: String
    let streamURL: URL
    let logoURL: URL?
    let group: String?

    init(name: String, streamURL: URL, logoURL: URL? = nil, group: String? = nil) {
        self.id = streamURL.absoluteString
        self.name = name
        self.streamURL = streamURL
        self.logoURL = logoURL
        self.group = group
    }
}
