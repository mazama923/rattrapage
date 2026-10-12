import SwiftUI

struct SettingsView: View {
    @ObservedObject var playlistStore: PlaylistStore
    let isLoading: Bool
    let errorMessage: String?
    let onLoad: (PlaylistSource) -> Void

    @State private var newPlaylistName = ""
    @State private var newPlaylistURL = ""
    @State private var newEPGURL = ""
    @State private var inputError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Playlists")
                    .font(.largeTitle)

                Text("Choose a saved playlist or add your own M3U/M3U8 URL.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Saved playlists")
                        .font(.title2)

                    ForEach(playlistStore.sources) { source in
                        PlaylistSourceRow(
                            source: source,
                            isSelected: source.id == playlistStore.selectedSourceID,
                            isLoading: isLoading,
                            onLoad: { onLoad(source) },
                            onDelete: { playlistStore.remove(source) }
                        )
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Add a playlist")
                        .font(.title2)

                    TextField("Name (optional)", text: $newPlaylistName)
                    TextField("https://example.com/playlist.m3u", text: $newPlaylistURL)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    TextField("XMLTV guide URL (optional)", text: $newEPGURL)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)

                    if let inputError {
                        Text(inputError)
                            .foregroundStyle(.red)
                    }

                    Button("Save and load", action: addAndLoadPlaylist)
                        .disabled(isLoading || newPlaylistURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Text("The optional guide must be an XMLTV HTTP(S) URL. Channel IDs are matched using tvg-id.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text("Community playlists are maintained by third parties. Their availability, supported stream formats, and distribution rights can change independently of Rattrapage.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .padding(80)
        }
    }

    private func addAndLoadPlaylist() {
        guard let source = playlistStore.add(
            name: newPlaylistName,
            url: newPlaylistURL,
            epgURL: newEPGURL
        ) else {
            inputError = "Enter valid HTTP(S) URLs for the playlist and TV guide."
            return
        }

        inputError = nil
        newPlaylistName = ""
        newPlaylistURL = ""
        newEPGURL = ""
        onLoad(source)
    }
}

private struct PlaylistSourceRow: View {
    let source: PlaylistSource
    let isSelected: Bool
    let isLoading: Bool
    let onLoad: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            Button(action: onLoad) {
                HStack(spacing: 16) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "play.circle")
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.name)
                            .font(.headline)
                        Text(source.url)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            if !source.isBuiltIn {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .disabled(isLoading)
            }
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }
}
