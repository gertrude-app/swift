import DuetSQL
import Foundation
import Gertie
import PairQL

struct GetDashboardWidgets: Pair {
  static let auth: ClientAuth = .admin

  struct User: PairNestable {
    var id: Api.User.Id
    var name: String
    var isOnline: Bool
    var numDevices: Int
  }

  struct UserActivitySummary: PairNestable {
    var id: Api.User.Id
    var name: String
    var numUnreviewed: Int
    var numReviewed: Int
  }

  struct UnlockRequest: PairNestable {
    var id: Api.UnlockRequest.Id
    var userId: Api.User.Id
    var userName: String
    var target: String
    var comment: String?
    var createdAt: Date
  }

  struct RecentScreenshot: PairNestable {
    var id: Screenshot.Id
    var userName: String
    var url: String
    var createdAt: Date
  }

  struct Output: PairOutput {
    var users: [User]
    var userActivitySummaries: [UserActivitySummary]
    var unlockRequests: [UnlockRequest]
    var recentScreenshots: [RecentScreenshot]
    var numAdminNotifications: Int
  }
}

// resolver

extension GetDashboardWidgets: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let users = try await Api.User.query()
      .where(.adminId == context.admin.id)
      .all(in: context.db)

    guard !users.isEmpty else {
      return Output(
        users: [],
        userActivitySummaries: [],
        unlockRequests: [],
        recentScreenshots: [],
        numAdminNotifications: 0
      )
    }

    let userDevices = try await UserDevice.query()
      .where(.userId |=| users.map(\.id))
      .all(in: context.db)

    let unlockRequests = try await Api.UnlockRequest.query()
      .where(.userDeviceId |=| userDevices.map(\.id))
      .where(.status == .enum(RequestStatus.pending))
      .all(in: context.db)

    let deviceToUserMap: [UserDevice.Id: Api.User] = userDevices.reduce(into: [:]) { map, device in
      map[device.id] = users.first(where: { $0.id == device.userId })
    }

    async let keystrokes = KeystrokeLine.query()
      .where(.userDeviceId |=| userDevices.map(\.id))
      .where(.createdAt >= Date(subtractingDays: 14))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all(in: context.db)

    async let screenshots = Screenshot.query()
      .where(.userDeviceId |=| userDevices.map(\.id))
      .where(.createdAt >= Date(subtractingDays: 14))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all(in: context.db)

    async let notifications = context.admin.notifications(in: context.db)

    return try await .init(
      users: users.concurrentMap { user in .init(
        id: user.id,
        name: user.name,
        isOnline: try await userOnline(user.id, userDevices),
        numDevices: userDevices.filter { $0.userId == user.id }.count
      ) },
      userActivitySummaries: userActivitySummaries(
        users: users,
        map: deviceToUserMap,
        keystrokes: try await keystrokes,
        screenshots: try await screenshots
      ),
      unlockRequests: mapUnlockRequests(
        unlockRequests: unlockRequests,
        map: deviceToUserMap
      ),
      recentScreenshots: recentScreenshots(
        users: users,
        map: deviceToUserMap,
        screenshots: try await screenshots
      ),
      numAdminNotifications: try await notifications.count
    )
  }
}

// helpers

func userOnline(_ userId: User.Id, _ userDevices: [UserDevice]) async throws -> Bool {
  try await userDevices
    .filter { $0.userId == userId }
    .concurrentMap { await $0.isOnline() }
    .contains(true)
}

func mapUnlockRequests(
  unlockRequests: [Api.UnlockRequest],
  map: [UserDevice.Id: User]
) -> [GetDashboardWidgets.UnlockRequest] {
  unlockRequests.map { unlockRequest in
    .init(
      id: unlockRequest.id,
      userId: map[unlockRequest.userDeviceId]?.id ?? .init(),
      userName: map[unlockRequest.userDeviceId]?.name ?? "",
      target: unlockRequest.target ?? "",
      comment: unlockRequest.requestComment,
      createdAt: unlockRequest.createdAt
    )
  }
}

func recentScreenshots(
  users: [User],
  map: [UserDevice.Id: User],
  screenshots: [Screenshot]
) -> [GetDashboardWidgets.RecentScreenshot] {
  users.compactMap { user in
    screenshots
      .first { map[$0.userDeviceId]?.id == user.id }
      .map { .init(id: $0.id, userName: user.name, url: $0.url, createdAt: $0.createdAt) }
  }
}

func userActivitySummaries(
  users: [User],
  map: [UserDevice.Id: User],
  keystrokes: [KeystrokeLine],
  screenshots: [Screenshot]
) -> [GetDashboardWidgets.UserActivitySummary] {
  users.map { user in
    let userScreenshots = screenshots.filter { map[$0.userDeviceId]?.id == user.id }
    let userKeystrokes = keystrokes.filter { map[$0.userDeviceId]?.id == user.id }
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
