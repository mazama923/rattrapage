import Foundation

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var channelIDs: Set<String> = []

    private let userDefaults: UserDefaults
    private var currentSourceID: UUID?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load(for source: PlaylistSource?) {
        currentSourceID = source?.id
        guard let source else {
            channelIDs = []
            return
        }

        let savedIDs = userDefaults.stringArray(forKey: storageKey(for: source.id)) ?? []
        channelIDs = Set(savedIDs)
    }

    func isFavorite(_ channel: Channel) -> Bool {
        channelIDs.contains(channel.id)
    }

    func toggle(_ channel: Channel) {
        guard let currentSourceID else { return }

        if channelIDs.contains(channel.id) {
            channelIDs.remove(channel.id)
        } else {
            channelIDs.insert(channel.id)
        }

        userDefaults.set(Array(channelIDs).sorted(), forKey: storageKey(for: currentSourceID))
    }

    private func storageKey(for sourceID: UUID) -> String {
        "favoriteChannelIDs.\(sourceID.uuidString)"
    }
}
