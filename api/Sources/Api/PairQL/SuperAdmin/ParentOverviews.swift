import Foundation
import PairQL

struct ParentOverviews: Pair {
  static let auth: ClientAuth = .superAdmin

  struct ParentOverview: PairOutput {
    var email: EmailAddress
    var numKids: Int
    var numKeychains: Int
    var numNotifications: Int
    var signupDate: Date
    var subscriptionStatus: Admin.SubscriptionStatus
  }

  typealias Output = [ParentOverview]
}

extension ParentOverviews: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let data = try await AnalyticsQuery.shared.data()
    return data.parents.values.map { parent in
      ParentOverview(
        email: parent.email,
        numKids: parent.numChildren,
        numKeychains: parent.numNonEmptyKeychains,
        numNotifications: parent.numNotifications,
        signupDate: parent.createdAt,
        subscriptionStatus: parent.subscriptionStatus
      )
    }
  }
}
