# Rattrapage Code Map

## Entry point and shared state

```text
RattrapageApp
├── PlayerManager      Shared AVPlayer lifecycle
└── PlaylistStore      Saved playlist sources and selected source
    └── ChannelListView
        ├── SettingsView
        └── PlayerView
```

`RattrapageApp` owns shared objects with `@StateObject` and injects them with `@EnvironmentObject`. This gives every screen the same player and playlist state for the life of the app.

## Runtime flows

### Load a playlist

```text
SettingsView
→ PlaylistStore.add/select
→ ChannelListView.loadPlaylist
→ PlaylistLoader.load
→ M3UParser.parse
→ [Channel]
→ ChannelListView
```

`PlaylistLoader` downloads a remote HTTP(S) playlist with `URLSession`, validates the HTTP status, decodes its text, then delegates parsing to `M3UParser`.

### Play a channel

```text
ChannelListView
→ PlayerManager.play(channel)
→ AVPlayer
→ PlayerView
├── PlayerManager observes seekable DVR ranges
├── SwiftUI timeshift controls (when a DVR range exists)
└── AVPlayerViewController native controls
```

`PlayerManager` owns one `AVPlayer`, tracks whether it is playing, and refreshes the current DVR window from the item's seekable time ranges. Seeking is clamped to that window, and “LIVE” seeks just behind its moving edge. `PlayerView` layers SwiftUI status and timeshift buttons over an `AVPlayerViewController` adapted with `UIViewControllerRepresentable`; the native tvOS controls remain enabled.

### Persist playlist sources

```text
SettingsView
→ PlaylistStore
→ JSONEncoder
→ UserDefaults
```

`PlaylistStore` persists sources as JSON `Data` because `UserDefaults` cannot store custom Swift structs directly. Built-in sources are merged at launch so future app versions can add sources without deleting user-created entries.

## File responsibilities

| Path | Purpose | Change it when… |
| --- | --- | --- |
| `project.yml` | XcodeGen source of truth, deployment target, ATS | Changing target, resources, capabilities, or test targets. |
| `.mise.toml` | Reproducible local commands | Changing validation commands or simulator defaults. |
| `Sources/App/RattrapageApp.swift` | App entry and shared-object ownership | Adding app-wide state. |
| `Sources/Models/Channel.swift` | Parsed channel value | Playlist channel data changes. |
| `Sources/Models/PlaylistSource.swift` | Saved playlist-source value | Playlist-source data changes. |
| `Sources/Services/M3UParser.swift` | M3U text parsing | Supporting metadata or parsing behavior changes. |
| `Sources/Services/PlaylistLoader.swift` | Playlist download and decoding | Network loading behavior changes. |
| `Sources/Services/PlaylistStore.swift` | Source persistence and built-in sources | Adding defaults or persistence migrations. |
| `Sources/Services/PlayerManager.swift` | AVPlayer lifecycle and DVR-window seeking | Playback, pause, or timeshift behavior changes. |
| `Sources/Views/ChannelListView.swift` | Channel screen and navigation state | Channel list or loading UX changes. |
| `Sources/Views/SettingsView.swift` | Source selection and editing UI | Playlist-source UX changes. |
| `Sources/Views/PlayerView.swift` | Native player bridge and timeshift controls | Player-controller presentation changes. |
| `Tests/M3UParserTests.swift` | Parser regression coverage | Parser behavior changes. |
| `Tests/PlaylistStoreTests.swift` | Persistence regression coverage | Store behavior changes. |
| `Tests/PlayerManagerTests.swift` | Timeshift seeking regression coverage | Seek-window behavior changes. |

## Non-negotiable generated files

- `Rattrapage.xcodeproj/` is generated from `project.yml`.
- `Sources/App/Info.plist` is generated from `project.yml`.
- Both are ignored by Git and must not be edited manually.

Run `mise run generate` after changing `project.yml` or adding/removing source or test files.
