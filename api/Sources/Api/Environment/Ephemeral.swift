import Dependencies
import DuetSQL
import Foundation

actor Ephemeral {
  @Dependency(\.uuid) private var uuid
  @Dependency(\.date.now) private var now
  @Dependency(\.db) private var db
  @Dependency(\.env) private var env
  @Dependency(\.slack) private var slack
  @Dependency(\.logger) private var logger
  @Dependency(\.verificationCode) private var verificationCode

  struct Storage: Codable {
    struct ParentId: Codable {
      var parentId: Parent.Id
      var expiration: Date
    }

    struct ChildId: Codable {
      var childId: Child.Id
      var expiration: Date
    }

    struct PendingMethod: Codable {
      var model: Parent.NotificationMethod
      var code: Int
      var expiration: Date
    }

    var parentIds: [UUID: ParentId] = [:]
    var retrievedParentIds: [UUID: Parent.Id] = [:]
    var pendingAppConnections: [Int: ChildId] = [:]
    var pendingMethods: [Parent.NotificationMethod.Id: PendingMethod] = [:]
  }

  private var storage = Storage()

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
    defer { Task { await self.persistStorage() } }
    let token = self.uuid()
    self.storage.parentIds[token] = .init(
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
    defer { Task { await self.persistStorage() } }
    if let stored = self.storage.parentIds.removeValue(forKey: token) {
      if stored.expiration > self.now {
        self.storage.retrievedParentIds[token] = stored.parentId
        return .notExpired(stored.parentId)
      } else {
        // put back, so if they try again, they know it's expired, not missing
        self.storage.parentIds[token] = stored
        return .expired(stored.parentId)
      }
    } else if let parentId = self.storage.retrievedParentIds[token] {
      return .previouslyRetrieved(parentId)
    } else {
      return .notFound
    }
  }

  func createPendingNotificationMethod(
    _ model: Parent.NotificationMethod,
    expiration: Date? = nil
  ) -> Int {
    defer { Task { await self.persistStorage() } }
    let code = self.verificationCode.generate()
    self.storage.pendingMethods[model.id] = .init(
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
    defer { Task { await self.persistStorage() } }
    guard let stored = self.storage.pendingMethods.removeValue(forKey: modelId),
          code == stored.code,
          stored.expiration > self.now else {
      return nil
    }
    return stored.model
  }

  func createPendingAppConnection(
    _ childId: Child.Id,
    expiration: Date? = nil
  ) -> Int {
    defer { Task { await self.persistStorage() } }
    let code = self.verificationCode.generate()
    if self.storage.pendingAppConnections[code] != nil {
      return self.createPendingAppConnection(childId)
    }
    self.storage.pendingAppConnections[code] = .init(
      childId: childId,
      expiration: expiration ?? self.now + .days(2)
    )
    return code
  }

  func getPendingAppConnection(_ code: Int) -> Child.Id? {
    #if DEBUG
      if code == 999_999 { return AdminBetsy.Ids.jimmysId }
    #endif
    guard let stored = self.storage.pendingAppConnections[code],
          stored.expiration > self.now else {
      return nil
    }
    return stored.childId
  }
}

// extensions

extension Ephemeral {
  func persistStorage() async {
    guard let data = try? JSONEncoder().encode(self.storage),
          let json = String(data: data, encoding: .utf8) else {
      await self.slack.error("failed to encode ephemeral storage")
      return
    }
    _ = try? await self.storageQuery.delete(in: self.db)
    _ = try? await self.db.create(InterestingEvent(
      id: .init(UUID()),
      eventId: "store-ephemeral",
      kind: "system",
      context: "api",
      detail: json
    ))
  }

  func restoreStorage() async {
    guard let model = try? await self.storageQuery.first(in: self.db) else {
      if self.env.mode == .prod {
        await self.slack.error("no ephemeral storage found to restore")
      }
      return
    }

    guard let storage = try? JSONDecoder().decode(
      Storage.self,
      from: model.detail?.data(using: .utf8) ?? Data()
    ) else {
      await self.slack.error("failed to decode ephemeral storage")
      return
    }

    self.storage = storage
    self.logger.info("restored ephemeral storage")
    _ = try? await self.db.delete(model)
  }

  private var storageQuery: DuetQuery<InterestingEvent> {
    InterestingEvent.query()
      .where(.eventId == "store-ephemeral")
      .where(.context == "api")
      .where(.kind == "system")
  }
}

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
