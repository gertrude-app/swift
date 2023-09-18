import PairQL

extension Error {
  func userMessage(_ tags: [PqlError.AppTag: String] = [:], generic: String? = nil) -> String {
    let fallback =
      "Sorry, something went wrong. Please try again, or contact help if the problem persists."
    guard let pqlError = self as? PqlError else {
      return generic ?? fallback
    }
    if let appTag = pqlError.appTag, let message = tags[appTag] {
      return message
    } else if let userMessage = pqlError.userMessage {
      return userMessage
    } else {
      return generic ?? fallback
    }
  }
}
