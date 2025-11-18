import ComposableArchitecture
import IOSRoute
import LibClients

public extension IOSReducer {
  @CasePathable
  enum Action: Equatable {
    case interactive(Interactive)
    case programmatic(Programmatic)
    case destination(PresentationAction<Destination.Action>)

    @CasePathable
    public enum Interactive: Equatable {
      public enum OnboardingBtn: Equatable {
        case primary
        case secondary
        case tertiary
      }

      case onboardingClearCache(ClearCacheFeature.Action)
      case onboardingBtnTapped(OnboardingBtn, String)
      case blockGroupToggled(BlockGroup)
      case sheetDismissed
      case receivedShake
      case settingsBtnTapped
    }

    public enum Programmatic: Equatable {
      case appDidLaunch
      case appWillTerminate
      case setFirstLaunch(Date)
      case setScreen(Screen)
      case authorizationSucceeded
      case authorizationFailed(AuthFailureReason)
      case installSucceeded
      case installFailed(FilterInstallError)
      case setBatteryLevel(DeviceClient.BatteryLevel)
    }
  }
}
