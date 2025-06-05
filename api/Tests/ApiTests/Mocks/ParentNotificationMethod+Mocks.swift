import Gertie

@testable import Api

extension Parent.NotificationMethod: RandomMocked {
  public static var mock: Parent.NotificationMethod {
    Parent.NotificationMethod(parentId: .init(), config: .mock)
  }

  public static var empty: Parent.NotificationMethod {
    Parent.NotificationMethod(parentId: .init(), config: .empty)
  }

  public static var random: Parent.NotificationMethod {
    Parent.NotificationMethod(parentId: .init(), config: .random)
  }
}

extension Parent.NotificationMethod.Config: RandomMocked {
  public static var mock: Self {
    .email(email: "bob".random + "@example.com")
  }

  public static var empty: Self {
    .slack(channelId: "", channelName: "", token: "")
  }

  public static var random: Self {
    switch Int.random(in: 1 ... 3) {
    case 1:
      .email(email: "bob-random".random + "@example.com")
    case 2:
      .slack(
        channelId: "C\(Int.random)",
        channelName: "Channel".random,
        token: "xoxb-random".random
      )
    default:
      .text(phoneNumber: "555-555-" + "\(Int.random)")
    }
  }
}
