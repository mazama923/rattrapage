import AVFoundation
import Foundation

@MainActor
final class PlayerManager: ObservableObject {
    @Published private(set) var player: AVPlayer?
    @Published private(set) var isPlaying = false
    @Published private(set) var isTimeshiftAvailable = false
    @Published private(set) var playbackErrorMessage: String?

    private var seekableRange: CMTimeRange?
    private var timeObserver: Any?
    private var playbackStatusObservation: NSKeyValueObservation?
    private var playbackItemStatusObservation: NSKeyValueObservation?

    func play(_ channel: Channel) {
        stop()

        // AVURLAsset transmet le User-Agent de la playlist aux requêtes du flux et de ses segments.
        let assetOptions = channel.userAgent.map { [AVURLAssetHTTPUserAgentKey: $0] }
        let asset = AVURLAsset(url: channel.streamURL, options: assetOptions)
        let item = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer

        playbackItemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] observedItem, _ in
            guard observedItem.status == .failed else { return }
            let message = observedItem.error?.localizedDescription ?? "AVPlayer could not load this stream."
            DispatchQueue.main.async { [weak self, weak observedItem] in
                guard
                    let self,
                    let observedItem,
                    self.player?.currentItem === observedItem
                else {
                    return
                }
                self.playbackErrorMessage = message
            }
        }

        playbackStatusObservation = newPlayer.observe(
            \.timeControlStatus,
            options: [.initial, .new]
        ) { [weak self] observedPlayer, _ in
            let isPlaying = observedPlayer.timeControlStatus == .playing
            DispatchQueue.main.async { [weak self] in
                self?.isPlaying = isPlaying
            }
        }

        // Les fenêtres DVR évoluent au fil du direct : on relit les plages régulièrement.
        timeObserver = newPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 600),
            queue: .main
        ) { [weak self, weak newPlayer] _ in
            guard let self, let newPlayer else { return }
            self.updateTimeshiftAvailability(for: newPlayer.currentItem)
        }

        newPlayer.play()
    }

    func togglePlayback() {
        guard let player else { return }

        if isPlaying || player.timeControlStatus == .playing {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func seek(by seconds: TimeInterval) {
        guard let player, let seekableRange,
              let target = Self.clampedSeekTime(
                currentTime: player.currentTime(),
                offset: seconds,
                in: seekableRange
              )
        else {
            return
        }

        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func goToLive() {
        guard let player, let seekableRange,
              let target = Self.liveEdgeTime(in: seekableRange)
        else {
            return
        }

        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { [weak player] finished in
            if finished {
                player?.play()
            }
        }
    }

    func stop() {
        playbackStatusObservation = nil
        playbackItemStatusObservation = nil
        playbackErrorMessage = nil

        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil

        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        seekableRange = nil
        isPlaying = false
        isTimeshiftAvailable = false
    }

    static func clampedSeekTime(
        currentTime: CMTime,
        offset: TimeInterval,
        in range: CMTimeRange
    ) -> CMTime? {
        let start = range.start.seconds
        let duration = range.duration.seconds
        let current = currentTime.seconds
        let end = start + duration

        guard start.isFinite, duration.isFinite, duration > 0,
              current.isFinite, offset.isFinite, end.isFinite
        else {
            return nil
        }

        // On garde une seconde de marge pour ne pas chercher au-delà du direct disponible.
        let latestSeekTime = max(start, end - 1)
        let target = min(max(current + offset, start), latestSeekTime)
        return CMTime(seconds: target, preferredTimescale: 600)
    }

    private static func liveEdgeTime(in range: CMTimeRange) -> CMTime? {
        let start = range.start.seconds
        let duration = range.duration.seconds
        let end = start + duration

        guard start.isFinite, duration.isFinite, duration > 0, end.isFinite else {
            return nil
        }

        return CMTime(seconds: max(start, end - 1), preferredTimescale: 600)
    }

    private func updateTimeshiftAvailability(for item: AVPlayerItem?) {
        guard let item else {
            seekableRange = nil
            isTimeshiftAvailable = false
            return
        }

        let ranges = item.seekableTimeRanges
            .map(\.timeRangeValue)
            .filter { range in
                range.start.seconds.isFinite
                    && range.duration.seconds.isFinite
                    && range.duration.seconds > 0
            }

        seekableRange = ranges.max { lhs, rhs in
            lhs.start.seconds + lhs.duration.seconds < rhs.start.seconds + rhs.duration.seconds
        }
        isTimeshiftAvailable = seekableRange != nil
    }
}
