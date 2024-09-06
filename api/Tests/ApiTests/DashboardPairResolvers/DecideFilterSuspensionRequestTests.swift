import XCTest
import XExpect

@testable import Api

final class DecideFilterSuspensionRequestTests: ApiTestCase {
  func testDecideSuspendFilterRequest_Accepted() async throws {
    let user = try await Entities.user().withDevice {
      $0.appVersion = "2.4.0" // current version...
    }
    let request = try await SuspendFilterRequest.random {
      $0.userDeviceId = user.device.id
      $0.status = .pending
    }.create()

    let decision: DecideFilterSuspensionRequest.Decision = .accepted(
      durationInSeconds: 333,
      extraMonitoring: "@55+k"
    )

    let output = try await DecideFilterSuspensionRequest.resolve(
      with: .init(id: request.id, decision: decision, responseComment: "ok"),
      in: context(user.admin)
    )

    expect(output).toEqual(.success)

    let updated = try await SuspendFilterRequest.find(request.id)
    expect(updated.duration).toEqual(.init(333))
    expect(updated.responseComment).toEqual("ok")
    expect(updated.status).toEqual(.accepted)
    expect(updated.extraMonitoring).toEqual("@55+k")

    expect(sent.websocketMessages).toEqual([
      .init(
        .filterSuspensionRequestDecided_v2( // <-- ...most recent event
          id: updated.id.rawValue,
          decision: updated.decision!,
          comment: "ok"
        ),
        to: .userDevice(user.device.id)
      ),
    ])
  }

  func testDecideSuspendFilterRequest_Rejected() async throws {
    let user = try await Entities.user().withDevice {
      $0.appVersion = "2.1.7" // <-- older version...
    }
    let request = try await self.db.create(SuspendFilterRequest.random {
      $0.duration = .init(100)
      $0.userDeviceId = user.device.id
      $0.status = .pending
    })

    let output = try await DecideFilterSuspensionRequest.resolve(
      with: .init(id: request.id, decision: .rejected, responseComment: nil),
      in: context(user.admin)
    )

    expect(output).toEqual(.success)

    let updated = try await SuspendFilterRequest.find(request.id)
    expect(updated.responseComment).toBeNil()
    expect(updated.status).toEqual(.rejected)

    expect(sent.websocketMessages).toEqual([
      .init( // vvv -- ...older event
        .filterSuspensionRequestDecided(decision: updated.decision!, comment: nil),
        to: .userDevice(user.device.id)
      ),
    ])
  }
}
