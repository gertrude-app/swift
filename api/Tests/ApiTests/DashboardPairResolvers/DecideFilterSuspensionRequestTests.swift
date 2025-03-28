import XCTest
import XExpect

@testable import Api

final class DecideFilterSuspensionRequestTests: ApiTestCase, @unchecked Sendable {
  func testDecideSuspendFilterRequest_Accepted() async throws {
    let user = try await self.user().withDevice {
      $0.appVersion = "2.4.0"
    }
    let request = try await self.db.create(MacApp.SuspendFilterRequest.random {
      $0.computerUserId = user.device.id
      $0.status = .pending
    })

    let decision: DecideFilterSuspensionRequest.Decision = .accepted(
      durationInSeconds: 333,
      extraMonitoring: "@55+k"
    )

    let output = try await DecideFilterSuspensionRequest.resolve(
      with: .init(id: request.id, decision: decision, responseComment: "ok"),
      in: context(user.admin)
    )

    expect(output).toEqual(.success)

    let updated = try await self.db.find(request.id)
    expect(updated.duration).toEqual(.init(333))
    expect(updated.responseComment).toEqual("ok")
    expect(updated.status).toEqual(.accepted)
    expect(updated.extraMonitoring).toEqual("@55+k")

    expect(sent.websocketMessages).toEqual([
      .init(
        .filterSuspensionRequestDecided_v2(
          id: updated.id.rawValue,
          decision: updated.decision!,
          comment: "ok"
        ),
        to: .userDevice(user.device.id)
      ),
    ])
  }
}
