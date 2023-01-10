import SotoS3
import Vapor

typealias Env = Vapor.Environment

extension Configure {
  static func env(_ app: Application) {
    Env.mode = .init(from: app.environment)

    guard Env.mode != .test else { return }

    Current.sendGrid = .live(apiKey: Env.SENDGRID_API_KEY)
    Current.stripe = .live(secretKey: Env.STRIPE_SECRET_KEY)
    Current.aws = .live(
      s3: .init(
        client: AWSClient(
          credentialProvider: .static(
            accessKeyId: Env.CLOUD_STORAGE_KEY,
            secretAccessKey: Env.CLOUD_STORAGE_SECRET
          ),
          httpClientProvider: .shared(app.http.client.shared)
        ),
        endpoint: Env.CLOUD_STORAGE_ENDPOINT
      )
    )
  }
}

// extensions

extension Vapor.Environment {
  static var mode = Mode.dev

  enum Mode: Equatable {
    case prod
    case dev
    case staging
    case test

    init(from env: Env) {
      switch env.name {
      case "production":
        self = .prod
      case "development":
        self = .dev
      case "staging":
        self = .staging
      case "testing":
        self = .test
      default:
        fatalError("Unexpected environment: \(env.name)")
      }
    }

    var name: String {
      switch self {
      case .prod:
        return "production"
      case .dev:
        return "development"
      case .staging:
        return "staging"
      case .test:
        return "testing"
      }
    }
  }
}

extension Vapor.Environment {
  static let CLOUD_STORAGE_KEY = get("CLOUD_STORAGE_KEY")!
  static let CLOUD_STORAGE_SECRET = get("CLOUD_STORAGE_SECRET")!
  static let CLOUD_STORAGE_ENDPOINT = get("CLOUD_STORAGE_ENDPOINT")!
  static let CLOUD_STORAGE_BUCKET_URL = get("CLOUD_STORAGE_BUCKET_URL")!
  static let CLOUD_STORAGE_BUCKET = get("CLOUD_STORAGE_BUCKET")!
  static let SENDGRID_API_KEY = get("SENDGRID_API_KEY")!
  static let DATABASE_NAME = get("DATABASE_NAME")!
  static let DATABASE_USERNAME = get("DATABASE_USERNAME")!
  static let DATABASE_PASSWORD = get("DATABASE_PASSWORD")!
  static let DASHBOARD_URL = get("DASHBOARD_URL")!
  static let TWILIO_ACCOUNT_SID = get("TWILIO_ACCOUNT_SID")!
  static let TWILIO_AUTH_TOKEN = get("TWILIO_AUTH_TOKEN")!
  static let TWILIO_FROM_PHONE = get("TWILIO_FROM_PHONE")!
  static let STRIPE_SUBSCRIPTION_PRICE_ID = get("STRIPE_SUBSCRIPTION_PRICE_ID")!
  static let STRIPE_SECRET_KEY = get("STRIPE_SECRET_KEY")!
}
