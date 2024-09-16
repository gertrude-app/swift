import Duet

public extension SQL {
  enum OrderDirection: String, Sendable {
    case asc
    case desc
  }

  struct Order<M: Model>: Sendable {
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
  }
}
