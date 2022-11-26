import Foundation

public enum XCore {
  public enum Date {
    public enum Error: Swift.Error, Equatable, LocalizedError {
      case isoStringConversion(String)

      public var errorDescription: String? {
        switch self {
        case .isoStringConversion(let string):
          return "Failed to create Date() from invalid ISO string `\(string)`"
        }
      }
    }
  }
}
