import XCTest
import XExpect

@testable import DuetSQL

final class ThingStore: MemoryStore {
  public var things: [Thing.Id: Thing] = [:]
  func keyPath<M: Model>(to: M.Type) -> Models<M> {
    \ThingStore.things as! Models<M>
  }
}

final class MemoryClientTests: XCTestCase {
  func testSelectOffset() async throws {
    let client = MemoryClient(store: ThingStore())
    let thing1 = Thing()
    thing1.int = 0
    let thing2 = Thing()
    thing2.int = 1
    _ = try await client.create([thing1, thing2])

    let retrieved = try await client.select(
      Thing.self,
      orderBy: .init(.int, .asc),
      limit: 1,
      offset: 1
    )
    expect(retrieved.count).toEqual(1)
    expect(retrieved[0] === thing2).toBeTrue()
  }

  func testCreateAndSelect() async throws {
    let client = MemoryClient(store: ThingStore())
    let thing1 = Thing()
    _ = try await client.create(thing1)
    let retrieved = try await client.select(Thing.self)
    expect(retrieved[0] === thing1).toBeTrue()
  }

  func testSelectingSoftDeleted() async throws {
    let client = MemoryClient(store: ThingStore())
    let thing = Thing(deletedAt: .distantPast)
    _ = try await client.create(thing)
    let retrieved = try await client.select(Thing.self)
    expect(retrieved.count).toEqual(0)
  }

  func testDeletingSoftDeletable() async throws {
    let store = ThingStore()
    let client = MemoryClient(store: store)
    let thing = Thing()
    _ = try await client.create(thing)
    let retrieved = try await client.select(Thing.self)
    expect(retrieved.count).toEqual(1)
    expect(retrieved[0] === thing).toBeTrue()
    _ = try await client.delete(Thing.self, where: .id == .id(thing))
    let retrieved2 = try await client.select(Thing.self)
    expect(retrieved2.count).toEqual(0)
    expect(store.things.count).toEqual(1)
  }

  func testForceDeletingSoftDeletable() async throws {
    let store = ThingStore()
    let client = MemoryClient(store: store)
    let thing = Thing()
    _ = try await client.create(thing)
    // soft delete it
    try await client.delete(thing.id)
    expect(try store.models(of: Thing.self).count).toEqual(1)
    // now hard delete
    try await client.delete(thing.id, force: true)
    expect(try store.models(of: Thing.self).count).toEqual(0)
  }
}
