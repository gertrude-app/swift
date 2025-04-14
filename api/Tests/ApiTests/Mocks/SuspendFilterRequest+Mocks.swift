import Gertie

@testable import Api

extension MacApp.SuspendFilterRequest: RandomMocked {
  public static var mock: MacApp.SuspendFilterRequest {
    MacApp.SuspendFilterRequest(computerUserId: .init(), scope: .mock)
  }

  public static var empty: MacApp.SuspendFilterRequest {
    MacApp.SuspendFilterRequest(computerUserId: .init(), scope: .empty)
  }

  public static var random: MacApp.SuspendFilterRequest {
    MacApp.SuspendFilterRequest(computerUserId: .init(), scope: .random)
  }
}
