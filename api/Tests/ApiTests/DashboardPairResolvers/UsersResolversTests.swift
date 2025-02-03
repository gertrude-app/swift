import DuetSQL
import XCTest
import XExpect

@testable import Api

final class UsersResolversTests: ApiTestCase {
  func testSaveAndDeleteNewUser() async throws {
    let admin = try await self.admin()

    let input = SaveUser.Input(
      id: .init(),
      isNew: true,
      name: "Franny",
      keyloggingEnabled: false, // <-- ignored for new user, we set
      screenshotsEnabled: false, // <-- ignored for new user, we set
      screenshotsResolution: 999, // <-- ignored for new user, we set
      screenshotsFrequency: 888, // <-- ignored for new user, we set
      showSuspensionActivity: false, // <-- ignored for new user, we set
      downtime: "22:00-06:00",
      keychains: []
    )

    let output = try await SaveUser.resolve(with: input, in: admin.context)

    let user = try await self.db.find(input.id)
    expect(output).toEqual(.success)
    expect(user.name).toEqual("Franny")
    // vvv--- these are our recommended defaults
    expect(user.keyloggingEnabled).toEqual(true)
    expect(user.screenshotsEnabled).toEqual(true)
    expect(user.screenshotsResolution).toEqual(1000)
    expect(user.screenshotsFrequency).toEqual(180)
    expect(user.showSuspensionActivity).toEqual(true)
    expect(user.downtime).toEqual("22:00-06:00")

    let keychains = try await user.keychains(in: self.db)
    expect(keychains.count).toEqual(1)
    let keychainId = keychains[0].id
    expect(keychains[0].name).toEqual("Franny’s Keychain")
    expect(keychains[0].description!).toContain("created automatically")
    expect(sent.websocketMessages).toEqual([.init(.userUpdated, to: .user(user.id))])

    // now delete...
    let deleteOutput = try await DeleteEntity.resolve(
      with: .init(id: user.id.rawValue, type: .user),
      in: admin.context
    )
    expect(deleteOutput).toEqual(.success)
    let retrieved = try? await self.db.find(user.id)
    expect(retrieved).toBeNil()
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .user(user.id)),
      .init(.userDeleted, to: .user(user.id)),
    ])

    // and the empty keychain should be deleted
    let userKeychains = try await UserKeychain.query()
      .where(.childId == user.id)
      .all(in: self.db)
    expect(userKeychains.isEmpty).toBeTrue()
    let retrievedKeychain = try? await self.db.find(keychainId)
    expect(retrievedKeychain).toBeNil()
  }

  func testExistingUserUpdated() async throws {
    let user = try await self.user()

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
        downtime: "22:00-06:00",
        keychains: []
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
    expect(retrieved.downtime).toEqual("22:00-06:00")

    expect(sent.websocketMessages).toEqual([.init(.userUpdated, to: .user(user.id))])
  }

  func testEnforcesMinimumScreenshotFrequency() async throws {
    let user = try await self.user()

    let output = try await SaveUser.resolve(
      with: SaveUser.Input(
        id: user.id,
        isNew: false,
        name: "New name",
        keyloggingEnabled: false,
        screenshotsEnabled: false,
        screenshotsResolution: 333,
        screenshotsFrequency: 1, // <-- below minimum of 10
        showSuspensionActivity: true,
        keychains: []
      ),
      in: user.admin.context
    )

    let retrieved = try await self.db.find(user.id)
    expect(output).toEqual(.success)
    expect(retrieved.screenshotsFrequency).toEqual(10)
  }

  func testSetsNewKeychainsFromEmpty() async throws {
    let user = try await self.user()
    var keychain = Keychain.random
    keychain.parentId = user.admin.id
    try await self.db.create(keychain)

    let input = SaveUser.Input(from: user, keychains: [.init(id: keychain.id, schedule: nil)])
    _ = try await SaveUser.resolve(with: input, in: user.admin.context)

    let keychainIds = try await UserKeychain.query()
      .where(.childId == user.id)
      .all(in: self.db)
      .map(\.keychainId)

    expect(keychainIds).toEqual([keychain.id])
    expect(sent.websocketMessages).toEqual([.init(.userUpdated, to: .user(user.id))])
  }

  func testDeletesExistingKeychains() async throws {
    let user = try await self.user()
    var keychain = Keychain.random
    keychain.parentId = user.admin.id
    try await self.db.create(keychain)
    let pivot = try await self.db.create(UserKeychain(childId: user.id, keychainId: keychain.id))

    let input = SaveUser.Input(from: user, keychains: [])
    _ = try await SaveUser.resolve(with: input, in: user.admin.context)

    let keychains = try await UserKeychain.query()
      .where(.childId == user.id)
      .all(in: self.db)

    expect(keychains.isEmpty).toBeTrue()
    let userKeychain = try? await self.db.find(pivot.id)
    expect(userKeychain).toBeNil()
  }

  func testReplacesExistingKeychains() async throws {
    let user = try await self.user()

    var keychain1 = Keychain.random
    keychain1.parentId = user.admin.id
    var keychain2 = Keychain.random
    keychain2.parentId = user.admin.id
    try await self.db.create([keychain1, keychain2])

    let pivot = try await self.db.create(UserKeychain(childId: user.id, keychainId: keychain1.id))

    let input = SaveUser.Input(
      from: user,
      keychains: [.init(
        id: keychain2.id,
        schedule: .init(mode: .active, days: .all, window: "04:00-08:00")
      )]
    )
    _ = try await SaveUser.resolve(with: input, in: user.admin.context)

    let keychainIds = try await UserKeychain.query()
      .where(.childId == user.id)
      .all(in: self.db)
      .map(\.keychainId)

    expect(keychainIds).toEqual([keychain2.id])
    let retrievedOldPivot = try? await self.db.find(pivot.id)
    expect(retrievedOldPivot).toBeNil()

    let newPivot = try? await UserKeychain.query()
      .where(.childId == user.id)
      .first(in: self.db)
    expect(newPivot?.schedule)
      .toEqual(.init(mode: .active, days: .all, window: "04:00-08:00"))
  }

  func testUpdatedUserAddingNewBlockedApps() async throws {
    let user = try await self.user()
    var input = SaveUser.Input(from: user)
    input.blockedApps = [.init(identifier: "FaceSkype")]
    _ = try await SaveUser.resolve(with: input, in: user.admin.context)
    let blocked = try await user.model.blockedApps(in: self.db)
    expect(blocked.map(\.identifier)).toEqual(["FaceSkype"])
  }

  func testDeleteExistingBlockedApps() async throws {
    let user = try await self.user()
    try await self.db.create([UserBlockedApp(identifier: "FaceSkype", childId: user.id)])

    var input = SaveUser.Input(from: user)
    input.blockedApps = nil // <-- nil does not delete
    _ = try await SaveUser.resolve(with: input, in: user.admin.context)

    var retrieved = try await user.model.blockedApps(in: self.db)
    expect(retrieved.count).toEqual(1)

    input.blockedApps = []
    _ = try await SaveUser.resolve(with: input, in: user.admin.context)

    retrieved = try await user.model.blockedApps(in: self.db)
    expect(retrieved.count).toEqual(0)
  }

  func testUpdateExistingBlockedApps() async throws {
    let user = try await self.user()
    let id1 = UserBlockedApp.Id()
    let id2 = UserBlockedApp.Id()
    let id3 = UserBlockedApp.Id()
    try await self.db.create([UserBlockedApp(id: id1, identifier: "FaceSkype", childId: user.id)])

    var input = SaveUser.Input(from: user)
    input.blockedApps = [
      .init(id: id1, identifier: "FaceSkype"),
      .init(id: id2, identifier: "FaceApp"),
    ]
    _ = try await SaveUser.resolve(with: input, in: user.admin.context)

    var retrieved = try await user.model.blockedApps(in: self.db)
    expect(Set(retrieved.map(\.id))).toEqual([id1, id2])

    input = SaveUser.Input(from: user)
    input.blockedApps = [
      .init(id: id2, identifier: "FaceApp"),
      .init(id: id3, identifier: "WhatsZoom"),
    ]
    _ = try await SaveUser.resolve(with: input, in: user.admin.context)

    retrieved = try await user.model.blockedApps(in: self.db)
    expect(retrieved.map(\.id)).toEqual([id2, id3])
  }
}

extension SaveUser.Input {
  init(from user: UserEntities, keychains: [UserKeychain] = []) {
    self.init(
      id: user.id,
      isNew: false,
      name: user.name,
      keyloggingEnabled: user.keyloggingEnabled,
      screenshotsEnabled: user.screenshotsEnabled,
      screenshotsResolution: user.screenshotsResolution,
      screenshotsFrequency: user.screenshotsFrequency,
      showSuspensionActivity: user.showSuspensionActivity,
      keychains: keychains
    )
  }

  static var mock: Self {
    SaveUser.Input(
      id: .init(),
      isNew: true,
      name: "Franny",
      keyloggingEnabled: true,
      screenshotsEnabled: true,
      screenshotsResolution: 100,
      screenshotsFrequency: 180,
      showSuspensionActivity: true,
      downtime: nil,
      keychains: []
    )
  }

  static func mock(with config: (inout Self) -> Void) -> Self {
    var input = Self.mock
    config(&input)
    return input
  }
}
