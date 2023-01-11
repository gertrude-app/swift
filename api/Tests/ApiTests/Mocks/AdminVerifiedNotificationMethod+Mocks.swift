import DuetMock

@testable import Api

extension AdminVerifiedNotificationMethod: Mock {
  public static var mock: AdminVerifiedNotificationMethod {
    AdminVerifiedNotificationMethod(adminId: .init(), config: .mock)
  }

  public static var empty: AdminVerifiedNotificationMethod {
    AdminVerifiedNotificationMethod(adminId: .init(), config: .empty)
  }

  public static var random: AdminVerifiedNotificationMethod {
    AdminVerifiedNotificationMethod(adminId: .init(), config: .random)
  }
}

extension AdminVerifiedNotificationMethod.Config: Mock {
  public static var mock: Self {
    .email(email: "bob".random + "@example.com")
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

  public static var empty: Self {
    .slack(channelId: "", channelName: "", token: "")
  }
}
