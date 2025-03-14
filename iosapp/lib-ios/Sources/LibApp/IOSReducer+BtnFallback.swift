typealias OnboardingBtn = IOSReducer.Action.Interactive.OnboardingBtn

extension IOSReducer.Screen {
  func fallbackDestination(from btn: OnboardingBtn) -> Self {
    switch self {
    case .launching:
      return .onboarding(.happyPath(.hiThere))
    case .onboarding(let onboarding):
      return onboarding.fallbackDestination(from: btn)
    case .supervisionSuccessFirstLaunch:
      return .onboarding(.happyPath(.optOutBlockGroups))
    case .running(showVendorId: let showing, timesShaken: let timesShaken):
      return .running(showVendorId: showing, timesShaken: timesShaken)
    }
  }
}

extension IOSReducer.Onboarding {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch self {
    case .appleFamily(let appleFamily):
      return appleFamily.fallbackDestination(from: btn)
    case .authFail(let authFail):
      return authFail.fallbackDestination(from: btn)
    case .childIsOnboardingFail:
      return .onboarding(.happyPath(.hiThere))
    case .happyPath(let happyPath):
      return happyPath.fallbackDestination(from: btn)
    case .installFail(let installFail):
      return installFail.fallbackDestination(from: btn)
    case .major(let major):
      return major.fallbackDestination(from: btn)
    case .onParentDeviceFail:
      return .onboarding(.happyPath(.hiThere))
    case .supervision(let supervision):
      return supervision.fallbackDestination(from: btn)
    }
  }
}

extension IOSReducer.Onboarding.AppleFamily {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.checkIfInAppleFamily, .primary):
      return .onboarding(.happyPath(.confirmInAppleFamily))
    case (.checkIfInAppleFamily, _):
      return .onboarding(.appleFamily(.explainSetupFreeAndEasy))
    case (.explainRequiredForFiltering, _):
      return .onboarding(.appleFamily(.explainSetupFreeAndEasy))
    case (.explainSetupFreeAndEasy, _):
      return .onboarding(.appleFamily(.howToSetupAppleFamily))
    case (.explainWhatIsAppleFamily, _):
      return .onboarding(.appleFamily(.checkIfInAppleFamily))
    case (.howToSetupAppleFamily, _):
      return .onboarding(.happyPath(.confirmInAppleFamily))
    }
  }
}

extension IOSReducer.Onboarding.AuthFail {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch self {
    case .invalidAccount(let invalidAccountScreen):
      return invalidAccountScreen.fallbackDestination(from: btn)
    case .networkError, .passcodeRequired, .restricted, .unexpected, .authCanceled, .authConflict:
      return .onboarding(.happyPath(.explainTwoInstallSteps))
    }
  }
}

extension IOSReducer.Onboarding.AuthFail.InvalidAccount {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.confirmInAppleFamily, .primary):
      return .onboarding(.authFail(.invalidAccount(.confirmIsMinor)))
    case (.confirmInAppleFamily, .secondary):
      return .onboarding(.appleFamily(.explainRequiredForFiltering))
    case (.confirmInAppleFamily, .tertiary):
      return .onboarding(.appleFamily(.checkIfInAppleFamily))
    case (.confirmIsMinor, .primary):
      return .onboarding(.major(.explainHarderButPossible))
    case (.confirmIsMinor, _):
      return .onboarding(.authFail(.invalidAccount(.unexpected)))
    case (.letsFigureThisOut, _):
      return .onboarding(.authFail(.invalidAccount(.confirmInAppleFamily)))
    case (.unexpected, _):
      return .onboarding(.happyPath(.hiThere))
    }
  }
}

extension IOSReducer.Onboarding.InstallFail {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch self {
    case .permissionDenied, .other:
      return .onboarding(.happyPath(.explainInstallWithDevicePasscode))
    }
  }
}

extension IOSReducer.Onboarding.Supervision {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.explainNeedFriendWithMac, _):
      return .onboarding(.supervision(.explainRequiresEraseAndSetup))
    case (.explainRequiresEraseAndSetup, .primary):
      return .onboarding(.supervision(.instructions))
    case (.explainRequiresEraseAndSetup, _):
      return .onboarding(.supervision(.sorryNoOtherWay))
    case (.explainSupervision, _):
      return .onboarding(.supervision(.explainNeedFriendWithMac))
    case (.instructions, _):
      return .onboarding(.happyPath(.hiThere))
    case (.intro, _):
      return .onboarding(.supervision(.explainSupervision))
    case (.sorryNoOtherWay, _):
      return .onboarding(.happyPath(.hiThere))
    }
  }
}

extension IOSReducer.Onboarding.Major {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.askIfInAppleFamily, .primary):
      return .onboarding(.major(.explainFixAccountTypeEasyWay))
    case (.askIfInAppleFamily, .secondary):
      return .onboarding(.supervision(.intro))
    case (.askIfInAppleFamily, .tertiary):
      return .onboarding(.major(.explainAppleFamily))
    case (.askIfOtherIsParent, .primary):
      return .onboarding(.major(.explainFixAccountTypeEasyWay))
    case (.askIfOtherIsParent, _):
      return .onboarding(.major(.askIfOwnsMac))
    case (.askIfOwnsMac, _):
      return .onboarding(.supervision(.intro))
    case (.askSelfOrOtherIsOnboarding, .tertiary):
      return .onboarding(.major(.askIfInAppleFamily))
    case (.askSelfOrOtherIsOnboarding, _):
      return .onboarding(.major(.askIfOtherIsParent))
    case (.explainAppleFamily, _):
      return .onboarding(.major(.askIfInAppleFamily))
    case (.explainFixAccountTypeEasyWay, .primary):
      return .onboarding(.happyPath(.confirmMinorDevice))
    case (.explainFixAccountTypeEasyWay, _):
      return .onboarding(.major(.askIfOwnsMac))
    case (.explainHarderButPossible, _):
      return .onboarding(.major(.askSelfOrOtherIsOnboarding))
    }
  }
}

extension IOSReducer.Onboarding.HappyPath {
  func fallbackDestination(from btn: OnboardingBtn) -> IOSReducer.Screen {
    switch (self, btn) {
    case (.batteryWarning, _):
      return .onboarding(.happyPath(.requestAppStoreRating))
    case (.cacheCleared, _):
      return .onboarding(.happyPath(.requestAppStoreRating))
    case (.clearingCache(let bytes), _):
      return .onboarding(.happyPath(.clearingCache(bytes)))
    case (.confirmChildsDevice, .primary):
      return .onboarding(.happyPath(.explainMinorOrSupervised))
    case (.confirmChildsDevice, _):
      return .onboarding(.onParentDeviceFail)
    case (.confirmInAppleFamily, .primary):
      return .onboarding(.happyPath(.explainTwoInstallSteps))
    case (.confirmInAppleFamily, .secondary):
      return .onboarding(.appleFamily(.explainRequiredForFiltering))
    case (.confirmInAppleFamily, .tertiary):
      return .onboarding(.appleFamily(.explainWhatIsAppleFamily))
    case (.confirmMinorDevice, .primary):
      return .onboarding(.happyPath(.confirmParentIsOnboarding))
    case (.confirmMinorDevice, _):
      return .onboarding(.major(.explainHarderButPossible))
    case (.confirmParentIsOnboarding, .primary):
      return .onboarding(.happyPath(.confirmInAppleFamily))
    case (.confirmParentIsOnboarding, _):
      return .onboarding(.childIsOnboardingFail)
    case (.doneQuit, _):
      return .running(showVendorId: false)
    case (.dontGetTrickedPreAuth, _):
      return .onboarding(.happyPath(.explainAuthWithParentAppleAccount))
    case (.dontGetTrickedPreInstall, _):
      return .onboarding(.happyPath(.explainInstallWithDevicePasscode))
    case (.explainAuthWithParentAppleAccount, _):
      return .onboarding(.happyPath(.dontGetTrickedPreAuth))
    case (.explainInstallWithDevicePasscode, _):
      return .onboarding(.happyPath(.dontGetTrickedPreInstall))
    case (.explainMinorOrSupervised, _):
      return .onboarding(.happyPath(.confirmMinorDevice))
    case (.explainTwoInstallSteps, _):
      return .onboarding(.happyPath(.explainAuthWithParentAppleAccount))
    case (.hiThere, _):
      return .onboarding(.happyPath(.timeExpectation))
    case (.optOutBlockGroups, _):
      return .onboarding(.happyPath(.explainTwoInstallSteps))
    case (.promptClearCache, _):
      return .onboarding(.happyPath(.requestAppStoreRating))
    case (.requestAppStoreRating, _):
      return .onboarding(.happyPath(.doneQuit))
    case (.timeExpectation, _):
      return .onboarding(.happyPath(.confirmChildsDevice))
    }
  }
}
