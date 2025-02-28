import ComposableArchitecture
import LibApp
import SwiftUI

@main
struct IOSAppEntry: App {
  let store: StoreOf<IOSReducer>

  init() {
    self.store = Store(
      initialState: IOSReducer.State(),
      reducer: { IOSReducer() }
    )
  }

  var body: some Scene {
    WindowGroup {
      AppView(store: self.store)
        .onAppear {
          self.store.send(.programmatic(.appDidLaunch))
        }
    }
  }
}
