import Queues
import Vapor

struct AnalyticsJob: AsyncScheduledJob {
  func run(context: QueueContext) async throws {
    _ = try await AnalyticsQuery.shared.queryFreshData()
  }
}
