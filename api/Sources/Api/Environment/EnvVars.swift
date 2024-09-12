import Dependencies
import Foundation
import Vapor

public struct Env: Sendable {
  public var mode: AppMode
  public var s3: S3
  public var sendgridApiKey: String
  public var postmarkApiKey: String
  public var database: Database
  public var dashboardUrl: String
  public var twilio: Twilio
  public var stripe: Stripe
  public var analyticsSiteUrl: String
  public var get: @Sendable (String) -> String?

  public enum AppMode: Equatable, Sendable {
    case prod
    case dev
    case staging
    case test
  }

  public struct S3: Sendable {
    public var key: String
    public var secret: String
    public var endpoint: String
    public var bucketUrl: String
    public var bucket: String
  }

  public struct Database: Sendable {
    public var name: String
    public var username: String
    public var password: String
  }

  public struct Stripe: Sendable {
    public var secretKey: String
    public var subscriptionPriceId: String
  }

  public struct Twilio: Sendable {
    public var accountSid: String
    public var authToken: String
    public var fromPhone: String
  }
}

extension Env.AppMode {
  init(from env: Vapor.Environment?) {
    switch env?.name {
    case "production":
      self = .prod
    case "development":
      self = .dev
    case "staging":
      self = .staging
    case "testing":
      self = .test
    default:
      fatalError("Unexpected Vapor.Environment: \(String(describing: env))")
    }
  }

  var name: String {
    switch self {
    case .prod: "production"
    case .dev: "development"
    case .staging: "staging"
    case .test: "testing"
    }
  }

  var coloredName: String {
    switch self {
    case .prod: self.name.uppercased().red.bold
    case .dev: self.name.uppercased().green.bold
    case .staging: self.name.uppercased().yellow.bold
    case .test: self.name.uppercased().magenta.bold
    }
  }
}

extension Env: DependencyKey {
  public static func fromProcess(mode vaporEnv: Vapor.Environment?) -> Env {
    let mode = AppMode(from: vaporEnv)
    return Env(
      mode: mode,
      s3: S3(
        key: processEnv("CLOUD_STORAGE_KEY"),
        secret: processEnv("CLOUD_STORAGE_SECRET"),
        endpoint: processEnv("CLOUD_STORAGE_ENDPOINT"),
        bucketUrl: processEnv("CLOUD_STORAGE_BUCKET_URL"),
        bucket: processEnv("CLOUD_STORAGE_BUCKET")
      ),
      sendgridApiKey: processEnv("SENDGRID_API_KEY"),
      postmarkApiKey: processEnv("POSTMARK_API_KEY"),
      database: Database(
        name: mode == .test
          ? processEnv("TEST_DATABASE_NAME")
          : processEnv("DATABASE_NAME"),
        username: processEnv("DATABASE_USERNAME"),
        password: processEnv("DATABASE_PASSWORD")
      ),
      dashboardUrl: processEnv("DASHBOARD_URL"),
      twilio: Twilio(
        accountSid: processEnv("TWILIO_ACCOUNT_SID"),
        authToken: processEnv("TWILIO_AUTH_TOKEN"),
        fromPhone: processEnv("TWILIO_FROM_PHONE")
      ),
      stripe: Stripe(
        secretKey: processEnv("STRIPE_SECRET_KEY"),
        subscriptionPriceId: processEnv("STRIPE_SUBSCRIPTION_PRICE_ID")
      ),
      analyticsSiteUrl: processEnv("ANALYTICS_SITE_URL"),
      get: { ProcessInfo.processInfo.environment[$0] }
    )
  }

  public static var liveValue: Env {
    self.fromProcess(mode: try? Vapor.Environment.detect())
  }

  public static var fromProcess: Env {
    .liveValue
  }
}

public extension DependencyValues {
  var env: Env {
    get { self[Env.self] }
    set { self[Env.self] = newValue }
  }
}

func processEnv(_ key: String) -> String {
  guard let envVar = ProcessInfo.processInfo.environment[key] else {
    let stackTrace = Thread.callStackSymbols
    print(stackTrace.joined(separator: "\n"))
    #if !os(Linux)
      fflush(stdout)
    #endif
    fatalError("Missing required environment variable: `\(key)`")
  }
  return envVar
}

extension Env: TestDependencyKey {
  public static var testValue: Env {
    .fromProcess(mode: .testing)
  }
}
