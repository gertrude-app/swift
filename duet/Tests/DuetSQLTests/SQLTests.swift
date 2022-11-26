import Tagged
import XCTest

@testable import DuetSQL

final class SqlTests: XCTestCase {

  func testLimitOffset() throws {
    let stmt = SQL.select(
      .all,
      from: Thing.self,
      orderBy: .init(.string, .asc),
      limit: 2,
      offset: 3
    )

    let expectedQuery = """
    SELECT * FROM "things"
    ORDER BY "string" ASC
    LIMIT 2
    OFFSET 3;
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, [])
  }

  func testCountNoWhere() throws {
    let stmt = SQL.count(Thing.self)

    let expectedQuery = """
    SELECT COUNT(*) FROM "things";
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, [])
  }

  func testCountWhere() throws {
    let stmt = SQL.count(Thing.self, where: .string == "a")

    let expectedQuery = """
    SELECT COUNT(*) FROM "things"
    WHERE "string" = $1;
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, ["a"])
  }

  func testWhereIn() throws {
    let ids: [Thing.IdValue] = [
      .init(rawValue: UUID(uuidString: "6b9cfcdc-22a8-4c40-9ea8-eb409725dc34")!),
      .init(rawValue: UUID(uuidString: "c5bfe387-1e7a-426a-87ff-1aa472057acc")!),
    ]

    let stmt = SQL.select(.all, from: Thing.self, where: .id |=| ids)

    let expectedQuery = """
    SELECT * FROM "things"
    WHERE "id" IN ($1, $2);
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, ids.map { .uuid($0.rawValue) })
  }

  func testWhereInEmptyValues() throws {
    let ids: [Thing.IdValue] = []

    let stmt = SQL.select(.all, from: Thing.self, where: .id |=| ids)

    let expectedQuery = """
    SELECT * FROM "things"
    WHERE FALSE;
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, [])
  }

  func testAlwaysRemovedFromWhereClause() throws {
    var stmt = SQL.select(.all, from: Thing.self)

    var expectedQuery = """
    SELECT * FROM "things";
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, [])

    stmt = SQL.select(.all, from: Thing.self, where: .and(.always, .int == 3))

    expectedQuery = """
    SELECT * FROM "things"
    WHERE "int" = $1;
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, [3])
  }

  func testSimpleSelect() throws {
    let stmt = SQL.select(.all, from: Thing.self)

    let expectedQuery = """
    SELECT * FROM "things";
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, [])
  }

  func testSelectWithLimit() throws {
    let stmt = SQL.select(.all, from: Thing.self, limit: 4)

    let expectedQuery = """
    SELECT * FROM "things"
    LIMIT 4;
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, [])
  }

  func testSelectWithSingleWhere() throws {
    let stmt = SQL.select(.all, from: Thing.self, where: .id == 123)

    let expectedQuery = """
    SELECT * FROM "things"
    WHERE "id" = $1;
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, [123])
  }

  func testSelectWithMultipleWheres() throws {
    let stmt = SQL.select(.all, from: Thing.self, where: .id == 123 .&& .int == 789)

    let expectedQuery = """
    SELECT * FROM "things"
    WHERE ("id" = $1 AND "int" = $2);
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, [123, 789])
  }

  func testDeleteWithConstraint() throws {
    let stmt = SQL.delete(from: Thing.self, where: .id == 123)

    let expectedQuery = """
    DELETE FROM "things"
    WHERE "id" = $1;
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, [123])
  }

  func testDeleteWithOrderByAndLimit() throws {
    let stmt = SQL.delete(
      from: Thing.self,
      where: .id == 123,
      orderBy: .init(.createdAt, .asc),
      limit: 1
    )

    let expectedQuery = """
    DELETE FROM "things"
    WHERE "id" = $1
    ORDER BY "created_at" ASC
    LIMIT 1;
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, [123])
  }

  func testDeleteAll() throws {
    let stmt = SQL.delete(from: Thing.self)

    let expectedQuery = """
    DELETE FROM "things";
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, [])
  }

  func testBulkInsert() throws {
    let stmt = try SQL.insert(
      into: Thing.self,
      values: [[.int: 1, .optionalInt: 2], [.optionalInt: 4, .int: 3]]
    )

    let expectedQuery = """
    INSERT INTO "things"
    ("int", "optional_int")
    VALUES
    ($1, $2), ($3, $4);
    """

    XCTAssertEqual(stmt.query, expectedQuery)
    XCTAssertEqual(stmt.bindings, [1, 2, 3, 4])
  }

  func testUpdate() {
    let statement = SQL.update(
      Thing.self,
      set: [.optionalInt: 1, .bool: true],
      where: .string == "a"
    )

    let query = """
    UPDATE "things"
    SET "bool" = $1, "optional_int" = $2
    WHERE "string" = $3;
    """

    XCTAssertEqual(statement.query, query)
    XCTAssertEqual(statement.bindings, [true, 1, "a"])
  }

  func testUpdateWithoutWhere() {
    let statement = SQL.update(Thing.self, set: [.int: 1])

    let query = """
    UPDATE "things"
    SET "int" = $1;
    """

    XCTAssertEqual(statement.query, query)
    XCTAssertEqual(statement.bindings, [1])
  }

  func testUpdateReturning() {
    let statement = SQL.update(
      Thing.self,
      set: [.int: 1],
      where: .string == "a",
      returning: .all
    )

    let query = """
    UPDATE "things"
    SET "int" = $1
    WHERE "string" = $2
    RETURNING *;
    """

    XCTAssertEqual(statement.query, query)
    XCTAssertEqual(statement.bindings, [1, "a"])
  }

  func testBasicInsert() throws {
    let id = UUID()
    let statement = try SQL.insert(
      into: Thing.self,
      values: [.int: 33, .string: "lol", .id: .uuid(id)]
    )

    let query = """
    INSERT INTO "things"
    ("id", "int", "string")
    VALUES
    ($1, $2, $3);
    """

    XCTAssertEqual(statement.query, query)
    XCTAssertEqual(statement.bindings, [.uuid(id), 33, "lol"])
  }

  func testOptionalInts() throws {
    let statement = try SQL.insert(
      into: Thing.self,
      values: [.int: 22, .optionalInt: .int(nil)]
    )

    let query = """
    INSERT INTO "things"
    ("int", "optional_int")
    VALUES
    ($1, $2);
    """

    XCTAssertEqual(statement.query, query)
    XCTAssertEqual(statement.bindings, [22, .int(nil)])
  }

  func testOptionalStrings() throws {
    let statement = try SQL.insert(
      into: Thing.self,
      values: [.string: "howdy", .optionalString: .string(nil)]
    )

    let query = """
    INSERT INTO "things"
    ("optional_string", "string")
    VALUES
    ($1, $2);
    """

    XCTAssertEqual(statement.query, query)
    XCTAssertEqual(statement.bindings, [.string(nil), "howdy"])
  }

  func testEnums() throws {
    let statement = try SQL.insert(
      into: Thing.self,
      values: [
        .customEnum: .enum(Thing.CustomEnum.foo),
        .optionalCustomEnum: .enum(nil),
      ]
    )

    let query = """
    INSERT INTO "things"
    ("custom_enum", "optional_custom_enum")
    VALUES
    ($1, $2);
    """

    XCTAssertEqual(statement.query, query)
    XCTAssertEqual(statement.bindings, [.enum(Thing.CustomEnum.foo), .enum(nil)])
  }

  func testDates() throws {
    let date = try? Date(fromIsoString: "2021-12-14T17:16:16.896Z")!
    let statement = try SQL.insert(
      into: Thing.self,
      values: [.createdAt: .date(date), .updatedAt: .currentTimestamp]
    )

    let query = """
    INSERT INTO "things"
    ("created_at", "updated_at")
    VALUES
    ($1, $2);
    """

    XCTAssertEqual(statement.query, query)
    XCTAssertEqual(statement.bindings, [.date(date), .currentTimestamp])
  }

  func testUpdateRemovesIdAndCreatedAtFromInsertValues() throws {
    let thing = Thing(
      string: "foo",
      int: 1,
      bool: true,
      customEnum: .foo,
      optionalCustomEnum: .bar,
      optionalInt: 2,
      optionalString: "opt_foo"
    )
    let statement = SQL.update(Thing.self, set: thing.insertValues)

    let query = """
    UPDATE "things"
    SET "int" = $1, "updated_at" = $2, "bool" = $3, "optional_string" = $4, "custom_enum" = $5, "optional_custom_enum" = $6, "string" = $7, "optional_int" = $8;
    """

    XCTAssertEqual(statement.query, query)
  }
}
