import SwiftUI

struct ChannelListView: View {
    @EnvironmentObject private var playerManager: PlayerManager
    @EnvironmentObject private var playlistStore: PlaylistStore
    @EnvironmentObject private var favoritesStore: FavoritesStore

    @State private var channels: [Channel] = []
    @State private var programsByChannel: [String: [TVProgram]] = [:]
    @State private var selectedGroup: String?
    @State private var searchText = ""
    @State private var showsFavoritesOnly = false
    @State private var guideErrorMessage: String?
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
                } else if displayedChannels.isEmpty {
                    ContentUnavailableView(
                        "No matching channels",
                        systemImage: "line.3.horizontal.decrease",
                        description: Text("Try another search or change the category or favorites filter.")
                    )
                } else {
                    List {
                        if let guideErrorMessage {
                            Text("TV guide unavailable: \(guideErrorMessage)")
                                .foregroundStyle(.secondary)
                        }

                        ForEach(displayedChannels) { channel in
                            HStack(spacing: 16) {
                                Button {
                                    playerManager.play(channel)
                                    selectedChannel = channel
                                } label: {
                                    ChannelRow(
                                        channel: channel,
                                        programs: programsByChannel[channel.guideID ?? ""] ?? []
                                    )
                                }
                                .buttonStyle(.plain)

                                Spacer(minLength: 12)

                                Button {
                                    favoritesStore.toggle(channel)
                                } label: {
                                    Image(systemName: favoritesStore.isFavorite(channel) ? "star.fill" : "star")
                                        .font(.title2)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(
                                    favoritesStore.isFavorite(channel) ? "Remove from favorites" : "Add to favorites"
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rattrapage")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            selectedGroup = nil
                        } label: {
                            if selectedGroup == nil {
                                Label("All categories", systemImage: "checkmark")
                            } else {
                                Text("All categories")
                            }
                        }

                        ForEach(groups, id: \.self) { group in
                            Button {
                                selectedGroup = group
                            } label: {
                                if selectedGroup == group {
                                    Label(group, systemImage: "checkmark")
                                } else {
                                    Text(group)
                                }
                            }
                        }

                        if !groups.isEmpty {
                            Divider()
                        }

                        Toggle("Favorites only", isOn: $showsFavoritesOnly)
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease")
                    }
                }
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
        .searchable(text: $searchText, prompt: "Search channels")
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

    private var groups: [String] {
        Array(Set(channels.compactMap { $0.group })).sorted()
    }

    private var displayedChannels: [Channel] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return channels.filter { channel in
            let matchesSearch = query.isEmpty || channel.name.localizedCaseInsensitiveContains(query)
            let matchesGroup = selectedGroup == nil || channel.group == selectedGroup
            let matchesFavorites = !showsFavoritesOnly || favoritesStore.isFavorite(channel)
            return matchesSearch && matchesGroup && matchesFavorites
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
                favoritesStore.load(for: source)
                programsByChannel = [:]
                guideErrorMessage = nil
                selectedGroup = nil
                isSettingsPresented = false

                if let epgURL = source.epgURL {
                    do {
                        programsByChannel = try await EPGLoader().load(from: epgURL)
                    } catch {
                        guideErrorMessage = error.localizedDescription
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

private struct ChannelRow: View {
    let channel: Channel
    let programs: [TVProgram]

    var body: some View {
        HStack(spacing: 20) {
            AsyncImage(url: channel.logoURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "play.tv")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 64)
            .accessibilityLabel(channel.name)

            VStack(alignment: .leading, spacing: 6) {
                Text(channel.name)
                    .font(.title3)

                if let group = channel.group {
                    Text(group)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let currentProgram = programs.first(where: { $0.start <= Date() && $0.end > Date() }) {
                    Label("Now: \(currentProgram.title)", systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption)
                    if let nextProgram = programs.first(where: { $0.start >= currentProgram.end }) {
                        Text("Next: \(nextProgram.title)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if let nextProgram = programs.first {
                    Text("Next: \(nextProgram.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
    }
}
