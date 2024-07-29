public extension SQL {

  enum WhereConstraint<M: Model>: Equatable, Sendable {
    case equals(M.ColumnName, Postgres.Data)
    case lessThan(M.ColumnName, Postgres.Data)
    case greaterThan(M.ColumnName, Postgres.Data)
    case lessThanOrEqualTo(M.ColumnName, Postgres.Data)
    case greaterThanOrEqualTo(M.ColumnName, Postgres.Data)
    case `in`(M.ColumnName, [Postgres.Data])
    case isNull(M.ColumnName)
    case like(M.ColumnName, String)
    case ilike(M.ColumnName, String)
    case always
    case never
    indirect case or(WhereConstraint<M>, WhereConstraint<M>)
    indirect case and(WhereConstraint<M>, WhereConstraint<M>)
    indirect case not(WhereConstraint<M>)

    public func isSatisfied(by model: M) -> Bool {
      switch self {
      case .not(let constraint):
        return !constraint.isSatisfied(by: model)
      case .equals(let column, let data):
        return model.postgresData(for: column) == data
      case .in(let column, let values):
        let data = model.postgresData(for: column)
        return values.contains { value in data == value }
      case .isNull(let column):
        return model.postgresData(for: column).holdsNull
      case .like(let column, let pattern):
        guard case .string(.some(let string)) = model.postgresData(for: column) else {
          return false
        }
        let regex = "^" + pattern.replacingOccurrences(of: "%", with: ".*") + "$"
        return string.range(of: regex, options: .regularExpression) != nil
      case .ilike(let column, let pattern):
        guard case .string(.some(let string)) = model.postgresData(for: column) else {
          return false
        }
        let regex = "^" + pattern.replacingOccurrences(of: "%", with: ".*") + "$"
        return string.lowercased().range(of: regex, options: .regularExpression) != nil
      case .or(let lhs, let rhs):
        return lhs.isSatisfied(by: model) || rhs.isSatisfied(by: model)
      case .and(let lhs, let rhs):
        return lhs.isSatisfied(by: model) && rhs.isSatisfied(by: model)
      case .lessThan(let column, let data):
        let colData = model.postgresData(for: column)
        return colData < data
      case .greaterThan(let column, let data):
        let colData = model.postgresData(for: column)
        return colData > data
      case .lessThanOrEqualTo(let column, let data):
        let colData = model.postgresData(for: column)
        return colData <= data
      case .greaterThanOrEqualTo(let column, let data):
        let colData = model.postgresData(for: column)
        return colData >= data
      case .always:
        return true
      case .never:
        return false
      }
    }

    public static var notSoftDeleted: WhereConstraint<M> {
      if let deletedAt = try? M.column("deleted_at") {
        return WhereConstraint<M>.isNull(deletedAt) .|| deletedAt > .currentTimestamp
      }
      return .always
    }

    public var andNotSoftDeleted: WhereConstraint<M> {
      self .&& .notSoftDeleted
    }

    func sql(boundTo bindings: inout [Postgres.Data]) -> String {
      switch self {
      case .not(let constraint):
        return "NOT \(constraint.sql(boundTo: &bindings))"
      case .isNull(let column):
        return "\"\(M.columnName(column))\" IS NULL"
      case .equals(let column, let value):
        bindings.append(value)
        return "\"\(M.columnName(column))\" = $\(bindings.count)"
      case .lessThan(let column, let value):
        bindings.append(value)
        return "\"\(M.columnName(column))\" < $\(bindings.count)"
      case .greaterThan(let column, let value):
        bindings.append(value)
        return "\"\(M.columnName(column))\" > $\(bindings.count)"
      case .lessThanOrEqualTo(let column, let value):
        bindings.append(value)
        return "\"\(M.columnName(column))\" <= $\(bindings.count)"
      case .greaterThanOrEqualTo(let column, let value):
        bindings.append(value)
        return "\"\(M.columnName(column))\" >= $\(bindings.count)"
      case .in(let column, let values):
        guard !values.isEmpty else {
          return WhereConstraint<M>.never.sql(boundTo: &bindings)
        }
        var placeholders: [String] = []
        for value in values {
          bindings.append(value)
          placeholders.append("$\(bindings.count)")
        }
        return "\"\(M.columnName(column))\" IN (\(placeholders.list))"
      case .and(.never, _), .and(_, .never):
        return WhereConstraint<M>.never.sql(boundTo: &bindings)
      case .and(let lhs, .always):
        return lhs.sql(boundTo: &bindings)
      case .and(.always, let rhs):
        return rhs.sql(boundTo: &bindings)
      case .and(let lhs, let rhs):
        return "(\(lhs.sql(boundTo: &bindings)) AND \(rhs.sql(boundTo: &bindings)))"
      case .or(let lhs, let rhs):
        return "(\(lhs.sql(boundTo: &bindings)) OR \(rhs.sql(boundTo: &bindings)))"
      case .like(let column, let pattern):
        bindings.append(.string(pattern))
        return "\"\(M.columnName(column))\" LIKE $\(bindings.count)"
      case .ilike(let column, let pattern):
        bindings.append(.string(pattern))
        return "\"\(M.columnName(column))\" ILIKE $\(bindings.count)"
      case .always:
        return "TRUE"
      case .never:
        return "FALSE"
      }
    }
  }
}

// operators

public func + <M: Model>(
  lhs: SQL.WhereConstraint<M>,
  rhs: SQL.WhereConstraint<M>
) -> SQL.WhereConstraint<M> {
  if lhs == .always {
    return rhs
  } else if rhs == .always {
    return lhs
  } else {
    return .and(lhs, rhs)
  }
}

public func < <M: Model>(
  lhs: M.ColumnName,
  rhs: Postgres.Data
) -> SQL.WhereConstraint<M> {
  .lessThan(lhs, rhs)
}

public func <= <M: Model>(
  lhs: M.ColumnName,
  rhs: Postgres.Data
) -> SQL.WhereConstraint<M> {
  .lessThanOrEqualTo(lhs, rhs)
}

public func > <M: Model>(
  lhs: M.ColumnName,
  rhs: Postgres.Data
) -> SQL.WhereConstraint<M> {
  .greaterThan(lhs, rhs)
}

public func >= <M: Model>(
  lhs: M.ColumnName,
  rhs: Postgres.Data
) -> SQL.WhereConstraint<M> {
  .greaterThanOrEqualTo(lhs, rhs)
}

public func < <M: Model>(
  lhs: M.ColumnName,
  rhs: Date
) -> SQL.WhereConstraint<M> {
  .lessThan(lhs, .date(rhs))
}

public func <= <M: Model>(
  lhs: M.ColumnName,
  rhs: Date
) -> SQL.WhereConstraint<M> {
  .lessThanOrEqualTo(lhs, .date(rhs))
}

public func > <M: Model>(
  lhs: M.ColumnName,
  rhs: Date
) -> SQL.WhereConstraint<M> {
  .greaterThan(lhs, .date(rhs))
}

public func >= <M: Model>(
  lhs: M.ColumnName,
  rhs: Date
) -> SQL.WhereConstraint<M> {
  .greaterThanOrEqualTo(lhs, .date(rhs))
}

public func == <M: Model>(
  lhs: M.ColumnName,
  rhs: Postgres.Data
) -> SQL.WhereConstraint<M> {
  .equals(lhs, rhs)
}

public func == <M: Model>(
  lhs: M.ColumnName,
  rhs: UUIDStringable
) -> SQL.WhereConstraint<M> {
  .equals(lhs, .uuid(rhs))
}

public func == <M: Model>(
  lhs: M.ColumnName,
  rhs: PostgresEnum
) -> SQL.WhereConstraint<M> {
  .equals(lhs, .enum(rhs))
}

public func == <M: Model>(
  lhs: M.ColumnName,
  rhs: String
) -> SQL.WhereConstraint<M> {
  .equals(lhs, .string(rhs))
}

public func != <M: Model>(
  lhs: M.ColumnName,
  rhs: Postgres.Data
) -> SQL.WhereConstraint<M> {
  .not(.equals(lhs, rhs))
}

public func != <M: Model>(
  lhs: M.ColumnName,
  rhs: UUIDStringable
) -> SQL.WhereConstraint<M> {
  .not(.equals(lhs, .uuid(rhs)))
}

public func != <M: Model>(
  lhs: M.ColumnName,
  rhs: PostgresEnum
) -> SQL.WhereConstraint<M> {
  .not(.equals(lhs, .enum(rhs)))
}

public func != <M: Model>(
  lhs: M.ColumnName,
  rhs: String
) -> SQL.WhereConstraint<M> {
  .not(.equals(lhs, .string(rhs)))
}

infix operator |=|

public func |=| <M: Model>(
  lhs: M.ColumnName,
  rhs: [UUIDStringable]
) -> SQL.WhereConstraint<M> {
  .in(lhs, rhs.map { .uuid($0) })
}

public func |=| <M: Model>(
  lhs: M.ColumnName,
  rhs: [M.IdValue]
) -> SQL.WhereConstraint<M> {
  .in(lhs, rhs.map { .uuid($0) })
}

public func |=| <M: Model>(
  lhs: M.ColumnName,
  rhs: [Postgres.Data]
) -> SQL.WhereConstraint<M> {
  .in(lhs, rhs)
}

infix operator .&&: AssignmentPrecedence

public func .&& <M: Model>(
  lhs: SQL.WhereConstraint<M>,
  rhs: SQL.WhereConstraint<M>
) -> SQL.WhereConstraint<M> {
  .and(lhs, rhs)
}

infix operator .||: AssignmentPrecedence

public func .|| <M: Model>(
  lhs: SQL.WhereConstraint<M>,
  rhs: SQL.WhereConstraint<M>
) -> SQL.WhereConstraint<M> {
  .or(lhs, rhs)
}

infix operator |!=|

public func |!=| <M: Model>(
  lhs: M.ColumnName,
  rhs: [M.IdValue]
) -> SQL.WhereConstraint<M> {
  .not(.in(lhs, rhs.map { .uuid($0) }))
}

public func |!=| <M: Model>(
  lhs: M.ColumnName,
  rhs: [Postgres.Data]
) -> SQL.WhereConstraint<M> {
  .not(.in(lhs, rhs))
}

public func |!=| <M: Model>(
  lhs: M.ColumnName,
  rhs: [PostgresEnum]
) -> SQL.WhereConstraint<M> {
  .not(.in(lhs, rhs.map { .enum($0) }))
}

infix operator <>

public func <> <M: Model>(
  lhs: M.ColumnName,
  rhs: Postgres.Data
) -> SQL.WhereConstraint<M> {
  .not(.equals(lhs, rhs))
}
