import ComposableArchitecture
import Foundation
import LibClients

@Reducer
struct IOSReducer {
  @ObservableState
  public struct State: Equatable {
    var screen: Screen = .onboarding(.happyPath(.hiThere))
    var blockGroups: [BlockGroup] = .all
    // TODO: maybe nest these in a struct?
    var firstLaunch: Date?
    var batteryLevel: DeviceClient.BatteryLevel = .unknown
    var majorOnboarder: MajorOnboarder?
    var ownsMac: Bool?
    var returningTo: Screen?

    mutating func takeReturningTo() -> Screen? {
      let returningTo = self.returningTo
      self.returningTo = nil
      return returningTo
    }
  }

  @ObservationIgnored
  @Dependency(\.api) var api
  @ObservationIgnored
  @Dependency(\.appStore) var appStore
  @ObservationIgnored
  @Dependency(\.device) var device
  @ObservationIgnored
  @Dependency(\.systemExtension) var systemExtension
  @ObservationIgnored
  @Dependency(\.storage) var storage
  @ObservationIgnored
  @Dependency(\.date.now) var now
  @ObservationIgnored
  @Dependency(\.locale) var locale
  @ObservationIgnored
  @Dependency(\.mainQueue) var mainQueue

  enum CancelId {
    case cacheClearUpdates
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch (state.screen, action) {
      case (_, .appDidLaunch):
        return .run { send in
          if let firstLaunch = self.storage.loadFirstLaunchDate() {
            await send(.setFirstLaunch(firstLaunch))
          } else {
            let now = self.now
            self.storage.saveFirstLaunchDate(now)
            await send(.setFirstLaunch(now))
            await self.api.logEvent(
              "8d35f043",
              "first launch, region: `\(self.locale.region?.identifier ?? "(nil)")`"
            )
          }
        }

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
        state.screen = .onboarding(.major(.explainHarderButPossible))
        return .none

      case (.onboarding(.happyPath(.confirmParentIsOnboarding)), .happyPathBtnTapped):
        state.screen = .onboarding(.happyPath(.confirmInAppleFamily))
        return .none

      case (.onboarding(.happyPath(.confirmInAppleFamily)), .happyPathBtnTapped):
        state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
        return .none

      case (.onboarding(.happyPath(.confirmInAppleFamily)), .sadPathBtnTapped):
        state.screen = .onboarding(.appleFamily(.explainRequiredForFiltering))
        return .none

      case (.onboarding(.happyPath(.confirmInAppleFamily)), .iDontKnowBtnTapped):
        state.screen = .onboarding(.appleFamily(.explainWhatIsAppleFamily))
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

      case (.onboarding(.happyPath(.optOutBlockGroups)), .onlyBtnTapped):
        if state.blockGroups.isEmpty {
          return .none
        }
        state.screen = .onboarding(.happyPath(.promptClearCache))
        return .run { send in
          await send(.setBatteryLevel(self.device.batteryLevel()))
        }

      case (.onboarding(.happyPath(.promptClearCache)), .primaryBtnTapped):
        switch state.batteryLevel {
        case .level(0.35 ... 1.0):
          state.screen = .onboarding(.happyPath(.clearingCache("")))
          return .publisher {
            self.device.clearCache()
              .map { .receiveClearCacheUpdate($0) }
              .receive(on: self.mainQueue)
          }
        default:
          state.screen = .onboarding(.happyPath(.batteryWarning))
          return .none
        }

      case (.onboarding(.happyPath(.batteryWarning)), .primaryBtnTapped):
        state.screen = .onboarding(.happyPath(.clearingCache("")))
        return .publisher {
          self.device.clearCache()
            .map { .receiveClearCacheUpdate($0) }
            .receive(on: self.mainQueue)
        }.cancellable(id: CancelId.cacheClearUpdates, cancelInFlight: true)

      case (
        .onboarding(.happyPath(.clearingCache)),
        .receiveClearCacheUpdate(.bytesCleared(let bytes))
      ):
        state.screen = .onboarding(.happyPath(.clearingCache("\(bytes) bytes")))
        return .none

      case (.onboarding(.happyPath(.clearingCache)), .receiveClearCacheUpdate(.completed)):
        state.screen = .onboarding(.happyPath(.cacheCleared))
        return .cancel(id: CancelId.cacheClearUpdates)

      case (.onboarding(.happyPath(.cacheCleared)), .onlyBtnTapped):
        state.screen = .onboarding(.happyPath(.requestAppStoreRating))
        return .none

      case (.onboarding(.happyPath(.requestAppStoreRating)), .primaryBtnTapped):
        state.screen = .onboarding(.happyPath(.doneQuit))
        return .run { _ in
          await self.appStore.requestRating()
        }

      case (.onboarding(.happyPath(.requestAppStoreRating)), .secondaryBtnTapped):
        state.screen = .onboarding(.happyPath(.doneQuit))
        return .run { _ in
          await self.appStore.requestReview()
        }

      case (.onboarding(.happyPath(.requestAppStoreRating)), .tertiaryBtnTapped):
        state.screen = .onboarding(.happyPath(.doneQuit))
        return .none

      // MARK: - major (18+) path

      case (.onboarding(.major(.explainHarderButPossible)), .onlyBtnTapped):
        state.screen = .onboarding(.major(.askSelfOrOtherIsOnboarding))
        return .none

      case (.onboarding(.major(.askSelfOrOtherIsOnboarding)), .secondaryBtnTapped):
        state.majorOnboarder = .other
        state.screen = .onboarding(.major(.askIfOtherIsParent))
        return .none

      case (.onboarding(.major(.askIfOtherIsParent)), .primaryBtnTapped):
        state.screen = .onboarding(.major(.explainFixAccountTypeEasyWay))
        return .none

      case (.onboarding(.major(.explainFixAccountTypeEasyWay)), .primaryBtnTapped):
        state.screen = .onboarding(.happyPath(.confirmMinorDevice))
        return .none

      case (.onboarding(.major(.askSelfOrOtherIsOnboarding)), .tertiaryBtnTapped):
        state.majorOnboarder = .self
        state.screen = .onboarding(.major(.askIfInAppleFamily))
        return .none

      case (.onboarding(.major(.askIfInAppleFamily)), .tertiaryBtnTapped):
        state.screen = .onboarding(.major(.explainAppleFamily))
        return .none

      case (.onboarding(.major(.explainAppleFamily)), .onlyBtnTapped):
        state.screen = .onboarding(.major(.askIfInAppleFamily))
        return .none

      case (.onboarding(.major(.askIfInAppleFamily)), .primaryBtnTapped):
        state.screen = .onboarding(.major(.explainFixAccountTypeEasyWay))
        return .none

      case (.onboarding(.major(.askIfInAppleFamily)), .secondaryBtnTapped):
        state.screen = .onboarding(.supervision(.intro))
        return .none

      case (.onboarding(.major(.explainFixAccountTypeEasyWay)), .secondaryBtnTapped):
        state.screen = .onboarding(.major(.askIfOwnsMac))
        return .none

      case (.onboarding(.major(.askIfOwnsMac)), _):
        state.ownsMac = action == .primaryBtnTapped
        state.screen = .onboarding(.supervision(.intro))
        return .none

      // MARK: - apple family

      case (.onboarding(.appleFamily(.explainRequiredForFiltering)), .onlyBtnTapped):
        state.screen = .onboarding(.appleFamily(.explainSetupFreeAndEasy))
        return .none

      case (.onboarding(.appleFamily(.explainSetupFreeAndEasy)), .onlyBtnTapped):
        state.screen = .onboarding(.appleFamily(.howToSetupAppleFamily))
        return .none

      case (.onboarding(.appleFamily(.checkIfInAppleFamily)), .primaryBtnTapped):
        state.screen = state.takeReturningTo() ?? .onboarding(.happyPath(.confirmInAppleFamily))
        return .none

      case (.onboarding(.appleFamily(.checkIfInAppleFamily)), .secondaryBtnTapped):
        state.screen = .onboarding(.appleFamily(.explainSetupFreeAndEasy))
        return .none

      case (.onboarding(.appleFamily(.howToSetupAppleFamily)), .tertiaryBtnTapped):
        state.screen = state.takeReturningTo() ?? .onboarding(.happyPath(.confirmInAppleFamily))
        return .none

      case (.onboarding(.appleFamily(.explainWhatIsAppleFamily)), .onlyBtnTapped):
        state.screen = .onboarding(.appleFamily(.checkIfInAppleFamily))
        return .none

      // MARK: - supervision

      case (.onboarding(.supervision(.intro)), .onlyBtnTapped):
        state.screen = .onboarding(.supervision(.explainSupervision))
        return .none

      case (.onboarding(.supervision(.explainSupervision)), .onlyBtnTapped):
        if state.ownsMac != true || state.majorOnboarder == .self {
          state.screen = .onboarding(.supervision(.explainNeedFriendWithMac))
        } else {
          state.screen = .onboarding(.supervision(.explainRequiresEraseAndSetup))
        }
        return .none

      case (.onboarding(.supervision(.explainNeedFriendWithMac)), .primaryBtnTapped):
        state.screen = .onboarding(.supervision(.explainRequiresEraseAndSetup))
        return .none

      case (.onboarding(.supervision(.explainNeedFriendWithMac)), .secondaryBtnTapped):
        state.screen = .onboarding(.supervision(.sorryNoOtherWay))
        return .none

      case (.onboarding(.supervision(.explainRequiresEraseAndSetup)), .primaryBtnTapped):
        state.screen = .onboarding(.supervision(.instructions))
        return .none

      case (.onboarding(.supervision(.explainRequiresEraseAndSetup)), .secondaryBtnTapped):
        state.screen = .onboarding(.supervision(.sorryNoOtherWay))
        return .none

      // MARK: - setters

      case (_, .setFirstLaunch(let date)):
        state.firstLaunch = date
        return .none

      case (_, .setBatteryLevel(let level)):
        state.batteryLevel = level
        return .none

      // MARK: - error paths

      case (.onboarding(.happyPath(.dontGetTrickedPreAuth)), .authorizationFailed(let err)):
        switch err {
        case .invalidAccountType:
          state.screen = .onboarding(.authFail(.invalidAccount(.letsFigureThisOut)))
        case .authorizationCanceled:
          state.screen = .onboarding(.authFail(.authCanceled))
        case .restricted:
          state.screen = .onboarding(.authFail(.restricted))
        case .authorizationConflict:
          state.screen = .onboarding(.authFail(.authConflict))
        case .networkError:
          state.screen = .onboarding(.authFail(.networkError))
        case .passcodeRequired:
          state.screen = .onboarding(.authFail(.passcodeRequired))
        case .other, .unexpected:
          state.screen = .onboarding(.authFail(.unexpected))
        }
        return .none

      case (.onboarding(.authFail(.invalidAccount(.letsFigureThisOut))), .onlyBtnTapped):
        state.screen = .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
        return .none

      case (.onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))), .primaryBtnTapped):
        state.screen = .onboarding(.authFail(.invalidAccount(.confirmIsMinor)))
        return .none

      case (.onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))), .secondaryBtnTapped):
        state.screen = .onboarding(.appleFamily(.explainRequiredForFiltering))
        return .none

      case (.onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))), .tertiaryBtnTapped):
        state.screen = .onboarding(.appleFamily(.checkIfInAppleFamily))
        state.returningTo = .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
        return .none

      case (.onboarding(.authFail(.invalidAccount(.confirmIsMinor))), .primaryBtnTapped):
        state.screen = .onboarding(.major(.explainHarderButPossible))
        return .none

      case (.onboarding(.authFail(.invalidAccount(.confirmIsMinor))), .secondaryBtnTapped):
        state.screen = .onboarding(.authFail(.invalidAccount(.unexpected)))
        return .none

      case (.onboarding(.authFail(.authConflict)), .onlyBtnTapped):
        state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
        return .none

      case (.onboarding(.authFail(.networkError)), .onlyBtnTapped):
        state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
        return .none

      case (.onboarding(.authFail(.passcodeRequired)), .onlyBtnTapped):
        state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
        return .none

      case (.onboarding(.authFail(.authCanceled)), .primaryBtnTapped):
        state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
        return .none

      case (.onboarding(.childIsOnboardingFail), .onlyBtnTapped):
        state.screen = .onboarding(.happyPath(.hiThere))
        return .none

      default:
        fatalError("unhandled combination:\n  .\(state.screen)\n  .\(action)")
      }
    }
  }
}

extension IOSReducer {
  enum Onboarding: Equatable {
    case happyPath(HappyPath)
    case appleFamily(AppleFamily)
    case major(Major)
    case supervision(Supervision)
    case authFail(AuthFail)

    case onParentDeviceFail
    case childIsOnboardingFail

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
      case promptClearCache
      case batteryWarning
      case clearingCache(String)
      case cacheCleared
      case requestAppStoreRating
      case doneQuit
    }

    enum Major: Equatable {
      case explainHarderButPossible
      case askSelfOrOtherIsOnboarding
      case askIfOtherIsParent
      case explainFixAccountTypeEasyWay
      case askIfOwnsMac
      case askIfInAppleFamily
      case explainAppleFamily
    }

    enum Supervision: Equatable {
      case intro
      case explainSupervision
      case explainNeedFriendWithMac
      case explainRequiresEraseAndSetup
      case instructions
      case sorryNoOtherWay
    }

    enum AuthFail: Equatable {
      case invalidAccount(InvalidAccount)
      case authConflict
      case authCanceled
      case restricted
      case passcodeRequired
      case networkError
      case unexpected

      enum InvalidAccount: Equatable {
        case letsFigureThisOut
        case confirmInAppleFamily
        case confirmIsMinor
        case unexpected
      }
    }

    // TODO: carefully think thru these flows, not sure if they landed correct
    enum AppleFamily: Equatable {
      case explainRequiredForFiltering
      case explainSetupFreeAndEasy
      case howToSetupAppleFamily
      // TODO: check this flow, how can we incorporate "it's required to install filter" idea?
      case explainWhatIsAppleFamily
      case checkIfInAppleFamily
    }
  }

  enum Screen: Equatable {
    case onboarding(Onboarding)
  }

  enum MajorOnboarder: Equatable {
    case `self`
    case other
  }
}

extension IOSReducer {
  enum Action: Equatable {
    case appDidLaunch
    case setFirstLaunch(Date)

    // buttons
    case onlyBtnTapped
    case happyPathBtnTapped
    case sadPathBtnTapped
    case iDontKnowBtnTapped
    case primaryBtnTapped
    case secondaryBtnTapped
    case tertiaryBtnTapped

    // auth
    case authorizationSucceeded
    case authorizationFailed(AuthFailureReason)

    // install
    case installSucceeded
    case installFailed(FilterInstallError)

    // special
    case blockGroupToggled(BlockGroup)
    case setBatteryLevel(DeviceClient.BatteryLevel)
    case receiveClearCacheUpdate(DeviceClient.ClearCacheUpdate)
  }
}

// extension IOSReducer.State {
//  func foo() {
//    //
//  }
// }
