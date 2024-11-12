import Dependencies
import DuetSQL
import Gertie
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class CheckInLatestReleaseTests: ApiTestCase {
  func test(
    releaseChannel: ReleaseChannel,
    currentVersion: String
  ) async throws -> CheckIn_v2.LatestRelease {
    let user = try await self.user().withDevice(adminDevice: {
      $0.appReleaseChannel = releaseChannel
    })
    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: currentVersion, filterVersion: currentVersion),
      in: user.context
    )
    return output.latestRelease
  }

  func testAppOnLatestVersionHappyPath() async throws {
    try await self.replaceAllReleases(with: [
      Release("1.0.0", pace: 10),
      Release("1.1.0", pace: 10),
    ])

    let output = try await test(releaseChannel: .stable, currentVersion: "1.1.0")

    expect(output).toEqual(.init(semver: "1.1.0"))
  }

  func testAppBehindOne() async throws {
    try await self.replaceAllReleases(with: [
      Release("1.0.0", pace: 10, createdAt: .epoch),
      Release("1.1.0", pace: 10, createdAt: .epoch.advanced(by: .days(10))),
      Release("1.2.0", pace: 10, createdAt: .epoch.advanced(by: .days(20))),
    ])

    let output = try await test(releaseChannel: .stable, currentVersion: "1.1.0")

    expect(output).toEqual(.init(
      semver: "1.2.0",
      pace: .init(
        nagOn: .epoch.advanced(by: .days(30)),
        requireOn: .epoch.advanced(by: .days(40))
      )
    ))
  }

  func testAppBehindTwoUsesFirstPace() async throws {
    try await self.replaceAllReleases(with: [
      Release("1.0.0", pace: 10, createdAt: .epoch),
      Release("1.1.0", pace: 10, createdAt: .epoch.advanced(by: .days(10))),
      Release("1.2.0", pace: 10, createdAt: .epoch.advanced(by: .days(20))),
      Release("1.3.0", pace: 10, createdAt: .epoch.advanced(by: .days(30))),
    ])

    let output = try await test(releaseChannel: .stable, currentVersion: "1.1.0")

    expect(output).toEqual(.init(
      semver: "1.3.0", // update to very latest...
      pace: .init(
        nagOn: .epoch.advanced(by: .days(30)), // ... w/ pace of first missed release
        requireOn: .epoch.advanced(by: .days(40))
      )
    ))
  }

  func testOnBetaAheadOfStable() async throws {
    try await self.replaceAllReleases(with: [
      Release("1.0.0", pace: 10, createdAt: .epoch),
      Release("1.1.0", pace: 10, createdAt: .epoch.advanced(by: .days(10))),
      Release("2.0.0", channel: .beta, pace: 10, createdAt: .epoch.advanced(by: .days(20))),
    ])

    let user = try await self.user().withDevice(adminDevice: {
      $0.appReleaseChannel = .stable // set to stable, but they're on beta
    })

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "2.0.0", filterVersion: nil),
      in: user.context
    )

    expect(output.updateReleaseChannel).toEqual(.stable)
    expect(output.latestRelease.semver).toEqual("2.0.0")
  }

  func testOnCanaryBehindStable() async throws {
    try await self.replaceAllReleases(with: [
      Release("2.0.0", channel: .stable, pace: nil, createdAt: .epoch),
      Release("2.1.0", channel: .canary, pace: nil, createdAt: .epoch.advanced(by: .days(10))),
      Release("2.1.1", channel: .stable, pace: nil, createdAt: .epoch.advanced(by: .days(20))),
    ])

    let user = try await self.user().withDevice(adminDevice: {
      $0.appReleaseChannel = .canary
    })

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "2.1.0", filterVersion: nil),
      in: user.context
    )

    expect(output.updateReleaseChannel).toEqual(.canary) // they still are on canary...
    expect(output.latestRelease.semver).toEqual("2.1.1") // ...but we pull them up to latest/stable
  }
}

// extensions, helpers

extension ApiTestCase {
  func replaceAllReleases(with releases: [Release]) async throws {
    try await self.db.delete(all: Release.self)
    try await self.db.create(releases)
    for var release in releases {
      try await release.modifyCreatedAt(.exact(release.createdAt))
    }
  }
}

extension Release: HasCreatedAt {}

extension Release {
  init(
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
