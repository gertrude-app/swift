import DuetSQL
import MacAppRoute
import XCore
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
      .where(.userDeviceId == user.device.id)
      .all()

    expect(suspendRequests).toHaveCount(1)
    expect(suspendRequests.first?.duration.rawValue).toEqual(1111)
    expect(suspendRequests.first?.requestComment).toEqual("test")

    expect(sent.adminNotifications).toEqual([
      .init(
        adminId: user.adminId,
        event: .suspendFilterRequestSubmitted(.init(
          dashboardUrl: "",
          userDeviceId: user.device.id,
          userName: user.name,
          duration: 1111,
          requestId: suspendRequests.first!.id,
          requestComment: "test"
        ))
      ),
    ])
  }

  func testCreateKeystrokeLines() async throws {
    let user = try await Entities.user().withDevice()
    let (uuid, _) = mockUUIDs()

    let output = try await CreateKeystrokeLines.resolve(
      with: [.init(
        appName: "Xcode",
        line: "import Foundation",
        filterSuspended: false,
        time: .epoch
      )],
      in: context(user)
    )

    expect(output).toEqual(.success)
    let inserted = try await Current.db.find(KeystrokeLine.Id(uuid))
    expect(inserted.appName).toEqual("Xcode")
    expect(inserted.line).toEqual("import Foundation")
    expect(inserted.createdAt).toEqual(.epoch)
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
    expect(unlockReq.userDeviceId).toEqual(user.device.id)
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

  func testCreateSignedScreenshotUploadWithDate() async throws {
    let user = try await Entities.user().withDevice()

    let (uuid, _) = mockUUIDs()
    Current.aws.signedS3UploadUrl = { _ in URL(string: "from-aws.com")! }

    _ = try await CreateSignedScreenshotUpload.resolve(
      with: .init(width: 1116, height: 222, createdAt: .epoch),
      in: context(user)
    )

    let screenshot = try await Current.db.find(Screenshot.Id(uuid))
    expect(screenshot.width).toEqual(1116)
    expect(screenshot.createdAt).toEqual(.epoch)
  }

  func testPre_2_1_0_AppSendingMonitoringItemsWithoutFilterSuspendedBool() {
    var json = """
    [{
      "appName": "Xcode",
      "line": "import Foundation",
      "time": 0.0
    }]
    """
    let keystrokes = try? JSON.decode(json, as: CreateKeystrokeLines.Input.self)
    expect(keystrokes).not.toBeNil()

    json = """
    {
      "width": 333,
      "height": 444,
      "createdAt": 0.0
    }
    """
    let screenshot = try? JSON.decode(json, as: CreateSignedScreenshotUpload.Input.self)
    expect(screenshot).not.toBeNil()
  }

  // helpers

  func context(_ user: UserEntities) async throws -> UserContext {
    .init(requestId: "", dashboardUrl: "", user: user.model, token: user.token)
  }

  func context(_ user: UserWithDeviceEntities) async throws -> UserContext {
    .init(requestId: "", dashboardUrl: "", user: user.model, token: user.token)
  }
}
