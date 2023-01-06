public extension Array where Element: Model {
  func first(orThrow error: Error = DuetSQLError.notFound) throws -> Element {
    guard let first = first else { throw error }
    return first
  }
}
