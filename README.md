# Rattrapage

A small tvOS 17+ IPTV player, built with Swift and SwiftUI to learn Apple frameworks without third-party dependencies.

> Use only playlists and streams you are authorized to access.

## Current features

- Save and select multiple HTTP(S) M3U/M3U8 playlist URLs.
- Restore saved playlists and the selected source after relaunching the app.
- Download and parse `#EXTINF` entries with `URLSession` and `async/await`.
- Browse channels using the tvOS focus engine.
- Play a channel fullscreen with `AVPlayerViewController`.
- Pause, rewind or fast-forward by 30 seconds, and return to live when the stream exposes a DVR window.

The player checks the HLS seekable time ranges while playback runs. Timeshift buttons appear only when a seekable window is available; the native tvOS playback controls remain available for every stream.

## Included playlist source

The settings screen provides the French playlist from the remote [iptv-org catalogue](https://github.com/iptv-org/iptv). Rattrapage does not bundle or host this playlist.

It is a third-party catalogue: stream availability, supported formats, and distribution rights can change independently of this app. Some entries may not be playable by `AVPlayer` (for example, non-HLS streams). Use only streams you are authorized to access.

## Architecture

| Path | Responsibility |
| --- | --- |
| `Sources/App/RattrapageApp.swift` | SwiftUI application entry point and ownership of shared objects. |
| `Sources/Models/Channel.swift` | Small immutable model for one playlist entry. |
| `Sources/Models/PlaylistSource.swift` | Codable description of one saved playlist source. |
| `Sources/Services/M3UParser.swift` | Pure M3U text parsing; easy to test independently from networking. |
| `Sources/Services/PlaylistLoader.swift` | Remote playlist loading and HTTP validation using `URLSession`. |
| `Sources/Services/PlaylistStore.swift` | Playlist persistence in `UserDefaults` as JSON and selected-source state. |
| `Sources/Services/PlayerManager.swift` | Shared `AVPlayer` lifecycle, playback state, and DVR-window seeking. |
| `Sources/Views/ChannelListView.swift` | Focusable channel list and screen-state coordination. |
| `Sources/Views/SettingsView.swift` | Saved playlist selection, creation, and deletion. |
| `Sources/Views/PlayerView.swift` | SwiftUI status and timeshift controls over the native player controller. |
| `Tests/` | Unit tests for playlist parsing, persistence, and timeshift seek bounds. |

## Development workflow

The repository uses [mise](https://mise.jdx.dev/) as the single entry point for development tasks. You need Xcode, [XcodeGen](https://github.com/yonaskolb/XcodeGen), and `mise` installed locally.

```sh
mise run doctor
mise run generate
mise run test
mise run build
```

Task definitions live in [`.mise.toml`](.mise.toml). `doctor` checks that Xcode, XcodeGen, the tvOS SDK, and the configured Apple TV simulator are available. If your Xcode installation uses another simulator name, update `TEST_DESTINATION` in `.mise.toml`.

## AI-assisted changes

Read [`AGENTS.md`](AGENTS.md) before modifying the project and use [`CODEMAP.md`](CODEMAP.md) to locate the relevant code. Those files define the source-of-truth rules, validation workflow, and application data flow.

## HTTP playlists and ATS

`project.yml` deliberately generates `NSAppTransportSecurity > NSAllowsArbitraryLoads = true`, allowing legacy `http://` playlists and stream URLs. This is broad and should be narrowed to specific domains before distributing the app.

## License

[Apache License 2.0](LICENSE)
