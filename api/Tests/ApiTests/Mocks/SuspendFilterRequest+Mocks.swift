import DuetMock

@testable import Api

extension SuspendFilterRequest: Mock {
  public static var mock: SuspendFilterRequest {
    SuspendFilterRequest(userDeviceId: .init(), scope: .mock)
  }

  public static var empty: SuspendFilterRequest {
    SuspendFilterRequest(userDeviceId: .init(), scope: .empty)
  }

  public static var random: SuspendFilterRequest {
    SuspendFilterRequest(userDeviceId: .init(), scope: .random)
  }
}
