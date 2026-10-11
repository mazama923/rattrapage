import SwiftUI

struct ChannelListView: View {
    @EnvironmentObject private var playerManager: PlayerManager
    @EnvironmentObject private var playlistStore: PlaylistStore

    @State private var channels: [Channel] = []
    @State private var isSettingsPresented = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedChannel: Channel?

    var body: some View {
        NavigationStack {
            Group {
                if channels.isEmpty {
                    ContentUnavailableView(
                        "No channels loaded",
                        systemImage: "tv",
                        description: Text("Open settings to choose an M3U playlist.")
                    )
                } else {
                    List(channels) { channel in
                        Button {
                            playerManager.play(channel)
                            selectedChannel = channel
                        } label: {
                            ChannelRow(channel: channel)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Rattrapage")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        errorMessage = nil
                        isSettingsPresented = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(
                playlistStore: playlistStore,
                isLoading: isLoading,
                errorMessage: errorMessage,
                onLoad: loadPlaylist
            )
        }
        .fullScreenCover(item: $selectedChannel, onDismiss: playerManager.stop) { channel in
            PlayerView(channel: channel)
                .ignoresSafeArea()
        }
    }

    private func loadPlaylist(_ source: PlaylistSource) {
        guard !isLoading else { return }

        playlistStore.select(source)
        isLoading = true
        errorMessage = nil

        Task {
            do {
                channels = try await PlaylistLoader().load(from: source.url)
                isSettingsPresented = false
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

private struct ChannelRow: View {
    let channel: Channel

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "play.tv")
                .font(.title2)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 6) {
                Text(channel.name)
                    .font(.title3)

                if let group = channel.group, !group.isEmpty {
                    Text(group)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 10)
    }
}
