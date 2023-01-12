import Foundation
import Shared

public struct FilterKey: Equatable, Codable {
  public let id: UUID
  public let type: Key

  public init(id: UUID, type: Key) {
    self.id = id
    self.type = type
  }
}
