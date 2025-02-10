import ComposableArchitecture
import LibClients

@Reducer
struct IOSReducer {
  @ObservableState
  public struct State: Equatable {
    var screen: Screen = .onboarding(.happyPath(.hiThere))
    var blockGroups: [BlockGroup] = .all
  }

  @ObservationIgnored
  @Dependency(\.api) var api
  @ObservationIgnored
  @Dependency(\.systemExtension) var systemExtension

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch (state.screen, action) {
      case (.onboarding(.happyPath(.hiThere)), .onlyBtnTapped):
        state.screen = .onboarding(.happyPath(.timeExpectation))
        return .none

      case (.onboarding(.happyPath(.timeExpectation)), .onlyBtnTapped):
        state.screen = .onboarding(.happyPath(.confirmChildsDevice))
        return .none

      case (.onboarding(.happyPath(.confirmChildsDevice)), .happyPathBtnTapped):
        state.screen = .onboarding(.happyPath(.explainMinorOrSupervised))
        return .none

      case (.onboarding(.happyPath(.confirmChildsDevice)), .sadPathBtnTapped):
        state.screen = .onboarding(.onParentDeviceFail)
        return .none

      case (.onboarding(.happyPath(.explainMinorOrSupervised)), .onlyBtnTapped):
        state.screen = .onboarding(.happyPath(.confirmMinorDevice))
        return .none

      case (.onboarding(.happyPath(.confirmMinorDevice)), .happyPathBtnTapped):
        state.screen = .onboarding(.happyPath(.confirmParentIsOnboarding))
        return .none

      case (.onboarding(.happyPath(.confirmMinorDevice)), .sadPathBtnTapped):
        state.screen = .onboarding(.major1_RENAME_ME)
        return .none

      case (.onboarding(.happyPath(.confirmParentIsOnboarding)), .happyPathBtnTapped):
        state.screen = .onboarding(.happyPath(.confirmInAppleFamily))
        return .none

      case (.onboarding(.happyPath(.confirmInAppleFamily)), .happyPathBtnTapped):
        state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
        return .none

      case (.onboarding(.happyPath(.confirmInAppleFamily)), .sadPathBtnTapped):
        state.screen = .onboarding(.fixAppleFamily(.explainRequiredForFiltering))
        return .none

      case (.onboarding(.happyPath(.confirmInAppleFamily)), .iDontKnowBtnTapped):
        state.screen = .onboarding(.fixAppleFamily(.explainWhatIsAppleFamily))
        return .none

      case (.onboarding(.happyPath(.confirmParentIsOnboarding)), .sadPathBtnTapped):
        state.screen = .onboarding(.childIsOnboardingFail)
        return .none

      case (.onboarding(.happyPath(.explainTwoInstallSteps)), .onlyBtnTapped):
        state.screen = .onboarding(.happyPath(.explainAuthWithParentAppleAccount))
        return .none

      case (.onboarding(.happyPath(.explainAuthWithParentAppleAccount)), .onlyBtnTapped):
        state.screen = .onboarding(.happyPath(.dontGetTrickedPreAuth))
        return .none

      case (.onboarding(.happyPath(.dontGetTrickedPreAuth)), .onlyBtnTapped):
        return .run { send in
          // jared
          switch await self.systemExtension.requestAuthorization() {
          case .success:
            await send(.authorizationSucceeded)
            await self.api.logEvent("4a0c585f", "authorization succeeded")
          case .failure(let reason):
            await send(.authorizationFailed(reason))
            await self.systemExtension.cleanupForRetry()
            await self.api.logEvent("e2e02460", "authorization failed: \(reason)")
          }
        }

      case (.onboarding(.happyPath(.dontGetTrickedPreAuth)), .authorizationSucceeded):
        state.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
        return .none

      case (.onboarding(.happyPath(.explainInstallWithDevicePasscode)), .onlyBtnTapped):
        state.screen = .onboarding(.happyPath(.dontGetTrickedPreInstall))
        return .none

      case (.onboarding(.happyPath(.dontGetTrickedPreInstall)), .onlyBtnTapped):
        return .run { send in
          switch await self.systemExtension.installFilter() {
          case .success:
            await send(.installSucceeded)
            await self.api.logEvent("adced334", "filter install success")
          case .failure(let error):
            await send(.installFailed(error))
            await self.systemExtension.cleanupForRetry()
            await self.api.logEvent("004d0d89", "filter install failed: \(error)")
          }
        }

      case (.onboarding(.happyPath(.dontGetTrickedPreInstall)), .installSucceeded):
        state.screen = .onboarding(.happyPath(.optOutBlockGroups))
        return .none

      case (.onboarding(.happyPath(.optOutBlockGroups)), .blockGroupToggled(let blockGroup)):
        state.blockGroups.toggle(blockGroup)
        return .none

      // MARK: - error paths

      case (.onboarding(.childIsOnboardingFail), .onlyBtnTapped):
        state.screen = .onboarding(.happyPath(.hiThere))
        return .none

      case (let screen, let action):
        fatalError("unhandled combination:\n  .\(screen)\n  .\(action)")
      }
    }
  }
}

extension IOSReducer {
  enum Onboarding: Equatable {
    case happyPath(HappyPath)
    case fixAppleFamily(FixAppleFamily)

    case onParentDeviceFail
    case childIsOnboardingFail

    case major1_RENAME_ME

    enum HappyPath: Equatable {
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
      case optOutBlockGroups
    }

    // TODO: carefully think thru these flows, not sure if they landed correct
    enum FixAppleFamily: Equatable {
      case explainRequiredForFiltering
      case explainSetupFreeAndEasy
      case howToSetupAppleFamily
      // TODO: check this flow, how can we incorporate "it's required to install filter" idea?
      case explainWhatIsAppleFamily
    }
  }

  enum Screen: Equatable {
    case onboarding(Onboarding)
  }
}

extension IOSReducer {
  enum Action: Equatable {
    // buttons
    case onlyBtnTapped
    case happyPathBtnTapped
    case sadPathBtnTapped
    case iDontKnowBtnTapped

    // auth
    case authorizationSucceeded
    case authorizationFailed(AuthFailureReason)

    // install
    case installSucceeded
    case installFailed(FilterInstallError)

    // special
    case blockGroupToggled(BlockGroup)
  }
}
