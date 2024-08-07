import DuetSQL
import PairQL

struct SaveUser: Pair {
  static let auth: ClientAuth = .admin

  struct Input: PairInput {
    var id: User.Id
    var isNew: Bool
    var name: String
    var keyloggingEnabled: Bool
    var screenshotsEnabled: Bool
    var screenshotsResolution: Int
    var screenshotsFrequency: Int
    var showSuspensionActivity: Bool
    var keychainIds: [Keychain.Id]
  }
}

// resolver

extension SaveUser: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    var user: User
    if input.isNew {
      user = try await Current.db.create(User(
        id: input.id,
        adminId: context.admin.id,
        name: input.name,
        keyloggingEnabled: input.keyloggingEnabled,
        screenshotsEnabled: input.screenshotsEnabled,
        screenshotsResolution: input.screenshotsResolution,
        screenshotsFrequency: input.screenshotsFrequency,
        showSuspensionActivity: input.showSuspensionActivity
      ))
    } else {
      user = try await Current.db.find(input.id)
      user.name = input.name
      user.keyloggingEnabled = input.keyloggingEnabled
      user.screenshotsEnabled = input.screenshotsEnabled
      user.screenshotsResolution = input.screenshotsResolution
      user.screenshotsFrequency = input.screenshotsFrequency
      user.showSuspensionActivity = input.showSuspensionActivity
      try await Current.db.update(user)
    }

    let existing = try await user.keychains().map(\.id)
    if existing.elementsEqual(input.keychainIds) {
      try await Current.connectedApps.notify(.userUpdated(user.id))
      return .init(true)
    }

    try await Current.db.query(UserKeychain.self)
      .where(.userId == user.id)
      .delete()

    let pivots = input.keychainIds
      .map { UserKeychain(userId: user.id, keychainId: $0) }

    try await Current.db.create(pivots)

    try await Current.connectedApps.notify(.userUpdated(user.id))
    return .init(true)
  }
}
