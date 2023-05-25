import Combine
import Foundation
import Gertie
import SharedCore

class AccountStatusPlugin: Plugin {
  var store: AppStore
  private var cancellables = Set<AnyCancellable>()

  var currentAccountStatus: AdminAccountStatus {
    store.state.accountStatus
  }

  init(store: AppStore) {
    self.store = store
    checkStatus(after: .seconds(3))
  }

  func checkStatus(after seconds: TimeInterval) {
    afterDelayOf(seconds: seconds) { [weak self] in
      self?.updateStatus()
    }
  }

  func updateStatus() {
    log(.plugin("AccountStatus", .info("update account status")))
    Current.api.getAccountStatus()
      .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] status in
        DispatchQueue.main.async {
          self?.store.send(.setAccountStatus(status))
        }
      })
      .store(in: &cancellables)
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
