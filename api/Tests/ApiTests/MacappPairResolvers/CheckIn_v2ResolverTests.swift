import DuetSQL
import Gertie
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class CheckIn_v2ResolverTests: ApiTestCase, @unchecked Sendable {
  func testCheckIn_UserProps() async throws {
    let child = try await self.child(with: {
      $0.keyloggingEnabled = false
      $0.screenshotsEnabled = true
      $0.screenshotsFrequency = 376
      $0.screenshotsResolution = 1081
      $0.downtime = "22:00-08:00"
    }).withDevice()

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: "3.3.3"),
      in: child.context
    )
    expect(output.userData.name).toBe(child.name)
    expect(output.userData.keyloggingEnabled).toBeFalse()
    expect(output.userData.screenshotsEnabled).toBeTrue()
    expect(output.userData.screenshotFrequency).toEqual(376)
    expect(output.userData.screenshotSize).toEqual(1081)
    expect(output.userData.downtime).toEqual("22:00-08:00")

    let computer = try await self.db.find(child.computer.id)
    expect(computer.filterVersion).toEqual("3.3.3")
  }

  func testCheckIn_OtherProps() async throws {
    try await replaceAllReleases(with: [
      Release("2.0.3", channel: .stable),
      Release("2.0.4", channel: .stable),
      Release("3.0.0", channel: .beta),
    ])

    let child = try await self.child(withParent: {
      $0.subscriptionStatus = .overdue
    }).withDevice(computer: {
      $0.appReleaseChannel = .beta
    })

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context
    )

    expect(output.adminAccountStatus).toEqual(.needsAttention)
    expect(output.updateReleaseChannel).toEqual(.beta)
    expect(output.latestRelease.semver).toEqual("3.0.0")
  }

  func testCheckInUpdatesDeviceData() async throws {
    let child = try await self.child().withDevice {
      $0.isAdmin = nil
    } computer: {
      $0.osVersion = nil
    }

    _ = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "1.0.0",
        filterVersion: "3.3.3",
        userIsAdmin: true,
        osVersion: "14.5.0"
      ),
      in: child.context
    )

    let computer = try await self.db.find(child.computer.id)
    expect(computer.osVersion).toEqual(Semver("14.5.0"))
    let computerUser = try await self.db.find(child.computerUser.id)
    expect(computerUser.isAdmin).toEqual(true)
  }

  func testCheckInDoesntOverwriteDeviceDataWithNil() async throws {
    let child = try await self.child().withDevice {
      $0.isAdmin = false
    } computer: {
      $0.osVersion = Semver("14.5.0")
    }

    _ = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "1.0.0",
        filterVersion: "3.3.3",
        userIsAdmin: nil, // <-- don't overwrite val in database
        osVersion: nil // <-- don't overwrite val in database
      ),
      in: child.context
    )

    let computer = try await self.db.find(child.computer.id)
    expect(computer.osVersion).toEqual(Semver("14.5.0"))
    let computerUser = try await self.db.find(child.computerUser.id)
    expect(computerUser.isAdmin).toEqual(false)
  }

  func testCheckIn_AppManifest() async throws {
    try await self.db.delete(all: IdentifiedApp.self)
    try await self.db.delete(all: AppBundleId.self)
    try await self.db.delete(all: AppCategory.self)
    await clearCachedAppIdManifest()

    let app = try await self.db.create(IdentifiedApp.random)
    var id = AppBundleId.random
    id.identifiedAppId = app.id
    try await self.db.create(id)

    let child = try await self.childWithComputer()
    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context
    )
    expect(output.appManifest.apps).toEqual([app.slug: [id.bundleId]])
  }

  func testUserWithNoKeychainsDoesNotGetAutoIncluded() async throws {
    let child = try await self.childWithComputer()
    try await self.createAutoIncludeKeychain()

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context
    )
    expect(output.keychains).toHaveCount(0)
  }

  func testUserWithAtLeastOneKeyGetsAutoIncluded() async throws {
    let child = try await self.childWithComputer()
    let parent = try await self.parent().withKeychain()
    try await self.db.create(ChildKeychain(childId: child.id, keychainId: parent.keychain.id))
    let (_, autoKey) = try await createAutoIncludeKeychain()

    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context
    )
    expect(output.keys.contains(.init(id: autoKey.id.rawValue, key: autoKey.key))).toBeTrue()
  }

  func testIncludesResolvedFilterSuspension() async throws {
    let child = try await self.childWithComputer()
    let susp = try await self.db.create(MacApp.SuspendFilterRequest.mock {
      $0.computerUserId = child.computerUser.id
      $0.status = .accepted
      $0.duration = 777
      $0.extraMonitoring = "@55+k"
      $0.responseComment = "susp2 response comment"
    })

    let output = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "1.0.0",
        filterVersion: nil,
        pendingFilterSuspension: susp.id.rawValue
      ),
      in: child.context
    )

    expect(output.resolvedFilterSuspension).toEqual(.init(
      id: susp.id.rawValue,
      decision: .accepted(
        duration: 777,
        extraMonitoring: .addKeyloggingAndSetScreenshotFreq(55)
      ),
      comment: "susp2 response comment"
    ))

    let notRequested = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context
    )
    expect(notRequested.resolvedFilterSuspension).toBeNil()
  }

  func testDoesNotIncludeUnresolvedSuspension() async throws {
    let child = try await self.childWithComputer()
    let susp = try await self.db.create(MacApp.SuspendFilterRequest.mock {
      $0.computerUserId = child.computerUser.id
      $0.status = .pending // <-- still pending!
    })

    let output = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "1.0.0",
        filterVersion: nil,
        pendingFilterSuspension: susp.id.rawValue
      ),
      in: child.context
    )

    expect(output.resolvedFilterSuspension).toBeNil()
  }

  func testIncludesResolvedUnlockRequests() async throws {
    let child = try await self.childWithComputer()
    let unlock1 = UnlockRequest.mock {
      $0.computerUserId = child.computerUser.id
      $0.status = .pending // <-- pending, will not be returned
    }

    let unlock2 = UnlockRequest.mock {
      $0.computerUserId = child.computerUser.id
      $0.status = .accepted // <-- resolved, will be returned
      $0.responseComment = "unlock2 response comment"
    }

    let unlock3 = UnlockRequest.mock {
      $0.computerUserId = child.computerUser.id
      $0.status = .rejected // <-- resolved, but not requested, not returned
    }

    try await self.db.create([unlock1, unlock2, unlock3])

    let output = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "1.0.0",
        filterVersion: nil,
        pendingUnlockRequests: [unlock1.id.rawValue, unlock2.id.rawValue]
      ),
      in: child.context
    )

    expect(output.resolvedUnlockRequests).toEqual(
      [.init(
        id: unlock2.id.rawValue,
        status: .accepted,
        target: "",
        comment: "unlock2 response comment"
      )]
    )

    let notRequested = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: nil),
      in: child.context
    )
    expect(notRequested.resolvedUnlockRequests).toBeNil()
  }
}

extension CheckIn_v2.Output {
  var keys: [RuleKey] {
    self.keychains.flatMap(\.keys)
  }
}
