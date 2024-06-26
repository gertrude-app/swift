import Gertie

@testable import Api

extension AdminNotification: RandomMocked {
  public static var mock: AdminNotification {
    AdminNotification(adminId: .init(), methodId: .init(), trigger: .unlockRequestSubmitted)
  }

  public static var empty: AdminNotification {
    AdminNotification(adminId: .init(), methodId: .init(), trigger: .unlockRequestSubmitted)
  }

  public static var random: AdminNotification {
    AdminNotification(
      adminId: .init(),
      methodId: .init(),
      trigger: Trigger.allCases.shuffled().first!
    )
  }
}
