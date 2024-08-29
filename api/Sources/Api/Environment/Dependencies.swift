import Dependencies
import XStripe

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
