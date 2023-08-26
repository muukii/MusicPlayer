//
//  ContentView.swift
//  MusicPlayer
//
//  Created by Muukii on 2023/08/26.
//

import SwiftUI
import MusicKit

struct ContentView: View {

  @ObservedObject var viewModel = ViewModel()

  var body: some View {
    VStack {
      Text("\(viewModel.localizedAuthorizationStatus)")
      Text("Hello, world!")
      Button("Request authorization") {
        viewModel.request()
      }
      Button("Fetch") {
        viewModel.fetch()
      }
    }
    .padding()
  }
}

@MainActor
final class ViewModel: ObservableObject {

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

  @Published private(set) var authorizationStatus: MusicAuthorization.Status = .notDetermined

  init() {
    self.authorizationStatus = MusicAuthorization.currentStatus
  }

  func request() {
    Task { @MainActor in
      self.authorizationStatus = await MusicAuthorization.request()
    }
  }

  func fetch() {

    Task {
      do {
        let re = try await MusicLibraryRequest<Playlist>().response()

        re.items.map { item in
          item
        }

        print(re)
      } catch {
        print(error)
      }
    }

  }

}

#Preview {
  ContentView()
}
