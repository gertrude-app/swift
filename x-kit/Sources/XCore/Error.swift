import Foundation

public enum XCore {
  public enum Date {
    public enum Error: Swift.Error, Equatable, LocalizedError {
      case isoStringConversion(String)

      public var errorDescription: String? {
        switch self {
        case .isoStringConversion(let string):
          "Failed to create Date() from invalid ISO string `\(string)`"
        }
      }
    }
  }
}

public struct StringError: Error {
  public var message: String

  public init(_ message: String) {
    self.message = message
  }
}

public extension StringError {
  func merge(with other: StringError) -> StringError {
    .init("\(self.message)\n(+) \(other.message)")
  }
}

extension StringError: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.message = value
  }
}

public extension Result where Failure == StringError {
  static func failure(_ message: String) -> Self {
    .failure(.init(message))
  }
}
