typealias OnboardingBtn = IOSReducer.Action.Interactive.OnboardingBtn

extension IOSReducer.Screen {
  func fallbackDestination(from btn: OnboardingBtn) -> Self {
    switch self {
    case .launching:
      .onboarding(.happyPath(.hiThere))
    case .onboarding(let onboarding):
      onboarding.fallbackDestination(from: btn)
    case .supervisionSuccessFirstLaunch:
      .onboarding(.happyPath(.optOutBlockGroups))
    case .running(state: let state):
      .running(state: state)
    }
  }
}

extension IOSReducer.Onboarding {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch self {
    case .appleFamily(let appleFamily):
      appleFamily.fallbackDestination(from: btn)
    case .authFail(let authFail):
      authFail.fallbackDestination(from: btn)
    case .childIsOnboardingFail:
      .onboarding(.happyPath(.hiThere))
    case .happyPath(let happyPath):
      happyPath.fallbackDestination(from: btn)
    case .installFail(let installFail):
      installFail.fallbackDestination(from: btn)
    case .major(let major):
      major.fallbackDestination(from: btn)
    case .onParentDeviceFail:
      .onboarding(.happyPath(.hiThere))
    case .supervision(let supervision):
      supervision.fallbackDestination(from: btn)
    }
  }
}

extension IOSReducer.Onboarding.AppleFamily {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.checkIfInAppleFamily, .primary):
      .onboarding(.happyPath(.confirmInAppleFamily))
    case (.checkIfInAppleFamily, _):
      .onboarding(.appleFamily(.explainSetupFreeAndEasy))
    case (.explainRequiredForFiltering, _):
      .onboarding(.appleFamily(.explainSetupFreeAndEasy))
    case (.explainSetupFreeAndEasy, _):
      .onboarding(.appleFamily(.howToSetupAppleFamily))
    case (.explainWhatIsAppleFamily, _):
      .onboarding(.appleFamily(.checkIfInAppleFamily))
    case (.howToSetupAppleFamily, _):
      .onboarding(.happyPath(.confirmInAppleFamily))
    }
  }
}

extension IOSReducer.Onboarding.AuthFail {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch self {
    case .invalidAccount(let invalidAccountScreen):
      invalidAccountScreen.fallbackDestination(from: btn)
    case .networkError, .passcodeRequired, .restricted, .unexpected, .authCanceled, .authConflict:
      .onboarding(.happyPath(.explainTwoInstallSteps))
    }
  }
}

extension IOSReducer.Onboarding.AuthFail.InvalidAccount {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.confirmInAppleFamily, .primary):
      .onboarding(.authFail(.invalidAccount(.confirmIsMinor)))
    case (.confirmInAppleFamily, .secondary):
      .onboarding(.appleFamily(.explainRequiredForFiltering))
    case (.confirmInAppleFamily, .tertiary):
      .onboarding(.appleFamily(.checkIfInAppleFamily))
    case (.confirmIsMinor, .primary):
      .onboarding(.major(.explainHarderButPossible))
    case (.confirmIsMinor, _):
      .onboarding(.authFail(.invalidAccount(.unexpected)))
    case (.letsFigureThisOut, _):
      .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
    case (.unexpected, _):
      .onboarding(.happyPath(.hiThere))
    }
  }
}

extension IOSReducer.Onboarding.InstallFail {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch self {
    case .permissionDenied, .other:
      .onboarding(.happyPath(.explainInstallWithDevicePasscode))
    }
  }
}

extension IOSReducer.Onboarding.Supervision {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.explainNeedFriendWithMac, _):
      .onboarding(.supervision(.explainRequiresEraseAndSetup))
    case (.explainRequiresEraseAndSetup, .primary):
      .onboarding(.supervision(.instructions))
    case (.explainRequiresEraseAndSetup, _):
      .onboarding(.supervision(.sorryNoOtherWay))
    case (.explainSupervision, _):
      .onboarding(.supervision(.explainNeedFriendWithMac))
    case (.instructions, _):
      .onboarding(.happyPath(.hiThere))
    case (.intro, _):
      .onboarding(.supervision(.explainSupervision))
    case (.sorryNoOtherWay, _):
      .onboarding(.happyPath(.hiThere))
    }
  }
}

extension IOSReducer.Onboarding.Major {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.askIfInAppleFamily, .primary):
      .onboarding(.major(.explainFixAccountTypeEasyWay))
    case (.askIfInAppleFamily, .secondary):
      .onboarding(.supervision(.intro))
    case (.askIfInAppleFamily, .tertiary):
      .onboarding(.major(.explainAppleFamily))
    case (.askIfOtherIsParent, .primary):
      .onboarding(.major(.explainFixAccountTypeEasyWay))
    case (.askIfOtherIsParent, _):
      .onboarding(.major(.askIfOwnsMac))
    case (.askIfOwnsMac, _):
      .onboarding(.supervision(.intro))
    case (.askSelfOrOtherIsOnboarding, .tertiary):
      .onboarding(.major(.askIfInAppleFamily))
    case (.askSelfOrOtherIsOnboarding, _):
      .onboarding(.major(.askIfOtherIsParent))
    case (.explainAppleFamily, _):
      .onboarding(.major(.askIfInAppleFamily))
    case (.explainFixAccountTypeEasyWay, .primary):
      .onboarding(.happyPath(.confirmMinorDevice))
    case (.explainFixAccountTypeEasyWay, _):
      .onboarding(.major(.askIfOwnsMac))
    case (.explainHarderButPossible, _):
      .onboarding(.major(.askSelfOrOtherIsOnboarding))
    }
  }
}

extension IOSReducer.Onboarding.HappyPath {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.batteryWarning, _):
      .onboarding(.happyPath(.requestAppStoreRating))
    case (.cacheCleared, _):
      .onboarding(.happyPath(.requestAppStoreRating))
    case (.clearingCache(let bytes), _):
      .onboarding(.happyPath(.clearingCache(bytes)))
    case (.confirmChildsDevice, .primary):
      .onboarding(.happyPath(.explainMinorOrSupervised))
    case (.confirmChildsDevice, _):
      .onboarding(.onParentDeviceFail)
    case (.confirmInAppleFamily, .primary):
      .onboarding(.happyPath(.explainTwoInstallSteps))
    case (.confirmInAppleFamily, .secondary):
      .onboarding(.appleFamily(.explainRequiredForFiltering))
    case (.confirmInAppleFamily, .tertiary):
      .onboarding(.appleFamily(.explainWhatIsAppleFamily))
    case (.confirmMinorDevice, .primary):
      .onboarding(.happyPath(.confirmParentIsOnboarding))
    case (.confirmMinorDevice, _):
      .onboarding(.major(.explainHarderButPossible))
    case (.confirmParentIsOnboarding, .primary):
      .onboarding(.happyPath(.confirmInAppleFamily))
    case (.confirmParentIsOnboarding, _):
      .onboarding(.childIsOnboardingFail)
    case (.dontGetTrickedPreAuth, _):
      .onboarding(.happyPath(.explainAuthWithParentAppleAccount))
    case (.dontGetTrickedPreInstall, _):
      .onboarding(.happyPath(.explainInstallWithDevicePasscode))
    case (.connectAccount, _):
        .onboarding(.happyPath(.dontGetTrickedPreAuth))
    case (.explainAuthWithParentAppleAccount, _):
      .onboarding(.happyPath(.dontGetTrickedPreAuth))
    case (.explainInstallWithDevicePasscode, _):
      .onboarding(.happyPath(.dontGetTrickedPreInstall))
    case (.explainMinorOrSupervised, _):
      .onboarding(.happyPath(.confirmMinorDevice))
    case (.explainTwoInstallSteps, _):
      .onboarding(.happyPath(.explainAuthWithParentAppleAccount))
    case (.hiThere, _):
      .onboarding(.happyPath(.timeExpectation))
    case (.optOutBlockGroups, _):
      .onboarding(.happyPath(.explainTwoInstallSteps))
    case (.promptClearCache, _):
      .onboarding(.happyPath(.requestAppStoreRating))
    case (.requestAppStoreRating, _):
      .running(state: .notConnected)
    case (.timeExpectation, _):
      .onboarding(.happyPath(.confirmChildsDevice))
    }
  }
}
