import Combine
import Foundation
import Gertie
import SharedCore

extension ApiClient {
  static let inactiveAccount = ApiClient(
    // to allow switching to another admin account
    connectToUser: ApiClient.live.connectToUser,

    createSuspendFilterRequest: { _, _ in
      log(.api(.inactiveAccountNoop("createSuspendFilterRequest")))
      return Empty().eraseToAnyPublisher()
    },

    createUnlockRequests: { _, _ in
      log(.api(.inactiveAccountNoop("createUnlockRequests")))
      return Empty().eraseToAnyPublisher()
    },

    // to permit determining if inactive account is restored to active status
    getAccountStatus: ApiClient.live.getAccountStatus,

    refreshRules: {
      log(.api(.inactiveAccountNoop("refreshRules")))
      return Empty().eraseToAnyPublisher()
    },

    uploadFilterDecisions: { _ in
      log(.api(.inactiveAccountNoop("uploadFilterDecisions")))
    },

    uploadKeystrokes: {
      log(.api(.inactiveAccountNoop("uploadKeystrokes")))
    },

    uploadScreenshot: { _, _, _, _ in
      log(.api(.inactiveAccountNoop("uploadScreenshot")))
    }
  )
}
