import DuetSQL
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class CheckInResolverTests: ApiTestCase {

  func testCheckIn_UserProps() async throws {
    let user = try await Entities.user(config: {
      $0.keyloggingEnabled = false
      $0.screenshotsEnabled = true
      $0.screenshotsFrequency = 376
      $0.screenshotsResolution = 1081
    }).withDevice()

    let output = try await CheckIn.resolve(with: .init(appVersion: "1.0.0"), in: user.context)
    expect(output.userData.name).toBe(user.name)
    expect(output.userData.keyloggingEnabled).toBeFalse()
    expect(output.userData.screenshotsEnabled).toBeTrue()
    expect(output.userData.screenshotFrequency).toEqual(376)
    expect(output.userData.screenshotSize).toEqual(1081)
  }

  func testCheckIn_OtherProps() async throws {
    try await createReleases([
      Release("2.0.3", channel: .stable),
      Release("2.0.4", channel: .stable),
      Release("3.0.0", channel: .beta),
    ])

    let user = try await Entities.user(admin: {
      $0.subscriptionStatus = .pastDue
    }).withDevice(adminDevice: {
      $0.appReleaseChannel = .beta
    })

    let output = try await CheckIn.resolve(with: .init(appVersion: "1.0.0"), in: user.context)

    expect(output.adminAccountStatus).toEqual(.needsAttention)
    expect(output.updateReleaseChannel).toEqual(.beta)
    expect(output.latestRelease.semver).toEqual("3.0.0")
  }

  func testCheckIn_AppManifest() async throws {
    try await Current.db.query(IdentifiedApp.self).delete(force: true)
    try await Current.db.query(AppBundleId.self).delete(force: true)
    try await Current.db.query(AppCategory.self).delete(force: true)
    await clearCachedAppIdManifest()

    let app = try await Current.db.create(IdentifiedApp.random)
    let id = AppBundleId.random
    id.identifiedAppId = app.id
    try await Current.db.create(id)

    let user = try await Entities.user().withDevice()
    let output = try await CheckIn.resolve(with: .init(appVersion: "1.0.0"), in: user.context)
    expect(output.appManifest.apps).toEqual([app.slug: [id.bundleId]])
  }

  func testUserWithNoKeychainsDoesNotGetAutoIncluded() async throws {
    let user = try await Entities.user().withDevice()
    try await createAutoIncludeKeychain()

    let output = try await CheckIn.resolve(with: .init(appVersion: "1.0.0"), in: user.context)
    expect(output.keys).toHaveCount(0)
  }

  func testUserWithAtLeastOneKeyGetsAutoIncluded() async throws {
    let user = try await Entities.user().withDevice()
    let admin = try await Entities.admin().withKeychain()
    try await Current.db.create(UserKeychain(userId: user.id, keychainId: admin.keychain.id))
    let (_, autoKey) = try await createAutoIncludeKeychain()

    let output = try await CheckIn.resolve(with: .init(appVersion: "1.0.0"), in: user.context)
    expect(output.keys.contains(.init(id: autoKey.id.rawValue, key: autoKey.key))).toBeTrue()
  }
}

// helpers

@discardableResult
func createAutoIncludeKeychain() async throws -> (Keychain, Key) {
  let admin = try await Entities.admin()
  try await Current.db.query(Keychain.self)
    .where(.name == "__auto_included__")
    .delete()

  let keychain = try await Current.db.create(Keychain(
    authorId: admin.model.id,
    name: "__auto_included__"
  ))
  let key = try await Current.db.create(Key(
    keychainId: keychain.id,
    key: .domain(domain: "foo.com", scope: .webBrowsers)
  ))
  return (keychain, key)
}