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

    expect(sent.adminNotifications).toEqual([
      .init(
        adminId: user.adminId,
        event: .suspendFilterRequestSubmitted(.init(
          dashboardUrl: "",
          deviceId: user.device.id,
          userName: user.name,
          duration: 1111,
          requestId: suspendRequests.first!.id,
          requestComment: "test"
        ))
      ),
    ])
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

    expect(sent.adminNotifications).toEqual([.init(
      adminId: user.adminId,
      event: .unlockRequestSubmitted(.init(
        dashboardUrl: "",
        userId: user.id,
        userName: user.name,
        requestIds: [retrieved.id]
      ))
    )])
  }

  func testCreateUnlockRequests_v2() async throws {
    let user = try await Entities.user().withDevice()
    let blocked = CreateUnlockRequests_v2.Input.BlockedRequest(
      time: .init(),
      bundleId: "com.example.app",
      url: "https://example.com"
    )

    let (uuid1, uuid2) = mockUUIDs()

    let output = try await CreateUnlockRequests_v2.resolve(
      with: .init(blockedRequests: [blocked], comment: "please dad!"),
      in: context(user)
    )

    expect(output).toEqual(.success)

    // it inserts a network decision, which the unlock req (currently) has a FK ref to
    let networkDecision = try await Current.db.find(NetworkDecision.Id(uuid1))
    expect(networkDecision.appBundleId).toEqual("com.example.app")
    expect(networkDecision.url).toEqual("https://example.com")
    expect(networkDecision.count).toEqual(1)
    expect(networkDecision.hostname).toBeNil()
    expect(networkDecision.ipAddress).toBeNil()

    // inserts unlock request with FK ref to network decision
    let unlockReq = try await Current.db.find(UnlockRequest.Id(uuid2))
    expect(unlockReq.requestComment).toEqual("please dad!")
    expect(unlockReq.networkDecisionId).toEqual(networkDecision.id)
    expect(unlockReq.deviceId).toEqual(user.device.id)
    expect(unlockReq.status).toEqual(.pending)

    expect(sent.adminNotifications).toEqual([.init(
      adminId: user.adminId,
      event: .unlockRequestSubmitted(.init(
        dashboardUrl: "",
        userId: user.id,
        userName: user.name,
        requestIds: [unlockReq.id]
      ))
    )])
  }

  func testCreateSignedScreenshotUpload() async throws {
    let beforeCount = try await Current.db.query(Screenshot.self).all().count
    let user = try await Entities.user().withDevice()

    Current.aws.signedS3UploadUrl = { _ in URL(string: "from-aws.com")! }

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
    .init(requestId: "", dashboardUrl: "", user: user.model, token: user.token)
  }

  func context(_ user: UserWithDeviceEntities) async throws -> UserContext {
    .init(requestId: "", dashboardUrl: "", user: user.model, token: user.token)
  }
}
