import AVKit
import SwiftUI

/// Pont minimal entre SwiftUI et le contrôleur vidéo natif d'Apple.
struct PlayerView: UIViewControllerRepresentable {
    @EnvironmentObject private var playerManager: PlayerManager
    let channel: Channel

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = true
        controller.player = playerManager.player
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        controller.player = playerManager.player
    }
}
