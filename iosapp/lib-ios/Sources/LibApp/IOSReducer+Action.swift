import ComposableArchitecture
import IOSRoute
import LibClients

public extension IOSReducer {
  @CasePathable
  enum Action: Equatable {
    case interactive(Interactive)
    case programmatic(Programmatic)
    case destination(PresentationAction<Destination.Action>)

    public enum Interactive: Equatable {
      public enum OnboardingBtn: Equatable {
        case primary
        case secondary
        case tertiary
      }

      case onboardingBtnTapped(OnboardingBtn, String)
      case blockGroupToggled(BlockGroup)
      case sheetDismissed
      case runningBtnTapped
      case receivedShake
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
      case setAvailableDiskSpaceInBytes(Int)
      case receiveClearCacheUpdate(DeviceClient.ClearCacheUpdate)
      case receivedSuspensionUpdate(PollFilterSuspensionDecision.Output)
      case suspensionRequestExpired
      case requestScreenTimeAuthorization
    }
  }
}
