import Foundation

public extension UUID {
  var redacted: String {
    uuidString.lowercased().dropLast(12) + "xxxxxxxxxxxx"
  }
}
