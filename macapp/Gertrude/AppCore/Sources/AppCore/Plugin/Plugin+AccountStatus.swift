import Combine
import Foundation
import Shared
import SharedCore

class AccountStatusPlugin: Plugin {
  var store: AppStore

  var currentAccountStatus: AdminAccountStatus {
    store.state.accountStatus
  }

  init(store: AppStore) {
    self.store = store
    checkStatus(after: .seconds(3))
  }

  func checkStatus(after seconds: TimeInterval) {
    afterDelayOf(seconds: seconds) { [updateStatus] in
      Task { await updateStatus() }
    }
  }

  @MainActor
  func updateStatus() async {
    log(.plugin("AccountStatus", .info("update account status")))
    if store.state.hasUserToken,
       let status = try? await Current.api.getAccountStatus().async() {
      store.send(.setAccountStatus(status))
    }
    checkStatus(after: currentAccountStatus.recheckTime)
  }

  func setApiImplementation() {
    Current.api = currentAccountStatus.apiImplementation
    store.environment.api = currentAccountStatus.apiImplementation
    log(.plugin("AccountStatus", .level(.info, "set api implementation", [
      "meta.primary": .string("accountStatus=\(currentAccountStatus)"),
    ])))
  }

  func respond(to event: AppEvent) {
    switch event {
    case .receivedNewAccountStatus:
      setApiImplementation()
    default:
      break
    }
  }
}

private extension AdminAccountStatus {
  var recheckTime: TimeInterval {
    switch self {
    case .inactive:
      return .hours(24)
    case .needsAttention:
      return .minutes(60)
    default:
      return .hours(24)
    }
  }

  var apiImplementation: ApiClient {
    switch self {
    case .inactive:
      return .inactiveAccount
    default:
      return .live
    }
  }
}
