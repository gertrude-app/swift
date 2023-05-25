import Combine
import Gertie

extension AdminWindowState {
  struct HealthCheckState: Equatable {
    enum MacOsUserType: Equatable {
      case standard
      case admin
      case errorDetermining
    }

    enum NotificationsPermission: Equatable {
      case none
      case banner
      case alert
    }

    var latestAppVersion: String?
    var filterVersion: String?
    var filterCommunicationVerified: Bool?
    var filterKeys: Int?
    var screenRecordingPermissionGranted: Bool?
    var keystrokeRecordingPermissionGranted: Bool?
    var macOsUserType: MacOsUserType?
    var notificationsPermission: NotificationsPermission?
  }
}

extension AppAction {
  enum HealthCheckAction: Equatable {
    case runAll
    case reset
    case setBool(WritableKeyPath<AdminWindowState.HealthCheckState, Bool?>, Bool?)
    case setString(WritableKeyPath<AdminWindowState.HealthCheckState, String?>, String?)
    case setInt(WritableKeyPath<AdminWindowState.HealthCheckState, Int?>, Int?)
    case setMacOsUserType(AdminWindowState.HealthCheckState.MacOsUserType)
    case setNotificationsPermission(AdminWindowState.HealthCheckState.NotificationsPermission)
    case repairFilterCommunication
    case repairFilterRules
  }
}

func healthCheckReducer(
  state: inout AdminWindowState.HealthCheckState,
  action: AppAction.HealthCheckAction,
  environment: Env
) -> AnyPublisher<AppAction, Never>? {
  switch action {
  case .runAll:
    return environment.healthCheck.runChecks()

  case .setInt(let keyPath, let value):
    state[keyPath: keyPath] = value

  case .setBool(let keyPath, let value):
    state[keyPath: keyPath] = value

  case .setString(let keyPath, let value):
    state[keyPath: keyPath] = value

  case .setMacOsUserType(let type):
    state.macOsUserType = type

  case .setNotificationsPermission(let permission):
    state.notificationsPermission = permission

  case .repairFilterCommunication:
    return environment.healthCheck.restartFilter()

  case .repairFilterRules:
    return environment.healthCheck.refreshRules()

  case .reset:
    state = .init()
  }

  return nil
}
