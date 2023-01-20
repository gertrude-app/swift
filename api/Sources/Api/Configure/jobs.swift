import Vapor

public extension Configure {
  static func jobs(_ app: Application) throws {
    app.queues.use(.fluent())
    app.queues.configuration.workerCount = 1
    app.queues.configuration.refreshInterval = .seconds(300)

    // app.queues.schedule(CleanupJob()).daily().at(4, 30, .am) // 12:30am EST
    app.queues.schedule(CleanupJob()).hourly().at(30)

    try app.queues.startScheduledJobs()
  }
}
