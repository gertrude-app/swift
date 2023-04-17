import Foundation
import Shared

public struct FilterKey: Equatable, Codable, Sendable {
  public let id: UUID
  public let key: Key

  public init(id: UUID = .init(), key: Key) {
    self.id = id
    self.key = key
  }
}
