public protocol PersistentState: Codable, Equatable {
  static var version: Int { get }
}
