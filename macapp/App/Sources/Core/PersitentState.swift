public protocol PersistentState: Codable, Equatable {
  static var version: Int { get }
}

public extension PersistentState {
  static var storageKey: String { "persistent.state.v\(version)" }
}
