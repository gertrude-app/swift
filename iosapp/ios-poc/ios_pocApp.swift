import App
import SwiftUI
import ComposableArchitecture

@main
struct ios_pocApp: App {
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
