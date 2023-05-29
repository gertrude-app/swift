public protocol PersistentState: Codable, Equatable {
  static var version: Int { get }
}

public extension PersistentState {
  static var currentStorageKey: String { "persistent.state.v\(version)" }
}
