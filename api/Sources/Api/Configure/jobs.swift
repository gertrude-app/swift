import Vapor

public extension Configure {
  static func jobs(_ app: Application) throws {
    app.queues.use(.fluent())
    app.queues.configuration.workerCount = 1
    app.queues.configuration.refreshInterval = .seconds(300)

    app.queues.schedule(CleanupJob()).daily().at(2, 30, .am)

    try app.queues.startScheduledJobs()
  }
}
