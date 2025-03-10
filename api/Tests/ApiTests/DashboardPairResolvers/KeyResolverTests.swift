import XCore
import XCTest
import XExpect

@testable import Api

final class KeyResolverTests: ApiTestCase, @unchecked Sendable {
  func prepare() async throws -> (SaveKey.Input, AdminWithKeychainEntities) {
    let admin = try await self.admin().withKeychain()
    let input = SaveKey.Input(
      isNew: true,
      id: .init(),
      keychainId: admin.keychain.id,
      key: .skeleton(scope: .bundleId("com.example.app")),
      comment: "a comment",
      expiration: nil
    )
    return (input, admin)
  }

  func testCreateKeyRecord() async throws {
    let (input, admin) = try await prepare()

    let output = try await SaveKey.resolve(with: input, in: admin.context)
    expect(output).toEqual(.success)

    let key = try await self.db.find(input.id)
    expect(key.comment).toEqual(input.comment)
    expect(key.key).toEqual(input.key)
    expect(sent.websocketMessages)
      .toEqual([.init(.userUpdated, to: .usersWith(keychain: admin.keychain.id))])
  }

  func testCreateKeyRecordWithExpiration() async throws {
    var (input, admin) = try await prepare()
    input.expiration = Date(addingDays: 5)

    let output = try await SaveKey.resolve(with: input, in: admin.context)
    expect(output).toEqual(.success)

    let key = try await self.db.find(input.id)
    expect(key.deletedAt).not.toBeNil()
  }

  func testCreateKeyRecordWithUnknownKeychainIdFails() async throws {
    var (input, admin) = try await prepare()
    input.keychainId = .init()

    let output = try? await SaveKey.resolve(with: input, in: admin.context)
    expect(output).toBeNil()
  }

  func testUpdateKeyRecord() async throws {
    var (input, admin) = try await prepare()
    let key = try await self.db.create(Key(keychainId: admin.keychain.id, key: .mock))

    input.isNew = false
    input.id = key.id
    input.comment = "updated comment"
    input.key = .skeleton(scope: .bundleId("com.updated"))

    let output = try await SaveKey.resolve(with: input, in: admin.context)
    expect(output).toEqual(.success)

    let updatedKey = try await self.db.find(key.id)
    expect(updatedKey.comment).toEqual(input.comment)
    expect(updatedKey.key).toEqual(input.key)
    expect(sent.websocketMessages)
      .toEqual([.init(.userUpdated, to: .usersWith(keychain: admin.keychain.id))])
  }

  func testUpdateKeyRecordWithExpiration() async throws {
    var (input, admin) = try await prepare()
    let key = try await self.db.create(Key(keychainId: admin.keychain.id, key: .mock))

    input.isNew = false
    input.id = key.id
    input.comment = "updated comment"
    input.key = .skeleton(scope: .bundleId("com.updated"))
    input.expiration = Date(addingDays: 5)

    let output = try await SaveKey.resolve(with: input, in: admin.context)
    expect(output).toEqual(.success)

    let updatedKey = try await self.db.find(key.id)
    expect(updatedKey.comment).toEqual(input.comment)
    expect(updatedKey.key).toEqual(input.key)
    expect(updatedKey.deletedAt).not.toBeNil()
  }
}
