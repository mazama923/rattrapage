import Foundation

@MainActor
final class PlaylistStore: ObservableObject {
    private static let sourcesKey = "playlistSources"
    private static let selectedSourceIDKey = "selectedPlaylistSourceID"

    // Les sources intégrées sont fusionnées avec les données sauvegardées à chaque lancement.
    // Une mise à jour peut donc en ajouter sans effacer les playlists de l'utilisateur.
    private static let builtInSources = [
        PlaylistSource(
            name: "IPTV-org (Countrie FR)",
            url: "https://iptv-org.github.io/iptv/countries/fr.m3u",
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
    func add(name: String, url: String, epgURL: String? = nil) -> PlaylistSource? {
        let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEPGURL = epgURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isHTTPURL(trimmedURL) else { return nil }
        if let trimmedEPGURL, !trimmedEPGURL.isEmpty, !isHTTPURL(trimmedEPGURL) {
            return nil
        }
        guard let parsedURL = URL(string: trimmedURL) else { return nil }
        let normalizedEPGURL = trimmedEPGURL.flatMap { $0.isEmpty ? nil : $0 }

        if let existingIndex = sources.firstIndex(where: { $0.url == trimmedURL }) {
            let existingSource = sources[existingIndex]
            if normalizedEPGURL != nil {
                sources[existingIndex] = PlaylistSource(
                    id: existingSource.id,
                    name: existingSource.name,
                    url: existingSource.url,
                    epgURL: normalizedEPGURL,
                    isBuiltIn: existingSource.isBuiltIn
                )
                persist()
            }
            let updatedSource = sources[existingIndex]
            select(updatedSource)
            return updatedSource
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = PlaylistSource(
            name: trimmedName.isEmpty ? (parsedURL.host ?? "Custom playlist") : trimmedName,
            url: trimmedURL,
            epgURL: normalizedEPGURL
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

    private func isHTTPURL(_ value: String) -> Bool {
        guard let url = URL(string: value), let scheme = url.scheme?.lowercased() else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(sources) else { return }

        userDefaults.set(data, forKey: Self.sourcesKey)
        userDefaults.set(selectedSourceID?.uuidString, forKey: Self.selectedSourceIDKey)
    }
}
