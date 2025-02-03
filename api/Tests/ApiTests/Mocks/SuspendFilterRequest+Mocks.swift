import Gertie

@testable import Api

extension SuspendFilterRequest: RandomMocked {
  public static var mock: SuspendFilterRequest {
    SuspendFilterRequest(computerUserId: .init(), scope: .mock)
  }

  public static var empty: SuspendFilterRequest {
    SuspendFilterRequest(computerUserId: .init(), scope: .empty)
  }

  public static var random: SuspendFilterRequest {
    SuspendFilterRequest(computerUserId: .init(), scope: .random)
  }
}
