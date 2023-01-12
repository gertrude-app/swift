import Foundation
import SharedCore

class BackgroundRefreshPlugin: Plugin {
  let store: AppStore
  let timer: Timer

  init(store: AppStore) {
    self.store = store

    timer = Timer.repeating(every: .minutes(30)) { _ in
      if store.state.userToken != nil {
        log(.plugin("BackgroundRefresh", .info("send repeating request for fresh rules")))
        store.send(.backgroundScheduledRefreshRuleEntities)
      }
    }

    // wait for XPX connection to be setup
    afterDelayOf(seconds: 5) {
      if store.state.userToken != nil {
        log(.plugin("BackgroundRefresh", .info("send initial launch request for fresh rules")))
        store.send(.backgroundScheduledRefreshRuleEntities)
      }
    }
  }

  func respond(to event: AppEvent) {
    switch event {
    case .userTokenChanged:
      log(.plugin("BackgroundRefresh", .info("refreshing rules on user token change")))
      store.send(.backgroundScheduledRefreshRuleEntities)
    default:
      break
    }
  }

  func terminate() {
    timer.invalidate()
  }
}
