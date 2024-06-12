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
    var dashboardUrl: String
    var userDeviceId: UserDevice.Id
    var userId: User.Id
    var userName: String
    var duration: Seconds<Int>
    var requestId: SuspendFilterRequest.Id
    var requestComment: String?
  }
}
