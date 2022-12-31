import DuetMock
import Shared

extension AppScope: Mock {
  public static var mock: AppScope {
    .webBrowsers
  }

  public static var empty: AppScope {
    .unrestricted
  }

  public static var random: AppScope {
    switch Int.random(in: 1 ... 6) {
    case 1:
      return .webBrowsers
    case 2:
      return .unrestricted
    default:
      return .single(.random)
    }
  }
}

extension AppScope.Single: Mock {
  public static var mock: AppScope.Single {
    .bundleId("com.foo")
  }

  public static var empty: AppScope.Single {
    .bundleId("")
  }

  public static var random: AppScope.Single {
    if Bool.random() {
      return .bundleId("com.foo".random)
    } else {
      return .identifiedAppSlug("slug".random)
    }
  }
}
