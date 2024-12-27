import Api
import Dependencies
import DuetSQL
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }

try withDependencies { deps in
  deps.logger = app.logger
  deps.uuid = UUIDGenerator { UUID() }
  deps.env = .fromProcess(mode: app.environment)
  deps.stripe = .liveValue
  deps.db = PgClient(threadCount: System.coreCount, env: deps.env)
  deps.aws = .liveValue
  deps.postmark = .liveValue
} operation: {
  try Configure.app(app)
  try app.run()
}
