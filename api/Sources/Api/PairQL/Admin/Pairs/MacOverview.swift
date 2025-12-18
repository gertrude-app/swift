import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL
import TaggedMoney

struct MacOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var annualRevenue: Int
    var payingParents: Int
    var activeParents: Int
    var childrenOfActiveParents: Int
    var allTimeChildren: Int
    var allTimeAppInstallations: Int
    var recentSignups: [RecentSignupOutput]
  }

  struct RecentSignupOutput: PairNestable {
    var date: Date
    var status: String
    var email: String
  }
}

extension MacOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let data = try await AnalyticsQuery.shared.data()
    return .init(
      annualRevenue: data.overview.annualRevenue.rawValue,
      payingParents: data.overview.payingParents,
      activeParents: data.overview.activeParents,
      childrenOfActiveParents: data.overview.childrenOfActiveParents,
      allTimeChildren: data.overview.allTimeChildren,
      allTimeAppInstallations: data.overview.allTimeAppInstallations,
      recentSignups: data.parents.values.map { parent in
        RecentSignupOutput(
          date: parent.createdAt,
          status: parent.status.rawValue,
          email: parent.email.rawValue,
        )
      },
    )
  }
}
