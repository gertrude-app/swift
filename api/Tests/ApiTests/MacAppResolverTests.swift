import DuetMock
import DuetSQL
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class MacAppResolverTests: ApiTestCase {

  func testCreateSuspendFilterRequest() async throws {
    let user = try await Entities.user().withDevice()

    let output = try await CreateSuspendFilterRequest.resolve(
      with: .init(duration: 1111, comment: "test"),
      in: .init(requestId: "", user: user.model, token: user.token)
    )

    expect(output).toEqual(.success)

    let suspendRequests = try await Current.db.query(SuspendFilterRequest.self)
      .where(.deviceId == user.device.id)
      .all()

    expect(suspendRequests).toHaveCount(1)
    expect(suspendRequests.first?.duration.rawValue).toEqual(1111)
    expect(suspendRequests.first?.requestComment).toEqual("test")
  }
}
