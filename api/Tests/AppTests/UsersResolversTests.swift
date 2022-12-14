import DashboardRoute
import DuetSQL
import Vapor
import XCTest

@testable import App

final class UsersResolversTests: AppTestCase {
  func testDeleteUser() async throws {
    let user = try await Entities.user()
    let output = try await DeleteUser.resolve(
      for: user.id.rawValue,
      in: user.admin.context
    )
    XCTAssertEqual(output, .true)
    let retrieved = try? await Current.db.find(user.id)
    XCTAssertNil(retrieved)
  }

  func testSaveNewUser() async throws {
    let admin = try await Entities.admin()

    let input = SaveUser.Input(
      id: UUID(),
      adminId: admin.id.rawValue,
      isNew: true,
      name: "Test User",
      keyloggingEnabled: true,
      screenshotsEnabled: true,
      screenshotsResolution: 111,
      screenshotsFrequency: 588,
      keychainIds: []
    )

    let output = try await SaveUser.resolve(for: input, in: admin.context)

    let user = try await Current.db.find(User.Id(input.id))
    XCTAssertEqual(output, .true)
    XCTAssertEqual(user.name, "Test User")
    XCTAssertEqual(user.keyloggingEnabled, true)
    XCTAssertEqual(user.screenshotsEnabled, true)
    XCTAssertEqual(user.screenshotsResolution, 111)
    XCTAssertEqual(user.screenshotsFrequency, 588)
  }

  func testExistingUserUpdated() async throws {
    let user = try await Entities.user()

    let output = try await SaveUser.resolve(
      for: SaveUser.Input(
        id: user.id.rawValue,
        adminId: user.admin.id.rawValue,
        isNew: false,
        name: "New name",
        keyloggingEnabled: false,
        screenshotsEnabled: false,
        screenshotsResolution: 333,
        screenshotsFrequency: 444,
        keychainIds: []
      ),
      in: user.admin.context
    )

    let retrieved = try await Current.db.find(user.id)
    XCTAssertEqual(output, .true)
    XCTAssertEqual(retrieved.name, "New name")
    XCTAssertEqual(retrieved.keyloggingEnabled, false)
    XCTAssertEqual(retrieved.screenshotsEnabled, false)
    XCTAssertEqual(retrieved.screenshotsResolution, 333)
    XCTAssertEqual(retrieved.screenshotsFrequency, 444)
  }

  func testSetsNewKeychainsFromEmpty() async throws {
    let user = try await Entities.user()
    let keychain = Keychain.random
    keychain.authorId = user.admin.id
    try await Current.db.create(keychain)

    let input = SaveUser.Input(from: user, keychainIds: [keychain.id])
    _ = try await SaveUser.resolve(for: input, in: user.admin.context)

    let keychainIds = try await Current.db.query(UserKeychain.self)
      .where(.userId == user.id)
      .all()
      .map(\.keychainId)

    XCTAssertEqual(keychainIds, [keychain.id])
  }

  func testDeletesExistingKeychains() async throws {
    let user = try await Entities.user()
    let keychain = Keychain.random
    keychain.authorId = user.admin.id
    try await Current.db.create(keychain)
    let pivot = try await Current.db.create(UserKeychain(userId: user.id, keychainId: keychain.id))

    let input = SaveUser.Input(from: user, keychainIds: [])
    _ = try await SaveUser.resolve(for: input, in: user.admin.context)

    let keychains = try await Current.db.query(UserKeychain.self)
      .where(.userId == user.id)
      .all()

    XCTAssert(keychains.isEmpty)
    let retrievedPivot = try? await Current.db.find(pivot.id)
    XCTAssertNil(retrievedPivot)
  }

  func testReplacesExistingKeychains() async throws {
    let user = try await Entities.user()

    let keychain1 = Keychain.random
    keychain1.authorId = user.admin.id
    let keychain2 = Keychain.random
    keychain2.authorId = user.admin.id
    try await Current.db.create([keychain1, keychain2])

    let pivot = try await Current.db.create(UserKeychain(userId: user.id, keychainId: keychain1.id))

    let input = SaveUser.Input(from: user, keychainIds: [keychain2.id])
    _ = try await SaveUser.resolve(for: input, in: user.admin.context)

    let keychainIds = try await Current.db.query(UserKeychain.self)
      .where(.userId == user.id)
      .all()
      .map(\.keychainId)

    XCTAssertEqual(keychainIds, [keychain2.id])
    let retrievedPivot = try? await Current.db.find(pivot.id)
    XCTAssertNil(retrievedPivot)
  }
}

extension SaveUser.Input {
  init(from user: UserEntities, keychainIds: [Keychain.Id] = []) {
    self.init(
      id: user.id.rawValue,
      adminId: user.admin.id.rawValue,
      isNew: false,
      name: user.name,
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotsResolution: user.screenshotsResolution,
      screenshotsFrequency: user.screenshotsFrequency,
      keychainIds: keychainIds.map(\.rawValue)
    )
  }
}
