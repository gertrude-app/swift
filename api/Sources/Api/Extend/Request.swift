import Vapor

extension Request {
  var id: String {
    if let value = logger[metadataKey: "request-id"],
       let uuid = UUID(uuidString: "\(value)") {
      return uuid.uuidString.lowercased()
    } else {
      return UUID().uuidString.lowercased()
    }
  }
}
