import Foundation
import IOSRoute

extension PollFilterSuspensionDecision: Resolver {
  static func resolve(with id: UUID, in context: IOSApp.ChildContext) async throws -> Output {
    guard let request = try? await context.db.find(IOSApp.SuspendFilterRequest.Id(id)) else {
      return .notFound
    }
    switch request.status {
    case .accepted:
      return .accepted(duration: request.duration, parentComment: request.responseComment)
    case .pending:
      return .pending
    case .rejected:
      return .denied(parentComment: request.responseComment)
    }
  }
}
