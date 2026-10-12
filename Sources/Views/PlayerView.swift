import AVKit
import SwiftUI

struct PlayerView: View {
    @EnvironmentObject private var playerManager: PlayerManager
    @State private var arePlaybackControlsVisible = true
    let channel: Channel

    var body: some View {
        ZStack {
            PlayerControllerView(player: playerManager.player) { isVisible in
                withAnimation(.easeInOut(duration: 0.2)) {
                    arePlaybackControlsVisible = isVisible
                }
            }

            if let playbackErrorMessage = playerManager.playbackErrorMessage {
                VStack {
                    Spacer()
                    Text("Playback failed: \(playbackErrorMessage)")
                        .font(.footnote)
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(48)
                .allowsHitTesting(false)
            }

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
            .opacity(arePlaybackControlsVisible ? 1 : 0)
            .allowsHitTesting(arePlaybackControlsVisible)
            .accessibilityHidden(!arePlaybackControlsVisible)
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
    let onControlsVisibilityChange: (Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onControlsVisibilityChange: onControlsVisibilityChange)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = true
        controller.delegate = context.coordinator
        controller.player = player
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        context.coordinator.onControlsVisibilityChange = onControlsVisibilityChange
        controller.delegate = context.coordinator
        controller.player = player
    }

    final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        var onControlsVisibilityChange: (Bool) -> Void

        init(onControlsVisibilityChange: @escaping (Bool) -> Void) {
            self.onControlsVisibilityChange = onControlsVisibilityChange
        }

        func playerViewController(
            _ playerViewController: AVPlayerViewController,
            willTransitionToVisibilityOfTransportBar visible: Bool,
            with animationCoordinator: AVPlayerViewControllerAnimationCoordinator
        ) {
            animationCoordinator.addCoordinatedAnimations { [weak self] in
                self?.onControlsVisibilityChange(visible)
            } completion: { _ in }
        }
    }
}
