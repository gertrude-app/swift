public extension Array where Element: Model {
  func firstOrThrowNotFound() throws -> Element {
    try firstOrThrow(DuetSQLError.notFound)
  }

  func firstOrThrow(_ error: Error) throws -> Element {
    guard let first = first else { throw error }
    return first
  }
}
