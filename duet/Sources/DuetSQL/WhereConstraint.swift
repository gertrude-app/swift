import Duet
import Foundation
import PostgresKit

public enum SQL {}

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
  }
}

public extension SQL.WhereConstraint {
  internal var sql: [SQL.Statement.Component]? {
    switch self {
    case .always:
      return nil
    case .never:
      return [.sql("FALSE")]
    case .equals(let column, let value):
      return [.sql("\"\(M.columnName(column))\" = "), .binding(value)]
    case .lessThan(let column, let value):
      return [.sql("\"\(M.columnName(column))\" < "), .binding(value)]
    case .greaterThan(let column, let value):
      return [.sql("\"\(M.columnName(column))\" > "), .binding(value)]
    case .lessThanOrEqualTo(let column, let value):
      return [.sql("\"\(M.columnName(column))\" <= "), .binding(value)]
    case .greaterThanOrEqualTo(let column, let value):
      return [.sql("\"\(M.columnName(column))\" >= "), .binding(value)]
    case .isNull(let column):
      return [.sql("\"\(M.columnName(column))\" IS NULL")]
    case .not(let inner):
      return inner.sql.map { [.sql("NOT ")] + $0 }
    case .and(.never, _), .and(_, .never):
      return [.sql("FALSE")]
    case .and(let lhs, .always):
      return lhs.sql
    case .and(.always, let rhs):
      return rhs.sql
    case .and(let lhs, let rhs):
      guard let lhsSql = lhs.sql, let rhsSql = rhs.sql else { return nil }
      return [.sql("(")] + lhsSql + [.sql(" AND ")] + rhsSql + [.sql(")")]
    case .or(_, .always):
      return nil
    case .or(.always, _):
      return nil
    case .or(let lhs, let rhs):
      guard let lhsSql = lhs.sql, let rhsSql = rhs.sql else { return nil }
      return [.sql("(")] + lhsSql + [.sql(" OR ")] + rhsSql + [.sql(")")]
    case .in(let column, let values):
      guard !values.isEmpty else {
        return [.sql("FALSE")]
      }
      if values.count == 1 {
        return SQL.WhereConstraint<M>.equals(column, values[0]).sql
      }
      var components: [SQL.Statement.Component] = [.sql("\"\(M.columnName(column))\" IN (")]
      for value in values {
        components.append(.binding(value))
        components.append(.sql(", "))
      }
      components.removeLast()
      components.append(.sql(")"))
      return components
    case .like(let column, let pattern):
      return [.sql("\"\(M.columnName(column))\" LIKE "), .binding(.string(pattern))]
    case .ilike(let column, let pattern):
      return [.sql("\"\(M.columnName(column))\" ILIKE "), .binding(.string(pattern))]
    }
  }

  static var notSoftDeleted: Self {
    if let deletedAt = try? M.column("deleted_at") {
      return .isNull(deletedAt) .|| deletedAt > .currentTimestamp
    }
    return .always
  }

  var andNotSoftDeleted: Self {
    self .&& .notSoftDeleted
  }

  static func withSoftDeleted(if included: Bool) -> Self {
    included ? .always : .notSoftDeleted
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
