import Foundation
import Shared

public struct FilterKey: Equatable, Codable, Sendable {
  public let id: UUID
  public let key: Key

  public init(id: UUID, key: Key) {
    self.id = id
    self.key = key
  }
}
