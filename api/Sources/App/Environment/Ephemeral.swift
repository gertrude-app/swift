import Foundation

// @SCOPE: when the API restarts, we'll lose all magic links, eventually
// this should be backed by the DB or some sort of persistent storage
actor Ephemeral {
  private var magicLinks: [UUID: (adminId: Admin.Id, expiration: Date)] = [:]

  func createMagicLinkToken(
    _ adminId: Admin.Id,
    expiration: Date = Current.date() + TWENTY_MINUTES
  ) -> UUID {
    let token = UUID()
    magicLinks[token] = (adminId: adminId, expiration: expiration)
    return token
  }

  func adminIdFromMagicLinkToken(_ token: UUID) -> Admin.Id? {
    guard let (adminId, expiration) = magicLinks.removeValue(forKey: token),
          expiration > Current.date() else {
      return nil
    }
    return adminId
  }

  private var pendingMethods: [UUID: (
    model: AdminVerifiedNotificationMethod,
    code: Int,
    expiration: Date
  )] = [:]

  func createPendingNotificationMethod(
    _ model: AdminVerifiedNotificationMethod,
    expiration: Date = Current.date() + TWENTY_MINUTES
  ) -> Int {
    let code = Current.verificationCode.generate()
    pendingMethods[model.id.rawValue] = (model: model, code: code, expiration: expiration)
    return code
  }

  func confirmPendingNotificationMethod(
    _ modelId: UUID,
    _ code: Int
  ) -> AdminVerifiedNotificationMethod? {
    guard let (model, storedCode, expiration) = pendingMethods.removeValue(forKey: modelId),
          code == storedCode,
          expiration > Current.date() else {
      return nil
    }
    return model
  }

  private var pendingAppConnections: [Int: (userId: User.Id, expiration: Date)] = [:]

  func createPendingAppConnection(
    _ userId: User.Id,
    expiration: Date = Current.date() + TWENTY_MINUTES
  ) -> Int {
    let code = Current.verificationCode.generate()
    if pendingAppConnections[code] != nil {
      return createPendingAppConnection(userId)
    }
    pendingAppConnections[code] = (userId: userId, expiration: expiration)
    return code
  }

  func getPendingAppConnection(_ code: Int) -> User.Id? {
    guard let (userId, expiration) = pendingAppConnections[code],
          expiration > Current.date() else {
      return nil
    }
    return userId
  }
}

private let TWENTY_MINUTES: TimeInterval = 60 * 20

