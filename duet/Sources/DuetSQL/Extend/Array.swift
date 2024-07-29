public extension Array where Element: Model {
  func first(orThrow error: Error = DuetSQLError.notFound("\(Element.self)")) throws -> Element {
    guard let first else { throw error }
    return first
  }
}
