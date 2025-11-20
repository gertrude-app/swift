import ComposableArchitecture
import LibApp
import SwiftUI

@main
struct IOSAppEntry: App {
  let store: StoreOf<IOSReducer>
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var osMajorVersion: Int {
    ProcessInfo.processInfo.operatingSystemVersion.majorVersion
  }

  init() {
    self.store = Store(
      initialState: IOSReducer.State(),
      reducer: { IOSReducer()._printChanges() },
    )
    self.appDelegate.onTerminate = { [weak store = self.store] in
      store?.send(.programmatic(.appWillTerminate))
    }
  }

  var body: some Scene {
    WindowGroup {
      AppView(store: self.store, osMajorVersion: self.osMajorVersion)
        .onAppear {
          self.store.send(.programmatic(.appDidLaunch))
        }
    }
  }
}

private class AppDelegate: NSObject, UIApplicationDelegate {
  var onTerminate: (() -> Void)?
  func applicationWillTerminate(_ application: UIApplication) {
    self.onTerminate?()
  }
}
