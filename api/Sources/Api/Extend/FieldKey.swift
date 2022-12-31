import Fluent

public extension FieldKey {
  init(_ stringLiteral: String) {
    self.init(stringLiteral: stringLiteral)
  }

  static let createdAt = FieldKey("created_at")
  static let updatedAt = FieldKey("updated_at")
  static let deletedAt = FieldKey("deleted_at")
}
