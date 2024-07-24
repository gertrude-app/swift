public struct PqlError: Error, Codable, Equatable, Sendable {
  public var version = 1
  public var id: String
  public var requestId: String
  public var type: Kind
  public var userMessage: String?
  public var userAction: String?
  public var debugMessage: String
  public var entityName: String?
  public var showContactSupport: Bool
  public var dashboardTag: DashboardTag?
  public var appTag: AppTag?
  public var statusCode: Int

  public init(
    id: String,
    requestId: String,
    type: Kind,
    debugMessage: String,
    userMessage: String? = nil,
    userAction: String? = nil,
    entityName: String? = nil,
    dashboardTag: DashboardTag? = nil,
    appTag: AppTag? = nil,
    showContactSupport: Bool = false
  ) {
    self.id = id
    self.requestId = requestId
    self.type = type
    self.userMessage = userMessage
    self.userAction = userAction
    self.debugMessage = debugMessage
    self.entityName = entityName
    self.dashboardTag = dashboardTag
    self.appTag = appTag
    self.showContactSupport = showContactSupport
    self.statusCode = type.statusCode
  }
}

public extension PqlError {
  enum Kind: String, Codable, CaseIterable, Sendable {
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

  enum DashboardTag: String, Codable, CaseIterable, Sendable {
    case magicLinkTokenNotFound
    case slackVerificationFailed
    case emailAlreadyVerified
  }

  enum AppTag: String, Codable, CaseIterable, Sendable {
    case userTokenNotFound
    case connectionCodeNotFound
  }
}
