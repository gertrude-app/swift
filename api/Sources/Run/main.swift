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

  deps.postmark = .live(apiKey: deps.env.postmarkApiKey)
  deps.sendgrid = .live(apiKey: deps.env.sendgridApiKey)
  let liveSendgridSend = deps.sendgrid.send
  let livePostmarkSend = deps.postmark.send

  deps.sendgrid.send = { message in
    if !isCypressTestAddress(message.firstRecipient.email) {
      try await liveSendgridSend(message)
    }
  }

  if deps.env.mode != .prod {
    deps.postmark.send = { email in
      try await liveSendgridSend(.init(postmark: email))
    }
  } else {
    deps.postmark.send = { email in
      if isCypressTestAddress(email.to) {
        return
      } else if isProdSmokeTestAddress(email.to) || isJaredTestAddress(email.to) {
        try await liveSendgridSend(.init(postmark: email))
      } else {
        try await livePostmarkSend(email)
      }
    }
  }

} operation: {
  try Configure.app(app)
  try app.run()
}
