# Rattrapage Code Map

## Entry point and shared state

```text
RattrapageApp
├── PlayerManager      Shared AVPlayer lifecycle
└── PlaylistStore      Saved playlist sources and selected source
    └── ChannelListView
        ├── SettingsView
        └── PlayerView

RattrapageApp also owns FavoritesStore, which saves favorite channel IDs separately for each playlist.
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
→ OfficialChannelAppService
├── known restricted channel → PlayerView official-app notice (no M3U playback attempt)
└── other channel → PlayerManager.play(channel) → AVPlayerViewController
    ├── PlayerManager observes seekable DVR ranges
    └── SwiftUI timeshift controls (when a DVR range exists)
```

`OfficialChannelAppService` recognizes TF1/TMC/TFX as requiring TF1+ and M6/W9/6ter as requiring M6+. Those channels show the official app notice and do not start their M3U streams. `PlayerManager` owns one `AVPlayer`, tracks whether it is playing, and refreshes the current DVR window from the item's seekable time ranges. Seeking is clamped to that window, and “LIVE” seeks just behind its moving edge. For supported streams, `PlayerView` layers SwiftUI status and timeshift buttons over an `AVPlayerViewController` adapted with `UIViewControllerRepresentable`; the native tvOS controls remain enabled.

### Browse metadata, favorites, and guide

```text
M3UParser → Channel (logo, group, tvg-id, optional User-Agent)
ChannelListView → searchable channel list + AsyncImage + category/favorites filters
SettingsView → PlaylistSource.epgURL
EPGLoader → XMLTVParser → current and next TVProgram per tvg-id
Channel.userAgent → AVURLAsset → AVPlayer request headers
FavoritesStore → UserDefaults (separate favorites per playlist)
```

The EPG URL is optional and supplied alongside a playlist. XMLTV programme IDs are matched to the playlist's `tvg-id`; entries without a matching ID have no guide text. The parser keeps only the current and next programme per channel to avoid retaining the full guide in memory. EPG download errors do not prevent playlist playback.

### Persist playlist sources

```text
SettingsView
→ PlaylistStore
→ JSONEncoder
→ UserDefaults
```

`PlaylistStore` persists sources as JSON `Data` because `UserDefaults` cannot store custom Swift structs directly. Built-in sources are merged at launch so future app versions can add sources without deleting user-created entries. The optional `epgURL` field remains compatible with saved sources that predate guide support.

## File responsibilities

| Path | Purpose | Change it when… |
| --- | --- | --- |
| `project.yml` | XcodeGen source of truth, deployment target, ATS | Changing target, resources, capabilities, or test targets. |
| `.mise.toml` | Reproducible local commands | Changing validation commands or simulator defaults. |
| `Sources/App/RattrapageApp.swift` | App entry and shared-object ownership | Adding app-wide state. |
| `Sources/Models/Channel.swift` | Immutable channel data, including logo, category, guide ID, and optional User-Agent | Playlist channel data changes. |
| `Sources/Models/TVProgram.swift` | One current or upcoming guide entry | Guide presentation data changes. |
| `Sources/Models/PlaylistSource.swift` | Saved playlist-source value | Playlist-source data changes. |
| `Sources/Services/M3UParser.swift` | M3U metadata and VLC User-Agent directive parsing | Supporting metadata or parsing behavior changes. |
| `Sources/Services/PlaylistLoader.swift` | Playlist download and decoding | Network loading behavior changes. |
| `Sources/Services/PlaylistStore.swift` | Source persistence and built-in sources, including optional EPG URL | Adding defaults or persistence migrations. |
| `Sources/Services/FavoritesStore.swift` | Per-playlist favorite persistence | Favorite behavior changes. |
| `Sources/Services/EPGLoader.swift` | XMLTV HTTP(S) download and response validation | Guide network loading changes. |
| `Sources/Services/XMLTVParser.swift` | XMLTV parsing and current/next programme selection | Guide format support changes. |
| `Sources/Services/PlayerManager.swift` | AVPlayer lifecycle, playlist-declared User-Agent, playback errors, and DVR-window seeking | Playback, pause, or timeshift behavior changes. |
| `Sources/Services/OfficialChannelAppService.swift` | Maps TF1-family and M6-family channel names to their official tvOS apps | Official-app channel routing changes. |
| `Sources/Views/ChannelListView.swift` | Searchable channel screen, filters, and navigation state | Channel list or loading UX changes. |
| `Sources/Views/SettingsView.swift` | Source selection and editing UI | Playlist-source UX changes. |
| `Sources/Views/PlayerView.swift` | Native player bridge, timeshift controls, playback errors, and official-app notice | Player-controller presentation changes. |
| `Tests/M3UParserTests.swift` | Playlist metadata parsing regression coverage | Parser behavior changes. |
| `Tests/XMLTVParserTests.swift` | XMLTV parsing regression coverage | Guide parsing changes. |
| `Tests/FavoritesStoreTests.swift` | Per-playlist favorites persistence coverage | Favorite persistence changes. |
| `Tests/PlaylistStoreTests.swift` | Persistence regression coverage | Store behavior changes. |
| `Tests/PlayerManagerTests.swift` | Timeshift seeking regression coverage | Seek-window behavior changes. |
| `Tests/OfficialChannelAppServiceTests.swift` | Official-app mapping regression coverage | Channel-to-app mapping changes. |

## Non-negotiable generated files

- `Rattrapage.xcodeproj/` is generated from `project.yml`.
- `Sources/App/Info.plist` is generated from `project.yml`.
- Both are ignored by Git and must not be edited manually.

Run `mise run generate` after changing `project.yml` or adding/removing source or test files.
