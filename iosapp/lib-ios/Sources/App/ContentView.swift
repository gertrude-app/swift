import ComposableArchitecture
import SwiftUI

public struct ContentView: View {
  let store: StoreOf<AppReducer>

  public init(store: StoreOf<AppReducer>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      BgGradient().ignoresSafeArea()
      VStack {
        switch self.store.appState {
        case .launching:
          EmptyView()

        case .welcome:
          Welcome {
            self.store.send(.welcomeNextTapped)
          }

        case .authorizing:
          LoadingScreen()

        case .authorized:
          Authorized {
            self.store.send(.installFilterTapped)
          }

        case .authorizationFailed(let reason):
          AuthFailed(reason: reason) {
            self.store.send(.authorizationFailedTryAgainTapped)
          }

        case .prereqs:
          PreReqs {
            self.store.send(.startAuthorizationTapped)
          }

        case .installFailed(let error):
          InstallFail(error: error) {
            self.store.send(.installFailedTryAgainTapped)
          }

        case .postInstall:
          PostInstall {
            self.store.send(.postInstallOkTapped)
          }

        case .running:
          Running()
        }
      }
    }
  }
}

public extension View {
  var deviceType: String {
    Device.current.type
  }
}

// previews

#Preview("Welcome") {
  app(state: .welcome)
}

#Preview("Authorized") {
  app(state: .authorized)
}

#Preview("Authorization failed") {
  app(state: .authorizationFailed(.invalidAccountType))
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