import Api
import Dependencies
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }

try withDependencies {
  $0.uuid = UUIDGenerator { UUID() }
} operation: {
  try Configure.app(app)
  try app.run()
}
