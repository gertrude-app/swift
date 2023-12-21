import XCTest
import XExpect

@testable import DuetSQL

final class WhereConstraintTests: XCTestCase {

  func testIsSatisfiedBy() throws {
    let cases: [(Thing, SQL.WhereConstraint<Thing>, Bool)] = [
      (.init(string: "bar"), .string == "bar", true),
      (.init(string: "not_bar"), .string == "bar", false),
      (.init(string: "bar"), .string <> "bar", false),
      (.init(string: "not_bar"), .string <> "bar", true),
      (.init(string: "bar"), .string |=| ["bar", "baz"], true),
      (.init(string: "bar"), .string |=| ["foo", "baz"], false),
      (.init(string: "bar"), .string |!=| ["bar", "baz"], false),
      (.init(string: "bar"), .string |!=| ["foo", "baz"], true),
      (.init(optionalString: "value"), .isNull(.optionalString), false),
      (.init(optionalString: nil), .isNull(.optionalString), true),
      (.init(optionalString: "value"), .not(.isNull(.optionalString)), true),
      (.init(optionalString: nil), .not(.isNull(.optionalString)), false),
      (.init(string: "b"), .string == "a" .|| .string == "b", true),
      (.init(string: "c"), .string == "a" .|| .string == "b", false),
      (.init(string: "b"), .string == "a" .&& .string == "b", false),
      (.init(string: "c"), .string == "a" .&& .string == "b", false),
      (.init(string: "b", int: 3), .string == "b" .&& .int == 3, true),
      (.init(string: "b", int: 3), .string == "b" .&& .int == 4, false),
      (.init(createdAt: .distantPast), .createdAt < .date(.distantFuture), true),
      (.init(createdAt: .distantFuture), .createdAt < .date(.distantPast), false),
      (.init(createdAt: .distantPast), .createdAt <= .date(.distantPast), true),
      (.init(createdAt: .distantPast), .createdAt >= .date(.distantPast), true),
      (.init(createdAt: .distantPast), .createdAt < .currentTimestamp, true),
      (.init(createdAt: .distantPast), .createdAt > .currentTimestamp, false),
      (.init(createdAt: .distantFuture), .createdAt > .currentTimestamp, true),
      (.init(createdAt: .distantFuture), .createdAt < .currentTimestamp, false),
    ]
    for (thing, constraint, expected) in cases {
      expect(constraint.isSatisfied(by: thing)).toEqual(expected)
      expect(thing.satisfies(constraint: constraint)).toEqual(expected)
    }
  }

  func testSQLFromWhereConstraint() throws {
    let cases: [(SQL.WhereConstraint<Thing>, String, [Postgres.Data])] = [
      (.like(.string, "%foo%"), #""string" LIKE $1"#, ["%foo%"]),
      (.ilike(.string, "%foo%"), #""string" ILIKE $1"#, ["%foo%"]),
      (.isNull(.optionalString), #""optional_string" IS NULL"#, []),
      (.not(.isNull(.optionalString)), #"NOT "optional_string" IS NULL"#, []),
      (.equals(.int, 3), #""int" = $1"#, [3]),
      (.int < 5, #""int" < $1"#, [5]),
      (.int < 5, #""int" < $1"#, [5]),
      (.int == 5, #""int" = $1"#, [5]),
      (.int <> 5, #"NOT "int" = $1"#, [5]),
      (.in(.string, ["jim", "jam"]), #""string" IN ($1, $2)"#, ["jim", "jam"]),
      (.string |=| ["jim", "jam"], #""string" IN ($1, $2)"#, ["jim", "jam"]),
      (.not(.in(.string, ["jim", "jam"])), #"NOT "string" IN ($1, $2)"#, ["jim", "jam"]),
      (
        .and(.isNull(.optionalString), .equals(.int, 3)),
        #"("optional_string" IS NULL AND "int" = $1)"#,
        [3]
      ),
      (
        .isNull(.optionalString) .&& .int == 3,
        #"("optional_string" IS NULL AND "int" = $1)"#,
        [3]
      ),
      (
        .isNull(.optionalString) .&& .int <> 3,
        #"("optional_string" IS NULL AND NOT "int" = $1)"#,
        [3]
      ),
      (
        .or(.isNull(.optionalString), .equals(.int, 3)),
        #"("optional_string" IS NULL OR "int" = $1)"#,
        [3]
      ),
      (
        .isNull(.optionalString) .|| .int == 3,
        #"("optional_string" IS NULL OR "int" = $1)"#,
        [3]
      ),
    ]

    for (constraint, expectedSQL, expectedBindings) in cases {
      var bindings: [Postgres.Data] = []
      expect(constraint.sql(boundTo: &bindings)).toEqual(expectedSQL)
      expect(bindings).toEqual(expectedBindings)
    }
  }
}
