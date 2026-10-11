import AVFoundation

@MainActor
final class PlayerManager: ObservableObject {
    @Published private(set) var player: AVPlayer?

    func play(_ channel: Channel) {
        // Une nouvelle instance évite de conserver l'état du flux précédent.
        player = AVPlayer(url: channel.streamURL)
        player?.play()
    }

    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }
}
