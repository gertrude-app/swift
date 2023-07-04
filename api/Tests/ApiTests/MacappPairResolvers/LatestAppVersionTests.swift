import DuetSQL
import Gertie
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class LatestAppVersionTests: ApiTestCase {
  func testAppOnLatestVersionHappyPath() async throws {
    try await createReleases([
      Release("1.0.0", pace: 10),
      Release("1.1.0", pace: 10),
    ])

    let output = try await LatestAppVersion.resolve(
      with: .init(releaseChannel: .stable, currentVersion: "1.1.0"),
      in: .init(requestId: "", dashboardUrl: "")
    )

    expect(output).toEqual(.init(semver: "1.1.0"))
  }

  func testAppBehindOne() async throws {
    try await Current.db.deleteAll(Release.self)
    try await createReleases([
      Release("1.0.0", pace: 10, createdAt: .epoch),
      Release("1.1.0", pace: 10, createdAt: .epoch.advanced(by: .days(10))),
      Release("1.2.0", pace: 10, createdAt: .epoch.advanced(by: .days(20))),
    ])

    let output = try await LatestAppVersion.resolve(
      with: .init(releaseChannel: .stable, currentVersion: "1.1.0"),
      in: .init(requestId: "", dashboardUrl: "")
    )

    expect(output).toEqual(.init(
      semver: "1.2.0",
      pace: .init(
        nagOn: .epoch.advanced(by: .days(30)),
        requireOn: .epoch.advanced(by: .days(40))
      )
    ))
  }

  func testAppBehindTwoUsesFirstPace() async throws {
    try await Current.db.deleteAll(Release.self)
    try await createReleases([
      Release("1.0.0", pace: 10, createdAt: .epoch),
      Release("1.1.0", pace: 10, createdAt: .epoch.advanced(by: .days(10))),
      Release("1.2.0", pace: 10, createdAt: .epoch.advanced(by: .days(20))),
      Release("1.3.0", pace: 10, createdAt: .epoch.advanced(by: .days(30))),
    ])

    let output = try await LatestAppVersion.resolve(
      with: .init(releaseChannel: .stable, currentVersion: "1.1.0"),
      in: .init(requestId: "", dashboardUrl: "")
    )

    expect(output).toEqual(.init(
      semver: "1.3.0", // update to very latest...
      pace: .init(
        nagOn: .epoch.advanced(by: .days(30)), // ... w/ pace of first missed release
        requireOn: .epoch.advanced(by: .days(40))
      )
    ))
  }
}

// extensions, helpers

func createReleases(_ releases: [Release]) async throws {
  try await Current.db.deleteAll(Release.self)
  try await Current.db.create(releases)
  for var release in releases {
    try await release.modifyCreatedAt(.exact(release.createdAt))
  }
}

extension Release: HasCreatedAt {}

extension Release {
  convenience init(
    _ semver: String,
    channel: ReleaseChannel = .stable,
    pace requirementPace: Int? = nil,
    createdAt: Date = .init()
  ) {
    self.init(
      semver: semver,
      channel: channel,
      signature: "signature-123",
      length: 123_456_789,
      revision: "somesha-123",
      requirementPace: requirementPace
    )
    self.createdAt = createdAt
    updatedAt = createdAt
  }
}
