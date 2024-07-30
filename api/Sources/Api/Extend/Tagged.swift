import Foundation
import PairQL
import Tagged

extension Tagged: PairInput where RawValue == UUID {}

public extension Tagged where RawValue == UUID {
  init() {
    self.init(rawValue: Current.uuid())
  }
}
