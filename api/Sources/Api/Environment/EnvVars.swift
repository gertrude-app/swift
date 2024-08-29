import Dependencies
import Foundation
import Vapor

// TODO: rename Env
public struct EnvVars: Sendable {
  var mode: AppMode
  var s3: S3
  var sendgridApiKey: String
  var postmarkApiKey: String
  var database: Database
  var dashboardUrl: String
  var twilio: Twilio
  var stripe: Stripe
  var analyticsSiteUrl: String

  enum AppMode: Equatable, Sendable {
    case prod
    case dev
    case staging
    case test
  }

  struct S3: Sendable {
    var key: String
    var secret: String
    var endpoint: String
    var bucketUrl: String
    var bucket: String
  }

  struct Database: Sendable {
    var name: String
    var username: String
    var password: String
  }

  struct Stripe: Sendable {
    var secretKey: String
    var subscriptionPriceId: String
  }

  struct Twilio: Sendable {
    var accountSid: String
    var authToken: String
    var fromPhone: String
  }
}

extension EnvVars.AppMode {
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
}

extension EnvVars: DependencyKey {
  public static var liveValue: EnvVars {
    EnvVars(
      mode: AppMode(from: try? Vapor.Environment.detect()),
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
        name: processEnv("DATABASE_NAME"),
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
      analyticsSiteUrl: processEnv("ANALYTICS_SITE_URL")
    )
  }
}

public extension DependencyValues {
  var env: EnvVars {
    get { self[EnvVars.self] }
    set { self[EnvVars.self] = newValue }
  }
}

func processEnv(_ key: String) -> String {
  guard let envVar = ProcessInfo.processInfo.environment[key] else {
    fatalError("Missing required environment variable: `\(key)`")
  }
  return envVar
}

extension EnvVars: TestDependencyKey {
  public static var testValue: EnvVars {
    EnvVars(
      mode: .test,
      s3: S3(
        key: "@test_var_cloud_storage_key",
        secret: "@test_var_cloud_storage_secret",
        endpoint: "@test_var_cloud_storage_endpoint",
        bucketUrl: "@test_var_cloud_storage_bucket_url",
        bucket: "@test_var_cloud_storage_bucket"
      ),
      sendgridApiKey: "@test_var_sendgrid_api_key",
      postmarkApiKey: "@test_var_postmark_api_key",
      database: Database(
        name: "@test_var_database_name",
        username: "@test_var_database_username",
        password: "@test_var_database_password"
      ),
      dashboardUrl: "@test_var_dashboard_url",
      twilio: Twilio(
        accountSid: "@test_var_twilio_account_sid",
        authToken: "@test_var_twilio_auth_token",
        fromPhone: "@test_var_twilio_from_phone"
      ),
      stripe: Stripe(
        secretKey: "@test_var_stripe_secret_key",
        subscriptionPriceId: "@test_var_stripe_subscription_price_id"
      ),
      analyticsSiteUrl: "@test_var_analytics_site_url"
    )
  }
}
