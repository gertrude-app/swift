import TaggedTime

enum AdminEvent: Equatable {
  case unlockRequestSubmitted(UnlockRequestSubmitted)
  case suspendFilterRequestSubmitted(SuspendFilterRequestSubmitted)

  struct UnlockRequestSubmitted: Equatable {
    let dashboardUrl: String
    let userId: User.Id
    let userName: String
    let requestIds: [UnlockRequest.Id]
  }

  struct SuspendFilterRequestSubmitted: Equatable {
    let dashboardUrl: String
    let deviceId: Device.Id
    let userName: String
    let duration: Seconds<Int>
    let requestId: SuspendFilterRequest.Id
    let requestComment: String?
  }
}
