import Gertie
import XCore
import XCTest
import XExpect

@testable import Api

final class UpdateUnlockRequestTests: ApiTestCase, @unchecked Sendable {
  func testUpdateUnlockRequest() async throws {
    let child = try await self.child().withDevice {
      $0.appVersion = "2.4.0"
    }

    var request = UnlockRequest.mock
    request.computerUserId = child.computerUser.id
    request.status = .pending
    try await self.db.create(request)

    let output = try await UpdateUnlockRequest.resolve(
      with: UpdateUnlockRequest.Input(
        id: request.id,
        responseComment: "looks good",
        status: .accepted,
      ),
      in: context(child.parent),
    )

    expect(output).toEqual(.success)

    let retrieved = try await self.db.find(request.id)
    expect(retrieved.responseComment).toEqual("looks good")
    expect(retrieved.status).toEqual(.accepted)

    expect(sent.websocketMessages).toEqual([
      .init(
        .unlockRequestUpdated_v2(
          id: request.id.rawValue,
          status: .accepted,
          target: request.target ?? "",
          comment: "looks good",
        ),
        to: .userDevice(child.computerUser.id),
      ),
    ])
  }
}
