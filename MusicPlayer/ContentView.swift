//
//  ContentView.swift
//  MusicPlayer
//
//  Created by Muukii on 2023/08/26.
//

import SwiftUI
import MusicKit

@MainActor
struct ContentView: View {

  let viewModel = ViewModel()

  var body: some View {

    if viewModel.authorizationStatus == .authorized {
      AuthorizedView(viewModel: viewModel)
    } else {
      VStack {
        Text("\(viewModel.localizedAuthorizationStatus)")
        Text("Hello, world!")
        Button("Request authorization") {
          viewModel.request()
        }
      }
      .padding()

    }

  }
}

struct AuthorizedView: View {
  
  let viewModel: ViewModel

  var body: some View {
    NavigationStack {
      if let playlist = viewModel.playlist {
        List {
          ForEach.init(playlist) { item in
            NavigationLink {
              PlaylistDetail(playlist: item)
            } label: {
              Self.makePlaylistView(item)
            }
          }
        }
      } else {
        ProgressView()
          .onAppear {
            Task {
              do {
                try await viewModel.fetchPlaylist()
              } catch {
                print(error)
              }
            }
          }

      }
    }

  }

  private static func makePlaylistView(_ playlist: MusicItemCollection<Playlist>.Element) -> some View {
    VStack {
      Text(playlist.name)
      Text(playlist.curatorName ?? "")
    }
  }

  struct PlaylistDetail: View {

    let playlist: MusicItemCollection<Playlist>.Element

    @State private var entries: MusicItemCollection<Playlist.Entry>?

    var body: some View {

      if let entries = entries {
        List {
          ForEach(entries) { track in
            NavigationLink {
              PlayerView(entry: track)
            } label: {
              Text(track.title)
            }

          }
        }
      } else {
        ProgressView()
          .task {
            do {
              let response = try await playlist.with([.entries, .tracks])
              self.entries = response.entries

            } catch {

            }
          }
      }
    }
  

  }

}

struct PlayerView: View {

  let entry: MusicItemCollection<Playlist.Entry>.Element
  let player: ApplicationMusicPlayer = .shared

  var body: some View {
    VStack {
      Text(entry.title)
      Text(entry.artistName ?? "")
      HStack {
        Button("1x") {
          player.state.playbackRate = 1
        }
        Button("0.5x") {
          player.state.playbackRate = 0.5
        }
      }
      TimelineView(.animation(minimumInterval: 0.5, paused: false)) { _ in
        Text("\(player.playbackTime)")
      }
    }
    .onAppear {
      player.queue = [entry]
      Task {
        try await player.play()
      }
    }
    .onDisappear(perform: {
      Task {
        player.stop()
      }
    })
  }

}

@MainActor
@Observable
final class ViewModel {

  var localizedAuthorizationStatus: String {
    switch authorizationStatus {
    case .notDetermined:
      return "notDetermined"
    case .denied:
      return "denied"
    case .restricted:
      return "restricted"
    case .authorized:
      return "authorized"
    @unknown default:
      return "unknown"
    }
  }

  private(set) var authorizationStatus: MusicAuthorization.Status = .notDetermined

  private(set) var playlist: MusicItemCollection<Playlist>?

  init() {
    self.authorizationStatus = MusicAuthorization.currentStatus
  }

  func request() {
    Task { @MainActor in
      self.authorizationStatus = await MusicAuthorization.request()
    }
  }

  func fetchPlaylist() async throws {

    let request = MusicLibraryRequest<Playlist>.init()

    let response = try await request.response()

    self.playlist = response.items

  }

}

#Preview {
  ContentView()
}
