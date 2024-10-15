import Foundation

public struct FilterUserTypes: Codable, Sendable, Equatable {
  public var exempt: [uid_t]
  public var protected: [uid_t]

  public init(exempt: [uid_t], protected: [uid_t]) {
    self.exempt = exempt
    self.protected = protected
  }
}
