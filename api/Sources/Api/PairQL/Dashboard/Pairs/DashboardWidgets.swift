import DuetSQL
import Foundation
import Gertie
import PairQL

struct DashboardWidgets: Pair {
  static let auth: ClientAuth = .admin

  struct Child: PairNestable {
    var id: User.Id
    var name: String
    var status: ChildComputerStatus
    var numDevices: Int
  }

  struct ChildActivitySummary: PairNestable {
    var id: Api.User.Id
    var name: String
    var numUnreviewed: Int
    var numReviewed: Int
  }

  struct UnlockRequest: PairNestable {
    var id: Api.UnlockRequest.Id
    var childId: User.Id
    var childName: String
    var target: String
    var comment: String?
    var createdAt: Date
  }

  struct RecentScreenshot: PairNestable {
    var id: Screenshot.Id
    var childName: String
    var url: String
    var createdAt: Date
  }

  struct Announcement: PairNestable {
    var id: DashAnnouncement.Id
    var icon: String?
    var html: String
    var learnMoreUrl: String?
  }

  struct Output: PairOutput {
    var children: [Child]
    var childActivitySummaries: [ChildActivitySummary]
    var unlockRequests: [UnlockRequest]
    var recentScreenshots: [RecentScreenshot]
    var numParentNotifications: Int
    var announcement: Announcement?
  }
}

// resolver

extension DashboardWidgets: NoInputResolver {
  static func resolve(in context: AdminContext) async throws -> Output {
    let children = try await Api.User.query()
      .where(.parentId == context.admin.id)
      .all(in: context.db)

    guard !children.isEmpty else {
      return Output(
        children: [],
        childActivitySummaries: [],
        unlockRequests: [],
        recentScreenshots: [],
        numParentNotifications: 0,
        announcement: nil
      )
    }

    let computerUsers = try await ComputerUser.query()
      .where(.childId |=| children.map(\.id))
      .all(in: context.db)

    let unlockRequests = try await Api.UnlockRequest.query()
      .where(.computerUserId |=| computerUsers.map(\.id))
      .where(.status == .enum(RequestStatus.pending))
      .all(in: context.db)

    let computerToChildMap: [ComputerUser.Id: Api.User] = computerUsers
      .reduce(into: [:]) { map, device in
        map[device.id] = children.first(where: { $0.id == device.childId })
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

    async let announcement = try? await DashAnnouncement.query()
      .where(.parentId == context.admin.id)
      .orderBy(.createdAt, .asc)
      .first(in: context.db)

    return try await .init(
      children: children.concurrentMap { user in try await .init(
        id: user.id,
        name: user.name,
        status: consolidatedChildComputerStatus(user.id, computerUsers),
        numDevices: computerUsers.filter { $0.childId == user.id }.count
      ) },
      childActivitySummaries: userActivitySummaries(
        children: children,
        map: computerToChildMap,
        keystrokes: keystrokes,
        screenshots: screenshots
      ),
      unlockRequests: mapUnlockRequests(
        unlockRequests: unlockRequests,
        map: computerToChildMap
      ),
      recentScreenshots: recentScreenshots(
        children: children,
        map: computerToChildMap,
        screenshots: screenshots
      ),
      numParentNotifications: notifications.count,
      announcement: announcement.map { .init(
        id: $0.id,
        icon: $0.icon,
        html: $0.html,
        learnMoreUrl: $0.learnMoreUrl
      ) }
    )
  }
}

// helpers

private func mapUnlockRequests(
  unlockRequests: [Api.UnlockRequest],
  map: [ComputerUser.Id: User]
) -> [DashboardWidgets.UnlockRequest] {
  unlockRequests.map { unlockRequest in
    .init(
      id: unlockRequest.id,
      childId: map[unlockRequest.computerUserId]?.id ?? .init(),
      childName: map[unlockRequest.computerUserId]?.name ?? "",
      target: unlockRequest.target ?? "",
      comment: unlockRequest.requestComment,
      createdAt: unlockRequest.createdAt
    )
  }
}

private func recentScreenshots(
  children: [User],
  map: [ComputerUser.Id: User],
  screenshots: [Screenshot]
) -> [DashboardWidgets.RecentScreenshot] {
  children.compactMap { user in
    screenshots
      .first { map[$0.computerUserId]?.id == user.id }
      .map { .init(id: $0.id, childName: user.name, url: $0.url, createdAt: $0.createdAt) }
  }
}

private func userActivitySummaries(
  children: [User],
  map: [ComputerUser.Id: User],
  keystrokes: [KeystrokeLine],
  screenshots: [Screenshot]
) -> [DashboardWidgets.ChildActivitySummary] {
  children.map { user in
    let userScreenshots = screenshots.filter { map[$0.computerUserId]?.id == user.id }
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
