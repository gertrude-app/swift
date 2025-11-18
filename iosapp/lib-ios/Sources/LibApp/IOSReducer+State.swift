// swiftformat:disable extensionAccessControl
import ComposableArchitecture
import LibClients
import TaggedTime

extension IOSReducer {
  @Reducer(state: .equatable, action: .equatable)
  public enum Destination {
    case connectAccount(ConnectAccount)
    case debug(Debug)
  }

  @ObservableState
  public struct State: Equatable {
    public var screen: Screen = .launching
    public var disabledBlockGroups: [BlockGroup] = []
    public var onboarding: OnboardingState = .init()

    @Presents
    public var destination: Destination.State?

    public init(
      screen: IOSReducer.Screen = .launching,
      disabledBlockGroups: [BlockGroup] = [],
      onboarding: OnboardingState = .init(),
    ) {
      self.screen = screen
      self.disabledBlockGroups = disabledBlockGroups
      self.onboarding = onboarding
    }

    public struct OnboardingState: Equatable {
      public var firstLaunch: Date?
      public var majorOnboarder: MajorOnboarder?
      public var ownsMac: Bool?
      public var returningTo: Screen?
      public var deviceSupervised: Bool = false
      public var clearCache: ClearCacheFeature.State?

      public init(
        firstLaunch: Date? = nil,
        majorOnboarder: IOSReducer.MajorOnboarder? = nil,
        ownsMac: Bool? = nil,
        returningTo: IOSReducer.Screen? = nil,
      ) {
        self.firstLaunch = firstLaunch
        self.majorOnboarder = majorOnboarder
        self.ownsMac = ownsMac
        self.returningTo = returningTo
      }

      mutating func takeReturningTo() -> IOSReducer.Screen? {
        let returningTo = self.returningTo
        self.returningTo = nil
        return returningTo
      }
    }
  }

  public enum Onboarding: Equatable {
    case happyPath(HappyPath)
    case appleFamily(AppleFamily)
    case major(Major)
    case supervision(Supervision)
    case authFail(AuthFail)
    case installFail(InstallFail)

    case onParentDeviceFail
    case childIsOnboardingFail

    public enum HappyPath: Equatable {
      case hiThere
      case timeExpectation
      case confirmChildsDevice
      case explainMinorOrSupervised
      case confirmMinorDevice
      case confirmParentIsOnboarding
      case confirmInAppleFamily
      case explainTwoInstallSteps
      case explainAuthWithParentAppleAccount
      case dontGetTrickedPreAuth
      case explainInstallWithDevicePasscode
      case dontGetTrickedPreInstall
      case offerAccountConnect
      case connectSuccess
      case optOutBlockGroups
      case promptClearCache
      case requestAppStoreRating
      case doneQuit
    }

    public enum AppleFamily: Equatable {
      case explainRequiredForFiltering
      case explainSetupFreeAndEasy
      case howToSetupAppleFamily
      case explainWhatIsAppleFamily
      case checkIfInAppleFamily
    }

    public enum Major: Equatable {
      case explainHarderButPossible
      case askSelfOrOtherIsOnboarding
      case askIfOtherIsParent
      case explainFixAccountTypeEasyWay
      case askIfOwnsMac
      case askIfInAppleFamily
      case explainAppleFamily
    }

    public enum Supervision: Equatable {
      case intro
      case explainSupervision
      case explainNeedFriendWithMac
      case explainRequiresEraseAndSetup
      case instructions
      case sorryNoOtherWay
    }

    public enum AuthFail: Equatable {
      case invalidAccount(InvalidAccount)
      case authConflict
      case authCanceled
      case restricted
      case passcodeRequired
      case networkError
      case unexpected

      public enum InvalidAccount: Equatable {
        case letsFigureThisOut
        case confirmInAppleFamily
        case confirmIsMinor
        case unexpected
      }
    }

    public enum InstallFail: Equatable {
      case permissionDenied
      case other(FilterInstallError)
    }
  }

  public enum RunningState: Equatable {
    case notConnected
    case connected(childName: String)

    public var childName: String? {
      switch self {
      case .notConnected:
        nil
      case .connected(let childName):
        childName
      }
    }
  }

  public enum Screen: Equatable {
    case launching
    case onboarding(Onboarding)
    case supervisionSuccessFirstLaunch
    case running(state: RunningState = .notConnected)

    var isRunning: Bool {
      if case .running = self { return true }
      return false
    }
  }

  public enum Connecting: Equatable {
    case enteringCode(String)
    case connecting
    case failedToConnect
    case connectSuccess
  }

  public enum MajorOnboarder: Equatable {
    case `self`
    case other
  }
}
