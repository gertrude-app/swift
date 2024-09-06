import XCTest
import XExpect

@testable import DuetSQL

final class WhereConstraintTests: XCTestCase {
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

    for (constraint, expectedSQL, expectedParams) in cases {
      var statement = SQL.Statement("")
      statement.components.append(contentsOf: constraint.sql!)
      expect(statement.prepared).toEqual(expectedSQL)
      expect(statement.params).toEqual(expectedParams)
    }
  }
}
