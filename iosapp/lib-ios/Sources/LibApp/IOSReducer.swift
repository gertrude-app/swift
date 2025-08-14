import ComposableArchitecture
import Foundation
import LibClients
import os.log

@_exported import GertieIOS
@_exported import XCore

@Reducer
public struct IOSReducer {
  struct Deps: Sendable {
    @Dependency(\.api) var api
    @Dependency(\.appStore) var appStore
    @Dependency(\.continuousClock) var clock
    @Dependency(\.device) var device
    @Dependency(\.filter) var filter
    @Dependency(\.systemExtension) var systemExtension
    @Dependency(\.sharedUserDefaults) var userDefaults
    @Dependency(\.sharedStorage) var sharedStorage
    @Dependency(\.date.now) var now
    @Dependency(\.locale) var locale
    @Dependency(\.mainQueue) var mainQueue
  }

  @ObservationIgnored
  let deps = Deps()

  enum CancelId {
    case cacheClearUpdates
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .interactive(let interactiveAction):
        self.interactive(state: &state, action: interactiveAction)
      case .programmatic(let programmaticAction):
        self.programmatic(state: &state, action: programmaticAction)
      case .destination(.presented(let destinationAction)):
        self.destination(state: &state, action: destinationAction)
      case .destination:
        .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }

  func interactive(state: inout State, action: Action.Interactive) -> Effect<Action> {
    switch action {
    case .onboardingBtnTapped(let btn, _):
      return self.onboardingBtnTapped(btn, state: &state, action: action)

    case .blockGroupToggled(let group):
      self.deps.log("block group toggled: \(group)", "02976f9b")
      state.disabledBlockGroups.toggle(group)
      return .none

    case .sheetDismissed where state.screen == .onboarding(.major(.explainAppleFamily)):
      self.deps.log(state.screen, action, "118d259f")
      state.screen = .onboarding(.major(.askIfInAppleFamily))
      return .none

    case .sheetDismissed:
      return .none

      // 👍 todo: move me into debug reducer
    // case .receivedShake where state.screen == .running(showVendorId: true, timesShaken: 5):
    //   state.screen = .running(showVendorId: false)
    //   return .run { [deps = self.deps] send in
    //     deps.log("entering recovery mode", "a8998540")
    //     if deps.storage.loadDisabledBlockGroups() == nil {
    //       deps.storage.saveDisabledBlockGroups([])
    //     }
    //     let rules = deps.storage.loadProtectionMode()
    //     if rules.missingRules {
    //       deps.log("rules missing in recovery mode", "bcca235f")
    //       let defaultRules = try? await deps.api
    //         .fetchDefaultBlockRules(deps.device.vendorId())
    //       if let defaultRules, !defaultRules.isEmpty {
    //         deps.storage.saveProtectionMode(.normal(defaultRules))
    //       } else {
    //         deps.log("failed to fetch defaults in recovery mode", "2c3a4481")
    //         deps.storage.saveProtectionMode(.normal(BlockRule.defaults))
    //       }
    //     }
    //     try await deps.filter.notifyRulesChanged()
    //     let directive = try? await deps.api.recoveryDirective()
    //     if directive == "retry" {
    //       await deps.systemExtension.cleanupForRetry()
    //       deps.log("received retry directive", "aeaa467d")
    //     }
    //   }

    case .receivedShake where state.screen.isRunning:
      // let timesShaken = (state.screen.timesShaken ?? 0) + 1
      // state.screen = .running(showVendorId: true, timesShaken: timesShaken)
      // return .run { [deps = self.deps] send in
      //   guard timesShaken == 1 else { return }
      //   guard let vendorId = await deps.device.vendorId() else {
      //     deps.log("UNEXPECTED no vendor id on shake", "caec76fe")
      //     return
      //   }
      //   let disabled = deps.storage.loadDisabledBlockGroups()
      //   if disabled == nil {
      //     deps.log("UNEXPECTED no stored disabled block groups on shake", "de5592c2")
      //     deps.storage.saveDisabledBlockGroups([])
      //   }
      //   let rules = try await deps.api.fetchBlockRules(
      //     vendorId: vendorId,
      //     disabledGroups: disabled ?? []
      //   )
      //   deps.storage.saveProtectionMode(.normal(rules))
      //   try await deps.filter.notifyRulesChanged()
      // }
      // 👍 todo: restore
      let allLogs = self.deps.sharedStorage.loadDebugLogs() ?? []
      for (i, logs) in allLogs.chunked(into: 6).enumerated() {
        os_log("[G•] APP dump memory logs %d:\n%{public}s", i + 1, logs.joined(separator: "\n"))
      }
      return .run { [filter = self.deps.filter] _ in
        try await filter.send(notification: .dumpLogs)
      }

    case .runningBtnTapped: // rename...?
      state.destination = .connectAccount(.init(screen: .enteringCode))
      return .none

    case .receivedShake where state.screen == .onboarding(.happyPath(.hiThere)):
      #if DEBUG
        state.screen = .onboarding(.happyPath(.dontGetTrickedPreAuth))
      #endif
      return .none

    case .receivedShake:
      return .none
    }
  }

  func onboardingBtnTapped(
    _ btn: Action.Interactive.OnboardingBtn,
    state: inout State,
    action: Action.Interactive
  ) -> Effect<Action> {
    switch (state.screen, btn) {
    case (.onboarding(.happyPath(.hiThere)), .primary):
      self.deps.log(state.screen, action, "6f97eb1b")
      state.screen = .onboarding(.happyPath(.timeExpectation))
      return .none

    case (.onboarding(.happyPath(.timeExpectation)), .primary):
      self.deps.log(state.screen, action, "762bf9bf")
      state.screen = .onboarding(.happyPath(.confirmChildsDevice))
      return .none

    case (.onboarding(.happyPath(.confirmChildsDevice)), .primary):
      self.deps.log(state.screen, action, "666d5e0f")
      state.screen = .onboarding(.happyPath(.explainMinorOrSupervised))
      return .none

    case (.onboarding(.happyPath(.confirmChildsDevice)), .secondary):
      self.deps.log(state.screen, action, "30fac4e6")
      state.screen = .onboarding(.onParentDeviceFail)
      return .none

    case (.onboarding(.happyPath(.explainMinorOrSupervised)), .primary):
      self.deps.log(state.screen, action, "6bc91c73")
      state.screen = .onboarding(.happyPath(.confirmMinorDevice))
      return .none

    case (.onboarding(.happyPath(.confirmMinorDevice)), .primary):
      self.deps.log(state.screen, action, "e17137b0")
      state.screen = .onboarding(.happyPath(.confirmParentIsOnboarding))
      return .none

    case (.onboarding(.happyPath(.confirmMinorDevice)), .secondary):
      self.deps.log(state.screen, action, "a21c9040")
      state.screen = .onboarding(.major(.explainHarderButPossible))
      return .none

    case (.onboarding(.happyPath(.confirmParentIsOnboarding)), .primary):
      self.deps.log(state.screen, action, "51611498")
      state.screen = .onboarding(.happyPath(.confirmInAppleFamily))
      return .none

    case (.onboarding(.happyPath(.confirmInAppleFamily)), .primary):
      self.deps.log(state.screen, action, "7d0fd46e")
      state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
      return .none

    case (.onboarding(.happyPath(.confirmInAppleFamily)), .secondary):
      self.deps.log(state.screen, action, "daa8c7fd")
      state.screen = .onboarding(.appleFamily(.explainRequiredForFiltering))
      return .none

    case (.onboarding(.happyPath(.confirmInAppleFamily)), .tertiary):
      self.deps.log(state.screen, action, "232fb200")
      state.screen = .onboarding(.appleFamily(.explainWhatIsAppleFamily))
      return .none

    case (.onboarding(.happyPath(.confirmParentIsOnboarding)), .secondary):
      self.deps.log(state.screen, action, "3c4772ad")
      state.screen = .onboarding(.childIsOnboardingFail)
      return .none

    case (.onboarding(.happyPath(.explainTwoInstallSteps)), .primary):
      self.deps.log(state.screen, action, "6582656c")
      state.screen = .onboarding(.happyPath(.explainAuthWithParentAppleAccount))
      return .none

    case (.onboarding(.happyPath(.explainAuthWithParentAppleAccount)), .primary):
      self.deps.log(state.screen, action, "5d3a5ba2")
      state.screen = .onboarding(.happyPath(.dontGetTrickedPreAuth))
      return .none

    case (.onboarding(.happyPath(.dontGetTrickedPreAuth)), .primary):
      self.deps.log(state.screen, action, "87601352")
      return .run { [deps = self.deps] send in
        switch await deps.systemExtension.requestAuthorization() {
        case .success:
          await send(.programmatic(.authorizationSucceeded))
          await deps.api.logEvent("4a0c585f", "[onboarding] authorization succeeded")
        case .failure(let reason):
          await send(.programmatic(.authorizationFailed(reason)))
          await deps.systemExtension.cleanupForRetry()
          await deps.api.logEvent("e2e02460", "[onboarding] authorization failed: \(reason)")
        }
      }

    case (.onboarding(.happyPath(.explainInstallWithDevicePasscode)), .primary):
      self.deps.log(state.screen, action, "5dcaa641")
      state.screen = .onboarding(.happyPath(.dontGetTrickedPreInstall))
      return .none

    case (.onboarding(.happyPath(.dontGetTrickedPreInstall)), .primary):
      self.deps.log(state.screen, action, "47bee21e")
      return .run { [deps = self.deps] send in
        switch await deps.systemExtension.installFilter() {
        case .success:
          await send(.programmatic(.installSucceeded))
          await deps.api.logEvent("adced334", "[onboarding] filter install success")
        case .failure(let error):
          await send(.programmatic(.installFailed(error)))
          await deps.systemExtension.cleanupForRetry()
          await deps.api.logEvent("004d0d89", "[onboarding] filter install failed: \(error)")
        }
      }

    case (.onboarding(.happyPath(.offerAccountConnect)), .primary):
      self.deps.log(state.screen, action, "62b6a262")
      state.screen = .onboarding(.happyPath(.optOutBlockGroups))
      return .none

    case (.onboarding(.happyPath(.offerAccountConnect)), .secondary):
      self.deps.log(state.screen, action, "b93bb543")
      state.destination = .connectAccount(.init())
      return .none

    case (.onboarding(.happyPath(.connectSuccess)), .primary):
      self.deps.log(state.screen, action, "63d34e4c")
      state.screen = .onboarding(.happyPath(.promptClearCache))
      return .none

    case (.onboarding(.happyPath(.optOutBlockGroups)), .primary):
      self.deps.log(state.screen, action, "cdb31095")
      if state.disabledBlockGroups == .all { return .none }
      state.screen = .onboarding(.happyPath(.promptClearCache))
      return .merge(
        .run { [deps = self.deps, disabled = state.disabledBlockGroups] _ in
          deps.sharedStorage.saveDisabledBlockGroups(disabled)
          if let vendorId = await deps.device.vendorId() {
            let result = try? await deps.api.fetchBlockRules(
              vendorId: vendorId,
              disabledGroups: disabled
            )
            if let rules = result, !rules.isEmpty {
              deps.sharedStorage.saveProtectionMode(.normal(rules))
            }
          } else {
            deps.log("UNEXPECTED no vendor id on opt out", "d9e93a4b")
          }
          // NB: safeguard so we don't ever end up with empty rules
          if deps.sharedStorage.loadProtectionMode().missingRules {
            deps.log("UNEXPECTED missing rules after opt-out", "ffff30ac")
            deps.sharedStorage.saveProtectionMode(.normal(BlockRule.Legacy.defaults.map(\.current)))
          }
        },
        .run { [device = self.deps.device] send in
          await send(.programmatic(.setBatteryLevel(device.batteryLevel())))
        },
        .run { [device = self.deps.device] send in
          if let bytes = await device.availableDiskSpaceInBytes() {
            await send(.programmatic(.setAvailableDiskSpaceInBytes(bytes)))
          }
        }
      )

    case (.onboarding(.happyPath(.promptClearCache)), .primary):
      let available = state.onboarding.availableDiskSpaceInBytes ?? -1
      let humanSize = Bytes.humanReadable(available, decimalPlaces: 1, prefix: .binary)
      if state.onboarding.batteryLevel.isLow || available > (Bytes.inGigabyte * 60) {
        self.deps.log("clear cache -> battery warning, disk size: \(humanSize)", "ea3f9c37")
        state.screen = .onboarding(.happyPath(.batteryWarning))
        return .none
      } else {
        self.deps.log("clear cache, skip battery warning, disk size: \(humanSize)", "8a8a3033")
        state.onboarding.startClearCache = self.deps.now
        state.screen = .onboarding(.happyPath(.clearingCache(0)))
        return .publisher { [deps = self.deps] in
          deps.device.clearCache(state.onboarding.availableDiskSpaceInBytes)
            .map { .programmatic(.receiveClearCacheUpdate($0)) }
            .receive(on: deps.mainQueue)
        }
      }

    case (.onboarding(.happyPath(.promptClearCache)), .secondary):
      self.deps.log(state.screen, action, "1221f1a3")
      state.screen = .onboarding(.happyPath(.requestAppStoreRating))
      return .none

    case (.onboarding(.happyPath(.batteryWarning)), .primary):
      self.deps.log(state.screen, action, "72dc8e84")
      state.onboarding.startClearCache = self.deps.now
      state.screen = .onboarding(.happyPath(.clearingCache(0)))
      return .publisher { [deps = self.deps] in
        deps.device.clearCache(state.onboarding.availableDiskSpaceInBytes)
          .map { .programmatic(.receiveClearCacheUpdate($0)) }
          .receive(on: deps.mainQueue)
      }.cancellable(id: CancelId.cacheClearUpdates, cancelInFlight: true)

    case (.onboarding(.happyPath(.cacheCleared)), .primary):
      self.deps.log(state.screen, action, "f9f2e206")
      state.screen = .onboarding(.happyPath(.requestAppStoreRating))
      return .none

    case (.onboarding(.happyPath(.requestAppStoreRating)), .primary):
      self.deps.log(state.screen, action, "4fc0b1bf")
      state.screen = .onboarding(.happyPath(.doneQuit))
      return .run { [deps = self.deps] _ in
        await deps.appStore.requestRating()
      }

    case (.onboarding(.happyPath(.requestAppStoreRating)), .secondary):
      self.deps.log(state.screen, action, "a9480aa2")
      state.screen = .onboarding(.happyPath(.doneQuit))
      return .run { [deps = self.deps] _ in
        await deps.appStore.requestReview()
      }

    case (.onboarding(.happyPath(.requestAppStoreRating)), .tertiary):
      self.deps.log(state.screen, action, "0dddc87c")
      state.screen = .onboarding(.happyPath(.doneQuit))
      return .none

      // MARK: - major (18+) path

    case (.onboarding(.major(.explainHarderButPossible)), .primary):
      self.deps.log(state.screen, action, "085eb5a6")
      state.screen = .onboarding(.major(.askSelfOrOtherIsOnboarding))
      return .none

    case (.onboarding(.major(.askSelfOrOtherIsOnboarding)), .secondary):
      self.deps.log(state.screen, action, "6d88421b")
      state.onboarding.majorOnboarder = .other
      state.screen = .onboarding(.major(.askIfOtherIsParent))
      return .none

    case (.onboarding(.major(.askIfOtherIsParent)), .primary):
      self.deps.log(state.screen, action, "e0605ab9")
      state.screen = .onboarding(.major(.explainFixAccountTypeEasyWay))
      return .none

    case (.onboarding(.major(.askIfOtherIsParent)), .secondary):
      self.deps.log(state.screen, action, "db2a8c0b")
      state.screen = .onboarding(.major(.askIfOwnsMac))
      return .none

    case (.onboarding(.major(.explainFixAccountTypeEasyWay)), .primary):
      self.deps.log(state.screen, action, "1ed887e0")
      state.screen = .onboarding(.happyPath(.confirmMinorDevice))
      return .none

    case (.onboarding(.major(.askSelfOrOtherIsOnboarding)), .tertiary):
      self.deps.log(state.screen, action, "bbc0dac1", extra: "onboarder is self")
      state.onboarding.majorOnboarder = .self
      state.screen = .onboarding(.major(.askIfInAppleFamily))
      return .none

    case (.onboarding(.major(.askIfInAppleFamily)), .primary):
      self.deps.log(state.screen, action, "605151b9")
      state.screen = .onboarding(.major(.explainFixAccountTypeEasyWay))
      return .none

    case (.onboarding(.major(.askIfInAppleFamily)), .secondary):
      self.deps.log(state.screen, action, "0fa6bc2a")
      state.screen = .onboarding(.supervision(.intro))
      return .none

    case (.onboarding(.major(.askIfInAppleFamily)), .tertiary):
      self.deps.log(state.screen, action, "d17b9ef6")
      state.screen = .onboarding(.major(.explainAppleFamily))
      return .none

    case (.onboarding(.major(.explainAppleFamily)), .primary):
      self.deps.log(state.screen, action, "62f783e1")
      state.screen = .onboarding(.major(.askIfInAppleFamily))
      return .none

    case (.onboarding(.major(.explainFixAccountTypeEasyWay)), .secondary):
      self.deps.log(state.screen, action, "fd166517")
      state.screen = .onboarding(.major(.askIfOwnsMac))
      return .none

    case (.onboarding(.major(.askIfOwnsMac)), .primary):
      self.deps.log(state.screen, action, "219ba991")
      state.onboarding.ownsMac = true
      state.screen = .onboarding(.supervision(.intro))
      return .none

    case (.onboarding(.major(.askIfOwnsMac)), .secondary):
      self.deps.log(state.screen, action, "c1f63c92")
      state.onboarding.ownsMac = false
      state.screen = .onboarding(.supervision(.intro))
      return .none

      // MARK: - apple family

    case (.onboarding(.appleFamily(.explainRequiredForFiltering)), .primary):
      self.deps.log(state.screen, action, "97a57eb2")
      state.screen = .onboarding(.appleFamily(.explainSetupFreeAndEasy))
      return .none

    case (.onboarding(.appleFamily(.explainSetupFreeAndEasy)), .primary):
      self.deps.log(state.screen, action, "2badbcb8")
      state.screen = .onboarding(.appleFamily(.howToSetupAppleFamily))
      return .none

    case (.onboarding(.appleFamily(.checkIfInAppleFamily)), .primary):
      self.deps.log(state.screen, action, "07cac029")
      state.screen = state.onboarding
        .takeReturningTo() ?? .onboarding(.happyPath(.confirmInAppleFamily))
      return .none

    case (.onboarding(.appleFamily(.checkIfInAppleFamily)), .secondary):
      self.deps.log(state.screen, action, "b311a78a")
      state.screen = .onboarding(.appleFamily(.explainSetupFreeAndEasy))
      return .none

    case (.onboarding(.appleFamily(.howToSetupAppleFamily)), .tertiary):
      self.deps.log(state.screen, action, "548e81b6")
      state.screen = .onboarding(.happyPath(.confirmInAppleFamily))
      state.onboarding.returningTo = nil
      return .none

    case (.onboarding(.appleFamily(.explainWhatIsAppleFamily)), .primary):
      self.deps.log(state.screen, action, "1c495932")
      state.screen = .onboarding(.appleFamily(.checkIfInAppleFamily))
      return .none

      // MARK: - supervision

    case (.onboarding(.supervision(.intro)), .primary):
      self.deps.log(state.screen, action, "ad77fbb6")
      state.screen = .onboarding(.supervision(.explainSupervision))
      return .none

    case (.onboarding(.supervision(.explainSupervision)), .primary):
      if state.onboarding.ownsMac != true || state.onboarding.majorOnboarder == .self {
        self.deps.log(state.screen, action, "896bc216", extra: "NEEDS friend w/ mac")
        state.screen = .onboarding(.supervision(.explainNeedFriendWithMac))
      } else {
        self.deps.log(state.screen, action, "25a77e6a", extra: "HAS friend w/ mac")
        state.screen = .onboarding(.supervision(.explainRequiresEraseAndSetup))
      }
      return .none

    case (.onboarding(.supervision(.explainNeedFriendWithMac)), .primary):
      self.deps.log(state.screen, action, "0c5bdbdd")
      state.screen = .onboarding(.supervision(.explainRequiresEraseAndSetup))
      return .none

    case (.onboarding(.supervision(.explainNeedFriendWithMac)), .secondary):
      self.deps.log(state.screen, action, "d858eaf8")
      state.screen = .onboarding(.supervision(.sorryNoOtherWay))
      return .none

    case (.onboarding(.supervision(.explainRequiresEraseAndSetup)), .primary):
      self.deps.log(state.screen, action, "dc1521e6")
      state.screen = .onboarding(.supervision(.instructions))
      return .none

    case (.onboarding(.supervision(.explainRequiresEraseAndSetup)), .secondary):
      self.deps.log(state.screen, action, "bee80538")
      state.screen = .onboarding(.supervision(.sorryNoOtherWay))
      return .none

    case (.onboarding(.supervision(.sorryNoOtherWay)), .secondary):
      self.deps.log(state.screen, action, "f3b3f3b6")
      state.screen = .onboarding(.happyPath(.hiThere))
      return .none

    // MARK: - error paths

    case (.onboarding(.authFail(.invalidAccount(.letsFigureThisOut))), .primary):
      self.deps.log(state.screen, action, "285efafb")
      state.screen = .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
      return .none

    case (.onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))), .primary):
      self.deps.log(state.screen, action, "e90ff997")
      state.screen = .onboarding(.authFail(.invalidAccount(.confirmIsMinor)))
      return .none

    case (.onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))), .secondary):
      self.deps.log(state.screen, action, "39c52acf")
      state.screen = .onboarding(.appleFamily(.explainRequiredForFiltering))
      return .none

    case (.onboarding(.authFail(.invalidAccount(.confirmInAppleFamily))), .tertiary):
      self.deps.log(state.screen, action, "a9cbe4fe")
      state.screen = .onboarding(.appleFamily(.checkIfInAppleFamily))
      state.onboarding.returningTo = .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
      return .none

    case (.onboarding(.authFail(.invalidAccount(.confirmIsMinor))), .primary):
      self.deps.log(state.screen, action, "9d0d9eac")
      state.screen = .onboarding(.major(.explainHarderButPossible))
      return .none

    case (.onboarding(.authFail(.invalidAccount(.confirmIsMinor))), .secondary):
      self.deps.log(state.screen, action, "e457cf15")
      state.screen = .onboarding(.authFail(.invalidAccount(.unexpected)))
      return .none

    case (.onboarding(.authFail(.restricted)), .secondary):
      self.deps.log(state.screen, action, "b8422c3a")
      state.screen = .onboarding(.happyPath(.hiThere))
      return .none

    case (.onboarding(.authFail(.authConflict)), .primary):
      self.deps.log(state.screen, action, "7b53bdc0")
      state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
      return .none

    case (.onboarding(.authFail(.networkError)), .primary):
      self.deps.log(state.screen, action, "16e57d91")
      state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
      return .none

    case (.onboarding(.authFail(.passcodeRequired)), .primary):
      self.deps.log(state.screen, action, "d2888470")
      state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
      return .none

    case (.onboarding(.authFail(.authCanceled)), .primary):
      self.deps.log(state.screen, action, "6e3b2c93")
      state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
      return .none

    case (.onboarding(.authFail(.unexpected)), .primary):
      self.deps.log(state.screen, action, "87c5ad82")
      state.screen = .onboarding(.happyPath(.explainTwoInstallSteps))
      return .none

    case (.onboarding(.installFail(.permissionDenied)), .primary):
      self.deps.log(state.screen, action, "b122af01")
      state.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
      return .none

    case (.onboarding(.installFail(.other)), .primary):
      self.deps.log(state.screen, action, "cf059547")
      state.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
      return .none

    case (.onboarding(.childIsOnboardingFail), .primary):
      self.deps.log(state.screen, action, "566a3484")
      state.screen = .onboarding(.happyPath(.hiThere))
      return .none

    case (.supervisionSuccessFirstLaunch, .primary):
      self.deps.log(state.screen, action, "aa563df6")
      state.onboarding.deviceSupervised = true
      state.screen = .onboarding(.happyPath(.offerAccountConnect))
      return .none

    default:
      #if DEBUG
        fatalError("Unhandled combination:\n -> btn: .\(btn)\n -> screen: .\(state.screen)")
      #else
        self.log(state.screen, action, "7c039b10", extra: "UNHANDLED ACTION")
        state.screen = state.screen.fallbackDestination(from: btn)
        return .none
      #endif
    }
  }

  func programmatic(state: inout State, action: Action.Programmatic) -> Effect<Action> {
    switch action {
    case .appDidLaunch:
      return .merge(
        // detect current state and set screen
        .run { [deps = self.deps] send in
          let filterRunning = await deps.systemExtension.filterRunning()
          let disabledBlockGroups = deps.sharedStorage.loadDisabledBlockGroups()
          let connection = deps.sharedStorage.loadAccountConnection()
          let hasLegacyData = deps.userDefaults.loadData(forKey: .legacyStorageKey) != nil
          switch (filterRunning, disabledBlockGroups, hasLegacyData) {
          case (true, .some, _):
            await send(.programmatic(.setScreen(.running(
              state: connection.map { .connected(childName: $0.childName) } ?? .notConnected
            ))))
            if let token = connection?.token {
              await deps.api.setAuthToken(token)
            }
          case (false, .some, _):
            // NB: if they remove the filter via Settings then launch app, we'll get here
            deps.log("non-running filter w/ stored groups", "23c207e2")
            await send(.programmatic(.setScreen(.onboarding(.happyPath(.hiThere)))))
          case (false, .none, _):
            await send(.programmatic(.setScreen(.onboarding(.happyPath(.hiThere)))))
          case (_, .none, true):
            try await deps.handleUpgrade(send: send)
          case (true, .none, false):
            deps.log("supervision success first launch", "bad8adcc")
            await send(.programmatic(.setScreen(.supervisionSuccessFirstLaunch)))
          }
        },
        // handle first launch
        .run { [deps = self.deps] send in
          if let firstLaunch = deps.sharedStorage.loadFirstLaunchDate() {
            await send(.programmatic(.setFirstLaunch(firstLaunch)))
          } else {
            let now = deps.now
            deps.sharedStorage.saveFirstLaunchDate(now)
            await send(.programmatic(.setFirstLaunch(now)))
            // prefetch the default block groups for onboarding
            let defaultRules = try? await deps.api.fetchDefaultBlockRules(deps.device.vendorId())
            if let defaultRules, !defaultRules.isEmpty {
              deps.sharedStorage.saveProtectionMode(.onboarding(defaultRules))
            } else {
              deps.sharedStorage
                .saveProtectionMode(.onboarding(BlockRule.Legacy.defaults.map(\.current)))
            }
            await deps.api.logEvent(
              "8d35f043",
              "[onboarding] first launch, region: `\(deps.locale.region?.identifier ?? "(nil)")`"
            )
          }
        },
        // safeguard in case app crashed trying to fill the disk
        .run { [deps = self.deps] send in
          await deps.device.deleteCacheFillDir()
        }
      )

    case .appWillTerminate:
      return .cancel(id: CancelId.cacheClearUpdates)

    case .setFirstLaunch(let date):
      state.onboarding.firstLaunch = date
      return .none

    case .setScreen(let screen):
      state.screen = screen
      return .none

    case .setBatteryLevel(let level):
      state.onboarding.batteryLevel = level
      return .none

    case .setAvailableDiskSpaceInBytes(let bytes):
      state.onboarding.availableDiskSpaceInBytes = bytes
      return .none

    case .authorizationSucceeded:
      if state.screen == .onboarding(.happyPath(.dontGetTrickedPreAuth)) {
        self.deps.log(action, "021834f6")
      } else {
        self.deps.unexpected(state.screen, action, "e30624c6")
      }
      state.screen = .onboarding(.happyPath(.explainInstallWithDevicePasscode))
      return .none

    case .authorizationFailed(let err):
      if state.screen != .onboarding(.happyPath(.dontGetTrickedPreAuth)) {
        self.deps.unexpected(state.screen, action, "fa49f256")
      }
      let errStr = String(reflecting: err)
      switch err {
      case .invalidAccountType:
        self.deps.log(action, "2bcf3d96", extra: "invalid account: \(errStr)")
        state.screen = .onboarding(.authFail(.invalidAccount(.letsFigureThisOut)))
      case .authorizationCanceled:
        self.deps.log(action, "e220a765", extra: "auth canceled: \(errStr)")
        state.screen = .onboarding(.authFail(.authCanceled))
      case .restricted:
        self.deps.log(action, "6f0a66e4", extra: "restricted: \(errStr)")
        state.screen = .onboarding(.authFail(.restricted))
      case .authorizationConflict:
        self.deps.log(action, "24220209", extra: "auth conflict: \(errStr)")
        state.screen = .onboarding(.authFail(.authConflict))
      case .networkError:
        self.deps.log(action, "104a7ef6", extra: "network: \(errStr)")
        state.screen = .onboarding(.authFail(.networkError))
      case .passcodeRequired:
        self.deps.log(action, "d2e2ee7c", extra: "passcode req: \(errStr)")
        state.screen = .onboarding(.authFail(.passcodeRequired))
      case .other, .unexpected:
        self.deps.log(action, "f4ed05fd", extra: "other/unexpected: \(errStr)")
        state.screen = .onboarding(.authFail(.unexpected))
      }
      return .none

    case .installSucceeded:
      if state.screen == .onboarding(.happyPath(.dontGetTrickedPreInstall)) {
        self.deps.log(action, "421d373b")
      } else {
        self.deps.unexpected(state.screen, action, "c98b9525")
      }
      state.screen = .onboarding(.happyPath(.offerAccountConnect))
      return .run { [deps = self.deps] _ in
        deps.sharedStorage.saveDisabledBlockGroups([])
      }

    case .installFailed(let err):
      if state.screen != .onboarding(.happyPath(.dontGetTrickedPreInstall)) {
        self.deps.unexpected(state.screen, action, "93958bd1")
      }
      switch err {
      case .configurationPermissionDenied:
        self.deps.log(action, "0dc1632a", extra: "install failed, permission denied")
        state.screen = .onboarding(.installFail(.permissionDenied))
      case .configurationCannotBeRemoved, .configurationDisabled, .configurationInternalError,
           .configurationInvalid, .configurationStale, .unexpected:
        self.deps.log(action, "321558ed", extra: "other error: \(String(reflecting: err))")
        state.screen = .onboarding(.installFail(.other(err)))
      }
      return .none

    case .receiveClearCacheUpdate(.bytesCleared(let bytes)):
      if case .onboarding(.happyPath(.clearingCache)) = state.screen {
        state.screen = .onboarding(.happyPath(.clearingCache(bytes)))
      }
      return .none

    case .receiveClearCacheUpdate(.finished):
      state.onboarding.endClearCache = self.deps.now
      let diskSpace = state.onboarding.availableDiskSpaceInBytes
        .map { Bytes.humanReadable($0) } ?? "unknown"
      if let start = state.onboarding.startClearCache {
        let elapsed = String(format: "%.1f", self.deps.now.timeIntervalSince(start) / 60.0)
        self.deps.log(action, "cb9cf096", extra: "elapsed time: \(elapsed)m, disk: \(diskSpace)")
      } else {
        self.deps.log(action, "cb9cf096", extra: "disk: \(diskSpace)")
      }
      state.screen = .onboarding(.happyPath(.cacheCleared))
      return .cancel(id: CancelId.cacheClearUpdates)

    case .receiveClearCacheUpdate(.errorCouldNotCreateDir):
      self.deps.log("UNEXPECTED error, could not create cache clear dir", "ae941213")
      state.onboarding.endClearCache = self.deps.now
      state.screen = .onboarding(.happyPath(.cacheCleared))
      return .cancel(id: CancelId.cacheClearUpdates)
    }
  }

  func destination(state: inout State, action: Destination.Action) -> Effect<Action> {
    switch action {
    case .connectAccount(.connectionSucceeded(childData: let data)):
      state.screen = .onboarding(.happyPath(.connectSuccess))
      return .run { [deps = self.deps] send in
        await deps.api.setAuthToken(data.token)
        deps.sharedStorage.saveAccountConnection(data)
      }
    default:
      return .none
    }
  }
}

extension IOSReducer.Deps {
  // TODO: need to handle two upgrades, > 1.3.x, and > 1.5.x
  func handleUpgrade(send: Send<IOSReducer.Action>) async throws {
    self.log("handling upgrade", "180e2347")
    self.sharedStorage.saveDisabledBlockGroups([])
    let defaultRules = try? await self.api.fetchDefaultBlockRules(self.device.vendorId())
    if let defaultRules {
      self.sharedStorage.saveProtectionMode(.normal(defaultRules))
    } else {
      self.log("unexpected upgrade rule failure", "8d4a445b")
      self.sharedStorage.saveProtectionMode(.onboarding(BlockRule.Legacy.defaults.map(\.current)))
    }
    self.userDefaults.removeObject(forKey: .legacyStorageKey)
    await send(.programmatic(.setScreen(.running(state: .notConnected))))
    try await self.filter.send(notification: .rulesChanged)
  }
}
