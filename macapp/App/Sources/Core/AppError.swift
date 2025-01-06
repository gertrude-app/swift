import os.log

public struct AppError: Error, Equatable, Sendable {
  public var message: String

  public init(_ message: String) {
    self.message = message
  }

  public init(oslogging message: String, context: String? = nil) {
    if let context {
      os_log("[G•] AppError context: %{public}s, message: %{public}s", context, message)
    } else {
      os_log("[G•] AppError message: %{public}s", message)
    }
    self.message = message
  }
}

extension AppError: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.message = value
  }
}
