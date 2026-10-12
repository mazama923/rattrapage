import AVKit
import SwiftUI

struct PlayerView: View {
    @EnvironmentObject private var playerManager: PlayerManager
    let channel: Channel

    var body: some View {
        ZStack {
            PlayerControllerView(player: playerManager.player)

            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(channel.name)
                            .font(.title2.bold())

                        Label(
                            playerManager.isTimeshiftAvailable
                                ? "DVR window available"
                                : "Timeshift unavailable for this stream",
                            systemImage: playerManager.isTimeshiftAvailable
                                ? "clock.arrow.circlepath"
                                : "clock"
                        )
                        .font(.subheadline)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    Spacer()
                }

                Spacer()

                if playerManager.isTimeshiftAvailable {
                    timeshiftControls
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 64)
            .padding(.vertical, 48)
        }
    }

    private var timeshiftControls: some View {
        HStack(spacing: 24) {
            Button {
                playerManager.seek(by: -30)
            } label: {
                Label("Back 30 seconds", systemImage: "gobackward.30")
            }
            .accessibilityLabel("Rewind 30 seconds")

            Button {
                playerManager.togglePlayback()
            } label: {
                Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
            }
            .accessibilityLabel(playerManager.isPlaying ? "Pause" : "Play")

            Button {
                playerManager.seek(by: 30)
            } label: {
                Label("Forward 30 seconds", systemImage: "goforward.30")
            }
            .accessibilityLabel("Forward 30 seconds")

            Button {
                playerManager.goToLive()
            } label: {
                Label("LIVE", systemImage: "dot.radiowaves.left.and.right")
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(20)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

/// Pont entre SwiftUI et le contrôleur vidéo natif, pour garder les contrôles tvOS.
private struct PlayerControllerView: UIViewControllerRepresentable {
    let player: AVPlayer?

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = true
        controller.player = player
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        controller.player = player
    }
}
