import Gertie
import SharedCore

enum AdminScreenSection: String, Identifiable {
  case healthCheck = "Health Check"
  case actions = "Actions"
  case exemptUsers = "Exempt Users"

  var id: String { rawValue }

  var systemImage: String {
    switch self {
    case .healthCheck:
      return "cross"
    case .actions:
      return "cursorarrow.rays"
    case .exemptUsers:
      return "person.2"
    }
  }
}

enum AdminWindowState {
  case healthCheck(HealthCheckState)
  case actions(ActionsState)
  case exemptUsers(ExemptUsersState)
  case connect(ConnectState)

  static var `default`: Self {
    .healthCheck(.init())
  }

  var section: AdminScreenSection? {
    switch self {
    case .healthCheck:
      return .healthCheck
    case .actions:
      return .actions
    case .exemptUsers:
      return .exemptUsers
    case .connect:
      return nil
    }
  }

  var healthCheckState: HealthCheckState {
    get {
      switch self {
      case .healthCheck(let state):
        return state
      default:
        return .init()
      }
    }
    set {
      switch self {
      case .healthCheck:
        self = .healthCheck(newValue)
      default:
        break
      }
    }
  }

  var exemptUsersState: ExemptUsersState {
    get {
      switch self {
      case .exemptUsers(let state):
        return state
      default:
        return .init()
      }
    }
    set {
      switch self {
      case .exemptUsers:
        self = .exemptUsers(newValue)
      default:
        break
      }
    }
  }

  var actionsState: ActionsState {
    get {
      switch self {
      case .actions(let state):
        return state
      default:
        return .init()
      }
    }
    set {
      switch self {
      case .actions:
        self = .actions(newValue)
      default:
        break
      }
    }
  }

  var connectState: ConnectState {
    switch self {
    case .connect(let state):
      return state
    default:
      return ConnectState()
    }
  }

  class ConnectState {
    var code = ""
    var fetchState = FetchState<String>.waiting
  }
}

// protocols

extension AdminWindowState.ConnectState: Equatable {
  static func == (lhs: AdminWindowState.ConnectState, rhs: AdminWindowState.ConnectState) -> Bool {
    if lhs.code != rhs.code {
      return false
    }
    if lhs.fetchState != rhs.fetchState {
      return false
    }
    return true
  }
}

extension AdminWindowState: Equatable {}
