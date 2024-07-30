import Duet
import FluentSQL
import XCore

public enum SQL {
  public enum OrderDirection: Sendable {
    case asc
    case desc

    var sql: String {
      switch self {
      case .asc:
        return "ASC"
      case .desc:
        return "DESC"
      }
    }
  }

  public struct Order<M: Model>: Sendable {
    let column: M.ColumnName
    let direction: OrderDirection

    public init(column: M.ColumnName, direction: OrderDirection) {
      self.column = column
      self.direction = direction
    }

    public init(_ column: M.ColumnName, _ direction: OrderDirection) {
      self.column = column
      self.direction = direction
    }

    static func sql(_ order: Self?, prefixedBy prefix: String = "\n") -> String {
      guard let order = order else { return "" }
      return "\(prefix)ORDER BY \"\(M.columnName(order.column))\" \(order.direction.sql)"
    }
  }

  public struct PreparedStatement {
    let query: String
    let bindings: [Postgres.Data]
  }

  public static func delete<M: Model>(
    from Model: M.Type,
    where constraint: WhereConstraint<M> = .always,
    orderBy: Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) -> PreparedStatement {
    var bindings: [Postgres.Data] = []
    let WHERE = whereClause(constraint, bindings: &bindings)
    let ORDER_BY = Order<M>.sql(orderBy)
    let LIMIT = limit.sql(.limit)
    let OFFSET = offset.sql(.offset)
    let query = #"DELETE FROM "\#(Model.tableName)"\#(WHERE)\#(ORDER_BY)\#(LIMIT)\#(OFFSET);"#
    return PreparedStatement(query: query, bindings: bindings)
  }

  public static func softDelete<M: Model>(
    _: M.Type,
    where constraint: WhereConstraint<M> = .always
  ) -> PreparedStatement {
    update(table: M.tableName, set: ["deleted_at": .currentTimestamp], where: constraint)
  }

  private static func update<M: Model>(
    table: String,
    set values: [String: Postgres.Data],
    where constraint: WhereConstraint<M> = .always,
    returning: Postgres.Columns? = nil
  ) -> PreparedStatement {
    var bindings: [Postgres.Data] = []
    var setPairs: [String] = []

    for (column, value) in values.filter({ key, _ in key != "created_at" && key != "id" }) {
      bindings.append(value)
      setPairs.append("\"\(column)\" = $\(bindings.count)")
    }

    let WHERE = whereClause(constraint, bindings: &bindings)

    var RETURNING = ""
    if let returning = returning {
      RETURNING = "\nRETURNING \(returning.sql)"
    }

    let query = """
    UPDATE "\(table)"
    SET \(setPairs.list)\(WHERE)\(RETURNING);
    """

    return PreparedStatement(query: query, bindings: bindings)
  }

  public static func update<M: Model>(
    _: M.Type,
    set values: [M.ColumnName: Postgres.Data],
    where constraint: WhereConstraint<M> = .always,
    returning: Postgres.Columns? = nil
  ) -> PreparedStatement {
    update(
      table: M.tableName,
      set: values.mapKeys { M.columnName($0) },
      where: constraint,
      returning: returning
    )
  }

  public static func insert<M: Model>(
    into _: M.Type,
    values: [M.ColumnName: Postgres.Data]
  ) throws -> PreparedStatement {
    try insert(into: M.self, values: [values])
  }

  public static func insert<M: Model>(
    into _: M.Type,
    values columnValues: [[M.ColumnName: Postgres.Data]]
  ) throws -> PreparedStatement {
    let values = columnValues.map { $0.mapKeys { M.columnName($0) } }
    guard let firstRecord = values.first else {
      throw DuetSQLError.emptyBulkInsertInput
    }

    guard values.allSatisfy({ $0.keys.sorted() == firstRecord.keys.sorted() }) else {
      throw DuetSQLError.nonUniformBulkInsertInput
    }

    let columns = firstRecord.keys.sorted()
    var placeholderGroups: [String] = []
    var bindings: [Postgres.Data] = []

    for record in values {
      var placeholders: [String] = []
      for key in record.keys.sorted() {
        bindings.append(record[key]!)
        placeholders.append("$\(bindings.count)")
      }
      placeholderGroups.append("(\(placeholders.list))")
    }

    let query = """
    INSERT INTO "\(M.tableName)"
    (\(columns.quotedList))
    VALUES
    \(placeholderGroups.list);
    """

    return PreparedStatement(query: query, bindings: bindings)
  }

  public static func select<M: Model>(
    _ columns: Postgres.Columns,
    from _: M.Type,
    where constraint: WhereConstraint<M> = .always,
    orderBy order: Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) -> PreparedStatement {
    var bindings: [Postgres.Data] = []
    let WHERE = whereClause(constraint, bindings: &bindings)
    let ORDER_BY = Order<M>.sql(order)
    let LIMIT = limit.sql(.limit)
    let OFFSET = offset.sql(.offset)
    let query = """
    SELECT \(columns.sql) FROM "\(M.tableName)"\(WHERE)\(ORDER_BY)\(LIMIT)\(OFFSET);
    """
    return PreparedStatement(query: query, bindings: bindings)
  }

  public static func count<M: Model>(
    _: M.Type,
    where constraint: WhereConstraint<M> = .always
  ) -> PreparedStatement {
    var bindings: [Postgres.Data] = []
    let WHERE = whereClause(constraint, bindings: &bindings)
    let query = """
    SELECT COUNT(*) FROM "\(M.tableName)"\(WHERE);
    """
    return PreparedStatement(query: query, bindings: bindings)
  }

  @discardableResult
  public static func execute(
    _ statement: PreparedStatement,
    on db: SQLDatabase
  ) async throws -> [SQLRow] {
    // e.g. SELECT statements with no WHERE clause have
    // no bindings, and so can't be sent as a pg prepared statement
    if statement.bindings.isEmpty {
      if LOG_SQL {
        print("\n```SQL\n\(statement.query)\n```")
      }
      do {
        return try await db.raw("\(unsafeRaw: statement.query)").all()
      } catch {
        #if DEBUG && !canImport(XCTest)
          print("Error executing SQL (no bindings): \(String(reflecting: error))")
          print("Query: \(statement.query)")
        #endif
        throw error
      }
    }

    let types = statement.bindings.map(\.typeName).list
    let params = statement.bindings.map(\.param).list
    let key = [statement.query, types].joined()
    let name: String

    if let previouslyInsertedName = await PreparedStatements.shared.get(key) {
      name = previouslyInsertedName
    } else {
      let id = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
      name = "plan_\(id)"
      let insertPrepareSql = """
      PREPARE \(name)(\(types)) AS
      \(statement.query)
      """

      if LOG_SQL {
        print("\n```SQL\n\(insertPrepareSql)\n```")
      }

      await PreparedStatements.shared.set(name, forKey: key)
      do {
        _ = try await db.raw("\(unsafeRaw: insertPrepareSql)").all().get()
      } catch {
        #if DEBUG && !canImport(XCTest)
          print("Error preparing SQL: \(String(reflecting: error))")
          print("Query: \(statement.query)")
        #endif
        throw error
      }
    }

    if LOG_SQL {
      print("\n```SQL\n\(unPrepare(statement: statement))\n```")
    }

    do {
      return try await db.raw("\(unsafeRaw: "EXECUTE \(name)(\(params))")").all()
    } catch {
      #if DEBUG && !canImport(XCTest)
        print("Error executing prepared SQL: \(String(reflecting: error))")
      #endif
      throw error
    }
  }

  private static func whereClause<M: Model>(
    _ constraint: WhereConstraint<M>? = .always,
    bindings: inout [Postgres.Data],
    separatedBy: String = "\n"
  ) -> String {
    guard let constraint = constraint, constraint != .always else {
      return ""
    }
    return "\(separatedBy)WHERE \(constraint.sql(boundTo: &bindings))"
  }

  public static func resetPreparedStatements() async {
    await PreparedStatements.shared.reset()
  }
}

extension Sequence where Element == String {
  var list: String {
    joined(separator: ", ")
  }

  var quotedList: String {
    "\"\(joined(separator: "\", \""))\""
  }
}

private enum IntConstraint {
  case limit
  case offset
}

private extension Optional where Wrapped == Int {
  func sql(prefixedBy prefix: String = "\n", _ type: IntConstraint) -> String {
    guard let value = self else { return "" }
    switch type {
    case .limit:
      return "\(prefix)LIMIT \(value)"
    case .offset:
      return "\(prefix)OFFSET \(value)"
    }
  }
}

@globalActor private actor PreparedStatements {
  static let shared = PreparedStatements()

  var statements: [String: String] = [:]

  func get(_ key: String) -> String? {
    statements[key]
  }

  func set(_ value: String, forKey key: String) {
    statements[key] = value
  }

  func reset() {
    statements = [:]
  }
}

private func unPrepare(statement: SQL.PreparedStatement) -> String {
  var sql = statement.query
  for (index, binding) in statement.bindings.reversed().enumerated() {
    sql = sql.replacingOccurrences(of: "$\(statement.bindings.count - index)", with: binding.param)
  }
  return sql
}

private let LOG_SQL = ProcessInfo.processInfo.environment["DUET_LOG_SQL"] != nil
