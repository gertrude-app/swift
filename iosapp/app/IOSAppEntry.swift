import ComposableArchitecture
import SwiftUI

@main
struct IOSAppEntry: App {
  let store: StoreOf<AppReducer>

  init() {
    self.store = Store(initialState: .init()) {
      AppReducer()
    }
  }

  var body: some Scene {
    WindowGroup {
      ContentView(store: self.store)
        .onAppear {
          self.store.send(.appLaunched)
        }
    }
  }
}
