import DuetMock

@testable import Api

extension SuspendFilterRequest: Mock {
  public static var mock: SuspendFilterRequest {
    SuspendFilterRequest(deviceId: .init(), scope: .mock)
  }

  public static var empty: SuspendFilterRequest {
    SuspendFilterRequest(deviceId: .init(), scope: .empty)
  }

  public static var random: SuspendFilterRequest {
    SuspendFilterRequest(deviceId: .init(), scope: .random)
  }
}
