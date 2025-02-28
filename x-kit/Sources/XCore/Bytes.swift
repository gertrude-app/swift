public enum Bytes {
  public static var inKilobyte: Int { 1000 }
  public static var inKibibyte: Int { 1024 }
  public static var inMegabyte: Int { 1_000_000 }
  public static var inMebibyte: Int { 1_048_576 }
  public static var inGigabyte: Int { 1_000_000_000 }
  public static var inGibibyte: Int { 1_073_741_824 }
  public static var inTerabyte: Int { 1_000_000_000_000 }
  public static var inTebibyte: Int { 1_099_511_627_776 }
  public static var inPetabyte: Int { 1_000_000_000_000_000 }
  public static var inPebibyte: Int { 1_125_899_906_842_624 }

  public static func humanReadable(
    _ bytes: Int,
    decimalPlaces: Int? = nil,
    prefix: Prefix = .binary
  ) -> String {
    guard bytes > 0 else {
      return "0 bytes"
    }

    if bytes == 1 {
      return "1 byte"
    }

    var value = Double(bytes)
    var unitIndex = 0
    let divisor = prefix == .binary ? 1024.0 : 1000.0
    let units = prefix == .decimal
      ? ["bytes", "KB", "MB", "GB", "TB", "PB"]
      : ["bytes", "KiB", "MiB", "GiB", "TiB", "PiB"]

    while value >= divisor, unitIndex < units.count - 1 {
      value /= divisor
      unitIndex += 1
    }

    if unitIndex == 0 {
      return "\(Int(value)) \(units[unitIndex])"
    }

    let places = decimalPlaces ?? (value < 10 ? 1 : 0)
    return String(format: "%.\(places)f %@", value, units[unitIndex])
  }
}

public extension Bytes {
  enum Prefix {
    case binary
    case decimal
  }
}
