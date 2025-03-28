import Gertie
import TaggedTime

enum AdminEvent: Equatable {
  case unlockRequestSubmitted(UnlockRequestSubmitted)
  case suspendFilterRequestSubmitted(SuspendFilterRequestSubmitted)
  case adminChildSecurityEvent(MacAppSecurityEvent)

  struct MacAppSecurityEvent: Equatable {
    var userName: String
    var event: Gertie.SecurityEvent.MacApp
    var detail: String?
  }

  struct UnlockRequestSubmitted: Equatable {
    var dashboardUrl: String
    var userId: User.Id
    var userName: String
    var requestIds: [UnlockRequest.Id]
  }

  struct SuspendFilterRequestSubmitted: Equatable {
    enum Context: Equatable {
      case macapp(
        computerUserId: ComputerUser.Id,
        requestId: MacApp.SuspendFilterRequest.Id
      )
      case iosapp(
        deviceId: IOSApp.Device.Id,
        requestId: IOSApp.SuspendFilterRequest.Id
      )
    }

    var dashboardUrl: String
    var childId: User.Id
    var childName: String
    var duration: Seconds<Int>
    var requestComment: String?
    var context: Context
  }
}
