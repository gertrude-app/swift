import Tagged
import XCore

extension Tagged: RandomEmptyInitializing where RawValue == UUID {
  public init() {
    self.init(rawValue: .new())
  }
}

extension Tagged: UUIDStringable where RawValue == UUID {
  public var uuidString: String { rawValue.uuidString }
}

extension Tagged where RawValue == UUID {
  var lowercased: String { rawValue.lowercased }
}
