import Dependencies
import DuetSQL
import Foundation
import Gertie
import Queues
import Vapor

struct CleanupJob: AsyncScheduledJob {
  @Dependency(\.env) var env
  @Dependency(\.db) var db

  func run(context: QueueContext) async throws {
    guard self.env.mode == .prod else {
      return
    }

    let logs = try await cleanupDb()
    for log in logs {
      context.logger.info("DbCleanupJob: \(log)")
    }
  }

  func cleanupDb() async throws -> [String] {
    let now = Date()
    var logs: [String] = []

    let deletedScreenshots = try await Screenshot.query()
      .where(.or(
        .not(.isNull(.deletedAt)) .&& .deletedAt <= now,
        .createdAt <= 21.daysAgo
      ))
      .delete(in: self.db, force: true)

    logs.append("Deleted \(deletedScreenshots) screenshots")

    let deletedNonPendingUnlockRequests = try await UnlockRequest.query()
      .where(.not(.equals(.status, .enum(RequestStatus.pending))))
      .where(.updatedAt < 3.daysAgo)
      .delete(in: self.db)

    logs.append("Deleted \(deletedNonPendingUnlockRequests) non-pending unlock requests")

    let deletedPendingUnlockRequests = try await UnlockRequest.query()
      .where(.equals(.status, .enum(RequestStatus.pending)))
      .where(.updatedAt < 7.daysAgo)
      .delete(in: self.db)

    logs.append("Deleted \(deletedPendingUnlockRequests) pending unlock requests")

    let deletedAdminTokens = try await AdminToken.query()
      .where(.deletedAt < now .&& .not(.isNull(.deletedAt)))
      .delete(in: self.db, force: true)

    logs.append("Deleted \(deletedAdminTokens) admin tokens")

    let suspendFilterRequests = try await MacApp.SuspendFilterRequest.query()
      .where(.createdAt < 3.daysAgo)
      .delete(in: self.db)

    logs.append("Deleted \(suspendFilterRequests) suspend filter requests")

    let keystrokeslines = try await KeystrokeLine.query()
      .where(.createdAt < 21.daysAgo)
      .delete(in: self.db, force: true)

    logs.append("Deleted \(keystrokeslines) keystroke lines")

    let smokeAdmins = try await Admin.query()
      .where(.like(.email, "%.smoke-test-%"))
      .delete(in: self.db)

    logs.append("Deleted \(smokeAdmins) smoke test admin accounts")

    await self.db.notifyDeprecationComplete(
      if: "BlockRules(v1)",
      notLoggedWithinLast: .days(90)
    )

    return logs
  }
}

// helpers

private extension Array {
  func chunked(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}
