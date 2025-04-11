import LibClients

public extension IOSReducer {
  enum Action: Equatable {
    public enum Interactive: Equatable {
      public enum OnboardingBtn: Equatable {
        case primary
        case secondary
        case tertiary
      }

      case onboardingBtnTapped(OnboardingBtn, String)
      case blockGroupToggled(BlockGroup)
      case sheetDismissed
      case receivedShake
    }

    public enum Programmatic: Equatable {
      case appDidLaunch
      case setFirstLaunch(Date)
      case setScreen(Screen)
      case authorizationSucceeded
      case authorizationFailed(AuthFailureReason)
      case installSucceeded
      case installFailed(FilterInstallError)
      case setBatteryLevel(DeviceClient.BatteryLevel)
      case setAvailableDiskSpaceInBytes(Int)
      case receiveClearCacheUpdate(DeviceClient.ClearCacheUpdate)
    }

    case interactive(Interactive)
    case programmatic(Programmatic)
  }
}
