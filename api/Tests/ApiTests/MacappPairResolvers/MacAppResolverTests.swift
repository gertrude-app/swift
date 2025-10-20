import Dependencies
import DuetSQL
import MacAppRoute
import XCore
import XCTest
import XExpect

@testable import Api

final class MacAppResolverTests: ApiTestCase, @unchecked Sendable {
  func testCreateSuspendFilterRequest() async throws {
    let child = try await self.childWithComputer()

    let id = try await CreateSuspendFilterRequest_v2.resolve(
      with: .init(duration: 1111, comment: "test"),
      in: self.context(child)
    )

    let suspendRequests = try await MacApp.SuspendFilterRequest.query()
      .where(.computerUserId == child.computerUser.id)
      .all(in: self.db)

    expect(suspendRequests).toHaveCount(1)
    expect(suspendRequests.first?.duration.rawValue).toEqual(1111)
    expect(suspendRequests.first?.requestComment).toEqual("test")
    expect(suspendRequests.first?.id.rawValue).toEqual(id)

    expect(sent.parentNotifications).toEqual([
      .init(
        parentId: child.parentId,
        event: .suspendFilterRequestSubmitted(.init(
          dashboardUrl: "",
          childId: child.id,
          childName: child.name,
          duration: 1111,
          requestComment: "test",
          context: .macapp(
            computerUserId: child.computerUser.id,
            requestId: suspendRequests.first!.id
          )
        ))
      ),
    ])
  }

  func testOneFailedNotificationDoesntBlockRest() async throws {
    let child = try await self.childWithComputer()

    // admin gets two notifications on suspend filter request
    let slack = try await self.db.create(Parent.NotificationMethod(
      parentId: child.parentId,
      config: .slack(
        channelId: "#gertie",
        channelName: "Gertie",
        token: "definitely-not-a-real-token"
      )
    ))
    let text = try await self.db.create(Parent.NotificationMethod(
      parentId: child.parentId,
      config: .text(phoneNumber: "1234567890")
    ))
    try await self.db.create(Parent.Notification(
      parentId: child.parentId,
      methodId: slack.id,
      trigger: .suspendFilterRequestSubmitted
    ))
    try await self.db.create(Parent.Notification(
      parentId: child.parentId,
      methodId: text.id,
      trigger: .suspendFilterRequestSubmitted
    ))

    try await withDependencies {
      $0.slack.send = { @Sendable _, _ in "oh noes!" } // <-- slack fails
      // we want to test the LIVE admin notifier implementation
      $0.adminNotifier = .liveValue
    } operation: {
      try await CreateSuspendFilterRequest_v2.resolve(
        with: .init(duration: 1111, comment: "test"),
        in: self.context(child)
      )
    }

    expect(sent.slacks).toHaveCount(0)
    expect(sent.texts).toHaveCount(1)
  }

  func testCreateKeystrokeLines() async throws {
    let child = try await self.childWithComputer()

    let (uuid, output) = try await withUUID {
      try await CreateKeystrokeLines.resolve(
        with: [.init(
          appName: "Xcode",
          line: "import Foundation",
          filterSuspended: false,
          time: .epoch
        )],
        in: self.context(child)
      )
    }

    expect(output).toEqual(.success)
    let inserted = try await self.db.find(KeystrokeLine.Id(uuid))
    expect(inserted.appName).toEqual("Xcode")
    expect(inserted.line).toEqual("import Foundation")
    expect(inserted.createdAt).toEqual(.epoch)
  }

  func testInsertKeystrokeLineWithNullByte() async throws {
    let child = try await self.childWithComputer()

    let (uuid, output) = try await withUUID {
      try await CreateKeystrokeLines.resolve(
        with: [.init(
          appName: "Xcode",
          line: "Hello\0World", // <-- causes postgres to choke
          filterSuspended: false,
          time: .epoch
        )],
        in: self.context(child)
      )
    }

    expect(output).toEqual(.success)
    let inserted = try await self.db.find(KeystrokeLine.Id(uuid))
    expect(inserted.line).toEqual("Hello�World")
  }

  func testCreateSignedScreenshotUpload() async throws {
    let beforeCount = try await self.db.count(Screenshot.self)
    let child = try await self.childWithComputer()

    let output = try await withDependencies {
      $0.aws._signedS3UploadUrl = { _, _, _ in URL(string: "from-aws.com")! }
    } operation: {
      try await CreateSignedScreenshotUpload.resolve(
        with: .init(width: 111, height: 222),
        in: self.context(child)
      )
    }

    expect(output.uploadUrl.absoluteString).toEqual("from-aws.com")

    let afterCount = try await self.db.count(Screenshot.self)
    expect(afterCount).toEqual(beforeCount + 1)
  }

  func testCreateSignedScreenshotUploadWithDate() async throws {
    let child = try await self.childWithComputer()
    let uuids = MockUUIDs()

    try await withDependencies {
      $0.aws._signedS3UploadUrl = { _, _, _ in URL(string: "from-aws.com")! }
      $0.uuid = .mock(uuids)
    } operation: {
      _ = try await CreateSignedScreenshotUpload.resolve(
        with: .init(width: 1116, height: 222, createdAt: .epoch),
        in: self.context(child)
      )
      let screenshot = try await self.db.find(Screenshot.Id(uuids[1]))
      expect(screenshot.width).toEqual(1116)
      expect(screenshot.createdAt).toEqual(.epoch)
    }
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
    let child = try await self.child().withDevice {
      $0.isAdmin = true
    }

    let output = try await LogSecurityEvent.resolve(
      with: .init(deviceId: child.computerUser.id.rawValue, event: "appQuit", detail: "foo"),
      in: context(child)
    )

    let retrieved = try await SecurityEvent.query()
      .where(.computerUserId == child.computerUser.id)
      .first(in: self.db)

    expect(output).toEqual(.success)
    expect(retrieved.event).toEqual("appQuit")

    expect(sent.parentNotifications).toEqual([.init(
      parentId: child.parentId,
      event: .adminChildSecurityEvent(.init(
        userName: child.name,
        event: .appQuit,
        detail: "foo"
      ))
    )])
  }
}
