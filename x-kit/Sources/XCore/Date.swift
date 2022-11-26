import Foundation

public extension Date {
  /// An ISO date string w/ fractional seconds, suitable for interop with javascript
  var isoString: String {
    isoFormatter().string(from: self)
  }

  init?(fromIsoString isoString: String) throws {
    guard let date = isoFormatter().date(from: isoString) else {
      throw XCore.Date.Error.isoStringConversion(isoString)
    }
    self = date
  }

  init(fromIsoString isoString: String, orFallback fallback: Date) {
    if let date = try? Date(fromIsoString: isoString) {
      self = date
    } else {
      self = fallback
    }
  }

  init(addingDays numDays: Int, to reference: Date = Date()) {
    let calendar = Calendar.current
    let days = DateComponents(day: numDays)
    self = calendar.date(byAdding: days, to: reference)!
  }

  init(subtractingDays numDays: Int, from reference: Date = Date()) {
    let calendar = Calendar.current
    let days = DateComponents(day: -numDays)
    self = calendar.date(byAdding: days, to: reference)!
  }
}

// helpers

private func isoFormatter() -> ISO8601DateFormatter {
  return threadSharedObject(key: "com.x-kit.jaredh159.isoFormatter", create: createFormatter)
}

private func createFormatter() -> ISO8601DateFormatter {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [
    .withFullDate,
    .withFullTime,
    .withDashSeparatorInDate,
    .withColonSeparatorInTime,
    .withFractionalSeconds,
  ]
  return formatter
}
