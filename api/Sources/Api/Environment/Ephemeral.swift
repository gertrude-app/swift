import Dependencies
import Foundation

// @SCOPE: when the API restarts, we'll lose all magic links, eventually
// this should be backed by the DB or some sort of persistent storage
actor Ephemeral {
  @Dependency(\.uuid) private var uuid
  @Dependency(\.date.now) private var now
  @Dependency(\.verificationCode) private var verificationCode

  private var parentIds: [UUID: (parentId: Parent.Id, expiration: Date)] = [:]
  private var retrievedParentIds: [UUID: Parent.Id] = [:]

  enum ParentId: Equatable {
    case notFound
    case notExpired(Parent.Id)
    case expired(Parent.Id)
    case previouslyRetrieved(Parent.Id)

    var notExpired: Parent.Id? {
      guard case .notExpired(let parentId) = self else { return nil }
      return parentId
    }
  }

  func createParentIdToken(
    _ parentId: Parent.Id,
    expiration: Date? = nil
  ) -> UUID {
    let token = self.uuid()
    self.parentIds[token] = (
      parentId: parentId,
      expiration: expiration ?? self.now + .minutes(60)
    )
    return token
  }

  func unexpiredParentIdFromToken(_ token: UUID) -> Parent.Id? {
    switch self.parentIdFromToken(token) {
    case .notExpired(let parentId):
      parentId
    case .expired, .notFound, .previouslyRetrieved:
      nil
    }
  }

  func parentIdFromToken(_ token: UUID) -> ParentId {
    if let (parentId, expiration) = self.parentIds.removeValue(forKey: token) {
      if expiration > self.now {
        self.retrievedParentIds[token] = parentId
        return .notExpired(parentId)
      } else {
        // put back, so if they try again, they know it's expired, not missing
        self.parentIds[token] = (parentId, expiration)
        return .expired(parentId)
      }
    } else if let parentId = retrievedParentIds[token] {
      return .previouslyRetrieved(parentId)
    } else {
      return .notFound
    }
  }

  private var pendingMethods: [Parent.NotificationMethod.Id: (
    model: Parent.NotificationMethod,
    code: Int,
    expiration: Date
  )] = [:]

  func createPendingNotificationMethod(
    _ model: Parent.NotificationMethod,
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
    _ modelId: Parent.NotificationMethod.Id,
    _ code: Int
  ) -> Parent.NotificationMethod? {
    guard let (model, storedCode, expiration) = pendingMethods.removeValue(forKey: modelId),
          code == storedCode,
          expiration > self.now else {
      return nil
    }
    return model
  }

  private var pendingAppConnections: [Int: (userId: Child.Id, expiration: Date)] = [:]

  func createPendingAppConnection(
    _ userId: Child.Id,
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

  func getPendingAppConnection(_ code: Int) -> Child.Id? {
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
