import ComposableArchitecture
import SwiftUI

public struct ContentView: View {
  let store: StoreOf<AppReducer>

  public init(store: StoreOf<AppReducer>) {
    self.store = store
  }

  public var body: some View {
    NewAppView(store: Store(
      initialState: NewApp.State()
//      initialState: .happyPath_13
    ) {
      NewApp()
    })
  }
}

public extension View {
  var deviceType: String {
    @Dependency(\.device) var device
    return device.type.rawValue
  }
}

#Preview {
  app(state: .welcome)
}

private func app(state: AppReducer.AppState) -> some View {
  ContentView(
    store: Store(initialState: .init(appState: state)) {
      AppReducer()
    }
  )
}
