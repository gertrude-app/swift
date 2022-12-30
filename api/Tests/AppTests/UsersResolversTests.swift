import DuetSQL
import XCTest
import XExpect

@testable import App

final class UsersResolversTests: AppTestCase {
  func testDeleteUser() async throws {
    let user = try await Entities.user()
    let output = try await DeleteEntity.resolve(
      with: .init(id: user.id.rawValue, type: "User"),
      in: user.admin.context
    )
    expect(output).toEqual(.success)
    let retrieved = try? await Current.db.find(user.id)
    expect(retrieved).toBeNil()
  }

  func testSaveNewUser() async throws {
    let admin = try await Entities.admin()

    let input = SaveUser.Input(
      id: .init(),
      isNew: true,
      name: "Test User",
      keyloggingEnabled: true,
      screenshotsEnabled: true,
      screenshotsResolution: 111,
      screenshotsFrequency: 588,
      keychainIds: []
    )

    let output = try await SaveUser.resolve(with: input, in: admin.context)

    let user = try await Current.db.find(input.id)
    expect(output).toEqual(.success)
    expect(user.name).toEqual("Test User")
    expect(user.keyloggingEnabled).toEqual(true)
    expect(user.screenshotsEnabled).toEqual(true)
    expect(user.screenshotsResolution).toEqual(111)
    expect(user.screenshotsFrequency).toEqual(588)
  }

  func testExistingUserUpdated() async throws {
    let user = try await Entities.user()

    let output = try await SaveUser.resolve(
      with: SaveUser.Input(
        id: user.id,
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
    expect(output).toEqual(.success)
    expect(retrieved.name).toEqual("New name")
    expect(retrieved.keyloggingEnabled).toEqual(false)
    expect(retrieved.screenshotsEnabled).toEqual(false)
    expect(retrieved.screenshotsResolution).toEqual(333)
    expect(retrieved.screenshotsFrequency).toEqual(444)
  }

  func testSetsNewKeychainsFromEmpty() async throws {
    let user = try await Entities.user()
    let keychain = Keychain.random
    keychain.authorId = user.admin.id
    try await Current.db.create(keychain)

    let input = SaveUser.Input(from: user, keychainIds: [keychain.id])
    _ = try await SaveUser.resolve(with: input, in: user.admin.context)

    let keychainIds = try await Current.db.query(UserKeychain.self)
      .where(.userId == user.id)
      .all()
      .map(\.keychainId)

    expect(keychainIds).toEqual([keychain.id])
  }

  func testDeletesExistingKeychains() async throws {
    let user = try await Entities.user()
    let keychain = Keychain.random
    keychain.authorId = user.admin.id
    try await Current.db.create(keychain)
    let pivot = try await Current.db.create(UserKeychain(userId: user.id, keychainId: keychain.id))

    let input = SaveUser.Input(from: user, keychainIds: [])
    _ = try await SaveUser.resolve(with: input, in: user.admin.context)

    let keychains = try await Current.db.query(UserKeychain.self)
      .where(.userId == user.id)
      .all()

    expect(keychains.isEmpty).toBeTrue()
    let retrievedPivot = try? await Current.db.find(pivot.id)
    expect(retrievedPivot).toBeNil()
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
    _ = try await SaveUser.resolve(with: input, in: user.admin.context)

    let keychainIds = try await Current.db.query(UserKeychain.self)
      .where(.userId == user.id)
      .all()
      .map(\.keychainId)

    expect(keychainIds).toEqual([keychain2.id])
    let retrievedPivot = try? await Current.db.find(pivot.id)
    expect(retrievedPivot).toBeNil()
  }
}

extension SaveUser.Input {
  init(from user: UserEntities, keychainIds: [Keychain.Id] = []) {
    self.init(
      id: user.id,
      isNew: false,
      name: user.name,
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotsResolution: user.screenshotsResolution,
      screenshotsFrequency: user.screenshotsFrequency,
      keychainIds: keychainIds
    )
  }
}
