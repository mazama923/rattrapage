import Foundation

@MainActor
final class PlaylistStore: ObservableObject {
    private static let sourcesKey = "playlistSources"
    private static let selectedSourceIDKey = "selectedPlaylistSourceID"

    // Les sources intégrées sont fusionnées avec les données sauvegardées à chaque lancement.
    // Une mise à jour peut donc en ajouter sans effacer les playlists de l'utilisateur.
    private static let builtInSources = [
        PlaylistSource(
            name: "Free-TV (community catalogue)",
            url: "https://raw.githubusercontent.com/Free-TV/IPTV/master/playlist.m3u8",
            isBuiltIn: true
        )
    ]

    private let userDefaults: UserDefaults

    @Published private(set) var sources: [PlaylistSource]
    @Published private(set) var selectedSourceID: UUID?

    var selectedSource: PlaylistSource? {
        sources.first { $0.id == selectedSourceID }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let savedSources: [PlaylistSource]
        if
            let data = userDefaults.data(forKey: Self.sourcesKey),
            let decodedSources = try? JSONDecoder().decode([PlaylistSource].self, from: data)
        {
            savedSources = decodedSources
        } else {
            savedSources = []
        }

        sources = savedSources

        for builtInSource in Self.builtInSources {
            guard !sources.contains(where: { $0.url == builtInSource.url }) else { continue }
            sources.append(builtInSource)
        }

        selectedSourceID = userDefaults
            .string(forKey: Self.selectedSourceIDKey)
            .flatMap(UUID.init(uuidString:))

        if selectedSource == nil {
            selectedSourceID = sources.first?.id
        }

        persist()
    }

    /// Ajoute une URL personnalisée et la sélectionne. Une URL déjà connue n'est pas dupliquée.
    @discardableResult
    func add(name: String, url: String) -> PlaylistSource? {
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let parsedURL = URL(string: trimmedURL),
            let scheme = parsedURL.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            return nil
        }

        if let existingSource = sources.first(where: { $0.url == trimmedURL }) {
            select(existingSource)
            return existingSource
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = PlaylistSource(
            name: trimmedName.isEmpty ? (parsedURL.host ?? "Custom playlist") : trimmedName,
            url: trimmedURL
        )
        sources.append(source)
        select(source)
        return source
    }

    func remove(_ source: PlaylistSource) {
        // Une source distribuée avec l'application reste disponible après une réinitialisation.
        guard !source.isBuiltIn else { return }

        sources.removeAll { $0.id == source.id }
        if selectedSourceID == source.id {
            selectedSourceID = sources.first?.id
        }
        persist()
    }

    func select(_ source: PlaylistSource) {
        selectedSourceID = source.id
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(sources) else { return }

        userDefaults.set(data, forKey: Self.sourcesKey)
        userDefaults.set(selectedSourceID?.uuidString, forKey: Self.selectedSourceIDKey)
    }
}
