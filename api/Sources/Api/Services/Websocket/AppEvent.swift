import Foundation
import Gertie
import TaggedTime

enum AppEvent: Equatable {
  case keychainUpdated(Keychain.Id)
  case suspendFilterRequestUpdated(SuspendFilterRequestUpdated)
  case unlockRequestUpdated(UnlockRequestUpdated)
  case userUpdated(User.Id)
  case userDeleted(User.Id)

  struct UnlockRequestUpdated: Equatable {
    let deviceId: Device.Id
    let status: RequestStatus
    let target: String
    let comment: String?
    let responseComment: String?
  }

  struct SuspendFilterRequestUpdated: Equatable {
    let deviceId: Device.Id
    let status: RequestStatus
    let duration: Seconds<Int>
    let requestComment: String?
    let responseComment: String?
  }
}
