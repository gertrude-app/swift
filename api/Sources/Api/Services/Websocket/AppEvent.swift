import Foundation
import Gertie
import TaggedTime

enum AppEvent: Equatable {
  case keychainUpdated(Keychain.Id)
  case suspendFilterRequestDecided(UserDevice.Id, FilterSuspensionDecision, String?)
  case unlockRequestUpdated(UnlockRequestUpdated)
  case userUpdated(User.Id)
  case userDeleted(User.Id)

  struct UnlockRequestUpdated: Equatable {
    let userDeviceId: UserDevice.Id
    let status: RequestStatus
    let target: String
    let comment: String?
    let responseComment: String?
  }

  // deprecated, remove when app MSV is 2.1.0
  case suspendFilterRequestUpdated(SuspendFilterRequestUpdated)
  struct SuspendFilterRequestUpdated: Equatable {
    let userDeviceId: UserDevice.Id
    let status: RequestStatus
    let duration: Seconds<Int>
    let requestComment: String?
    let responseComment: String?
  }
}
