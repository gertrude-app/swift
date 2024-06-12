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
      in: self.context(user)
    )

    expect(output).toEqual(.success)

    let suspendRequests = try await SuspendFilterRequest.query()
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
          userId: user.id,
          userName: user.name,
          duration: 1111,
          requestId: suspendRequests.first!.id,
          requestComment: "test"
        ))
      ),
    ])
  }

  func testOneFailedNotificationDoesntBlockRest() async throws {
    let user = try await Entities.user().withDevice()

    // admin gets two notifications on suspend filter request
    let slack = try await AdminVerifiedNotificationMethod.create(.init(
      adminId: user.adminId,
      config: .slack(
        channelId: "#gertie",
        channelName: "Gertie",
        token: "definitely-not-a-real-token"
      )
    ))
    let text = try await AdminVerifiedNotificationMethod.create(.init(
      adminId: user.adminId,
      config: .text(phoneNumber: "1234567890")
    ))
    try await AdminNotification.create(.init(
      adminId: user.adminId,
      methodId: slack.id,
      trigger: .suspendFilterRequestSubmitted
    ))
    try await AdminNotification.create(.init(
      adminId: user.adminId,
      methodId: text.id,
      trigger: .suspendFilterRequestSubmitted
    ))

    // we want to test the LIVE admin notifier implementation
    Current.adminNotifier = .live
    Current.slack.send = { _, _ in "oh noes!" } // slack fails

    _ = try await CreateSuspendFilterRequest.resolve(
      with: .init(duration: 1111, comment: "test"),
      in: self.context(user)
    )

    expect(sent.slacks).toHaveCount(0)
    expect(sent.texts).toHaveCount(1)
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
      in: self.context(user)
    )

    expect(output).toEqual(.success)
    let inserted = try await Current.db.find(KeystrokeLine.Id(uuid))
    expect(inserted.appName).toEqual("Xcode")
    expect(inserted.line).toEqual("import Foundation")
    expect(inserted.createdAt).toEqual(.epoch)
  }

  func testInsertKeystrokeLineWithNullByte() async throws {
    let user = try await Entities.user().withDevice()
    let (uuid, _) = mockUUIDs()

    let output = try await CreateKeystrokeLines.resolve(
      with: [.init(
        appName: "Xcode",
        line: "Hello\0World", // <-- causes postgres to choke
        filterSuspended: false,
        time: .epoch
      )],
      in: self.context(user)
    )

    expect(output).toEqual(.success)
    let inserted = try await Current.db.find(KeystrokeLine.Id(uuid))
    expect(inserted.line).toEqual("Hello�World")
  }

  func testCreateUnlockRequests_v2() async throws {
    let user = try await Entities.user().withDevice()
    let blocked = CreateUnlockRequests_v2.Input.BlockedRequest(
      bundleId: "com.example.app",
      url: "https://example.com"
    )

    let (uuid, _) = mockUUIDs()

    let output = try await CreateUnlockRequests_v2.resolve(
      with: .init(blockedRequests: [blocked], comment: "please dad!"),
      in: self.context(user)
    )

    expect(output).toEqual(.success)

    let unlockReq = try await Current.db.find(UnlockRequest.Id(uuid))
    expect(unlockReq.requestComment).toEqual("please dad!")
    expect(unlockReq.appBundleId).toEqual("com.example.app")
    expect(unlockReq.url).toEqual("https://example.com")
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
      in: self.context(user)
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
      in: self.context(user)
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

  func testLogsAndNotifiesSecurityEvent() async throws {
    let user = try await Entities.user().withDevice {
      $0.isAdmin = true
    }

    let output = try await LogSecurityEvent.resolve(
      with: .init(deviceId: user.device.id.rawValue, event: "appQuit", detail: "foo"),
      in: context(user)
    )

    let retrieved = try await SecurityEvent.query()
      .where(.userDeviceId == user.device.id)
      .first()

    expect(output).toEqual(.success)
    expect(retrieved.event).toEqual("appQuit")

    expect(sent.adminNotifications).toEqual([.init(
      adminId: user.adminId,
      event: .adminChildSecurityEvent(.init(
        userName: user.name,
        event: .appQuit,
        detail: "foo"
      ))
    )])
  }
}
