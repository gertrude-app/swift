import DuetSQL
import Foundation
import Gertie
import Queues
import Vapor

struct CleanupJob: AsyncScheduledJob {
  func run(context: QueueContext) async throws {
    guard Env.mode == .prod else { return }

    let logs = try await cleanupDb()
    for log in logs {
      context.logger.info("DbCleanupJob: \(log)")
    }
  }
}

func cleanupDb() async throws -> [String] {
  let now = Date()
  var logs: [String] = []

  let deletedScreenshots = try await Current.db.query(Screenshot.self)
    .withSoftDeleted()
    .where(.not(.isNull(.deletedAt)) .&& .deletedAt <= now)
    .all()

  try await deletedScreenshots.chunked(into: Postgres.MAX_BIND_PARAMS).asyncForEach {
    try await Current.db.query(Screenshot.self)
      .where(.id |=| $0.map(\.id))
      .delete(force: true)
  }

  logs.append("Deleted \(deletedScreenshots.count) screenshots")

  let deletedDecisions = try await Current.db.query(NetworkDecision.self)
    .where(.createdAt < 7.daysAgo)
    .delete()

  logs.append("Deleted \(deletedDecisions.count) network decisions")

  let deletedNonPendingUnlockRequests = try await Current.db.query(UnlockRequest.self)
    .where(.not(.equals(.status, .enum(RequestStatus.pending))))
    .where(.updatedAt < 3.daysAgo)
    .delete()

  logs.append("Deleted \(deletedNonPendingUnlockRequests.count) non-pending unlock requests")

  let deletedPendingUnlockRequests = try await Current.db.query(UnlockRequest.self)
    .where(.equals(.status, .enum(RequestStatus.pending)))
    .where(.updatedAt < 7.daysAgo)
    .delete()

  logs.append("Deleted \(deletedPendingUnlockRequests.count) pending unlock requests")

  let deletedAdminTokens = try await Current.db.query(AdminToken.self)
    .where(.deletedAt < now .&& .not(.isNull(.deletedAt)))
    .delete(force: true)

  logs.append("Deleted \(deletedAdminTokens.count) admin tokens")

  let suspendFilterRequests = try await Current.db.query(SuspendFilterRequest.self)
    .where(.createdAt < 3.daysAgo)
    .delete()

  logs.append("Deleted \(suspendFilterRequests.count) suspend filter requests")

  let users = try await Current.db.query(User.self)
    .where(.deletedAt < 7.daysAgo .&& .not(.isNull(.deletedAt)))
    .delete(force: true)

  logs.append("Deleted \(users.count) users")

  let keychains = try await Current.db.query(Keychain.self)
    .where(.deletedAt < 30.daysAgo .&& .not(.isNull(.deletedAt)))
    .delete(force: true)

  logs.append("Deleted \(keychains.count) keychains")

  let keystrokeslines = try await Current.db.query(KeystrokeLine.self)
    .where(.createdAt < 21.daysAgo)
    .delete(force: true)

  logs.append("Deleted \(keystrokeslines.count) keystroke lines")

  return logs
}

// helpers

private extension Array {
  func chunked(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}
