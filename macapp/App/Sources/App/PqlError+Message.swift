import PairQL

extension Error {
  func userMessage(_ tags: [PqlError.AppTag: String] = [:], generic: String? = nil) -> String {
    guard let pqlError = self as? PqlError else {
      return generic ?? "Please try again, or contact help if the problem persists."
    }
    if let appTag = pqlError.appTag, let message = tags[appTag] {
      return message
    } else if let userMessage = pqlError.userMessage {
      return userMessage
    } else {
      return generic ?? "Please try again, or contact help if the problem persists."
    }
  }
}
