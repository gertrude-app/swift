import Gertie
import XCore
import XCTest
import XExpect

@testable import Api

final class UpdateUnlockRequestTests: ApiTestCase {
  func testUpdateUnlockRequest_legacyVersion() async throws {
    let user = try await Entities.user().withDevice {
      $0.appVersion = "2.1.7" // <-- older version...
    }

    var request = UnlockRequest.mock
    request.userDeviceId = user.device.id
    request.status = .pending
    try await request.create()

    let output = try await UpdateUnlockRequest.resolve(
      with: UpdateUnlockRequest.Input(
        id: request.id,
        responseComment: "no way",
        status: .rejected
      ),
      in: context(user.admin)
    )

    expect(output).toEqual(.success)

    let retrieved = try await UnlockRequest.find(request.id)
    expect(retrieved.responseComment).toEqual("no way")
    expect(retrieved.status).toEqual(.rejected)

    expect(sent.websocketMessages).toEqual([
      .init(
        .unlockRequestUpdated( // <-- ... produces older event
          status: .rejected,
          target: request.target ?? "",
          parentComment: "no way"
        ),
        to: .userDevice(user.device.id)
      ),
    ])
  }

  func testUpdateUnlockRequest() async throws {
    let user = try await Entities.user().withDevice {
      $0.appVersion = "2.4.0" // <-- current version...
    }

    var request = UnlockRequest.mock
    request.userDeviceId = user.device.id
    request.status = .pending
    try await request.create()

    let output = try await UpdateUnlockRequest.resolve(
      with: UpdateUnlockRequest.Input(
        id: request.id,
        responseComment: "looks good",
        status: .accepted
      ),
      in: context(user.admin)
    )

    expect(output).toEqual(.success)

    let retrieved = try await UnlockRequest.find(request.id)
    expect(retrieved.responseComment).toEqual("looks good")
    expect(retrieved.status).toEqual(.accepted)

    expect(sent.websocketMessages).toEqual([
      .init(
        .unlockRequestUpdated_v2( // <-- ... produces current event
          id: request.id.rawValue,
          status: .accepted,
          target: request.target ?? "",
          comment: "looks good"
        ),
        to: .userDevice(user.device.id)
      ),
    ])
  }
}
