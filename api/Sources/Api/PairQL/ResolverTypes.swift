import DuetSQL
import PairQL
import Vapor
import XCore
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
    _ tag: PqlError.DashboardTag? = nil
  ) -> PqlError {
    PqlError(
      id: id,
      requestId: requestId,
      type: type,
      debugMessage: debugMessage,
      dashboardTag: tag
    )
  }

  func error(
    _ id: String,
    _ type: PqlError.Kind,
    _ tag: PqlError.DashboardTag? = nil,
    user userMessage: String
  ) -> PqlError {
    PqlError(
      id: id,
      requestId: requestId,
      type: type,
      debugMessage: userMessage,
      userMessage: userMessage,
      dashboardTag: tag
    )
  }

  func error(
    id: String,
    type: PqlError.Kind,
    debugMessage: String,
    userMessage: String? = nil,
    userAction: String? = nil,
    entityName: String? = nil,
    dashboardTag: PqlError.DashboardTag? = nil,
    appTag: PqlError.AppTag? = nil,
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
      dashboardTag: dashboardTag,
      appTag: appTag,
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

extension DuetSQLError: PqlErrorConvertible {
  func pqlError<C: ResolverContext>(in context: C) -> PqlError {
    switch self {
    case .notFound(let modelType):
      return context.error(
        id: "6ac1205a",
        type: .notFound,
        debugMessage: "DuetSQL: \(modelType) not found",
        entityName: modelType
          .snakeCased
          .lowercased()
          .replacingOccurrences(of: "_", with: " ")
          .capitalizingFirstLetter(),
        showContactSupport: false
      )
    case .decodingFailed:
      return context.error(
        id: "416d42b5",
        type: .serverError,
        debugMessage: "DuetSQL model decoding failed",
        showContactSupport: true
      )
    case .emptyBulkInsertInput:
      return context.error(
        id: "c3d8dbfe",
        type: .serverError,
        debugMessage: "DuetSQL: empty bulk insert input",
        showContactSupport: true
      )
    case .invalidEntity:
      return context.error(
        id: "cc7c423d",
        type: .serverError,
        debugMessage: "DuetSQL: invalid entity",
        showContactSupport: true
      )
    case .missingExpectedColumn(let column):
      return context.error(
        id: "a6b2da10",
        type: .serverError,
        debugMessage: "DuetSQL: missing expected column `\(column)`",
        showContactSupport: true
      )
    case .nonUniformBulkInsertInput:
      return context.error(
        id: "0d09dbca",
        type: .serverError,
        debugMessage: "DuetSQL: non-uniform bulk insert input",
        showContactSupport: true
      )
    case .notImplemented(let fn):
      return context.error(
        id: "e3b3ae0e",
        type: .serverError,
        debugMessage: "DuetSQL: not implemented `\(fn)`",
        showContactSupport: true
      )
    case .tooManyResultsForDeleteOne:
      return context.error(
        id: "277b3958",
        type: .serverError,
        debugMessage: "DuetSQL: too many results for delete one",
        showContactSupport: true
      )
    }
  }
}

private extension String {
  func capitalizingFirstLetter() -> String {
    prefix(1).capitalized + dropFirst()
  }
}
