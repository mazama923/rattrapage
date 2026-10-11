import SwiftUI

@main
struct RattrapageApp: App {
    // StateObject garantit une seule instance du lecteur pendant la vie de l'application.
    @StateObject private var playerManager = PlayerManager()
    // Le store est partagé pour que les réglages et la liste utilisent les mêmes sources.
    @StateObject private var playlistStore = PlaylistStore()

    var body: some Scene {
        WindowGroup {
            ChannelListView()
                .environmentObject(playerManager)
                .environmentObject(playlistStore)
        }
    }
}
