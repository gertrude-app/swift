import Foundation

public enum Stripe {
  public enum Api {
    public enum Currency: String {
      case USD
    }

    public struct PaymentIntent: Decodable {
      public var id: String
      public var clientSecret: String

      public init(id: String, clientSecret: String) {
        self.id = id
        self.clientSecret = clientSecret
      }
    }

    public struct Refund: Decodable {
      public var id: String

      public init(id: String) {
        self.id = id
      }
    }

    public struct CheckoutSession: Decodable {
      public var id: String
      public var url: String?
      public var subscription: String?
      public var clientReferenceId: String?

      public init(id: String, url: String?, subscription: String?, clientReferenceId: String?) {
        self.id = id
        self.url = url
        self.subscription = subscription
        self.clientReferenceId = clientReferenceId
      }
    }

    public struct Subscription: Decodable {
      public enum Status: String, Decodable {
        case incomplete
        case incompleteExpired = "incomplete_expired"
        case trialing
        case active
        case pastDue = "past_due"
        case canceled
        case unpaid
      }

      public let id: String
      public let status: Status
      public let customer: String

      public init(id: String, status: Status, customer: String) {
        self.id = id
        self.status = status
        self.customer = customer
      }
    }

    public struct BillingPortalSession: Decodable {
      public let id: String
      public let url: String

      public init(id: String, url: String) {
        self.id = id
        self.url = url
      }
    }

    public struct Error: Swift.Error {
      public let type: String
      public let code: String?
      public let message: String?
      public let docUrl: String?
      public let param: String?

      public init(
        type: String,
        code: String? = nil,
        message: String? = nil,
        docUrl: String? = nil,
        param: String? = nil
      ) {
        self.type = type
        self.code = code
        self.message = message
        self.docUrl = docUrl
        self.param = param
      }
    }
  }

  public struct CheckoutSessionData: Equatable {
    public struct LineItem: Equatable {
      public let quantity: Int
      public let priceId: String

      public init(quantity: Int, priceId: String) {
        self.quantity = quantity
        self.priceId = priceId
      }
    }

    public enum Mode: String {
      case payment
      case setup
      case subscription
    }

    public enum TrialEndBehavior: String {
      case pause
      case createInvoice = "create_invoice"
    }

    public enum PaymentMethodCollection: String {
      case always
      case ifRequired = "if_required"
    }

    public let successUrl: String
    public let cancelUrl: String
    public let lineItems: [LineItem]
    public let mode: Mode
    public let clientReferenceId: String?
    public let customerEmail: String?
    public let trialPeriodDays: Int?
    public let trialEndBehavior: TrialEndBehavior?
    public let paymentMethodCollection: PaymentMethodCollection?

    public init(
      successUrl: String,
      cancelUrl: String,
      lineItems: [Stripe.CheckoutSessionData.LineItem],
      mode: Stripe.CheckoutSessionData.Mode,
      clientReferenceId: String?,
      customerEmail: String?,
      trialPeriodDays: Int?,
      trialEndBehavior: TrialEndBehavior?,
      paymentMethodCollection: PaymentMethodCollection?
    ) {
      self.successUrl = successUrl
      self.cancelUrl = cancelUrl
      self.lineItems = lineItems
      self.mode = mode
      self.clientReferenceId = clientReferenceId
      self.customerEmail = customerEmail
      self.trialPeriodDays = trialPeriodDays
      self.trialEndBehavior = trialEndBehavior
      self.paymentMethodCollection = paymentMethodCollection
    }
  }
}

extension Stripe.Api.Error: CustomStringConvertible {
  public var description: String {
    "Stripe.Api.Error(type: `\(type)`, code: `\(code ?? "nil")`, message: `\(message ?? "nil")`, docUrl: `\(docUrl ?? "nil")`, param: `\(param ?? "nil")`)"
  }
}

extension Stripe.Api.Error: CustomDebugStringConvertible {
  public var debugDescription: String { description }
}

extension Stripe.Api.Error: Decodable {}
