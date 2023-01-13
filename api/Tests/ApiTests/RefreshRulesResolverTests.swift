import DuetMock
import DuetSQL
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class RefreshResolverTests: ApiTestCase {

  func testRefreshRules_UserProps() async throws {
    let user = try await Entities.user(config: {
      $0.keyloggingEnabled = false
      $0.screenshotsEnabled = true
      $0.screenshotsFrequency = 376
      $0.screenshotsResolution = 1081
    })

    let output = try await RefreshRules.resolve(with: .init(appVersion: "1"), in: user.context)
    expect(output.keyloggingEnabled).toBeFalse()
    expect(output.screenshotsEnabled).toBeTrue()
    expect(output.screenshotsFrequency).toEqual(376)
    expect(output.screenshotsResolution).toEqual(1081)
  }

  func testRefreshRules_AppManifest() async throws {
    try await Current.db.query(IdentifiedApp.self).delete(force: true)
    try await Current.db.query(AppBundleId.self).delete(force: true)
    try await Current.db.query(AppCategory.self).delete(force: true)
    await clearCachedAppIdManifest()

    let app = try await Current.db.create(IdentifiedApp.random)
    let id = AppBundleId.random
    id.identifiedAppId = app.id
    try await Current.db.create(id)

    let user = try await Entities.user()
    let output = try await RefreshRules.resolve(with: .init(appVersion: "1"), in: user.context)
    expect(output.appManifest.apps).toEqual([app.slug: [id.bundleId]])
  }

  func testUserWithNoKeychainsDoesNotGetAutoIncluded() async throws {
    let user = try await Entities.user()
    try await createAutoIncludeKeychain()

    let output = try await RefreshRules.resolve(with: .init(appVersion: "1"), in: user.context)
    expect(output.keys).toHaveCount(0)
  }

  func testUserWithAtLeastOneKeyGetsAutoIncluded() async throws {
    let user = try await Entities.user()
    let admin = try await Entities.admin().withKeychain()
    try await Current.db.create(UserKeychain(userId: user.id, keychainId: admin.keychain.id))
    let (_, autoKey) = try await createAutoIncludeKeychain()

    let output = try await RefreshRules.resolve(with: .init(appVersion: "1"), in: user.context)
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
