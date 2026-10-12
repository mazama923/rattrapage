# Rattrapage

A small tvOS 17+ IPTV player, built with Swift and SwiftUI to learn Apple frameworks without third-party dependencies.

> Use only playlists and streams you are authorized to access.

## Current features

- Save and select multiple HTTP(S) M3U/M3U8 playlist URLs.
- Restore saved playlists and the selected source after relaunching the app.
- Download and parse `#EXTINF` entries with `URLSession` and `async/await`, including playlist-declared `http-user-agent` settings for stream requests.
- Search channels by name using the native tvOS search field; results combine with category and favorites filters.
- Browse channels using the tvOS focus engine, with playlist logos and category filters when the M3U provides `tvg-logo` and `group-title`.
- Mark channels as favorites; favorites are saved separately for each playlist and can be filtered.
- Optionally enter an XMLTV guide URL for a playlist; current and next programmes are matched through the channel's `tvg-id`.
- Play supported playlist channels fullscreen with `AVPlayerViewController`, with playback failures shown on screen.
- Identify TF1, M6, W9, 6ter, TMC, and TFX entries and direct viewers to the corresponding official tvOS app instead of attempting their unavailable M3U streams.
- Pause, rewind or fast-forward by 30 seconds, and return to live when the stream exposes a DVR window.

The player checks the HLS seekable time ranges while playback runs. Timeshift buttons appear only when a seekable window is available; the native tvOS playback controls remain available for every stream.

The optional XMLTV guide is configured in the playlist form. To attach one to an already-saved source, enter the same playlist URL again with the guide URL; an empty guide field leaves an existing guide setting unchanged. Guide metadata is only shown when its XMLTV channel ID matches that playlist entry's `tvg-id`. A guide download or parsing error does not prevent channel playback.

## Included playlist source

The settings screen provides the French playlist from the remote [iptv-org catalogue](https://github.com/iptv-org/iptv). Rattrapage does not bundle or host this playlist.

It is a third-party catalogue: stream availability, supported formats, and distribution rights can change independently of this app. Some entries may not be playable by `AVPlayer` (for example, non-HLS streams). Use only streams you are authorized to access.

## Architecture

| Path | Responsibility |
| --- | --- |
| `Sources/App/RattrapageApp.swift` | SwiftUI application entry point and ownership of shared objects. |
| `Sources/Models/Channel.swift` | Immutable playlist entry with logo, group, and guide matching metadata. |
| `Sources/Models/TVProgram.swift` | Small immutable model for one EPG programme. |
| `Sources/Models/PlaylistSource.swift` | Codable saved playlist source with an optional XMLTV URL. |
| `Sources/Services/M3UParser.swift` | Pure M3U text parsing; easy to test independently from networking. |
| `Sources/Services/PlaylistLoader.swift` | Remote playlist loading and HTTP validation using `URLSession`. |
| `Sources/Services/PlaylistStore.swift` | Playlist and optional EPG URL persistence in `UserDefaults` as JSON. |
| `Sources/Services/FavoritesStore.swift` | Favorites saved independently for each playlist. |
| `Sources/Services/EPGLoader.swift` | XMLTV guide download and HTTP response validation. |
| `Sources/Services/XMLTVParser.swift` | XMLTV parser that retains the current and next programme per channel. |
| `Sources/Services/PlayerManager.swift` | Shared `AVPlayer` lifecycle, playback state, and DVR-window seeking. |
| `Sources/Services/OfficialChannelAppService.swift` | Maps supported French channels to the official tvOS app required for playback. |
| `Sources/Views/ChannelListView.swift` | Focusable channel list, logos, filters, favorites actions, guide text, and screen state. |
| `Sources/Views/SettingsView.swift` | Saved playlist selection, creation, and deletion. |
| `Sources/Views/PlayerView.swift` | Native playback controls, timeshift controls, playback status, and official-app notice. |
| `Tests/` | Unit tests for M3U/XMLTV parsing, playlist/favorite persistence, timeshift seek bounds, and official-app channel mapping. |

## Why this SwiftUI architecture

- `RattrapageApp` creates shared stores with `@StateObject` once, then injects them using `@EnvironmentObject`. Screens can share player, playlist, and favorite state without passing each value through every view.
- `ChannelListView` keeps temporary screen choices such as the search query, selected category, and favorite-only filter in `@State`. The native `.searchable` modifier provides tvOS search interaction; parsing and persistence remain in services.
- Small value models (`Channel`, `PlaylistSource`, and `TVProgram`) carry data between services and views. This keeps M3U/XMLTV parsing testable without launching SwiftUI.
- `AsyncImage` and native SwiftUI controls avoid extra dependencies. The logo has a system-image fallback when no URL exists or loading fails.

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
