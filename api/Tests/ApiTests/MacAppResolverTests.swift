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
      in: context(user)
    )

    expect(output).toEqual(.success)

    let suspendRequests = try await Current.db.query(SuspendFilterRequest.self)
      .where(.deviceId == user.device.id)
      .all()

    expect(suspendRequests).toHaveCount(1)
    expect(suspendRequests.first?.duration.rawValue).toEqual(1111)
    expect(suspendRequests.first?.requestComment).toEqual("test")
  }

  func testInsertNetworkDecisions() async throws {
    let user = try await Entities.user().withDevice()
    let (uuid, _) = mockUUIDs()
    let clientId = UUID()

    let output = try await CreateNetworkDecisions.resolve(
      with: [
        .init(verdict: .block, reason: .defaultNotAllowed, time: Date(), count: 333),
        .init(id: clientId, verdict: .block, reason: .defaultNotAllowed, time: Date(), count: 1),
      ],
      in: context(user)
    )

    expect(output).toEqual(.success)

    let retrieved = try await Current.db.find(NetworkDecision.Id(uuid))
    expect(retrieved.count).toEqual(333)

    let retrieved2 = try await Current.db.find(NetworkDecision.Id(clientId))
    expect(retrieved2.count).toEqual(1)
  }

  func testCreateUnlockRequests() async throws {
    let user = try await Entities.user().withDevice()
    let decision = NetworkDecision.random
    decision.deviceId = user.device.id
    try await Current.db.create(decision)
    let (uuid, _) = mockUUIDs()

    let output = try await CreateUnlockRequests.resolve(
      with: [.init(networkDecisionId: decision.id.rawValue, comment: "please dad!")],
      in: context(user)
    )

    expect(output).toEqual(.success)

    let retrieved = try await Current.db.find(UnlockRequest.Id(uuid))
    expect(retrieved.requestComment).toEqual("please dad!")

    // TODO: test event, notify connected app
  }

  func testCreateSignedScreenshotUpload() async throws {
    let beforeCount = try await Current.db.query(Screenshot.self).all().count
    let user = try await Entities.user().withDevice()

    Current.aws.signedS3UploadURL = { _ in URL(string: "from-aws.com")! }

    let output = try await CreateSignedScreenshotUpload.resolve(
      with: .init(width: 111, height: 222),
      in: context(user)
    )

    expect(output.uploadUrl.absoluteString).toEqual("from-aws.com")

    let afterCount = try await Current.db.query(Screenshot.self).all().count
    expect(afterCount).toEqual(beforeCount + 1)
  }

  // helpers

  func context(_ user: UserEntities) async throws -> UserContext {
    .init(requestId: "", user: user.model, token: user.token)
  }

  func context(_ user: UserWithDeviceEntities) async throws -> UserContext {
    .init(requestId: "", user: user.model, token: user.token)
  }
}
