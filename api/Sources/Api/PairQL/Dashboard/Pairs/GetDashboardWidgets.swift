import DuetSQL
import Foundation
import Gertie
import PairQL

// deprecated: remove after 6/14/25
struct GetDashboardWidgets: Pair {
  static let auth: ClientAuth = .parent

  struct User: PairNestable {
    var id: Api.Child.Id
    var name: String
    var status: ChildComputerStatus
    var numDevices: Int
  }

  struct UserActivitySummary: PairNestable {
    var id: Api.Child.Id
    var name: String
    var numUnreviewed: Int
    var numReviewed: Int
  }

  struct UnlockRequest: PairNestable {
    var id: Api.UnlockRequest.Id
    var userId: Api.Child.Id
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
    let users = try await Api.Child.query()
      .where(.parentId == context.admin.id)
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

    let computerUsers = try await ComputerUser.query()
      .where(.childId |=| users.map(\.id))
      .all(in: context.db)

    let unlockRequests = try await Api.UnlockRequest.query()
      .where(.computerUserId |=| computerUsers.map(\.id))
      .where(.status == .enum(RequestStatus.pending))
      .all(in: context.db)

    let deviceToUserMap: [ComputerUser.Id: Api.Child] = computerUsers
      .reduce(into: [:]) { map, device in
        map[device.id] = users.first(where: { $0.id == device.childId })
      }

    async let keystrokes = KeystrokeLine.query()
      .where(.computerUserId |=| computerUsers.map(\.id))
      .where(.createdAt >= Date(subtractingDays: 14))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all(in: context.db)

    async let screenshots = Screenshot.query()
      .where(.computerUserId |=| computerUsers.map(\.id))
      .where(.createdAt >= Date(subtractingDays: 14))
      .orderBy(.createdAt, .desc)
      .withSoftDeleted()
      .all(in: context.db)

    async let notifications = context.admin.notifications(in: context.db)

    return try await .init(
      users: users.concurrentMap { user in try await .init(
        id: user.id,
        name: user.name,
        status: consolidatedChildComputerStatus(user.id, computerUsers),
        numDevices: computerUsers.filter { $0.childId == user.id }.count
      ) },
      userActivitySummaries: userActivitySummaries(
        users: users,
        map: deviceToUserMap,
        keystrokes: keystrokes,
        screenshots: screenshots
      ),
      unlockRequests: mapUnlockRequests(
        unlockRequests: unlockRequests,
        map: deviceToUserMap
      ),
      recentScreenshots: recentScreenshots(
        users: users,
        map: deviceToUserMap,
        screenshots: screenshots
      ),
      numAdminNotifications: notifications.count
    )
  }
}

// helpers

func mapUnlockRequests(
  unlockRequests: [Api.UnlockRequest],
  map: [ComputerUser.Id: Child]
) -> [GetDashboardWidgets.UnlockRequest] {
  unlockRequests.map { unlockRequest in
    .init(
      id: unlockRequest.id,
      userId: map[unlockRequest.computerUserId]?.id ?? .init(),
      userName: map[unlockRequest.computerUserId]?.name ?? "",
      target: unlockRequest.target ?? "",
      comment: unlockRequest.requestComment,
      createdAt: unlockRequest.createdAt
    )
  }
}

func recentScreenshots(
  users: [Child],
  map: [ComputerUser.Id: Child],
  screenshots: [Screenshot]
) -> [GetDashboardWidgets.RecentScreenshot] {
  users.compactMap { user in
    screenshots
      // TODO: show ios screenshots as well
      .first { $0.computerUserId.map { map[$0]?.id == user.id } ?? false }
      .map { .init(id: $0.id, userName: user.name, url: $0.url, createdAt: $0.createdAt) }
  }
}

func userActivitySummaries(
  users: [Child],
  map: [ComputerUser.Id: Child],
  keystrokes: [KeystrokeLine],
  screenshots: [Screenshot]
) -> [GetDashboardWidgets.UserActivitySummary] {
  users.map { user in
    // TODO: show ios screenshots as well
    let userScreenshots = screenshots
      .filter { $0.computerUserId.map { map[$0]?.id == user.id } ?? false }
    let userKeystrokes = keystrokes.filter { map[$0.computerUserId]?.id == user.id }
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
