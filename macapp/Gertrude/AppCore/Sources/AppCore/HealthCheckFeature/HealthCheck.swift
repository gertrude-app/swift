import Shared
import SwiftUI

struct HealthCheck: Identifiable {
  enum State {
    case checking
    case success
    case warning
    case failure
  }

  var title: String
  var state: State
  var successMeta: String?
  var warnView: (() -> AnyView)?
  var errorView: (() -> AnyView)?
  var id: String { title }

  @ViewBuilder
  var meta: some View {
    switch state {
    case .checking:
      Text(" ")
    case .success:
      Text(successMeta ?? " ").subtle()
    case .warning:
      warnView?() ?? AnyView(Text(" "))
    case .failure:
      errorView?() ?? AnyView(Text(" "))
    }
  }

  init(
    title: String,
    state: State = .checking,
    successMeta: String? = nil,
    warnView: @escaping (() -> AnyView) = { AnyView(Text(" ")) },
    errorView: @escaping (() -> AnyView) = { AnyView(Text(" ")) }
  ) {
    self.title = title
    self.state = state
    self.successMeta = successMeta
    self.warnView = warnView
    self.errorView = errorView
  }

  init(
    title: String,
    state: State = .checking,
    successMeta: String? = nil,
    warnView: String,
    errorView: String
  ) {
    self.title = title
    self.state = state
    self.successMeta = successMeta
    self.warnView = { AnyView(Text(warnView).subtle()) }
    self.errorView = { AnyView(Text(errorView).subtle()) }
  }

  init(
    title: String,
    state: State = .checking,
    successMeta: String? = nil,
    warnView: @escaping (() -> AnyView) = { AnyView(Text(" ")) },
    errorView: String
  ) {
    self.title = title
    self.state = state
    self.successMeta = successMeta
    self.warnView = warnView
    self.errorView = { AnyView(Text(errorView).subtle()) }
  }

  init(
    title: String,
    state: State = .checking,
    successMeta: String? = nil,
    warnView: String,
    errorView: @escaping (() -> AnyView) = { AnyView(Text(" ")) }
  ) {
    self.title = title
    self.state = state
    self.successMeta = successMeta
    self.warnView = { AnyView(Text(warnView).subtle()) }
    self.errorView = errorView
  }
}

extension HealthCheck.State {
  init(accountStatus: AdminAccountStatus?) {
    guard let accountStatus = accountStatus else {
      self = .checking
      return
    }
    switch accountStatus {
    case .active:
      self = .success
    case .needsAttention:
      self = .warning
    case .inactive:
      self = .failure
    }
  }

  init(appVersion: String, latestAppVersion: String?) {
    switch latestAppVersion {
    case .none:
      self = .checking
    case .some(let latest):
      self = latest == appVersion ? .success : .failure
    }
  }

  init(filterVersion: String?, latestAppVersion: String?) {
    switch (filterVersion, latestAppVersion) {
    case (nil, _), (_, nil):
      self = .checking
    case (.some(let filterVersion), .some(let latestAppVersion)):
      self = filterVersion == latestAppVersion ? .success : .failure
    }
  }

  init(permission: Bool?, enabled: Bool) {
    if permission == true {
      self = .success
      return
    }

    if permission == false {
      self = enabled ? .failure : .warning
      return
    }

    self = .checking
  }

  init(accountStatus: String?) {
    guard let status = accountStatus else {
      self = .checking
      return
    }
    switch status {
    case "active", "trialing", "complimentary":
      self = .success
    case "incomplete", "incompleteExpired", "pastDue":
      self = .warning
    default:
      self = .failure
    }
  }

  init(_ bool: Bool?) {
    switch bool {
    case nil:
      self = .checking
    case .some(true):
      self = .success
    case .some(false):
      self = .failure
    }
  }

  init(_ permission: AdminWindowState.HealthCheckState.NotificationsPermission?) {
    guard let permission = permission else {
      self = .checking
      return
    }
    switch permission {
    case .none:
      self = .failure
    case .banner:
      self = .warning
    case .alert:
      self = .success
    }
  }
}

extension AdminAccountStatus {
  var userString: String {
    switch self {
    case .active:
      return "active"
    case .inactive:
      return "INACTIVE"
    case .needsAttention:
      return "NEEDS ATTENTION"
    }
  }
}
