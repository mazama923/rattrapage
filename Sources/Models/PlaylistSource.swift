import Foundation

/// Une source de playlist que l'utilisateur peut sélectionner dans les réglages.
struct PlaylistSource: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let url: String
    let epgURL: String?
    let isBuiltIn: Bool

    init(id: UUID = UUID(), name: String, url: String, epgURL: String? = nil, isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.url = url
        self.epgURL = epgURL
        self.isBuiltIn = isBuiltIn
    }
}
