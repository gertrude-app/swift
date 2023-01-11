import Foundation
import Shared
import TaggedTime

enum Event: Equatable {

  // delete Key, update Key, create Key
  case keychainUpdated(Payload.KeychainUpdated) // 👍

  // set user keychains, update user
  case userUpdated(Payload.UserUpdated) // 👍

  // func decideUnlockRequest
  case unlockRequestUpdated(Payload.UnlockRequestUpdated) // 👍

  // updateSuspendFilterRequest
  case suspendFilterRequestUpdated(Payload.SuspendFilterRequestUpdated) // 👍

  enum Payload {
    struct KeychainUpdated: EventPayload {
      let keychainId: Keychain.Id
    }

    struct UserUpdated: EventPayload {
      let userId: User.Id
    }

    struct UnlockRequestUpdated: EventPayload {
      let deviceId: Device.Id
      let status: RequestStatus
      let target: String
      let comment: String?
      let responseComment: String?
    }

    struct SuspendFilterRequestUpdated: EventPayload {
      let deviceId: Device.Id
      let status: RequestStatus
      let scope: AppScope
      let duration: Seconds<Int>
      let requestComment: String?
      let responseComment: String?
    }
  }
}

protocol EventPayload: Equatable, Codable {}

protocol AdminUserIdentifiable {
  var adminId: Admin.Id { get }
}

extension Event {
  var payload: Any {
    switch self {
    case .keychainUpdated(let payload):
      return payload
    case .userUpdated(let payload):
      return payload
    case .unlockRequestUpdated(let payload):
      return payload
    case .suspendFilterRequestUpdated(let payload):
      return payload
    }
  }
}
