protocol Plugin: AnyObject {
  func onTerminate()
  func respond(to: AppEvent)
}

protocol StorePlugin: Plugin {
  var store: AppStore { get }
}

extension Plugin {
  func onTerminate() {}
  func respond(to: AppEvent) {}
}

extension StorePlugin {
  func ifFilterConnected(_ work: () -> Void) {
    store.ifFilterConnected(work)
  }
}
