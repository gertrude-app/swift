import Dependencies
import Foundation
import PairQL
import Tagged

extension Tagged: PairInput where RawValue == UUID {}

public extension Tagged where RawValue == UUID {
  init() {
    @Dependency(\.uuid) var uuid
    self.init(rawValue: uuid())
  }
}
