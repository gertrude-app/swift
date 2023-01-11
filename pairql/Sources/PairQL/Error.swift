public struct PqlError: Error, Codable {
  public var version = 1
  public var id: String
  public var requestId: String
  public var type: Kind
  public var userMessage: String?
  public var userAction: String?
  public var debugMessage: String
  public var entityName: String?
  public var showContactSupport: Bool
  public var tag: Tag?
  public var statusCode: Int

  public init(
    id: String,
    requestId: String,
    type: Kind,
    debugMessage: String,
    userMessage: String? = nil,
    userAction: String? = nil,
    entityName: String? = nil,
    tag: Tag? = nil,
    showContactSupport: Bool = false
  ) {
    self.id = id
    self.requestId = requestId
    self.type = type
    self.userMessage = userMessage
    self.userAction = userAction
    self.debugMessage = debugMessage
    self.entityName = entityName
    self.tag = tag
    self.showContactSupport = showContactSupport
    statusCode = type.statusCode
  }
}

public extension PqlError {
  enum Kind: String, Codable, CaseIterable {
    case notFound
    case badRequest
    case serverError
    case unauthorized
    case loggedOut

    var statusCode: Int {
      switch self {
      case .notFound: return 404
      case .badRequest: return 400
      case .serverError: return 500
      case .unauthorized: return 401
      case .loggedOut: return 401
      }
    }
  }

  enum Tag: String, Codable, CaseIterable {
    case magicLinkTokenNotFound
    case slackVerificationFailed
  }
}
