import DuetMock

@testable import Api

extension UnlockRequest: Mock {
  public static var mock: UnlockRequest {
    UnlockRequest(networkDecisionId: .init(), userDeviceId: .init())
  }

  public static var empty: UnlockRequest {
    UnlockRequest(networkDecisionId: .init(), userDeviceId: .init())
  }

  public static var random: UnlockRequest {
    UnlockRequest(networkDecisionId: .init(), userDeviceId: .init())
  }
}
