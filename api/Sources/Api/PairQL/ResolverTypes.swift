import PairQL
import Vapor
import XStripe

protocol Resolver: Pair {
  associatedtype Context: ResolverContext
  static func resolve(with input: Input, in context: Context) async throws -> Output
}

protocol NoInputResolver: Pair where Input == NoInput {
  associatedtype Context
  static func resolve(in context: Context) async throws -> Output
}

protocol RouteResponder {
  associatedtype Context
  static func respond(to route: Self, in context: Context) async throws -> Response
}

protocol ResolverContext {
  var requestId: String { get }
}

protocol PqlErrorConvertible: Error {
  func pqlError<C: ResolverContext>(in: C) -> PqlError
}

// extensions

extension RouteResponder {
  static func respond<T: PairOutput>(with output: T) async throws -> Response {
    try output.response()
  }
}

extension Resolver {
  static func result(with input: Input, in context: Context) async -> Result<Output, Error> {
    do {
      return .success(try await resolve(with: input, in: context))
    } catch {
      return .failure(error)
    }
  }
}

extension PairOutput {
  func response() throws -> Response {
    Response(
      status: .ok,
      headers: ["Content-Type": "application/json"],
      body: .init(data: try jsonData())
    )
  }
}

extension ResolverContext {
  func error(
    _ id: String,
    _ type: PqlError.Kind,
    _ debugMessage: String,
    _ tag: PqlError.Tag? = nil
  ) -> PqlError {
    PqlError(id: id, requestId: requestId, type: type, debugMessage: debugMessage, tag: tag)
  }

  func error(
    _ id: String,
    _ type: PqlError.Kind,
    _ tag: PqlError.Tag? = nil,
    user userMessage: String
  ) -> PqlError {
    PqlError(
      id: id,
      requestId: requestId,
      type: type,
      debugMessage: userMessage,
      userMessage: userMessage,
      tag: tag
    )
  }

  func error(
    id: String,
    type: PqlError.Kind,
    debugMessage: String,
    userMessage: String? = nil,
    userAction: String? = nil,
    entityName: String? = nil,
    tag: PqlError.Tag? = nil,
    showContactSupport: Bool = false
  ) -> PqlError {
    PqlError(
      id: id,
      requestId: requestId,
      type: type,
      debugMessage: debugMessage,
      userMessage: userMessage,
      userAction: userAction,
      entityName: entityName,
      tag: tag,
      showContactSupport: showContactSupport
    )
  }
}

extension Stripe.Api.Error: PqlErrorConvertible {
  func pqlError<C: ResolverContext>(in context: C) -> PqlError {
    context.error(
      id: "xstripe:\(type):\(code ?? "")",
      type: .serverError,
      debugMessage: "\(message.map { "\($0), error: " } ?? "")\(self)",
      showContactSupport: true
    )
  }
}
