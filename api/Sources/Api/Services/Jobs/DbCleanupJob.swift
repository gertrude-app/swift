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

  let deletedScreenshots = try await Screenshot.query()
    .withSoftDeleted()
    .where(.not(.isNull(.deletedAt)) .&& .deletedAt <= now)
    .all()

  try await deletedScreenshots.chunked(into: Postgres.MAX_BIND_PARAMS).asyncForEach {
    try await Screenshot.query()
      .where(.id |=| $0.map(\.id))
      .delete(force: true)
  }

  logs.append("Deleted \(deletedScreenshots.count) screenshots")

  let deletedNonPendingUnlockRequests = try await UnlockRequest.query()
    .where(.not(.equals(.status, .enum(RequestStatus.pending))))
    .where(.updatedAt < 3.daysAgo)
    .delete()

  logs.append("Deleted \(deletedNonPendingUnlockRequests) non-pending unlock requests")

  let deletedPendingUnlockRequests = try await UnlockRequest.query()
    .where(.equals(.status, .enum(RequestStatus.pending)))
    .where(.updatedAt < 7.daysAgo)
    .delete()

  logs.append("Deleted \(deletedPendingUnlockRequests) pending unlock requests")

  let deletedAdminTokens = try await AdminToken.query()
    .where(.deletedAt < now .&& .not(.isNull(.deletedAt)))
    .delete(force: true)

  logs.append("Deleted \(deletedAdminTokens) admin tokens")

  let suspendFilterRequests = try await SuspendFilterRequest.query()
    .where(.createdAt < 3.daysAgo)
    .delete()

  logs.append("Deleted \(suspendFilterRequests) suspend filter requests")

  let keystrokeslines = try await KeystrokeLine.query()
    .where(.createdAt < 21.daysAgo)
    .delete(force: true)

  logs.append("Deleted \(keystrokeslines) keystroke lines")

  let smokeAdmins = try await Admin.query()
    .where(.like(.email, "%.smoke-test-%"))
    .delete(force: true)

  logs.append("Deleted \(smokeAdmins) smoke test admin accounts")

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
