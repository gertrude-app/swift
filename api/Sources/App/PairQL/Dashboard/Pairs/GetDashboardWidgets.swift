import DuetSQL
import Foundation
import Shared
import TypescriptPairQL

struct GetDashboardWidgets: TypescriptPair {
  static var auth: ClientAuth = .admin

  struct User: TypescriptNestable {
    var id: App.User.Id
    var userName: String
    var isOnline: Bool
  }

  struct UserActivitySummary: TypescriptNestable {
    var id: App.User.Id
    var name: String
    var numUnreviewed: Int
    var numReviewed: Int
  }

  struct UnlockRequest: TypescriptNestable {
    var id: App.UnlockRequest.Id
    var userId: App.User.Id
    var userName: String
    var target: String
    var comment: String?
    var createdAt: Date
  }

  struct RecentScreenshot: TypescriptNestable {
    var id: Screenshot.Id
    var userName: String
    var url: String
    var createdAt: Date
  }

  struct Output: TypescriptPairOutput {
    var users: [User]
    var userActivitySummaries: [UserActivitySummary]
    var unlockRequests: [UnlockRequest]
    var recentScreenshots: [RecentScreenshot]
  }
}

// resolver

extension GetDashboardWidgets: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let users = try await Current.db.query(App.User.self)
      .where(.adminId == context.admin.id)
      .all()

    guard !users.isEmpty else {
      return Output(
        users: [],
        userActivitySummaries: [],
        unlockRequests: [],
        recentScreenshots: []
      )
    }

    let devices = try await Current.db.query(Device.self)
      .where(.userId |=| users.map(\.id))
      .all()

    let unlockRequests = try await Current.db.query(App.UnlockRequest.self)
      .where(.deviceId |=| devices.map(\.id))
      .where(.status == .enum(RequestStatus.pending))
      .all()

    async let awaitedNetworkDecisions = Current.db.query(NetworkDecision.self)
      .where(.id |=| unlockRequests.map(\.networkDecisionId))
      .all()

    let deviceToUserMap: [Device.Id: App.User] = devices.reduce(into: [:]) { map, device in
      map[device.id] = users.first(where: { $0.id == device.userId })
    }

    async let keystrokes = Current.db.query(KeystrokeLine.self)
      .where(.deviceId |=| devices.map(\.id))
      .where(.createdAt >= Date(subtractingDays: 14))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all()

    async let screenshots = Current.db.query(Screenshot.self)
      .where(.deviceId |=| devices.map(\.id))
      .where(.createdAt >= Date(subtractingDays: 14))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all()

    let networkDecisions = try await awaitedNetworkDecisions

    return .init(
      users: users.map { user in .init(
        id: user.id,
        userName: user.name,
        isOnline: devices.filter { $0.userId == user.id && $0.isOnline }.count > 0
      ) },
      userActivitySummaries: userActivitySummaries(
        users: users,
        map: deviceToUserMap,
        keystrokes: try await keystrokes,
        screenshots: try await screenshots
      ),
      unlockRequests: mapUnlockRequests(
        unlockRequests: unlockRequests,
        map: deviceToUserMap,
        networkDecisions: networkDecisions
      ),
      recentScreenshots: recentScreenshots(
        users: users,
        map: deviceToUserMap,
        screenshots: try await screenshots
      )
    )
  }
}

// helpers

func mapUnlockRequests(
  unlockRequests: [App.UnlockRequest],
  map: [Device.Id: User],
  networkDecisions: [NetworkDecision]
) -> [GetDashboardWidgets.UnlockRequest] {
  unlockRequests.map { unlockRequest in
    .init(
      id: unlockRequest.id,
      userId: map[unlockRequest.deviceId]?.id ?? .init(),
      userName: map[unlockRequest.deviceId]?.name ?? "",
      target: networkDecisions
        .first(where: { $0.id == unlockRequest.networkDecisionId })?
        .target ?? "",
      comment: unlockRequest.requestComment,
      createdAt: unlockRequest.createdAt
    )
  }
}

func recentScreenshots(
  users: [User],
  map: [Device.Id: User],
  screenshots: [Screenshot]
) -> [GetDashboardWidgets.RecentScreenshot] {
  users.compactMap { user in
    screenshots
      .first { map[$0.deviceId]?.id == user.id }
      .map { .init(id: $0.id, userName: user.name, url: $0.url, createdAt: $0.createdAt) }
  }
}

func userActivitySummaries(
  users: [User],
  map: [Device.Id: User],
  keystrokes: [KeystrokeLine],
  screenshots: [Screenshot]
) -> [GetDashboardWidgets.UserActivitySummary] {
  users.map { user in
    let userScreenshots = screenshots.filter { map[$0.deviceId]?.id == user.id }
    let userKeystrokes = keystrokes.filter { map[$0.deviceId]?.id == user.id }
    return .init(
      id: user.id,
      name: user.name,
      numUnreviewed: coalesce(
        userScreenshots.filter(\.notDeleted),
        userKeystrokes.filter(\.notDeleted)
      ).count,
      numReviewed: coalesce(
        userScreenshots.filter(\.isDeleted),
        userKeystrokes.filter(\.isDeleted)
      ).count
    )
  }
}
