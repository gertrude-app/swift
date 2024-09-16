import Tagged

extension Tagged: UUIDStringable where RawValue == UUID {
  public var uuidString: String { rawValue.uuidString }
}

extension Tagged where RawValue == UUID {
  var lowercased: String { rawValue.uuidString.lowercased() }
}
