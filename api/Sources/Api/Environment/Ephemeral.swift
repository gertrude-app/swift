import Dependencies
import Foundation

// @SCOPE: when the API restarts, we'll lose all magic links, eventually
// this should be backed by the DB or some sort of persistent storage
actor Ephemeral {
  @Dependency(\.uuid) private var uuid
  @Dependency(\.date.now) private var now
  @Dependency(\.verificationCode) private var verificationCode

  private var adminIds: [UUID: (adminId: Admin.Id, expiration: Date)] = [:]
  private var retrievedAdminIds: [UUID: Admin.Id] = [:]

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
    expiration: Date? = nil
  ) -> UUID {
    let token = self.uuid()
    self.adminIds[token] = (
      adminId: adminId,
      expiration: expiration ?? self.now + .minutes(60)
    )
    return token
  }

  func unexpiredAdminIdFromToken(_ token: UUID) -> Admin.Id? {
    switch self.adminIdFromToken(token) {
    case .notExpired(let adminId):
      adminId
    case .expired, .notFound, .previouslyRetrieved:
      nil
    }
  }

  func adminIdFromToken(_ token: UUID) -> AdminId {
    if let (adminId, expiration) = adminIds.removeValue(forKey: token) {
      if expiration > self.now {
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
    expiration: Date? = nil
  ) -> Int {
    let code = self.verificationCode.generate()
    self.pendingMethods[model.id] = (
      model: model,
      code: code,
      expiration: expiration ?? self.now + .minutes(60)
    )
    return code
  }

  func confirmPendingNotificationMethod(
    _ modelId: AdminVerifiedNotificationMethod.Id,
    _ code: Int
  ) -> AdminVerifiedNotificationMethod? {
    guard let (model, storedCode, expiration) = pendingMethods.removeValue(forKey: modelId),
          code == storedCode,
          expiration > self.now else {
      return nil
    }
    return model
  }

  private var pendingAppConnections: [Int: (userId: User.Id, expiration: Date)] = [:]

  func createPendingAppConnection(
    _ userId: User.Id,
    expiration: Date? = nil
  ) -> Int {
    let code = self.verificationCode.generate()
    if self.pendingAppConnections[code] != nil {
      return self.createPendingAppConnection(userId)
    }
    self.pendingAppConnections[code] = (
      userId: userId,
      expiration: expiration ?? self.now + .days(2)
    )
    return code
  }

  func getPendingAppConnection(_ code: Int) -> User.Id? {
    #if DEBUG
      if code == 999_999 { return AdminBetsy.Ids.jimmysId }
    #endif
    guard let (userId, expiration) = pendingAppConnections[code],
          expiration > self.now else {
      return nil
    }
    return userId
  }
}

// dependency

extension DependencyValues {
  var ephemeral: Ephemeral {
    get { self[Ephemeral.self] }
    set { self[Ephemeral.self] = newValue }
  }
}

extension Ephemeral: DependencyKey {
  public static var liveValue: Ephemeral {
    .init()
  }
}

#if DEBUG
  extension Ephemeral: TestDependencyKey {
    public static var testValue: Ephemeral {
      .init()
    }
  }
#endif
