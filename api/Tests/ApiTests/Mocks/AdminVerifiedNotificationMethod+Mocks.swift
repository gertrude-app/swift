import Gertie

@testable import Api

extension AdminVerifiedNotificationMethod: RandomMocked {
  public static var mock: AdminVerifiedNotificationMethod {
    AdminVerifiedNotificationMethod(parentId: .init(), config: .mock)
  }

  public static var empty: AdminVerifiedNotificationMethod {
    AdminVerifiedNotificationMethod(parentId: .init(), config: .empty)
  }

  public static var random: AdminVerifiedNotificationMethod {
    AdminVerifiedNotificationMethod(parentId: .init(), config: .random)
  }
}

extension AdminVerifiedNotificationMethod.Config: RandomMocked {
  public static var mock: Self {
    .email(email: "bob".random + "@example.com")
  }

  public static var empty: Self {
    .slack(channelId: "", channelName: "", token: "")
  }

  public static var random: Self {
    switch Int.random(in: 1 ... 3) {
    case 1:
      return .email(email: "bob-random".random + "@example.com")
    case 2:
      return .slack(
        channelId: "C\(Int.random)",
        channelName: "Channel".random,
        token: "xoxb-random".random
      )
    default:
      return .text(phoneNumber: "555-555-" + "\(Int.random)")
    }
  }
}
