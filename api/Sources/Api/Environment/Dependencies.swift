import Dependencies
import DuetSQL
import PostgresKit
import XStripe

import FluentKit

extension Stripe.Client: DependencyKey {
  public static var liveValue: Stripe.Client {
    @Dependency(\.env.stripe.secretKey) var secretKey
    return .live(secretKey: secretKey)
  }
}

public extension DependencyValues {
  var stripe: Stripe.Client {
    get { self[Stripe.Client.self] }
    set { self[Stripe.Client.self] = newValue }
  }
}

public extension DependencyValues {
  var db: any DuetSQL.Client {
    get { self[DbClientKey.self] }
    set { self[DbClientKey.self] = newValue }
  }
}

public enum DbClientKey: TestDependencyKey {
  public static var testValue: any DuetSQL.Client {
    PgClient(threadCount: 1, env: .fromProcess(mode: .testing))
  }
}

extension DbClientKey: DependencyKey {
  public static var liveValue: any DuetSQL.Client {
    PgClient(threadCount: System.coreCount, env: .fromProcess)
  }
}

public extension PgClient {
  init(threadCount: Int, env: Env) {
    self = PgClient(
      factory: .from(env: env),
      logger: .null,
      numberOfThreads: threadCount
    )
  }
}

extension DatabaseConfigurationFactory {
  static func from(env: Env) -> DatabaseConfigurationFactory {
    .postgres(configuration: .init(
      hostname: env.get("DATABASE_HOST") ?? "localhost",
      username: env.database.username,
      password: env.database.password,
      database: env.database.name,
      tls: .disable
    ))
  }

  static var testDb: DatabaseConfigurationFactory {
    .from(env: .testValue)
  }
}

#if DEBUG
  public extension Stripe.Client {
    static let failing = Stripe.Client(
      createPaymentIntent: unimplemented("Stripe.Client.createPaymentIntent()"),
      cancelPaymentIntent: unimplemented("Stripe.Client.cancelPaymentIntent()"),
      createRefund: unimplemented("Stripe.Client.createRefund()"),
      getCheckoutSession: unimplemented("Stripe.Client.getCheckoutSession()"),
      createCheckoutSession: unimplemented("Stripe.Client.createCheckoutSession()"),
      getSubscription: unimplemented("Stripe.Client.getSubscription()"),
      createBillingPortalSession: unimplemented("Stripe.Client.createBillingPortalSession()")
    )
  }
#endif
