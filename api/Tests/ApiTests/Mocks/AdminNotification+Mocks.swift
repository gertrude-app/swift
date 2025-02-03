import Gertie

@testable import Api

extension AdminNotification: RandomMocked {
  public static var mock: AdminNotification {
    AdminNotification(parentId: .init(), methodId: .init(), trigger: .unlockRequestSubmitted)
  }

  public static var empty: AdminNotification {
    AdminNotification(parentId: .init(), methodId: .init(), trigger: .unlockRequestSubmitted)
  }

  public static var random: AdminNotification {
    AdminNotification(
      parentId: .init(),
      methodId: .init(),
      trigger: Trigger.allCases.shuffled().first!
    )
  }
}
