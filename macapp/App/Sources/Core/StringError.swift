import os.log
import XCore

public extension StringError {
  init(oslogging message: String, context: String? = nil) {
    if let context {
      os_log("[G•] StringError, context: %{public}s, message: %{public}s", context, message)
    } else {
      os_log("[G•] StringError, message: %{public}s", message)
    }
    self.init(message)
  }
}
