import Dependencies
import Foundation

// @SCOPE: when the API restarts, we'll lose all magic links, eventually
// this should be backed by the DB or some sort of persistent storage
actor Ephemeral {
  private var adminIds: [UUID: (adminId: Admin.Id, expiration: Date)] = [:]
  private var retrievedAdminIds: [UUID: Admin.Id] = [:]

  @Dependency(\.uuid) private var uuid

  enum AdminId: Equatable {
    case notFound
    case notExpired(Admin.Id)
    case expired(Admin.Id)
    case previouslyRetrieved(Admin.Id)

    var notExpired: Admin.Id? {
      guard case .notExpired(let adminId) = self else { return nil }
      return adminId
    }
  }

  func createAdminIdToken(
    _ adminId: Admin.Id,
    expiration: Date = Current.date() + ONE_HOUR
  ) -> UUID {
    let token = self.uuid()
    self.adminIds[token] = (adminId: adminId, expiration: expiration)
    return token
  }

  func unexpiredAdminIdFromToken(_ token: UUID) -> Admin.Id? {
    switch self.adminIdFromToken(token) {
    case .notExpired(let adminId):
      return adminId
    case .expired, .notFound, .previouslyRetrieved:
      return nil
    }
  }

  func adminIdFromToken(_ token: UUID) -> AdminId {
    if let (adminId, expiration) = adminIds.removeValue(forKey: token) {
      if expiration > Current.date() {
        self.retrievedAdminIds[token] = adminId
        return .notExpired(adminId)
      } else {
        // put back, so if they try again, they know it's expired, not missing
        self.adminIds[token] = (adminId, expiration)
        return .expired(adminId)
      }
    } else if let adminId = retrievedAdminIds[token] {
      return .previouslyRetrieved(adminId)
    } else {
      return .notFound
    }
  }

  private var pendingMethods: [AdminVerifiedNotificationMethod.Id: (
    model: AdminVerifiedNotificationMethod,
    code: Int,
    expiration: Date
  )] = [:]

  func createPendingNotificationMethod(
    _ model: AdminVerifiedNotificationMethod,
    expiration: Date = Current.date() + ONE_HOUR
  ) -> Int {
    let code = Current.verificationCode.generate()
    self.pendingMethods[model.id] = (model: model, code: code, expiration: expiration)
    return code
  }

  func confirmPendingNotificationMethod(
    _ modelId: AdminVerifiedNotificationMethod.Id,
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
    expiration: Date = Current.date() + ONE_HOUR
  ) -> Int {
    let code = Current.verificationCode.generate()
    if self.pendingAppConnections[code] != nil {
      return self.createPendingAppConnection(userId)
    }
    self.pendingAppConnections[code] = (userId: userId, expiration: expiration)
    return code
  }

  func getPendingAppConnection(_ code: Int) -> User.Id? {
    #if DEBUG
      if code == 999_999 { return AdminBetsy.Ids.jimmysId }
    #endif
    guard let (userId, expiration) = pendingAppConnections[code],
          expiration > Current.date() else {
      return nil
    }
    return userId
  }
}

private let ONE_HOUR: TimeInterval = 60 * 60
