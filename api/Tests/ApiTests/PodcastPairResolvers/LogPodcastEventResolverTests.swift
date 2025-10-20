import DuetSQL
import Foundation
import PodcastRoute
import XCTest
import XExpect

@testable import Api

final class LogPodcastEventResolverTests: ApiTestCase, @unchecked Sendable {
  func testLogPodcastEventCreatesRecord() async throws {
    let eventId = "abc123de"
    let kind = "info"
    let label = "The Daily"
    let detail = "Started playing episode 1234"
    let deviceType = "iPhone"
    let appVersion = "1.0.0"
    let iosVersion = "18.0.1"
    let installId = UUID()

    _ = try await LogPodcastEvent.resolve(
      with: .init(
        eventId: eventId,
        kind: kind,
        label: label,
        detail: detail,
        installId: installId,
        deviceType: deviceType,
        appVersion: appVersion,
        iosVersion: iosVersion
      ),
      in: .mock
    )

    let retrieved = try await PodcastEvent.query()
      .where(.eventId == eventId)
      .first(in: self.db)

    expect(retrieved.eventId).toEqual(eventId)
    expect(retrieved.kind).toEqual(.info)
    expect(retrieved.label).toEqual(label)
    expect(retrieved.deviceType).toEqual(deviceType)
    expect(retrieved.appVersion).toEqual(appVersion)
    expect(retrieved.iosVersion).toEqual(iosVersion)
    expect(retrieved.installId).toEqual(installId)
    expect(retrieved.detail).toEqual(detail)
    expect(retrieved.createdAt).not.toBeNil()
  }
}
