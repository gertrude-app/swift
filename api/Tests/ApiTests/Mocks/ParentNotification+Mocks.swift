import Gertie

@testable import Api

extension Parent.Notification: RandomMocked {
  public static var mock: Parent.Notification {
    Parent.Notification(parentId: .init(), methodId: .init(), trigger: .unlockRequestSubmitted)
  }

  public static var empty: Parent.Notification {
    Parent.Notification(parentId: .init(), methodId: .init(), trigger: .unlockRequestSubmitted)
  }

  public static var random: Parent.Notification {
    Parent.Notification(
      parentId: .init(),
      methodId: .init(),
      trigger: Trigger.allCases.shuffled().first!
    )
  }
}
