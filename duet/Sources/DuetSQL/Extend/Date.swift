import XCore

public extension Date {
  /// A string suitable for insertion as a postgres TIMESTAMP
  var postgresTimestampString: String {
    isoString
  }
}
