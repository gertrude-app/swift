import DuetSQL
import Foundation
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class iOSResolverTests: ApiTestCase, @unchecked Sendable {
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
