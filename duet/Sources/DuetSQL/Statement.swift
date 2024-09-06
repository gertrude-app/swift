import Duet
import PostgresKit

public extension SQL {
  struct Statement: Equatable, Sendable {
    public enum Component: Equatable, Sendable {
      case sql(String)
      case binding(Postgres.Data)
    }

    var first: String
    var components: [Component] = []

    public init(_ first: String) {
      self.first = first
    }
  }
}

public extension SQL.Statement {
  internal static func update<M: Model>(_ model: M) -> SQL.Statement {
    var stmt = SQL.Statement("UPDATE \"\(M.tableName)\"\nSET ")
    let values = model.insertValues.mapKeys { M.columnName($0) }
    for (column, value) in values {
      if column == "id" || column == "created_at" {
        continue
      } else if column == "updated_at" {
        stmt.components.append(.sql("\"\(column)\" = "))
        stmt.components.append(.binding(.currentTimestamp))
        stmt.components.append(.sql(", "))
      } else {
        stmt.components.append(.sql("\"\(column)\" = "))
        stmt.components.append(.binding(value))
        stmt.components.append(.sql(", "))
      }
    }
    stmt.components.removeLast()
    stmt.components.append(.sql("\nWHERE "))
    stmt.components.append(contentsOf: SQL.WhereConstraint<M>.equals(.id, .id(model)).sql!)
    stmt.components.append(.sql("\nRETURNING *"))
    return stmt
  }

  internal static func create<M: Model>(_ models: [M]) -> SQL.Statement {
    let first = models[0]
    let insert = first.insertValues
    let sorted = insert.keys.map { ($0, M.columnName($0)) }.sorted { $0.1 < $1.1 }
    let colList: String = sorted.map(\.1).quotedList
    let columns: [M.ColumnName] = sorted.map(\.0)
    var stmt = SQL.Statement("INSERT INTO \"\(M.tableName)\"\n(\(colList))\nVALUES\n")
    for model in models {
      stmt.components.append(.sql("("))
      for column in columns {
        let value = model.insertValues[column]!
        stmt.components.append(.binding(value))
        stmt.components.append(.sql(", "))
      }
      stmt.components.removeLast()
      stmt.components.append(.sql(")"))
      stmt.components.append(.sql(", "))
    }
    stmt.components.removeLast()
    return stmt
  }

  internal static func select<M: Model>(
    _: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy order: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) -> SQL.Statement {
    .query(
      "SELECT * FROM",
      M.self,
      where: constraint,
      orderBy: order,
      limit: limit,
      offset: offset
    )
  }

  internal static func delete<M: Model>(
    _ Model: M.Type,
    where constraint: SQL.WhereConstraint<M>,
    orderBy order: SQL.Order<M>?,
    limit: Int?,
    offset: Int?
  ) -> SQL.Statement {
    var stmt = SQL.Statement.query(
      "DELETE FROM",
      M.self,
      where: constraint,
      orderBy: order,
      limit: limit,
      offset: offset
    )
    stmt.components.append(.sql("\nRETURNING id"))
    return stmt
  }

  internal static func softDelete<M: Model>(
    _ Model: M.Type,
    where constraint: SQL.WhereConstraint<M>,
    orderBy order: SQL.Order<M>?,
    limit: Int?,
    offset: Int?
  ) -> SQL.Statement {
    .query(
      initial: "UPDATE \"\(M.tableName)\"\nSET \"deleted_at\" = CURRENT_TIMESTAMP",
      M.self,
      where: constraint,
      orderBy: order,
      limit: limit,
      offset: offset
    )
  }

  internal static func count<M: Model>(
    _: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always
  ) -> SQL.Statement {
    .query("SELECT COUNT(*) FROM", M.self, where: constraint)
  }

  private static func query<M: Model>(
    _ query: String,
    _: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy order: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) -> SQL.Statement {
    .query(
      initial: "\(query) \"\(M.tableName)\"",
      M.self,
      where: constraint,
      orderBy: order,
      limit: limit,
      offset: offset
    )
  }

  private static func query<M: Model>(
    initial query: String,
    _: M.Type,
    where constraint: SQL.WhereConstraint<M> = .always,
    orderBy order: SQL.Order<M>? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) -> SQL.Statement {
    var stmt = SQL.Statement(query)
    if let whereSql = constraint.sql {
      stmt.components.append(.sql("\nWHERE "))
      stmt.components.append(contentsOf: whereSql)
    }
    if let order {
      stmt.components.append(.sql(
        "\nORDER BY \"\(M.columnName(order.column))\" \(order.direction.rawValue.uppercased())"
      ))
    }
    if let limit {
      stmt.components.append(.sql("\nLIMIT \(limit)"))
    }
    if let offset {
      stmt.components.append(.sql("\nOFFSET \(offset)"))
    }
    return stmt
  }

  var sql: SQLQueryString {
    var sql = SQLQueryString(stringLiteral: self.first)
    for component in self.components {
      switch component {
      case .sql(let fragment):
        sql += SQLQueryString(stringLiteral: fragment)
      case .binding(.date(.some(let date))):
        sql.appendInterpolation(expression: .date(date))
      case .binding(.date(.none)):
        sql.appendInterpolation(expression: .null)
      case .binding(.uuid(.some(let uuid))):
        sql.appendInterpolation(expression: .uuid(uuid.uuidString))
      case .binding(.uuid(.none)):
        sql.appendInterpolation(expression: .null)
      case .binding(.currentTimestamp):
        sql.appendInterpolation(expression: .currentTimestamp)
      case .binding(.id(let id)):
        sql.appendInterpolation(expression: .uuid(id.uuidId.uuidString))
      case .binding(.enum(.some(let customEnum))):
        sql.appendInterpolation(expression: .customEnum(customEnum.typeName, customEnum.rawValue))
      case .binding(.json(.some(let json))):
        sql.appendInterpolation(expression: .jsonb(json))
      case .binding(.json(.none)):
        sql.appendInterpolation(expression: .null)
      case .binding(let data):
        sql.appendInterpolation(bind: data.binding)
      }
    }
    return sql
  }

  /// NB: these are only for asserting in tests
  #if DEBUG
    var prepared: String {
      var bindNum = 1
      return self.first + components.map {
        switch $0 {
        case .sql(let sql):
          return sql
        case .binding:
          defer { bindNum += 1 }
          return "$\(bindNum)"
        }
      }.joined(separator: "")
    }

    var params: [Postgres.Data] {
      components.compactMap {
        switch $0 {
        case .sql:
          return nil
        case .binding(let data):
          return data
        }
      }
    }
  #endif
}

extension Sequence where Element == String {
  var list: String {
    joined(separator: ", ")
  }

  var quotedList: String {
    "\"\(joined(separator: "\", \""))\""
  }
}
