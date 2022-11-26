import XCTest

@testable import DuetSQL

final class ThingStore: MemoryStore {
  public var things: [Thing.Id: Thing] = [:]
  func keyPath<M: Model>(to: M.Type) -> Models<M> {
    return \ThingStore.things as! Models<M>
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
    XCTAssertEqual(retrieved.count, 1)
    XCTAssertTrue(retrieved[0] === thing2)
  }

  func testCreateAndSelect() async throws {
    let client = MemoryClient(store: ThingStore())
    let thing1 = Thing()
    _ = try await client.create(thing1)
    let retrieved = try await client.select(Thing.self)
    XCTAssertTrue(retrieved[0] === thing1)
  }

  func testSelectingSoftDeleted() async throws {
    let client = MemoryClient(store: ThingStore())
    let thing = Thing(deletedAt: .distantPast)
    _ = try await client.create(thing)
    let retrieved = try await client.select(Thing.self)
    XCTAssertEqual(retrieved.count, 0)
  }

  func testDeletingSoftDeletable() async throws {
    let store = ThingStore()
    let client = MemoryClient(store: store)
    let thing = Thing()
    _ = try await client.create(thing)
    let retrieved = try await client.select(Thing.self)
    XCTAssertEqual(retrieved.count, 1)
    XCTAssertTrue(retrieved[0] === thing)
    _ = try await client.delete(Thing.self, where: .id == .id(thing))
    let retrieved2 = try await client.select(Thing.self)
    XCTAssertEqual(retrieved2.count, 0)
    XCTAssertEqual(store.things.count, 1)
  }

  func testForceDeletingSoftDeletable() async throws {
    let store = ThingStore()
    let client = MemoryClient(store: store)
    let thing = Thing()
    _ = try await client.create(thing)
    // soft delete it
    try await client.delete(thing.id)
    XCTAssertEqual(try store.models(of: Thing.self).count, 1)
    // now hard delete
    try await client.delete(thing.id, force: true)
    XCTAssertEqual(try store.models(of: Thing.self).count, 0)
  }
}
