import DuetSQL
import TypescriptPairQL

struct SaveUser: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct Input: TypescriptPairInput {
    var id: UUID
    var adminId: UUID
    var isNew: Bool
    var name: String
    var keyloggingEnabled: Bool
    var screenshotsEnabled: Bool
    var screenshotsResolution: Int
    var screenshotsFrequency: Int
    var keychainIds: [UUID]
  }
}

// resolver

extension SaveUser: PairResolver {
  static func resolve(for input: Input, in context: AdminContext) async throws -> Output {
    let user: User
    if input.isNew {
      user = try await Current.db.create(User(
        id: .init(input.id),
        adminId: .init(input.adminId),
        name: input.name,
        keyloggingEnabled: input.keyloggingEnabled,
        screenshotsEnabled: input.screenshotsEnabled,
        screenshotsResolution: input.screenshotsResolution,
        screenshotsFrequency: input.screenshotsFrequency
      ))
    } else {
      user = try await Current.db.find(User.Id(input.id))
      user.name = input.name
      user.keyloggingEnabled = input.keyloggingEnabled
      user.screenshotsEnabled = input.screenshotsEnabled
      user.screenshotsResolution = input.screenshotsResolution
      user.screenshotsFrequency = input.screenshotsFrequency
      try await Current.db.update(user)
    }

    let existing = try await user.keychains().map(\.id.rawValue)
    if existing.elementsEqual(input.keychainIds) {
      // TODO: dispatch event
      return .init(true)
    }

    try await Current.db.query(UserKeychain.self)
      .where(.userId == user.id)
      .delete()

    let pivots = input.keychainIds
      .map { UserKeychain(userId: user.id, keychainId: .init(rawValue: $0)) }

    try await Current.db.create(pivots)

    // TODO: dispatch event
    return .init(true)
  }
}
