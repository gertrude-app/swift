import Dependencies
import DuetSQL
import Foundation
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class iOSResolverTests: ApiTestCase, @unchecked Sendable {
  func testScreenshotUploadUrlTests() async throws {
    let signedUrl = URL(string: "/\(UUID())")!
    let child = try await self.childWithIOSDevice()
    let output = try await withDependencies {
      $0.date = .constant(.reference)
      $0.uuid = .incrementing
      $0.aws._signedS3UploadUrl = { _, _, _ in signedUrl }
    } operation: {
      try await ScreenshotUploadUrl.resolve(
        with: .init(width: 973, height: 321, createdAt: .reference),
        in: child.context
      )
    }
    let record = try await Screenshot.query()
      .where(.iosDeviceId == child.device.id)
      .first(in: self.db)
    expect(record.width).toEqual(973)
    expect(record.height).toEqual(321)
    expect(record.filterSuspended).toEqual(true)
    expect(output.uploadUrl).toEqual(signedUrl)
  }

  func testLogIOSEvent() async throws {
    let eventId = UUID().uuidString
    let vendorId = UUID()
    _ = try await LogIOSEvent.resolve(
      with: .init(
        eventId: eventId,
        kind: "event",
        deviceType: "iPhone",
        iOSVersion: "18.0.1",
        vendorId: vendorId,
        detail: "first launch"
      ),
      in: .mock
    )

    let retrieved = try await InterestingEvent.query()
      .where(.eventId == eventId)
      .first(in: self.db)

    expect(retrieved.kind).toEqual("event")
    expect(retrieved.context).toEqual("ios")
    expect(retrieved.detail!).toContain("iPhone")
    expect(retrieved.detail!).toContain("18.0.1")
    expect(retrieved.detail!).toContain(vendorId.lowercased)
    expect(retrieved.detail!).toContain("first launch")
  }
}
