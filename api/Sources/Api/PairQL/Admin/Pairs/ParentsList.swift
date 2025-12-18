import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL

struct ParentsList: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var page: Int
    var pageSize: Int?
  }

  struct Output: PairOutput {
    var parents: [ParentSummary]
    var totalCount: Int
    var page: Int
    var totalPages: Int
  }

  struct ParentSummary: PairNestable {
    var id: Parent.Id
    var email: String
    var createdAt: Date
    var subscriptionStatus: String
    var numChildren: Int
    var numKeychains: Int
    var numNotifications: Int
    var status: String
  }
}

extension ParentsList: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let pageSize = input.pageSize ?? 30
    let page = max(1, input.page)
    let offset = (page - 1) * pageSize

    let totalCount = try await Parent.query().count(in: context.db)
    let totalPages = max(1, Int(ceil(Double(totalCount) / Double(pageSize))))

    let parents = try await Parent.query()
      .where(.not(.like(.email, "%.smoke-test-%")))
      .where(.not(.like(.email, "e2e-user-%")))
      .orderBy(.createdAt, .desc)
      .limit(pageSize)
      .offset(offset)
      .all(in: context.db)

    let analyticsData = try await AnalyticsQuery.shared.data()

    let summaries = parents.map { parent -> ParentSummary in
      let parentData = analyticsData.parents[parent.id]
      return ParentSummary(
        id: parent.id,
        email: parent.email.rawValue,
        createdAt: parent.createdAt,
        subscriptionStatus: parent.subscriptionStatus.rawValue,
        numChildren: parentData?.numChildren ?? 0,
        numKeychains: parentData?.numNonEmptyKeychains ?? 0,
        numNotifications: parentData?.numNotifications ?? 0,
        status: parentData?.status.rawValue ?? "unknown",
      )
    }

    return .init(
      parents: summaries,
      totalCount: totalCount,
      page: page,
      totalPages: totalPages,
    )
  }
}
