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
      dashSecurityEvent(.childAdded, "name: \(user.name)", in: context)
    } else {
      user = try await User.find(input.id)
      if let details = monitoringDecreased(user: user, input: input) {
        let detail = "for child: \(user.name), \(details)"
        dashSecurityEvent(.monitoringDecreased, detail, in: context)
      }
      user.name = input.name
      user.keyloggingEnabled = input.keyloggingEnabled
      user.screenshotsEnabled = input.screenshotsEnabled
      user.screenshotsResolution = input.screenshotsResolution
      user.screenshotsFrequency = input.screenshotsFrequency
      user.showSuspensionActivity = input.showSuspensionActivity
      try await user.save()
    }

    let existing = try await user.keychains().map(\.id)
    if !existing.elementsEqual(input.keychainIds) {
      dashSecurityEvent(.keychainsChanged, "child: \(user.name)", in: context)

      try await UserKeychain.query()
        .where(.userId == user.id)
        .delete()

      let pivots = input.keychainIds
        .map { UserKeychain(userId: user.id, keychainId: $0) }

      try await Current.db.create(pivots)
    }

    try await Current.websockets.send(.userUpdated, to: .user(user.id))
    return .success
  }
}

// helpers

func monitoringDecreased(user: User, input: SaveUser.Input) -> String? {
  var parts: [String] = []
  if user.keyloggingEnabled, !input.keyloggingEnabled {
    parts.append("keylogging disabled")
  }
  if user.screenshotsEnabled, !input.screenshotsEnabled {
    parts.append("screenshots disabled")
  }
  if user.screenshotsResolution > input.screenshotsResolution {
    parts.append("screenshots resolution decreased")
  }
  if user.screenshotsFrequency < input.screenshotsFrequency {
    parts.append("screenshots frequency decreased")
  }
  if user.showSuspensionActivity, !input.showSuspensionActivity {
    parts.append("suspension activity visibility disabled")
  }
  return parts.isEmpty ? nil : parts.joined(separator: ", ")
}
