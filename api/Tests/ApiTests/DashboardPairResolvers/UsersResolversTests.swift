import DuetSQL
import XCTest
import XExpect

@testable import Api

final class UsersResolversTests: ApiTestCase {
  func testDeleteUser() async throws {
    let user = try await Entities.user()
    let output = try await DeleteEntity.resolve(
      with: .init(id: user.id.rawValue, type: .user),
      in: user.admin.context
    )
    expect(output).toEqual(.success)
    let retrieved = try? await self.db.find(user.id)
    expect(retrieved).toBeNil()
    expect(sent.websocketMessages).toEqual([.init(.userDeleted, to: .user(user.id))])
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
      showSuspensionActivity: false,
      keychainIds: []
    )

    let output = try await SaveUser.resolve(with: input, in: admin.context)

    let user = try await self.db.find(input.id)
    expect(output).toEqual(.success)
    expect(user.name).toEqual("Test User")
    expect(user.keyloggingEnabled).toEqual(true)
    expect(user.screenshotsEnabled).toEqual(true)
    expect(user.screenshotsResolution).toEqual(111)
    expect(user.screenshotsFrequency).toEqual(588)
    expect(user.showSuspensionActivity).toEqual(false)
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
        showSuspensionActivity: true,
        keychainIds: []
      ),
      in: user.admin.context
    )

    let retrieved = try await self.db.find(user.id)
    expect(output).toEqual(.success)
    expect(retrieved.name).toEqual("New name")
    expect(retrieved.keyloggingEnabled).toEqual(false)
    expect(retrieved.screenshotsEnabled).toEqual(false)
    expect(retrieved.screenshotsResolution).toEqual(333)
    expect(retrieved.screenshotsFrequency).toEqual(444)
    expect(retrieved.showSuspensionActivity).toEqual(true)

    expect(sent.websocketMessages).toEqual([.init(.userUpdated, to: .user(user.id))])
  }

  func testSetsNewKeychainsFromEmpty() async throws {
    let user = try await Entities.user()
    var keychain = Keychain.random
    keychain.authorId = user.admin.id
    try await self.db.create(keychain)

    let input = SaveUser.Input(from: user, keychainIds: [keychain.id])
    _ = try await SaveUser.resolve(with: input, in: user.admin.context)

    let keychainIds = try await UserKeychain.query()
      .where(.userId == user.id)
      .all(in: self.db)
      .map(\.keychainId)

    expect(keychainIds).toEqual([keychain.id])
    expect(sent.websocketMessages).toEqual([.init(.userUpdated, to: .user(user.id))])
  }

  func testDeletesExistingKeychains() async throws {
    let user = try await Entities.user()
    var keychain = Keychain.random
    keychain.authorId = user.admin.id
    try await self.db.create(keychain)
    let pivot = try await self.db.create(UserKeychain(userId: user.id, keychainId: keychain.id))

    let input = SaveUser.Input(from: user, keychainIds: [])
    _ = try await SaveUser.resolve(with: input, in: user.admin.context)

    let keychains = try await UserKeychain.query()
      .where(.userId == user.id)
      .all(in: self.db)

    expect(keychains.isEmpty).toBeTrue()
    let retrievedPivot = try? await self.db.find(pivot.id)
    expect(retrievedPivot).toBeNil()
  }

  func testReplacesExistingKeychains() async throws {
    let user = try await Entities.user()

    var keychain1 = Keychain.random
    keychain1.authorId = user.admin.id
    var keychain2 = Keychain.random
    keychain2.authorId = user.admin.id
    try await self.db.create([keychain1, keychain2])

    let pivot = try await self.db.create(UserKeychain(userId: user.id, keychainId: keychain1.id))

    let input = SaveUser.Input(from: user, keychainIds: [keychain2.id])
    _ = try await SaveUser.resolve(with: input, in: user.admin.context)

    let keychainIds = try await UserKeychain.query()
      .where(.userId == user.id)
      .all(in: self.db)
      .map(\.keychainId)

    expect(keychainIds).toEqual([keychain2.id])
    let retrievedPivot = try? await self.db.find(pivot.id)
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
      showSuspensionActivity: user.showSuspensionActivity,
      keychainIds: keychainIds
    )
  }
}
