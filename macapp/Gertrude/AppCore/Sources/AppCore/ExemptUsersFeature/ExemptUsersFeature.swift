import Collaboration
import Combine
import Foundation
import Gertie
import SharedCore

struct MacOSUser: Identifiable, Hashable {
  var id: uid_t
  var name: String
}

extension AdminWindowState {
  struct ExemptUsersState: Equatable {
    var exemptUsers: Set<MacOSUser>?
    var users: Set<MacOSUser>
    var currentUser: MacOSUser
    var errorMsg: String?

    init(
      exemptUsers: Set<MacOSUser>? = nil,
      users: Set<MacOSUser>,
      currentUser: MacOSUser,
      errorMsg: String? = nil
    ) {
      self.exemptUsers = exemptUsers
      self.users = users
      self.currentUser = currentUser
      self.errorMsg = errorMsg
    }
  }
}

extension AppAction {
  enum ExemptUserAction: Equatable {
    case viewDidAppear
    case setUserExempt(MacOSUser, Bool)
    case receivedCurrentExemptUserIds(Set<uid_t>)
    case updateSucceeded
    case updateFailed(Set<uid_t>)
  }
}

func exemptUserReducer(
  state: inout AdminWindowState.ExemptUsersState,
  action: AppAction.ExemptUserAction,
  environment: Env
) -> AnyPublisher<AppAction.ExemptUserAction, Never>? {
  switch action {
  case .viewDidAppear:
    return environment.filter.getCurrentExemptUserIds()
      .map { .receivedCurrentExemptUserIds($0) }
      .eraseToAnyPublisher()

  case .receivedCurrentExemptUserIds(let ids):
    state.exemptUsers = state.users.filter { ids.contains($0.id) }

  case .updateFailed(let ids):
    state.exemptUsers = state.users.filter { ids.contains($0.id) }
    state.errorMsg =
      "Updating exempt user list failed, please try again or contact support if the problem persists."

  case .updateSucceeded:
    break

  case .setUserExempt(let user, let isExempt):
    if isExempt {
      state.exemptUsers?.insert(user)
    } else {
      state.exemptUsers?.remove(user)
    }
    let ids = Set(state.exemptUsers?.map(\.id) ?? [])
    return environment.filter.sendExemptUserIds(ids)
      .map { .updateSucceeded }
      .catch { Just(AppAction.ExemptUserAction.updateFailed($0)) }
      .eraseToAnyPublisher()
  }

  return nil
}

// extensions

extension AdminWindowState.ExemptUsersState {
  init() {
    let users = MacOSUser.getAll()
    let currentUser = users
      .first { $0.id == getuid() } ?? .init(id: getuid(), name: NSFullUserName())
    self.init(exemptUsers: nil, users: users, currentUser: currentUser, errorMsg: nil)
  }
}

extension MacOSUser {
  // @see https://stackoverflow.com/questions/3681895/get-all-users-on-os-x
  static func getAll() -> Set<Self> {
    let defaultAuthority = CSGetLocalIdentityAuthority().takeUnretainedValue()
    let identityClass = kCSIdentityClassUser
    let query = CSIdentityQueryCreate(nil, identityClass, defaultAuthority).takeRetainedValue()
    var error: Unmanaged<CFError>?
    CSIdentityQueryExecute(query, 0, &error)
    let results = CSIdentityQueryCopyResults(query).takeRetainedValue()
    let resultsCount = CFArrayGetCount(results)
    var users: Set<Self> = []

    for idx in 0 ..< resultsCount {
      let identity = unsafeBitCast(CFArrayGetValueAtIndex(results, idx), to: CSIdentity.self)
      let id: uid_t = CSIdentityGetPosixID(identity)
      let name = CSIdentityGetFullName(identity).takeUnretainedValue() as String
      users.insert(.init(id: id, name: name))
    }

    return users
  }
}
