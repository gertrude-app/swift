import PostgresKit
import Tagged
import XCTest
import XExpect

@testable import DuetSQL

final class SqlTests: XCTestCase {
  func testSelect() async throws {
    let stmt = try await select(Thing.self)

    let expected = """
    SELECT * FROM "things"
    """

    expect(stmt.prepared).toEqual(expected)
    expect(stmt.params).toEqual([])
  }

  func testSelectWithoutSoftDeleted() async throws {
    let stmt = try await select(Thing.self, withSoftDeleted: false)

    let expected = """
    SELECT * FROM "things"
    WHERE ("deleted_at" IS NULL OR "deleted_at" > $1)
    """

    expect(stmt.prepared).toEqual(expected)
    expect(stmt.params).toEqual([.currentTimestamp])
  }

  func testSelectAlwaysRemoved() async throws {
    let stmt = try await select(Thing.self)

    let expected = """
    SELECT * FROM "things"
    """

    expect(stmt.prepared).toEqual(expected)
    expect(stmt.params).toEqual([])
  }

  func testWhereClauses() async throws {
    var stmt = try await select(Thing.self, where: .string == "foo")
    var expected = """
    SELECT * FROM "things"
    WHERE "string" = $1
    """

    expect(stmt.prepared).toEqual(expected)
    expect(stmt.params).toEqual([.string("foo")])

    stmt = try await select(Thing.self, where: .isNull(.optionalInt))
    expected = """
    SELECT * FROM "things"
    WHERE "optional_int" IS NULL
    """

    expect(stmt.prepared).toEqual(expected)
    expect(stmt.params).toEqual([])

    stmt = try await select(Thing.self, where: .not(.isNull(.optionalInt)))
    expected = """
    SELECT * FROM "things"
    WHERE NOT "optional_int" IS NULL
    """

    expect(stmt.prepared).toEqual(expected)
    expect(stmt.params).toEqual([])

    stmt = try await select(Thing.self, where: .int < .int(42))
    expected = """
    SELECT * FROM "things"
    WHERE "int" < $1
    """

    expect(stmt.prepared).toEqual(expected)
    expect(stmt.params).toEqual([.int(42)])

    stmt = try await select(Thing.self, where: .int >= .int(42))
    expected = """
    SELECT * FROM "things"
    WHERE "int" >= $1
    """

    expect(stmt.prepared).toEqual(expected)
    expect(stmt.params).toEqual([.int(42)])

    let ids = [Thing.Id(.init()), Thing.Id(.init())]
    stmt = try await select(Thing.self, where: .id |=| ids)
    expected = """
    SELECT * FROM "things"
    WHERE "id" IN ($1, $2)
    """

    expect(stmt.prepared).toEqual(expected)
    expect(stmt.params).toEqual(ids.map { .uuid($0.rawValue) })
  }

  func testMultipleWheres() async throws {
    let stmt = try await select(
      Thing.self,
      where: .id == 123 .&& .int == 789,
      withSoftDeleted: true
    )

    let expected = """
    SELECT * FROM "things"
    WHERE ("id" = $1 AND "int" = $2)
    """

    expect(stmt.prepared).toEqual(expected)
    expect(stmt.params).toEqual([123, 789])
  }

  func testWhereInEmpty() async throws {
    let ids: [Thing.IdValue] = []

    let stmt = try await select(Thing.self, where: .id |=| ids)
    let expected = """
    SELECT * FROM "things"
    WHERE FALSE
    """

    expect(stmt.prepared).toEqual(expected)
    expect(stmt.params).toEqual([])
  }

  func testWhereInOneChangedToEquals() async throws {
    let ids = [Thing.Id(.init())]

    let stmt = try await select(Thing.self, where: .id |=| ids)
    let expected = """
    SELECT * FROM "things"
    WHERE "id" = $1
    """

    expect(stmt.prepared).toEqual(expected)
    expect(stmt.params).toEqual([.uuid(ids[0].rawValue)])
  }

  func testLimitOffset() async throws {
    let stmt = try await select(
      Thing.self,
      orderBy: .init(.string, .asc),
      limit: 2,
      offset: 3
    )

    let expected = """
    SELECT * FROM "things"
    ORDER BY "string" ASC
    LIMIT 2
    OFFSET 3
    """

    expect(stmt.prepared).toEqual(expected)
    expect(stmt.params).toEqual([])
  }

  func testCount() async throws {
    let client = TestClient()
    _ = try? await client.count(Thing.self)

    let expected = """
    SELECT COUNT(*) FROM "things"
    WHERE ("deleted_at" IS NULL OR "deleted_at" > $1)
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual([.currentTimestamp])
  }

  func testCountWhere() async throws {
    let client = TestClient()
    _ = try? await client.count(Thing.self, where: .string == "a")

    let expected = """
    SELECT COUNT(*) FROM "things"
    WHERE ("string" = $1 AND ("deleted_at" IS NULL OR "deleted_at" > $2))
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual(["a", .currentTimestamp])
  }

  func testCountWhereWithSoftDeleted() async throws {
    let client = TestClient()
    _ = try? await client.count(
      Thing.self,
      where: .string == "a",
      withSoftDeleted: true
    )

    let expected = """
    SELECT COUNT(*) FROM "things"
    WHERE "string" = $1
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual(["a"])
  }

  func testForceDelete() async throws {
    let client = TestClient()
    _ = try await client.forceDelete(Thing.self)

    let expected = """
    DELETE FROM "things"
    RETURNING id
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual([])
  }

  func testSoftDelete() async throws {
    let client = TestClient()
    _ = try await client.delete(all: Thing.self)

    let expected = """
    UPDATE "things"
    SET "deleted_at" = CURRENT_TIMESTAMP
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual([])
  }

  func testForceDeleteWithConstraint() async throws {
    let client = TestClient()
    _ = try await client.forceDelete(Thing.self, where: .id == 123)

    let expected = """
    DELETE FROM "things"
    WHERE "id" = $1
    RETURNING id
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual([123])
  }

  func testSoftDeleteWithConstraint() async throws {
    let client = TestClient()
    _ = try await client.delete(Thing.self, where: .id == 123)

    let expected = """
    UPDATE "things"
    SET "deleted_at" = CURRENT_TIMESTAMP
    WHERE "id" = $1
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual([123])
  }

  func testSoftDeleteById() async throws {
    let client = TestClient()
    let id: UUID = .init()
    _ = try await client.delete(Thing.self, byId: id)

    let expected = """
    UPDATE "things"
    SET "deleted_at" = CURRENT_TIMESTAMP
    WHERE "id" = $1
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual([.uuid(id)])
  }

  func testForceDeleteWithOrderByAndLimit() async throws {
    let client = TestClient()
    _ = try await client.forceDelete(
      Thing.self,
      where: .id == 123,
      orderBy: .init(.createdAt, .asc),
      limit: 1
    )

    let expected = """
    DELETE FROM "things"
    WHERE "id" = $1
    ORDER BY "created_at" ASC
    LIMIT 1
    RETURNING id
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual([123])
  }

  func testSoftDeleteWithOrderByAndLimit() async throws {
    let client = TestClient()
    _ = try await client.delete(
      Thing.self,
      where: .string == "a",
      orderBy: .init(.createdAt, .asc),
      limit: 1
    )

    let expected = """
    UPDATE "things"
    SET "deleted_at" = CURRENT_TIMESTAMP
    WHERE "string" = $1
    ORDER BY "created_at" ASC
    LIMIT 1
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual(["a"])
  }

  func testUpdateDeletedAt() async throws {
    let thing = LilThing(int: 3, deletedAt: .epoch)
    let client = TestClient()
    _ = try? await client.update(thing)

    let expected = """
    UPDATE "lil_things"
    SET "int" = $1, "deleted_at" = $2, "updated_at" = $3
    WHERE "id" = $4
    RETURNING *
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual([3, .date(.epoch), .currentTimestamp, .id(thing)])
  }

  func testCreate() async throws {
    let thing = LilThing(int: 3)

    let client = TestClient()
    _ = try await client.create([thing])

    let expected = """
    INSERT INTO "lil_things"
    ("created_at", "deleted_at", "id", "int", "updated_at")
    VALUES
    ($1, $2, $3, $4, $5)
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual([
      .currentTimestamp,
      .date(nil),
      .id(thing),
      .int(3),
      .currentTimestamp,
    ])
  }

  func testCreateTwo() async throws {
    let thing1 = LilThing(int: 1)
    let thing2 = LilThing(int: 2)

    let client = TestClient()
    _ = try await client.create([thing1, thing2])

    let expected = """
    INSERT INTO "lil_things"
    ("created_at", "deleted_at", "id", "int", "updated_at")
    VALUES
    ($1, $2, $3, $4, $5), ($6, $7, $8, $9, $10)
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual([
      .currentTimestamp,
      .date(nil),
      .id(thing1),
      .int(1),
      .currentTimestamp,
      .currentTimestamp,
      .date(nil),
      .id(thing2),
      .int(2),
      .currentTimestamp,
    ])
  }

  func testCreateOptionalHonest() async throws {
    let thing = OptLilThing(int: 3, string: "hi")

    let client = TestClient()
    _ = try await client.create([thing])

    let expected = """
    INSERT INTO "opt_lil_things"
    ("created_at", "id", "int", "string")
    VALUES
    ($1, $2, $3, $4)
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual([.currentTimestamp, .id(thing), 3, "hi"])
  }

  func testCreateOptionalNil() async throws {
    let thing = OptLilThing(int: nil, string: nil)

    let client = TestClient()
    _ = try await client.create([thing])

    let expected = """
    INSERT INTO "opt_lil_things"
    ("created_at", "id", "int", "string")
    VALUES
    ($1, $2, $3, $4)
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual([
      .currentTimestamp,
      .id(thing),
      .int(nil),
      .string(nil),
    ])
  }

  func testUpdate() async throws {
    let thing = LilThing(int: 5, createdAt: .epoch, updatedAt: .reference)

    let client = TestClient()
    _ = try? await client.update(thing)

    let expected = """
    UPDATE "lil_things"
    SET "int" = $1, "deleted_at" = $2, "updated_at" = $3
    WHERE "id" = $4
    RETURNING *
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual([5, .date(nil), .currentTimestamp, .id(thing)])
  }

  func testKitchenSinkInsert() async throws {
    let thing = Thing(
      string: "string",
      version: "version",
      int: 3,
      bool: false,
      customEnum: .foo,
      optionalCustomEnum: nil,
      optionalInt: 4,
      optionalString: nil
    )

    let client = TestClient()
    _ = try await client.create([thing])

    let expected = """
    INSERT INTO "things"
    ("bool", "created_at", "custom_enum", "id", "int", "optional_custom_enum", "optional_int", "optional_string", "string", "updated_at", "version")
    VALUES
    ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
    """

    expect(client.stmt.prepared).toEqual(expected)
    expect(client.stmt.params).toEqual([
      .bool(false),
      .currentTimestamp,
      .enum(Thing.CustomEnum.foo),
      .id(thing),
      .int(3),
      .enum(nil),
      .int(4),
      .string(nil),
      .string("string"),
      .currentTimestamp,
      .varchar("version"),
    ])
  }
}

// helpers

func select<M: Model>(
  _ Model: M.Type,
  where constraint: SQL.WhereConstraint<M> = .always,
  orderBy order: SQL.Order<M>? = nil,
  limit: Int? = nil,
  offset: Int? = nil,
  withSoftDeleted: Bool = true
) async throws -> SQL.Statement {
  let testClient = TestClient()
  _ = try? await testClient.select(
    M.self,
    where: constraint,
    orderBy: order,
    limit: limit,
    offset: offset,
    withSoftDeleted: withSoftDeleted
  )
  return testClient.stmt
}

final class TestClient: Client, @unchecked Sendable {
  private var stmts: [SQL.Statement] = []

  var stmt: SQL.Statement {
    if self.stmts.isEmpty {
      fatalError("No statement was executed")
    } else if self.stmts.count > 1 {
      fatalError("Multiple statements were executed")
    } else {
      return self.stmts[0]
    }
  }

  func execute(statement: SQL.Statement) async throws -> [SQLRow] {
    self.stmts.append(statement)
    return [TestDbRow()]
  }

  func execute<M: Model>(statement: SQL.Statement, returning: M.Type) async throws -> [M] {
    self.stmts.append(statement)
    throw TestError()
  }

  func execute(raw: SQLQueryString) async throws -> [SQLRow] {
    fatalError("TestClient.execute(raw:) not implemented")
  }
}

public extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
}

private struct TestError: Error {}

private struct TestDbRow: SQLRow {
  var allColumns: [String] = []

  func contains(column: String) -> Bool {
    true
  }

  func decodeNil(column: String) throws -> Bool {
    true
  }

  func decode<D: Decodable>(column: String, as: D.Type) throws -> D {
    try JSONDecoder().decode(D.self, from: String(column).data(using: .utf8)!)
  }
}
