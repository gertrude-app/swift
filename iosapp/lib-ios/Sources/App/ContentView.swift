import ComposableArchitecture
import SwiftUI

public struct ContentView: View {
  let store: StoreOf<AppReducer>

  public init(store: StoreOf<AppReducer>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      BgGradient()
      VStack {
        switch self.store.appState {
        case .launching:
          EmptyView()

        case .welcome:
          Welcome(store: self.store)

        case .authorizing:
          LoadingScreen()

        case .authorized:
          VStack(spacing: 20) {
            Text("Authorization granted! One more step: install the content filter.")
            Button("Install Filter") {
              self.store.send(.installFilterTapped)
            }
          }

        case .authorizationFailed(let reason):
          AuthFailed(reason: reason) {
            self.store.send(.authorizationFailedTryAgainTapped)
          }

        case .prereqs:
          PreReqs(store: self.store)

        case .installFailed(let error):
          VStack(spacing: 20) {
            Text("Filter setup failed with an error:")
            Group {
              switch error {
              case .configurationInvalid:
                Text("Configuration is invalid.")
              case .configurationDisabled:
                Text("Configuration is disabled.")
              case .configurationStale:
                Text("Configuration is stale.")
              case .configurationCannotBeRemoved:
                Text("Configuration can not be removed.")
              case .configurationPermissionDenied:
                Text("Permission denied.")
              case .configurationInternalError:
                Text("Internal error.")
              case .unexpected(let underlying):
                Text("Unexpected error: \(underlying)")
              }
            }.font(.footnote)
            Button("Try again") {
              self.store.send(.installFailedTryAgainTapped)
            }
          }

        case .postInstall:
          VStack(spacing: 20) {
            Text("Filter installed successfully!")
            Text("Good to know:")
            VStack(alignment: .leading, spacing: 12) {
              Text(
                "Previously loaded GIFs will still be visible, so if you want to test that the filter is working, try searching for a new GIF."
              )
              Text("You can quit this app now—it will keep blocking even when not running.")
              Text(
                "Use Screen Time restrictions to make sure this \(self.deviceType) user can’t delete apps. Deleting the app removes the content filter."
              )
              Text("Questions? Drop us a line at https://gertrude.app/contact.")

            }.font(.footnote)
            Button("OK") {
              self.store.send(.postInstallOkTapped)
            }
          }

        case .running:
          VStack(spacing: 20) {
            Text("Gertrude is blocking GIFs and image searches.")
            VStack(alignment: .leading, spacing: 12) {
              Text("You can quit this app now—it will keep blocking even when not running.")
              Text("Questions? Drop us a line at https://gertrude.app/contact.")

            }.font(.footnote)
          }
        }
      }
    }.ignoresSafeArea()
  }
}

extension View {
  var deviceType: String {
    #if os(iOS)
      UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
    #else
      "iPhone"
    #endif
  }
}

// previews

#Preview("Welcome") {
  app(state: .welcome)
}

#Preview("Prereqs") {
  app(state: .prereqs)
}

#Preview("Install Fail") {
  app(state: .installFailed(.configurationPermissionDenied))
}

#Preview("Post-install") {
  app(state: .postInstall)
}

#Preview("Running") {
  app(state: .running)
}

private func app(state: AppReducer.AppState) -> some View {
  ContentView(
    store: Store(initialState: .init(appState: state)) {
      AppReducer()
    }
  )
}
