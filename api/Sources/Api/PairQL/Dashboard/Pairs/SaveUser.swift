import DuetSQL
import Gertie
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
    var downtime: PlainTimeWindow?
    var keychains: [UserKeychain]
    var blockedApps: [UserBlockedApp.DTO]?

    struct UserKeychain: PairNestable {
      var id: Keychain.Id
      var schedule: RuleSchedule?
    }
  }
}

// resolver

extension SaveUser: Resolver {
  static func resolve(with input: Input, in context: AdminContext) async throws -> Output {
    var user: User
    if input.isNew {
      user = try await context.db.create(User(
        id: input.id,
        parentId: context.admin.id,
        name: input.name,
        // vvv--- these are our recommended defaults
        keyloggingEnabled: true,
        screenshotsEnabled: true,
        screenshotsResolution: 1000,
        screenshotsFrequency: 180,
        showSuspensionActivity: true,
        downtime: input.downtime
      ))
      let keychain = try await context.db.create(Keychain(
        parentId: context.admin.id,
        name: "\(input.name)’s Keychain",
        isPublic: false,
        description: """
        This keychain was created automatically as a default place for you to \
        add keys for \(input.name). Feel free to use it as is, change it, \
        delete it, or create as many other keychains as you like.
        """
      ))
      try await context.db.create(UserKeychain(childId: user.id, keychainId: keychain.id))
      dashSecurityEvent(.childAdded, "name: \(user.name)", in: context)
    } else {
      user = try await context.db.find(input.id)
      if let details = monitoringDecreased(user: user, input: input) {
        let detail = "for child: \(user.name), \(details)"
        dashSecurityEvent(.monitoringDecreased, detail, in: context)
      }
      user.name = input.name
      user.keyloggingEnabled = input.keyloggingEnabled
      user.screenshotsEnabled = input.screenshotsEnabled
      user.screenshotsResolution = input.screenshotsResolution
      user.screenshotsFrequency = max(10, input.screenshotsFrequency)
      user.showSuspensionActivity = input.showSuspensionActivity
      user.downtime = input.downtime
      try await context.db.update(user)

      if let blockedApps = input.blockedApps {
        let existing = try await user.blockedApps(in: context.db).map(\.dto)
        if !existing.elementsEqual(blockedApps) {
          dashSecurityEvent(.blockedAppsChanged, "child: \(user.name)", in: context)
          try await UserBlockedApp.query()
            .where(.childId == user.id)
            .delete(in: context.db)
          let models = blockedApps.map { UserBlockedApp(dto: $0, childId: user.id) }
          try await context.db.create(models)
        }
      }

      let existing = try await userKeychainSummaries(for: user.id, in: context.db)
        .map(\.userKeychain)
      if !existing.elementsEqual(input.keychains) {
        dashSecurityEvent(.keychainsChanged, "child: \(user.name)", in: context)

        try await UserKeychain.query()
          .where(.childId == user.id)
          .delete(in: context.db)

        let pivots = input.keychains.map { keychain in
          UserKeychain(
            childId: user.id,
            keychainId: keychain.id,
            schedule: keychain.schedule
          )
        }

        try await context.db.create(pivots)
      }
    }

    try await with(dependency: \.websockets)
      .send(.userUpdated, to: .user(user.id))
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

extension UserKeychainSummary {
  var userKeychain: SaveUser.Input.UserKeychain {
    .init(id: id, schedule: schedule)
  }
}
